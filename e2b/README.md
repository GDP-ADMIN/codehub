# E2B Sandbox Manager

A comprehensive Python utility for managing E2B sandboxes using both the E2B CLI and Python SDK. This tool provides a unified interface for creating, listing, and managing cloud development environments.

## Features

- **Dual Interface Support**: Works with both E2B CLI and Python SDK
- **Authentication Management**: Automatic CLI authentication using access tokens
- **Sandbox Operations**: Create, list, and manage sandboxes
- **Template Management**: Check available templates and create sandboxes with specific templates
- **Error Handling**: Comprehensive error handling with fallback mechanisms
- **Environment Configuration**: Secure configuration using environment variables

## Prerequisites

- Python 3.7+
- E2B CLI installed (`pip install e2b`)
- E2B Python SDK (`pip install e2b`)
- Valid E2B API credentials

## Installation

1. Clone or download the project files
2. Install required dependencies:

```bash
pip install e2b python-dotenv
```

3. Create a `.env` file in the project directory with your E2B credentials:

```env
E2B_API_KEY=your_api_key_here
E2B_ACCESS_TOKEN=your_access_token_here
DOMAIN=glair.id
```

## Configuration

The script requires the following environment variables:

| Variable | Description | Required | Default |
|----------|-------------|----------|---------|
| `E2B_API_KEY` | Your E2B API key | Yes | - |
| `E2B_ACCESS_TOKEN` | Your E2B access token | Yes | - |
| `DOMAIN` | E2B domain | Yes | `glair.id` |

## Usage

### Running the Script

Simply execute the script to run the complete workflow:

```bash
python e2b-sandbox.py
```

The script will automatically:
1. Authenticate with E2B CLI
2. Check available templates
3. List existing sandboxes
4. Create a new sandbox
5. Fall back to Python SDK if CLI authentication fails

### Available Functions

#### CLI Operations

- `authenticate_cli()`: Authenticate with E2B CLI using access token
- `create_sandbox_cli(template)`: Create a new sandbox using CLI
- `list_sandboxes_cli()`: List all existing sandboxes
- `check_existing_sandbox_cli(sandbox_id)`: Get information about a specific sandbox
- `check_e2b_templates_cli()`: List available templates via CLI

#### Python SDK Operations

- `create_sandbox(template)`: Create a new sandbox using Python SDK
- `check_e2b_templates()`: List available templates (hardcoded list)

### Supported Templates

The script supports the following E2B templates:

- `base` - Basic environment
- `node` - Node.js environment
- `python` - Python environment
- `react` - React development environment
- `nextjs` - Next.js environment
- `vue` - Vue.js environment
- `angular` - Angular environment
- `django` - Django framework
- `flask` - Flask framework
- `fastapi` - FastAPI framework

## Example Usage

### Creating Sandbox using command

```
export E2B_ACCESS_TOKEN=”e2b_xxxx”
E2B_DOMAIN=glair.id e2b sandbox spawn rki5dems9wqfm4r03t7g

```

### Listing All Sandboxes

```
export E2B_ACCESS_TOKEN=”e2b_xxxx”
E2B_DOMAIN=glair.id e2b sandbox list

```
### Other command e2b CLI
```
export E2B_ACCESS_TOKEN=”e2b_xxxx”
E2B_DOMAIN=glair.id e2b help

Commands:
  auth            authentication commands
  template|tpl    manage sandbox templates
  sandbox|sbx     work with sandboxes

```


## Error Handling

The script includes comprehensive error handling:

- **Authentication Failures**: Falls back to Python SDK if CLI authentication fails
- **Network Errors**: Graceful handling of connection issues
- **Invalid Credentials**: Clear error messages for missing or invalid credentials
- **Template Errors**: Handles invalid template specifications

## Logging

The script uses Python's logging module with DEBUG level enabled. All operations are logged for debugging purposes.

## Security Notes

- Never commit your `.env` file to version control
- Keep your API keys and access tokens secure
- The script automatically loads environment variables from `.env` file
- All sensitive operations use environment variables instead of hardcoded values

## Troubleshooting

### Common Issues

1. **Authentication Failed**
   - Verify your `E2B_ACCESS_TOKEN` is correct
   - Check if the token has expired

2. **API Key Issues**
   - Verify your `E2B_API_KEY` is correct
   - Ensure the API key has the required permissions

3. **CLI Not Found**
   - Install E2B CLI: `pip install e2b`
   - Ensure the CLI is in your PATH


## Contributing

Feel free to submit issues and enhancement requests!

## License

This project is open source and available under the [MIT License](LICENSE).

## Support

For E2B-specific issues, refer to the [E2B Documentation](https://e2b.dev/docs).
