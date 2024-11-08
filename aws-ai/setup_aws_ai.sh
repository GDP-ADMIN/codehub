#!/bin/bash

# Version Script Information
VERSION="1.0.4"

# Capture the directory where the script was invoked
EXECUTION_DIR="$(pwd)"
export EXECUTION_DIR  # Export so child processes can access it

# Define Log File in the Execution Directory
LOG_FILE="$EXECUTION_DIR/setup.log"

# Redirect all stdout and stderr to the log file
exec > "$LOG_FILE" 2>&1

# Function to log messages to the log file with timestamps
log() {
  echo "$(date +"%Y-%m-%d %H:%M:%S") : [$1] $2"
}

# Function to handle errors by logging and exiting if critical
handle_error() {
  log "ERROR" "$1"
  exit 1
}

# Function to check internet connectivity
check_internet() {
  if ping -c 1 google.com &>/dev/null; then
    log "INFO" "Internet connectivity verified."
  else
    handle_error "No internet connection. Please check your network settings."
  fi
}

# Function to uninstall AWS CLI Version 1 if installed via pip
uninstall_awscli_pip() {
  if pip show awscli &>/dev/null; then
    log "INFO" "AWS CLI Version 1 detected via pip. Uninstalling..."
    pip uninstall -y awscli
    if [ $? -eq 0 ]; then
      log "INFO" "AWS CLI Version 1 uninstalled successfully."
    else
      handle_error "Failed to uninstall AWS CLI Version 1."
    fi
  else
    log "INFO" "No AWS CLI Version 1 detected via pip."
  fi
}

# Function to check if Python is installed
check_python_installed() {
  OS_TYPE="$(uname -s 2>/dev/null || echo "Windows")"
  case "$OS_TYPE" in
    WINDOWS*|CYGWIN*|MINGW*|MSYS*)
      if command -v python &>/dev/null; then
        PYTHON_CMD="python"
        log "INFO" "Python (likely Python 3) is already installed on Windows."
        return 0
      elif command -v python3 &>/dev/null; then
        PYTHON_CMD="python3"
        log "INFO" "Python3 is already installed on Windows."
        return 0
      else
        log "WARNING" "Python is not installed on Windows."
        return 1
      fi
      ;;
    Linux*|Darwin*)
      if command -v python3 &>/dev/null; then
        PYTHON_CMD="python3"
        log "INFO" "Python3 is already installed."
        return 0
      elif command -v python &>/dev/null; then
        PYTHON_CMD="python"
        log "INFO" "Python is already installed."
        return 0
      else
        log "WARNING" "Python is not installed."
        return 1
      fi
      ;;
    *)
      handle_error "Unsupported OS: $OS_TYPE."
      ;;
  esac
}

# Function to install Python3 and venv on Debian/Ubuntu-based systems
install_python3_venv() {
  log "INFO" "Attempting to install python3 and python3-venv..."
  if [[ "$(uname -s)" == "Linux" ]]; then
    sudo apt update
    if [ $? -ne 0 ]; then
      handle_error "Failed to update package lists."
    fi
    sudo apt install -y python3 python3-venv
    if [ $? -eq 0 ]; then
      log "INFO" "Successfully installed python3 and python3-venv."
    else
      handle_error "Failed to install python3 or python3-venv."
    fi
  else
    handle_error "install_python3_venv is only supported on Linux."
  fi
}

# Function to install Python3 on Windows using an external PowerShell script
install_python_windows() {
  log "INFO" "Python not found. Installing Python on Windows system..."

  # Set Execution Policy to allow script execution
  powershell -Command "Set-ExecutionPolicy RemoteSigned -Scope CurrentUser -Force"
  if [ $? -ne 0 ]; then
    handle_error "Failed to set PowerShell execution policy."
  fi

  # Download the PowerShell installer script
  powershell -Command "Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/GDP-ADMIN/codehub/refs/heads/main/devsecops/install_python.ps1' -OutFile 'install_python.ps1'"
  if [ $? -ne 0 ]; then
    handle_error "Failed to download install_python.ps1."
  fi
  log "INFO" "install_python.ps1 downloaded successfully."

  # Execute the installer script
  powershell -File install_python.ps1
  if [ $? -eq 0 ]; then
    log "INFO" "Python installed successfully via PowerShell."
    rm -f install_python.ps1
  else
    handle_error "Failed to install Python via PowerShell."
    rm -f install_python.ps1
    return 1
  fi

  # Re-check Python installation
  if command -v python &>/dev/null || command -v python3 &>/dev/null; then
    log "INFO" "Python is now installed on Windows."
    return 0
  else
    handle_error "Python installation verification failed."
    return 1
  fi
}

# Function to install AWS CLI if not already installed
install_aws_cli() {
  OS_TYPE="$(uname -s 2>/dev/null || echo "Windows")"
  if ! command -v aws &>/dev/null; then
    log "INFO" "AWS CLI not found. Installing AWS CLI..."
    case "$OS_TYPE" in
      WINDOWS*|CYGWIN*|MINGW*|MSYS*)
        # Define AWS CLI installer URL
        AWS_CLI_INSTALLER_URL="https://awscli.amazonaws.com/AWSCLIV2.msi"
        AWS_CLI_INSTALLER="AWSCLIV2.msi"

        # Download AWS CLI installer using PowerShell
        powershell.exe -Command "Invoke-WebRequest -Uri '$AWS_CLI_INSTALLER_URL' -OutFile '$AWS_CLI_INSTALLER'" >> "$LOG_FILE" 2>&1
        if [ $? -ne 0 ]; then
          handle_error "Failed to download AWS CLI installer."
        fi
        log "INFO" "AWS CLI installer downloaded successfully."

        # Install AWS CLI silently
        powershell.exe -Command "Start-Process msiexec.exe -ArgumentList '/i $AWS_CLI_INSTALLER /quiet' -Wait" >> "$LOG_FILE" 2>&1
        if [ $? -eq 0 ]; then
          log "INFO" "AWS CLI installed successfully via PowerShell."
        else
          handle_error "Failed to install AWS CLI via PowerShell."
          rm -f "$AWS_CLI_INSTALLER"
        fi

        # Clean up installer
        rm -f "$AWS_CLI_INSTALLER"

        # Re-check AWS CLI installation and verify version
        if command -v aws &>/dev/null; then
          AWS_CLI_VERSION=$(aws --version | awk '{print $1}' | cut -d/ -f2)
          log "INFO" "AWS CLI version $AWS_CLI_VERSION installed successfully on Windows."
          if [[ "$AWS_CLI_VERSION" =~ ^2\..* ]]; then
            log "INFO" "Confirmed: AWS CLI Version 2 is installed."
          else
            handle_error "AWS CLI Version 2 is not installed. Current version: $AWS_CLI_VERSION."
          fi
        else
          handle_error "AWS CLI installation verification failed."
        fi
        ;;
      Linux*|Darwin*)
        # Define AWS CLI installer URL
        AWS_CLI_INSTALLER_URL="https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip"
        AWS_CLI_INSTALLER_ZIP="awscliv2.zip"

        # Download AWS CLI installer
        curl -sL "$AWS_CLI_INSTALLER_URL" -o "$AWS_CLI_INSTALLER_ZIP"
        if [ $? -ne 0 ]; then
          handle_error "Failed to download AWS CLI."
        fi
        log "INFO" "AWS CLI installer downloaded successfully."

        # Unzip the installer
        unzip "$AWS_CLI_INSTALLER_ZIP"
        if [ $? -ne 0 ]; then
          handle_error "Failed to unzip AWS CLI installer."
        fi

        # Install AWS CLI
        sudo ./aws/install
        if [ $? -eq 0 ]; then
          log "INFO" "AWS CLI installed successfully."
        else
          handle_error "Failed to install AWS CLI."
        fi

        # Verify AWS CLI version
        AWS_CLI_VERSION=$(aws --version | awk '{print $1}' | cut -d/ -f2)
        log "INFO" "AWS CLI version $AWS_CLI_VERSION installed successfully on Linux."
        if [[ "$AWS_CLI_VERSION" =~ ^2\..* ]]; then
          log "INFO" "Confirmed: AWS CLI Version 2 is installed."
        else
          handle_error "AWS CLI Version 2 is not installed. Current version: $AWS_CLI_VERSION."
        fi

        # Clean up installer
        rm -rf "$AWS_CLI_INSTALLER_ZIP" aws
        ;;
      *)
        handle_error "Unsupported OS: $OS_TYPE."
        ;;
    esac
  else
    AWS_CLI_VERSION=$(aws --version | awk '{print $1}' | cut -d/ -f2)
    log "INFO" "AWS CLI is already installed. Version: $AWS_CLI_VERSION."
    if [[ "$AWS_CLI_VERSION" =~ ^2\..* ]]; then
      log "INFO" "Confirmed: AWS CLI Version 2 is installed."
    else
      handle_error "AWS CLI Version 2 is not installed. Current version: $AWS_CLI_VERSION."
    fi
  fi
}

# Function to install 'unzip' if not installed
install_unzip() {
  log "INFO" "Checking if 'unzip' is installed..."
  if ! command -v unzip &>/dev/null; then
    log "INFO" "'unzip' not found. Installing 'unzip'..."
    OS_TYPE="$(uname -s 2>/dev/null || echo "Windows")"
    case "$OS_TYPE" in
      Linux*)
        sudo apt update
        if [ $? -ne 0 ]; then
          handle_error "Failed to update package lists."
        fi
        sudo apt install -y unzip
        if [ $? -eq 0 ]; then
          log "INFO" "'unzip' installed successfully."
        else
          handle_error "Failed to install 'unzip' on Linux."
        fi
        ;;
      Darwin*)
        log "INFO" "'unzip' should already be installed on macOS."
        ;;
      WINDOWS*|CYGWIN*|MINGW*|MSYS*)
        # For Windows, use PowerShell's Expand-Archive if needed
        log "INFO" "'unzip' functionality is handled via PowerShell's Expand-Archive."
        ;;
      *)
        handle_error "Unsupported OS for 'unzip' installation: $OS_TYPE."
        ;;
    esac
  else
    log "INFO" "'unzip' is already installed."
  fi
}

# Function to validate environment variables
validate_env_vars() {
  local required_vars=("AWS_ACCESS_KEY_ID" "AWS_SECRET_ACCESS_KEY" "AWS_REGION" "MODEL_ID")
  for var in "${required_vars[@]}"; do
    if [ -z "${!var}" ]; then
      handle_error "Environment variable '$var' is not set."
    else
      log "INFO" "$var is set."
    fi
  done
}

# Function to configure AWS CLI profile and export AWS_PROFILE environment variable
configure_aws_profile() {
  local profile_name=$1
  local aws_access_key_id=$AWS_ACCESS_KEY_ID
  local aws_secret_access_key=$AWS_SECRET_ACCESS_KEY
  local aws_region=$AWS_REGION

  # Check if the profile already exists
  if aws configure list-profiles | grep -q "^${profile_name}$"; then
    log "INFO" "AWS profile '$profile_name' already exists. Skipping configuration."
    export AWS_PROFILE="$profile_name"
    return 0
  fi

  # Configure AWS CLI profile using values from .env
  aws configure set aws_access_key_id "$aws_access_key_id" --profile "$profile_name"
  if [ $? -ne 0 ]; then
    handle_error "Failed to set AWS_ACCESS_KEY_ID for profile '$profile_name'."
  fi

  aws configure set aws_secret_access_key "$aws_secret_access_key" --profile "$profile_name"
  if [ $? -ne 0 ]; then
    handle_error "Failed to set AWS_SECRET_ACCESS_KEY for profile '$profile_name'."
  fi

  aws configure set region "$aws_region" --profile "$profile_name"
  if [ $? -ne 0 ]; then
    handle_error "Failed to set AWS_REGION for profile '$profile_name'."
  fi

  # Export the AWS_PROFILE environment variable
  export AWS_PROFILE="$profile_name"
  log "INFO" "AWS profile '$profile_name' has been configured and exported as AWS_PROFILE."
}

# Function to verify AWS CLI version
verify_aws_cli_version() {
  if command -v aws &>/dev/null; then
    AWS_CLI_VERSION=$(aws --version | awk '{print $1}' | cut -d/ -f2)
    if [[ "$AWS_CLI_VERSION" =~ ^2\..* ]]; then
      log "INFO" "AWS CLI Version 2 is correctly installed: $AWS_CLI_VERSION."
    else
      handle_error "AWS CLI Version 2 is required. Current version: $AWS_CLI_VERSION."
    fi
  else
    handle_error "AWS CLI is not installed."
  fi
}

# Function to securely clean up temporary files
secure_cleanup() {
  rm -f install_python.ps1
  rm -f "$AWS_CLI_INSTALLER"
  rm -f awscliv2.zip
  rm -rf aws
}

# Main Execution Flow

# Check internet connectivity
check_internet

# Uninstall AWS CLI Version 1 if installed via pip
uninstall_awscli_pip

# Load environment variables from the .env file in the Execution Directory
if [ -f "$EXECUTION_DIR/.env" ]; then
  # Use 'export' and 'source' to load the .env file
  set -a
  source "$EXECUTION_DIR/.env"
  set +a
  log "INFO" ".env file loaded successfully."

  # Validate environment variables
  validate_env_vars
else
  handle_error ".env file not found in '$EXECUTION_DIR'. Please ensure it exists in the directory where you run the script."
fi

# OS-specific logic
OS_TYPE="$(uname -s 2>/dev/null || echo "Windows")"
case "$OS_TYPE" in
  Linux*|Darwin*)
    log "INFO" "Detected Unix-like system ($OS_TYPE)."
    if ! check_python_installed; then
      install_python3_venv
      # Re-check if Python is installed after installation attempt
      check_python_installed
    fi
    # Install 'unzip' before installing AWS CLI
    install_unzip
    # Check and install AWS CLI
    install_aws_cli
    # Verify AWS CLI version
    verify_aws_cli_version
    ;;
  WINDOWS*|CYGWIN*|MINGW*|MSYS*)
    log "INFO" "Detected Windows system ($OS_TYPE)."
    if ! check_python_installed; then
      install_python_windows
      # Re-check if Python is installed after installation attempt
      check_python_installed
    fi
    # Install 'unzip' on Windows if needed
    install_unzip
    # Check and install AWS CLI
    install_aws_cli
    # Verify AWS CLI version
    verify_aws_cli_version
    ;;
  *)
    handle_error "Unsupported OS: $OS_TYPE."
    ;;
esac

# Create and activate a Python virtual environment based on OS
if [ -n "$PYTHON_CMD" ]; then
  # Check if virtual environment exists
  if [ -d "my_venv" ]; then
    log "INFO" "Virtual environment 'my_venv' already exists. Activating it."
    case "$OS_TYPE" in
      Linux*|Darwin*)
        source my_venv/bin/activate
        ;;
      WINDOWS*|CYGWIN*|MINGW*|MSYS*)
        source my_venv/Scripts/activate
        ;;
    esac
  else
    # Create and activate the virtual environment
    case "$OS_TYPE" in
      Linux*|Darwin*)
        log "INFO" "Creating Python virtual environment for Unix..."
        "$PYTHON_CMD" -m venv my_venv
        if [ $? -eq 0 ]; then
          source my_venv/bin/activate
          log "INFO" "Virtual environment 'my_venv' activated."
        else
          handle_error "Failed to create virtual environment."
        fi
        ;;
      WINDOWS*|CYGWIN*|MINGW*|MSYS*)
        log "INFO" "Creating Python virtual environment for Windows..."
        "$PYTHON_CMD" -m venv my_venv
        if [ $? -eq 0 ]; then
          source my_venv/Scripts/activate
          log "INFO" "Virtual environment 'my_venv' activated."
        else
          handle_error "Failed to create virtual environment."
        fi
        ;;
    esac
  fi
else
  handle_error "Python command not found. Cannot create virtual environment."
fi

# Install required AWS SDK libraries and other dependencies
log "INFO" "Installing required Python packages..."
pip install --disable-pip-version-check boto3 python-dotenv
if [ $? -eq 0 ]; then
  log "INFO" "Python packages installed successfully."
else
  handle_error "Failed to install some Python packages."
fi

# Confirm installation
pip list --disable-pip-version-check | grep "boto3\|python-dotenv"
if [ $? -eq 0 ]; then
  log "INFO" "Confirmed installation of boto3 and python-dotenv."
else
  handle_error "Some required Python packages are not installed."
fi

# Store AWS profile info (profile name)
profile_name="bedrock-serverless"

configure_aws_profile "$profile_name"

# Ensure bedrock.py is present; if not, download it
if [ ! -f "bedrock.py" ]; then
  log "INFO" "bedrock.py not found. Downloading from repository..."
  curl -sL "https://raw.githubusercontent.com/GDP-ADMIN/codehub/main/aws-ai/bedrock.py" -o "bedrock.py"
  if [ $? -eq 0 ]; then
    log "INFO" "bedrock.py downloaded successfully."
  else
    handle_error "Failed to download bedrock.py."
    exit 1
  fi
else
  log "INFO" "bedrock.py is already present."
fi

# Run the bedrock.py script and capture the model response
if [ -f "bedrock.py" ]; then
  log "INFO" "Running bedrock.py script..."

  # Execute bedrock.py, capture stdout (model response), and log all errors
  MODEL_RESPONSE=$("$PYTHON_CMD" bedrock.py)

  # Check if the Python script executed successfully
  if [ $? -eq 0 ]; then
    # Print the model response to the terminal by redirecting to /dev/tty
    echo "$MODEL_RESPONSE" > /dev/tty
    log "INFO" "bedrock.py executed successfully."
  else
    handle_error "bedrock.py encountered an error during execution."
  fi
else
  handle_error "bedrock.py script not found in the execution directory."
fi

# Deactivate the virtual environment if it's activated
if [[ "$VIRTUAL_ENV" != "" ]]; then
  deactivate
  log "INFO" "Virtual environment 'my_venv' deactivated."
else
  log "INFO" "No virtual environment to deactivate."
fi

# Print completion messages to the terminal by redirecting to /dev/tty
echo "AWS environment setup and bedrock.py script execution complete." > /dev/tty
echo "Check 'setup.log' in '$EXECUTION_DIR' for detailed logs." > /dev/tty

# Log completion messages
log "INFO" "AWS environment setup and bedrock.py script execution complete."
log "INFO" "Check 'setup.log' in '$EXECUTION_DIR' for detailed logs."

# Securely clean up temporary files
secure_cleanup
