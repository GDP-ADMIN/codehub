#!/bin/bash

# Load environment variables from .env file
if ! [ -f .env ]; then
  echo "WARN: .env file not found. Copied .env.example to .env file as initial configuration."
  cp .env.example .env
fi

export $(grep -v '^#' .env | xargs)

# Check if required environment variables are set
required_vars=("LOGSTASH_HOSTS" "OPENSEARCH_USERNAME" "OPENSEARCH_PASSWORD" "FILEBEAT_VERSION" "HOSTNAME")

OPENSEARCH_USERNAME=${OPENSEARCH_USERNAME:-admin}
OPENSEARCH_PASSWORD=${OPENSEARCH_PASSWORD:-SamaJugaTerbaik120}
FILEBEAT_VERSION=${FILEBEAT_VERSION:-8.15.2}

for var in "${required_vars[@]}"; do
  if [ -z "${!var}" ]; then
    echo "Error: $var is not set in the .env file."
    exit 1
  fi
done

# Install Docker if it's not installed
if ! [ -x "$(command -v docker)" ]; then
  echo "Docker is not installed. Follow this guide: https://docs.docker.com/engine/install/"
  exit 1
fi

# Filebeat configuration template directory
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

# Start Filebeat using Docker
docker compose up -d --wait
