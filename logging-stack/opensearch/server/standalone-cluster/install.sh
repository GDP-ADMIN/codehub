#!/bin/bash

# Load environment variables from .env file
if ! [ -f .env ]; then
  echo "WARN: .env file not found. Copied .env.example to .env file as initial configuration."
  cp .env.example .env
fi

export $(grep -v '^#' .env | xargs)

# Check if required environment variables are set
required_vars=("OPENSEARCH_VERSION" "OPENSEARCH_INITIAL_ADMIN_PASSWORD" "LOGSTASH_VERSION" "LOGGING_INDEX_NAME" "GDPLABS_ANONYMIZER_VERSION")

OPENSEARCH_VERSION=${OPENSEARCH_VERSION:-2.17.1}
OPENSEARCH_INITIAL_ADMIN_PASSWORD=${OPENSEARCH_INITIAL_ADMIN_PASSWORD:-SamaJugaTerbaik120}
LOGSTASH_VERSION=${LOGSTASH_VERSION:-8.15.2}
LOGGING_INDEX_NAME=${LOGGING_INDEX_NAME:-logs-%{+YYYY.MM.dd\}}
GDPLABS_ANONYMIZER_VERSION=${GDPLABS_ANONYMIZER_VERSION:-0277c3f}

for var in "${required_vars[@]}"; do
  if [ -z "${!var}" ]; then
    echo "Error: $var is not set in the .env file."
    exit 1
  fi
done

# Ask user to install Docker if not installed
if ! [ -x "$(command -v docker)" ]; then
  echo "docker is not installed. Follow this guide: https://docs.docker.com/engine/install/"
  exit 1
fi

# Check if swap is enabled and disable it
if [ "$(swapon --noheadings)" ]; then
  echo "Swap is currently enabled. Disabling swap temporarily..."
  sudo swapoff -a
  echo "Swap has been disabled for this session."
else
  echo "Swap is already disabled."
fi

# Suggest disabling swap permanently
echo "To disable swap permanently, edit /etc/fstab and remove or comment out the swap entry."

# Directory containing the template files
TEMPLATE_DIR="template/"

# Replace variables in all template files and remove '-template' from filenames (handles any extension)
for file in "$TEMPLATE_DIR"/*-template.*; do
  sed_command="sed"

  for var in "${required_vars[@]}"; do
    escaped_value=$(printf '%s\n' "${!var}" | sed 's/[&/\]/\\&/g')
    sed_command+=" -e 's/\${$var}/$escaped_value/g'"
  done

  output_file="${file##*/}"
  output_file="${output_file%-template.*}.${file##*.}"

  sed_command+=" \"$file\" > \"./$output_file\""
  bash -c "$sed_command"
done

# Start ELK stack using Docker Compose
docker network create infra || :
docker compose up -d --wait

# Create index-pattern
curl \
  -X POST "http://localhost:5601/api/saved_objects/index-pattern/Logs" \
  -H 'osd-xsrf: true' \
  -H 'Content-Type: application/json' \
  -H "securitytenant: global" \
  -u "admin:$OPENSEARCH_INITIAL_ADMIN_PASSWORD" \
  -d '{"attributes":{"title": "'"${LOGGING_INDEX_NAME%%\%*}*"'", "timeFieldName": "@timestamp"}}'
