# 1-Click OAuth2 Proxy Setup

This repository contains a bash script that simplifies the setup of OAuth2 Proxy with Nginx for securing your web applications using Google OAuth authentication.

## Overview

The script automates the deployment of:
- OAuth2 Proxy for authentication
- Nginx as a reverse proxy
- SSL certificate generation
- Docker container setup and configuration

## Prerequisites

- Docker and Docker Compose installed
- bash shell environment
- openssl for SSL certificate generation
- nano text editor (for .env file editing)
- Basic understanding of OAuth2 and Google OAuth credentials

## User Interaction Guide

When running the script "Option 1: One-Click Deployment or Option 2: Manual Installation" , you'll be prompted to provide the following values:

1. **OAuth2 Proxy Client ID**
   - Description: Your Google OAuth application's Client ID
   - Example: `123456789-abcdef.apps.googleusercontent.com`
   - Where to get it: Google Cloud Console > APIs & Services > Credentials

2. **OAuth2 Proxy Client Secret**
   - Description: Your Google OAuth application's Client Secret
   - Example: `GOCSPX-abcdefghijklmnopqrstuvwxyz`
   - Where to get it: Google Cloud Console > APIs & Services > Credentials

3. **Backend Port**
   - Description: The port number where your application is running
   - Example: `3000`
   - Note: Must be a valid port number (1-65535)

4. **Domain Name**
   - Description: Your application's domain name
   - Example: `app.example.com`
   - Note: This will be used for SSL certificate generation

5. **Whitelist Domains**
   - Description: Comma-separated list of email domains allowed to access
   - Example: `example.com,company.com`
   - Note: Use `*` to allow all domains

After providing these values, the script will:
- Generate a secure cookie secret on
- Create persistent environtment .env
- Create SSL certificates
- Set up Nginx configuration
- Configure Docker containers
- Start the services

## Deployment Options

### Option 1: One-Click Deployment (Recommended)
The fastest way to deploy OAuth2 Proxy with Nginx. Simply run:
```bash
wget https://raw.githubusercontent.com/GDP-ADMIN/codehub/refs/heads/main/oauth2-proxy/1click-oauth2-proxy.sh -O 1click-oauth2-proxy.sh | chmod a+x 1click-oauth2-proxy.sh; ./1click-oauth2-proxy.sh
```

### Option 2: Manual Installation
For users who prefer manual control over the deployment process:
1. Clone this repository
2. Make the script executable:
   ```bash
   chmod +x 1click-oauth2-proxy.sh
   ```
3. Run the script:
   ```bash
   ./1click-oauth2-proxy.sh
   ```

### Option 3: DevSecOps Managed Deployment
For production environments, you can request deployment through our DevSecOps team:

1. Contact your DevSecOps team lead or manager
   or
   Send an email to `ticket@gdplabs.id`
3. Use the following subject format:
   ```
   [Production Deployment] OAuth2 Proxy Setup for {Your Application Name}
   ```
3. Include the following information in your request:
   - Application name
   - Target domain
   - Required backend port
   - Expected traffic volume
   - Any specific security requirements

Our DevSecOps team will review your request and assist with the deployment process.

## Configuration

When you run the script for the first time, you'll be prompted to provide:

- OAuth2 Proxy Client ID (from Google Cloud Console)
- OAuth2 Proxy Client Secret (from Google Cloud Console)
- Backend Port (the port of your application to secure)
- Domain Name (your application's domain)
- Whitelist Domains (comma-separated list of allowed domains)

These configurations are stored in a `.env` file and can be edited later using the nano editor.

## Features

- **Automatic SSL Setup**: Generates self-signed SSL certificates
- **Secure Configuration**: 
  - HTTP to HTTPS redirection
  - Secure cookie settings
  - CSRF protection
  - Proper header forwarding
- **Docker Integration**:
  - Uses official OAuth2 Proxy and Nginx images
  - Automatic container orchestration
  - Persistent configuration

## Security Features

- Cookie-based session management
- CSRF protection
- Secure SSL/TLS configuration
- Header-based authentication forwarding
- Whitelist domain support

## Environment Variables

The following environment variables are configured automatically:

- `OAUTH2_PROXY_CLIENT_ID`: Google OAuth client ID
- `OAUTH2_PROXY_CLIENT_SECRET`: Google OAuth client secret
- `OAUTH2_PROXY_COOKIE_SECRET`: Automatically generated secure cookie secret
- `BACKEND_PORT`: Your application's port
- `DOMAIN_NAME`: Your application's domain
- `WHITELIST_DOMAINS`: Allowed email domains

## Directory Structure

```
.
├── 1click-oauth2-proxy.sh
├── .env
├── docker-compose.yml
└── nginx/
    ├── nginx.conf
    ├── domain.pem
    └── domain.key
```

## Troubleshooting

1. Check container logs:
   ```bash
   docker compose logs oauth2-proxy
   docker compose logs nginx
   ```

2. Verify services are running:
   ```bash
   docker compose ps
   ```

3. Common issues:
   - Port conflicts: Ensure ports 80, 443, and your backend port are available
   - SSL certificate issues: Check nginx/domain.pem and nginx/domain.key exist
   - OAuth2 configuration: Verify your Google OAuth credentials

## License

This project is open source and available under the MIT License.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request. 