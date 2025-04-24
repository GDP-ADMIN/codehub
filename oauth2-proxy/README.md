<!-- Logo -->
<p align="center">
  <img src="https://raw.githubusercontent.com/oauth2-proxy/oauth2-proxy/master/docs/static/img/logos/OAuth2_Proxy_horizontal.svg" alt="OAuth2 Proxy Logo" width="500"/>
</p>

# 1-Click OAuth2 Proxy Setup

## Introduction

Welcome to the 1-Click OAuth2 Proxy Setup! This project provides a simple, automated way to secure your web applications using Google OAuth authentication, Nginx as a reverse proxy, and Docker for container orchestration. With a single script, you can deploy a production-ready authentication proxy with minimal manual configuration. This solution is ideal for developers and DevOps teams who want to quickly add OAuth2-based authentication to their services.

## How It Works

1. **User Access:**
   - The user visits your web application via the domain configured in the script.
2. **Nginx Reverse Proxy:**
   - Nginx receives the request and checks if the user is authenticated.
   - If not authenticated, Nginx forwards the request to the OAuth2 Proxy service.
3. **OAuth2 Proxy Authentication:**
   - OAuth2 Proxy redirects the user to Google OAuth for login.
   - The user logs in with their Google account and grants access.
   - Google redirects the user back to OAuth2 Proxy with an authentication code.
   - OAuth2 Proxy exchanges the code for user info and sets a secure cookie.
4. **Access to Backend:**
   - Once authenticated, Nginx proxies the request to your backend application, passing user identity headers.
   - The backend receives the request with user information and serves the response.
5. **SSL Handling:**
   - The script can generate a self-signed SSL certificate for development/testing, or you can provide your own for production.
6. **Container Orchestration:**
   - All services (Nginx, OAuth2 Proxy) run in Docker containers managed by Docker Compose for easy deployment and management.

<p align="center">
  <img src="https://github.com/oauth2-proxy/oauth2-proxy/raw/master/docs/static/img/simplified-architecture.svg" alt="OAuth2 Proxy Architecture" width="600"/>
</p>

## Reference

- [oauth2-proxy GitHub Repository](https://github.com/oauth2-proxy/oauth2-proxy)

This repository contains a bash script that simplifies the setup of OAuth2 Proxy with Nginx for securing your web applications using Google OAuth authentication.

## Overview

The script automates the deployment of:
- **OAuth2 Proxy** for authentication
- **Nginx** as a reverse proxy
- **SSL certificate generation**
- **Docker container setup and configuration**

## Prerequisites

- **OAuth Provider Credentials** (Client ID and Client Secret)
  - Google, GitHub, Azure, OIDC, or other supported providers. See instructions below on how to create these credentials for your provider.
- **Docker and Docker Compose** installed
- **bash** shell environment
- **openssl** for SSL certificate generation
- **nano** text editor (for .env file editing)
- **SSL Certificate (optional):** If you do not have a valid SSL certificate, the script can generate a self-signed certificate for testing purposes. For production, you should use a valid SSL certificate.
- Basic understanding of OAuth2 and your chosen OAuth provider's credentials

> **Note:** The script will check for required dependencies (`docker`, `docker compose` or `docker-compose`, `openssl`, `lsof`) and provide install instructions if missing.

### How to Create Google OAuth Credentials

1. Go to the [Google Cloud Console](https://console.cloud.google.com/).
2. Select your project or create a new one.
3. Navigate to **APIs & Services > Credentials**.
4. Click **+ CREATE CREDENTIALS** and select **OAuth client ID**.
5. If prompted, configure the consent screen (fill in required fields).
6. Choose **Web application** as the application type.
7. Set an appropriate name (e.g., "OAuth2 Proxy").
8. Under **Authorized redirect URIs**, add:
   ```
   https://<your-domain>/oauth2/callback
   ```
   Replace `<your-domain>` with your actual domain name.
9. Click **Create**.
10. Copy the **Client ID** and **Client Secret**. You will need these for the script.

> **Using another provider?** See [Using Other OAuth Providers](#using-other-oauth-providers) for GitHub, Azure, OIDC, and more.

## Deployment Options

### 🚀 Option 1: One-Click Deployment (Recommended)
The fastest way to deploy OAuth2 Proxy with Nginx. Simply run:
```bash
wget https://raw.githubusercontent.com/GDP-ADMIN/codehub/refs/heads/main/oauth2-proxy/1click-oauth2-proxy.sh -O 1click-oauth2-proxy.sh | chmod a+x 1click-oauth2-proxy.sh; ./1click-oauth2-proxy.sh
```

### 🛠 Option 2: Manual Installation
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

### 🏢 Option 3: DevSecOps Managed Deployment
For production environments, you can request deployment through our DevSecOps team:

1. Contact your DevSecOps team lead or manager
2. Or send an email to `ticket@gdplabs.id`
3. Use the following subject format:
   ```
   [Production Deployment] OAuth2 Proxy Setup for {Your Application Name}
   ```
4. Include the following information in your request:
   - Application name
   - Target domain
   - Required backend port
   - Expected traffic volume
   - Any specific security requirements

Our DevSecOps team will review your request and assist with the deployment process.

## Configuration

When you run the script for the first time, you'll be prompted to provide:

- **OAuth2 Proxy Provider** (e.g., google, github, azure, oidc)
- **OAuth2 Proxy Client ID** (from your OAuth provider)
- **OAuth2 Proxy Client Secret** (from your OAuth provider)
- **Backend Port** (the port of your application to secure)
- **Domain Name** (your application's domain)
- **Whitelist Domains** (comma-separated list of allowed domains)
- **SSL Certificate:** You can provide your own certificate and key, or let the script generate a self-signed certificate for you (recommended only for development/testing).

These configurations are stored in a `.env` file and can be edited later using the nano editor.

## Features

- **Automatic SSL Setup:** Generates self-signed SSL certificates if you do not provide your own
- **Secure Configuration:**
  - HTTP to HTTPS redirection
  - Secure cookie settings
  - CSRF protection
  - Proper header forwarding
- **Docker Integration:**
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

```text
.
├── 1click-oauth2-proxy.sh
├── .env
├── docker-compose.yml
└── nginx/
    ├── nginx.conf
    ├── domain.pem
    └── domain.key
```

## Troubleshooting & FAQ

1. **Check container logs:**
   ```bash
   docker compose logs oauth2-proxy
   docker compose logs nginx-oauth2-proxy
   ```

2. **Verify services are running:**
   ```bash
   docker compose ps
   ```

3. **Common issues:**
   - **Port conflicts:** Ensure ports 80, 443, and your backend port are available and not used by other services (e.g., Apache, another Nginx, or other containers).
   - **SSL certificate issues:** Check that `nginx/domain.pem` and `nginx/domain.key` exist and are readable. If you provided your own certificate, ensure the paths are correct and the files are valid.
   - **OAuth2 configuration:** Verify your Google OAuth credentials are correct and that the redirect URI matches what you set in the Google Cloud Console.
   - **.env file issues:** Make sure the `.env` file exists and contains all required variables. If you edit it manually, avoid extra spaces or quotes.
   - **Docker Compose not found:** If you see errors about `docker compose` or `docker-compose` not being found, install Docker Compose with `sudo apt install docker-compose` or update Docker to a recent version that includes the `docker compose` subcommand.
   - **Permission denied:** If you get permission errors, try running the script or Docker commands with `sudo`.
   - **Firewall issues:** Ensure your firewall allows inbound connections on ports 80 and 443.
   - **Browser SSL warnings:** If using a self-signed certificate, browsers will show a warning. This is expected for development/testing. For production, use a valid SSL certificate.
   - **Container restart loops:** Check logs for misconfiguration, missing environment variables, or port conflicts.
   - **Network issues:** If containers cannot communicate, ensure Docker networking is functioning and not blocked by system policies.
   - **OAuth redirect fails / Google Auth fails in browser:**
     - **Error 400:** This usually means the redirect URI registered in your Google Cloud Console does not exactly match the URI used by OAuth2 Proxy. Double-check for typos, missing paths, or protocol mismatches (http vs https).
     - **Error on redirect:** Ensure your application's domain and the redirect URI in Google Cloud Console are correct and use HTTPS if required. Also, make sure your local machine or server is accessible from the browser and not blocked by firewalls or NAT.
     - **Unauthenticated error:** This can occur if the OAuth2 Proxy is not able to validate the authentication cookie, or if the session has expired. Try clearing your browser cookies, ensure your system clock is correct, and verify that the `OAUTH2_PROXY_COOKIE_SECRET` is set and consistent across restarts.
     - **General troubleshooting:**
       - Check the logs of both `oauth2-proxy` and `nginx-oauth2-proxy` containers for detailed error messages.
       - Make sure your Google OAuth credentials (Client ID/Secret) are correct and active.
       - If using self-signed SSL, your browser may block or warn about the callback; accept the risk for development, but use a valid certificate for production.
       - If running locally, use `localhost` or a domain mapped to `127.0.0.1` and ensure it matches the Google Cloud Console configuration.

4. **Still having trouble?**
   - Review the logs for both containers for error messages.
   - Double-check your Google OAuth credentials and redirect URIs.
   - Consult the [oauth2-proxy documentation](https://oauth2-proxy.github.io/oauth2-proxy/docs/) for advanced configuration and troubleshooting.
   - Search for your error message in the [oauth2-proxy GitHub issues](https://github.com/oauth2-proxy/oauth2-proxy/issues).
   - **If you are still having issues, contact your DevSecOps team or email `ticket@gdplabs.id` for further assistance.**

## Example Output

When the script completes successfully, you should see output similar to:

```text
✅ All services are up and running!
🔑 Oauth2-proxy is running at: http://localhost:4180
🌟 Your site is available on:  http://your-domain  and  https://your-domain
```

## License

This project is open source and available under the MIT License.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## Using Other OAuth Providers

While this script and guide focus on Google OAuth, **OAuth2 Proxy** supports many other providers, such as GitHub, GitLab, Microsoft Azure, Facebook, and generic OIDC providers.

---

### 🌟 Example: GitHub OAuth Setup

1. **Register a new OAuth application** at [GitHub Developer Settings](https://github.com/settings/developers).
2. Set the **Authorization callback URL** to:
   ```
   https://<your-domain>/oauth2/callback
   ```
3. Note your **Client ID** and **Client Secret**.
4. When prompted by the script, set:
   - `OAUTH2_PROXY_PROVIDER=github`
   - `OAUTH2_PROXY_CLIENT_ID` and `OAUTH2_PROXY_CLIENT_SECRET` to your GitHub values.

---

### 🌟 Example: Microsoft Azure AD Setup

1. **Register an application** in [Azure Portal](https://portal.azure.com/).
2. Set the **Redirect URI** to:
   ```
   https://<your-domain>/oauth2/callback
   ```
3. Note your **Application (client) ID** and **Client Secret**.
4. When prompted by the script, set:
   - `OAUTH2_PROXY_PROVIDER=azure`
   - `OAUTH2_PROXY_CLIENT_ID` and `OAUTH2_PROXY_CLIENT_SECRET` to your Azure values.
   - You may also need to set `OAUTH2_PROXY_TENANT_ID` as an environment variable.

---

### 🌟 Example: Generic OIDC Provider

1. Register your application with your OIDC provider.
2. Set the **Redirect URI** to:
   ```
   https://<your-domain>/oauth2/callback
   ```
3. Note your **Client ID** and **Client Secret**.
4. When prompted by the script, set:
   - `OAUTH2_PROXY_PROVIDER=oidc`
   - `OAUTH2_PROXY_CLIENT_ID` and `OAUTH2_PROXY_CLIENT_SECRET` to your OIDC values.
   - Set `OAUTH2_PROXY_OIDC_ISSUER_URL` to your provider's issuer URL.

---

For more details and a full list of supported providers and their configuration options, see the [OAuth2 Proxy Provider Documentation](https://oauth2-proxy.github.io/oauth2-proxy/docs/configuration/oauth_provider/).
