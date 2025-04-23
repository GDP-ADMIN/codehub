#!/bin/bash
# set -x
set -e  # Exit immediately if a command exits with a non-zero status
# Detect OS
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=$ID
else
    OS="unknown"
fi

if [[ "$OS" != "debian" && "$OS" != "ubuntu" ]]; then
    echo "This script only supports Debian or Ubuntu."
    exit 1
fi

missing=()

# Check lsof
if ! command -v lsof >/dev/null 2>&1; then
    missing+=("lsof")
fi

# Check docker compose or docker-compose
if ! command -v docker compose >/dev/null 2>&1; then
  if ! command -v docker-compose >/dev/null 2>&1; then
    missing+=("docker-compose")
  fi
fi

# Check openssl
if ! command -v openssl >/dev/null 2>&1; then
    missing+=("openssl")
fi

if [ ${#missing[@]} -ne 0 ]; then
    echo "Error: The following packages are missing: ${missing[*]}"
    echo "To install them, run:"
    echo "  sudo apt update && sudo apt install ${missing[*]}"
    exit 1
else
    echo "All required packages are installed."
fi

# Check if nginx-oauth2-proxy container is already running

if command -v docker compose >/dev/null 2>&1; then
  DOCKER_COMPOSE_CMD="docker compose"
elif command -v docker-compose >/dev/null 2>&1; then
  DOCKER_COMPOSE_CMD="docker-compose"
else
  echo "Error: Neither 'docker compose' nor 'docker-compose' is installed."
  echo "To install Docker Compose, run:"
  echo "  sudo apt update && sudo apt install docker-compose"
  exit 1
fi

if $DOCKER_COMPOSE_CMD ps | grep -q "nginx-oauth2-proxy"; then
  echo "nginx-oauth2-proxy container is already running."
else
  # Check if port 80 or 443 is in use only if container is not running
  if lsof -Pi :80 -sTCP:LISTEN -t >/dev/null || lsof -Pi :443 -sTCP:LISTEN -t >/dev/null; then
    echo "Error: Port 80 or 443 is already in use. This script does not support running alongside another nginx instance."
    echo "Please stop any existing services using these ports or configure manually."
    exit 1
  fi
fi

# Function to read user input
prompt_user_input() {
    read -p "$1: " input
    echo $input
}

# Function to create or edit the .env file
setup_env_file() {
    if [ ! -f ".env" ]; then
        echo "Creating .env file. Please provide the required inputs."
        
        # Prompt for required values
        OAUTH2_PROXY_CLIENT_ID=$(prompt_user_input "Enter OAuth2 Proxy Client ID")
        OAUTH2_PROXY_CLIENT_SECRET=$(prompt_user_input "Enter OAuth2 Proxy Client Secret")        
        DOMAIN_NAME=$(prompt_user_input "Enter your domain name (e.g., yourdomain.com)")
        WHITELIST_DOMAINS=$(prompt_user_input "Enter domains to whitelist (comma-separated, e.g., example.com,another.com)")

        # Check for empty inputs
        if [ -z "$OAUTH2_PROXY_CLIENT_ID" ] || [ -z "$OAUTH2_PROXY_CLIENT_SECRET" ] || [ -z "$DOMAIN_NAME" ] || [ -z "$WHITELIST_DOMAINS" ]; then
            echo "All fields are required. Exiting..."
            exit 1
        fi
        BACKEND_PORT=$(prompt_user_input "Enter the port for the backend service to secure (e.g., 3000)")
        # Validate backend port input
        if ! [[ "$BACKEND_PORT" =~ ^[0-9]+$ ]]; then
            echo "Invalid port number."
            exit 1
        fi
        # Generate a 32-byte random base64 cookie secret
        OAUTH2_PROXY_COOKIE_SECRET=$(openssl rand -base64 24)  # 24 bytes => Base64 == 32 bytes

        # Create .env file
      {
            echo "# OAuth2 Proxy Client ID"
            echo "OAUTH2_PROXY_CLIENT_ID=$OAUTH2_PROXY_CLIENT_ID"
            echo "# OAuth2 Proxy Client Secret"
            echo "OAUTH2_PROXY_CLIENT_SECRET=$OAUTH2_PROXY_CLIENT_SECRET"
            echo "# Secret for signing cookies"
            echo "OAUTH2_PROXY_COOKIE_SECRET=$OAUTH2_PROXY_COOKIE_SECRET"
            echo "# Port for the backend service to secure (e.g., 3000)"
            echo "BACKEND_PORT=$BACKEND_PORT"
            echo "# Your domain name (e.g., yourdomain.com)"
            echo "DOMAIN_NAME=$DOMAIN_NAME"
            echo "# Domains to whitelist (comma-separated, e.g., example.com,another.com)"
            echo "WHITELIST_DOMAINS=$WHITELIST_DOMAINS"
        } > .env
        echo ".env file created successfully."
    else
        echo ".env file already exists. Opening in nano for editing..."
        sleep 3
        nano .env
    fi
}

# Setup .env file
setup_env_file

# Load environment variables from the .env file
source .env

# Check if the given port is already in use
if lsof -Pi :4180 -sTCP:LISTEN -t >/dev/null; then
    echo "Port 4180 is already in use. oauth2-proxy need that port"
    exit 1
fi

# Define the paths for SSL certificate and key
SSL_DIR="./nginx"
SSL_CERT="$SSL_DIR/${DOMAIN_NAME//./_}.pem"  # Replace dots with underscores for filename validity
SSL_KEY="$SSL_DIR/${DOMAIN_NAME//./_}.key"
NGINX_CONF_DIR="./nginx"
NGINX_CONF_FILE="$NGINX_CONF_DIR/nginx.conf"

# Create SSL and Nginx directories
mkdir -p "$SSL_DIR" "$NGINX_CONF_DIR"

# Ask user if they want to use their own SSL certificate
read -p "Do you want to use your own SSL certificate? (y/N), Enter when already setup before: " use_custom_cert
if [[ "$use_custom_cert" =~ ^[Yy]$ ]]; then
  echo "Please enter the full absolute path to your SSL certificate and key files."
  read -p "Enter the full path to your SSL certificate (.pem): " custom_cert
  read -p "Enter the full path to your SSL private key (.key): " custom_key
  # Check if the provided paths are valid
  if [ ! -f "$custom_cert" ] || [ ! -f "$custom_key" ]; then
    echo "Error: Provided certificate or key file does not exist."
    exit 1
  else
    # Copy custom certificate and key to SSL_DIR
    cp -uf "$custom_cert" "$SSL_CERT"
    cp -uf "$custom_key" "$SSL_KEY"
    SSL_CERT="$SSL_CERT"
    SSL_KEY="$SSL_KEY"
    echo "Using custom SSL certificate and key."
  fi
else
  # Check if SSL certificate and key already exist, if not create them
  if [ ! -f "$SSL_CERT" ] || [ ! -f "$SSL_KEY" ]; then
    echo "Generating self-signed SSL certificate for $DOMAIN_NAME..."
    openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
      -keyout "$SSL_KEY" -out "$SSL_CERT" \
      -subj "/C=ID/ST=Jakarta/L=Jakarta/O=GDPLabs/OU=GDPLabs/CN=$DOMAIN_NAME"
  else
    echo "Using existing SSL certificate and key for $DOMAIN_NAME."
  fi
fi

# Create Nginx configuration file
cat <<EOF > "$NGINX_CONF_FILE"
server_tokens off;

server {
  listen 80 default_server;
  server_name $DOMAIN_NAME;

  # Redirect HTTP to HTTPS
  return 301 https://\$host\$request_uri;
}

server {
    listen 443 ssl;
    server_name $DOMAIN_NAME;

    ssl_certificate /etc/nginx/${DOMAIN_NAME//./_}.pem;
    ssl_certificate_key /etc/nginx/${DOMAIN_NAME//./_}.key;

    location /oauth2/ {
        proxy_pass       http://oauth2-proxy:4180;
        proxy_set_header Host                    \$host;
        proxy_set_header X-Real-IP               \$remote_addr;
        proxy_set_header X-Auth-Request-Redirect \$request_uri;
    }

    location = /oauth2/auth {
        proxy_pass       http://oauth2-proxy:4180;
        proxy_set_header Host             \$host;
        proxy_set_header X-Real-IP        \$remote_addr;
        proxy_set_header X-Forwarded-Uri  \$request_uri;
        proxy_set_header Content-Length   "";
        proxy_pass_request_body           off;
    }

    location / {
        auth_request /oauth2/auth;
        error_page 401 =302 /oauth2/start;

        # Backend application
        proxy_pass        http://localhost:$BACKEND_PORT;  # Secure backend on specified port

        proxy_set_header X-User  \$upstream_http_x_auth_request_user;
        proxy_set_header X-Email \$upstream_http_x_auth_request_email;
        proxy_set_header X-Access-Token \$upstream_http_x_auth_request_access_token;

        proxy_http_version 1.1;
        proxy_set_header Connection "";
        resolver_timeout 30s;
        proxy_read_timeout 3600;
        proxy_set_header X-Real-IP          \$remote_addr;
        proxy_set_header X-Forwarded-Host   \$http_host;
        proxy_set_header X-Forwarded-For    \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto  \$scheme;
        proxy_set_header Origin             \$scheme://\$http_host;
        proxy_set_header Host               \$http_host;
        proxy_set_header  X-Forwarded-Ssl on;
    }
}
EOF

# Create docker-compose.yml with oauth2-proxy and nginx
cat <<EOF > docker-compose.yml
services:
  oauth2-proxy:
    image: quay.io/oauth2-proxy/oauth2-proxy:latest
    container_name: oauth2-proxy
    restart: always
    ports:
      - "4180:4180"
    environment:
      - OAUTH2_PROXY_PROVIDER=google
      - OAUTH2_PROXY_CLIENT_ID=${OAUTH2_PROXY_CLIENT_ID}
      - OAUTH2_PROXY_CLIENT_SECRET=${OAUTH2_PROXY_CLIENT_SECRET}
      - OAUTH2_PROXY_COOKIE_SECRET=${OAUTH2_PROXY_COOKIE_SECRET}
      - OAUTH2_PROXY_EMAIL_DOMAINS=*
      - OAUTH2_PROXY_REVERSE_PROXY=true
      - OAUTH2_PROXY_HTTP_ADDRESS=0.0.0.0:4180
      - OAUTH2_PROXY_SET_AUTHORIZATION_HEADER=true
      - OAUTH2_PROXY_SET_XAUTHREQUEST=true
      - OAUTH2_PROXY_WHITELIST_DOMAINS=${WHITELIST_DOMAINS}
      - OAUTH2_PROXY_SKIP_PROVIDER_BUTTON=true
      - OAUTH2_PROXY_COOKIE_NAME=_oauth2_proxy
      - OAUTH2_PROXY_COOKIE_SAMESITE=lax
      - OAUTH2_PROXY_SHOW_DEBUG_ON_ERROR=true
      - OAUTH2_PROXY_COOKIE_SECURE=false
      - OAUTH2_PROXY_PASS_ACCESS_TOKEN=true
      - OAUTH2_PROXY_SKIP_AUTH_HEADERS=true
      - OAUTH2_PROXY_BANNER="-"
    command:
      - --http-address=0.0.0.0:4180
      - --upstream=https://$DOMAIN_NAME/oauth2/callback
      - --redirect-url=https://$DOMAIN_NAME/oauth2/callback
      - --whitelist-domain=${WHITELIST_DOMAINS//,/ }
      - --skip-provider-button=true
      - --skip-auth-preflight=true
      - --footer=pwpush.$DOMAIN_NAME
      - --reverse-proxy=true
      - --cookie-secure=true
      - --cookie-samesite=lax
      - --cookie-csrf-per-request=true
      - --cookie-domain=$DOMAIN_NAME
      - --cookie-expire=48h0m0s
      - --cookie-csrf-expire=3m
      - --cookie-refresh=1m
      - --relative-redirect-url=true

  nginx-oauth2-proxy:
    image: docker.io/library/nginx:stable-alpine
    container_name: nginx-oauth2-proxy
    restart: always
    volumes:
      - $NGINX_CONF_FILE:/etc/nginx/conf.d/default.conf
      - $SSL_CERT:/etc/nginx/${DOMAIN_NAME//./_}.pem
      - $SSL_KEY:/etc/nginx/${DOMAIN_NAME//./_}.key
    ports:
      - "80:80"
      - "443:443"
    depends_on:
      - oauth2-proxy
EOF

echo -e "\nRunning the Docker containers using the generated docker-compose.yml..."
# Start the Docker containers
$DOCKER_COMPOSE_CMD up -d --force-recreate

sleep 10
# Get the last 100 logs from the oauth2-proxy service
echo -e "\nFetching the last 100 logs from the oauth2-proxy service..."
$DOCKER_COMPOSE_CMD logs --tail 100

echo -e "\nGetting info of docker services..."
$DOCKER_COMPOSE_CMD ps
echo -e "\nAll services are up:"
echo "Nginx is running on http://$DOMAIN_NAME and https://$DOMAIN_NAME"
echo "Oauth2-proxy is running on http://localhost:4180"
