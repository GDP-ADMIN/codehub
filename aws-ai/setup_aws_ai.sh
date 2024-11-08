#!/bin/bash

# Version Script Information
VERSION="1.0.1"

# Capture the directory where the script was invoked
EXECUTION_DIR="$(pwd)"
export EXECUTION_DIR  # Export so child processes can access it

# Define Log File in the Execution Directory
LOG_FILE="$EXECUTION_DIR/setup.log"

# Function to log messages to the log file with timestamps
log() {
  echo "$(date +"%Y-%m-%d %H:%M:%S") : $*" | tee -a "$LOG_FILE"
}

# Function to handle non-critical errors by logging them
handle_error() {
  log "ERROR: $1"
}

# Function to check if Python is installed
check_python_installed() {
  OS_TYPE="$(uname -s 2>/dev/null || echo "Windows")"
  case "$OS_TYPE" in
    WINDOWS*|CYGWIN*|MINGW*|MSYS*)
      if command -v python &>/dev/null; then
        PYTHON_CMD="python"
        log "Python (likely Python 3) is already installed on Windows."
        return 0
      elif command -v python3 &>/dev/null; then
        PYTHON_CMD="python3"
        log "Python3 is already installed on Windows."
        return 0
      else
        handle_error "Python is not installed on Windows."
        return 1
      fi
      ;;
    Linux*|Darwin*)
      if command -v python3 &>/dev/null; then
        PYTHON_CMD="python3"
        log "Python3 is already installed."
        return 0
      elif command -v python &>/dev/null; then
        PYTHON_CMD="python"
        log "Python is already installed."
        return 0
      else
        handle_error "Python is not installed."
        return 1
      fi
      ;;
    *)
      handle_error "Unsupported OS: $OS_TYPE."
      return 1
      ;;
  esac
}

# Function to install Python3 and venv on Debian/Ubuntu-based systems
install_python3_venv() {
  log "Attempting to install python3 and python3-venv..."
  if [[ "$(uname -s)" == "Linux" ]]; then
    sudo apt update >> "$LOG_FILE" 2>&1
    sudo apt install -y python3 python3-venv >> "$LOG_FILE" 2>&1
    if [ $? -eq 0 ]; then
      log "Successfully installed python3 and python3-venv."
    else
      handle_error "Failed to install python3 or python3-venv."
    fi
  else
    handle_error "install_python3_venv is only supported on Linux."
  fi
}

# <<< Updated Function Starts Here >>>
# Function to install Python3 on Windows using an external PowerShell script
install_python_windows() {
  echo "Python not found. Installing Python on Windows system..."
  
  # Set Execution Policy to allow script execution
  powershell -Command "Set-ExecutionPolicy RemoteSigned -Scope CurrentUser -Force"
  
  # Download the PowerShell installer script
  powershell -Command "Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/GDP-ADMIN/codehub/refs/heads/main/devsecops/install_python.ps1' -OutFile 'install_python.ps1'"
  
  # Execute the installer script
  powershell -File install_python.ps1
  
  # Check if the PowerShell script executed successfully
  if [ $? -eq 0 ]; then
    log "Python installed successfully via PowerShell."
    rm -f install_python.ps1
  else
    handle_error "Failed to install Python via PowerShell."
    rm -f install_python.ps1
    return 1
  fi

  # Re-check Python installation
  if command -v python &>/dev/null || command -v python3 &>/dev/null; then
    log "Python is now installed on Windows."
    return 0
  else
    handle_error "Python installation verification failed."
    return 1
  fi
}
# <<< Updated Function Ends Here >>>

# Function to install AWS CLI if not already installed
install_aws_cli() {
  OS_TYPE="$(uname -s 2>/dev/null || echo "Windows")"
  if ! command -v aws &>/dev/null; then
    log "AWS CLI not found. Installing AWS CLI..."
    case "$OS_TYPE" in
      WINDOWS*|CYGWIN*|MINGW*|MSYS*)
        # Define AWS CLI installer URL
        AWS_CLI_INSTALLER_URL="https://awscli.amazonaws.com/AWSCLIV2.msi"
        AWS_CLI_INSTALLER="AWSCLIV2.msi"

        # Download AWS CLI installer using PowerShell
        powershell.exe -Command "Invoke-WebRequest -Uri '$AWS_CLI_INSTALLER_URL' -OutFile '$AWS_CLI_INSTALLER'" >> "$LOG_FILE" 2>&1
        if [ $? -ne 0 ]; then
          handle_error "Failed to download AWS CLI installer."
          return 1
        fi
        log "AWS CLI installer downloaded successfully."

        # Install AWS CLI silently
        powershell.exe -Command "Start-Process msiexec.exe -ArgumentList '/i $AWS_CLI_INSTALLER /quiet' -Wait" >> "$LOG_FILE" 2>&1
        if [ $? -eq 0 ]; then
          log "AWS CLI installed successfully via PowerShell."
        else
          handle_error "Failed to install AWS CLI via PowerShell."
          rm -f "$AWS_CLI_INSTALLER"
          return 1
        fi

        # Clean up installer
        rm -f "$AWS_CLI_INSTALLER"

        # Re-check AWS CLI installation
        if command -v aws &>/dev/null; then
          log "AWS CLI is now installed on Windows."
          return 0
        else
          handle_error "AWS CLI installation verification failed."
          return 1
        fi
        ;;
      Linux*|Darwin*)
        # Existing Linux installation steps
        curl -sL "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" >> "$LOG_FILE" 2>&1
        if [ $? -ne 0 ]; then
          handle_error "Failed to download AWS CLI."
          return 1
        fi
        unzip awscliv2.zip >> "$LOG_FILE" 2>&1
        if [ $? -ne 0 ]; then
          handle_error "Failed to unzip AWS CLI installer."
          return 1
        fi
        sudo ./aws/install >> "$LOG_FILE" 2>&1
        if [ $? -eq 0 ]; then
          log "AWS CLI installed successfully."
        else
          handle_error "Failed to install AWS CLI."
        fi
        # Clean up
        rm -rf awscliv2.zip aws
        ;;
      *)
        handle_error "Unsupported OS: $OS_TYPE."
        ;;
    esac
  else
    log "AWS CLI is already installed."
  fi
}

# >>> Added: Function to check and install 'unzip'
install_unzip() {
  log "Checking if 'unzip' is installed..."
  if ! command -v unzip &>/dev/null; then
    log "'unzip' not found. Installing 'unzip'..."
    OS_TYPE="$(uname -s 2>/dev/null || echo "Windows")"
    case "$OS_TYPE" in
      Linux*)
        sudo apt update >> "$LOG_FILE" 2>&1
        sudo apt install -y unzip >> "$LOG_FILE" 2>&1
        if [ $? -eq 0 ]; then
          log "'unzip' installed successfully."
        else
          handle_error "Failed to install 'unzip' on Linux."
        fi
        ;;
      Darwin*)
        log "'unzip' should already be installed on macOS."
        ;;
      WINDOWS*|CYGWIN*|MINGW*|MSYS*)
        # For Windows, use PowerShell's Expand-Archive if needed
        log "'unzip' functionality is handled via PowerShell's Expand-Archive."
        ;;
      *)
        handle_error "Unsupported OS for 'unzip' installation: $OS_TYPE."
        ;;
    esac
  else
    log "'unzip' is already installed."
  fi
}
# <<< Added

# Load environment variables from the .env file in the Execution Directory
if [ -f "$EXECUTION_DIR/.env" ]; then
  # Use 'export' and 'source' to load the .env file
  set -a
  source "$EXECUTION_DIR/.env"
  set +a
  log ".env file loaded successfully."

  # Debugging: Check if variables are set (without printing sensitive information)
  if [ -n "$AWS_ACCESS_KEY_ID" ]; then
    log "AWS_ACCESS_KEY_ID is set."
  else
    handle_error "AWS_ACCESS_KEY_ID is not set after loading .env."
  fi

  if [ -n "$AWS_SECRET_ACCESS_KEY" ]; then
    log "AWS_SECRET_ACCESS_KEY is set."
  else
    handle_error "AWS_SECRET_ACCESS_KEY is not set after loading .env."
  fi

  if [ -n "$AWS_REGION" ]; then
    log "AWS_REGION is set to '$AWS_REGION'."
  else
    handle_error "AWS_REGION is not set after loading .env."
  fi

  if [ -n "$MODEL_ID" ]; then
    log "MODEL_ID is set to '$MODEL_ID'."
  else
    handle_error "MODEL_ID is not set after loading .env."
  fi
else
  handle_error ".env file not found in '$EXECUTION_DIR'. Please ensure it exists in the directory where you run the script."
fi

# Ensure that AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY, and AWS_REGION are set
if [ -z "$AWS_ACCESS_KEY_ID" ] || [ -z "$AWS_SECRET_ACCESS_KEY" ] || [ -z "$AWS_REGION" ]; then
  handle_error "AWS credentials or region not found in the .env file. Please check the .env file."
fi

# Function to configure AWS CLI profile and export AWS_PROFILE environment variable
configure_aws_profile() {
  local profile_name=$1
  local aws_access_key_id=$AWS_ACCESS_KEY_ID
  local aws_secret_access_key=$AWS_SECRET_ACCESS_KEY
  local aws_region=$AWS_REGION

  # Check if the profile already exists
  if aws configure list-profiles | grep -q "^${profile_name}$"; then
    log "AWS profile '$profile_name' already exists. Skipping configuration."
    export AWS_PROFILE="$profile_name"
    return 0
  fi

  # Configure AWS CLI profile using values from .env
  aws configure set aws_access_key_id "$aws_access_key_id" --profile "$profile_name" >> "$LOG_FILE" 2>&1
  if [ $? -ne 0 ]; then
    handle_error "Failed to set AWS_ACCESS_KEY_ID for profile '$profile_name'."
  fi

  aws configure set aws_secret_access_key "$aws_secret_access_key" --profile "$profile_name" >> "$LOG_FILE" 2>&1
  if [ $? -ne 0 ]; then
    handle_error "Failed to set AWS_SECRET_ACCESS_KEY for profile '$profile_name'."
  fi

  aws configure set region "$aws_region" --profile "$profile_name" >> "$LOG_FILE" 2>&1
  if [ $? -ne 0 ]; then
    handle_error "Failed to set AWS_REGION for profile '$profile_name'."
  fi

  # Export the AWS_PROFILE environment variable
  export AWS_PROFILE="$profile_name"
  log "AWS profile '$profile_name' has been configured and exported as AWS_PROFILE."
}

# OS-specific logic
OS_TYPE="$(uname -s 2>/dev/null || echo "Windows")"
case "$OS_TYPE" in
  Linux*|Darwin*)
    log "Detected Unix-like system ($OS_TYPE)."
    if ! check_python_installed; then
      install_python3_venv
      # Re-check if Python is installed after installation attempt
      check_python_installed
    fi
    # >>> Added: Install 'unzip' before installing AWS CLI
    install_unzip
    # <<< Added
    # Check and install AWS CLI
    install_aws_cli
    ;;
  WINDOWS*|CYGWIN*|MINGW*|MSYS*)
    log "Detected Windows system ($OS_TYPE)."
    if ! check_python_installed; then
      install_python_windows
      # Re-check if Python is installed after installation attempt
      check_python_installed
    fi
    # >>> Added: Install 'unzip' on Windows if needed
    install_unzip
    # <<< Added
    # Check and install AWS CLI
    install_aws_cli
    ;;
  *)
    handle_error "Unsupported OS: $OS_TYPE."
    ;;
esac

# Create and activate a Python virtual environment based on OS
if [ -n "$PYTHON_CMD" ]; then
  # Check if virtual environment exists
  if [ -d "my_venv" ]; then
    log "Virtual environment 'my_venv' already exists. Activating it."
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
        log "Creating Python virtual environment for Unix..."
        "$PYTHON_CMD" -m venv my_venv >> "$LOG_FILE" 2>&1
        if [ $? -eq 0 ]; then
          source my_venv/bin/activate
          log "Virtual environment 'my_venv' activated."
        else
          handle_error "Failed to create virtual environment."
        fi
        ;;
      WINDOWS*|CYGWIN*|MINGW*|MSYS*)
        log "Creating Python virtual environment for Windows..."
        "$PYTHON_CMD" -m venv my_venv >> "$LOG_FILE" 2>&1
        if [ $? -eq 0 ]; then
          source my_venv/Scripts/activate
          log "Virtual environment 'my_venv' activated."
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
log "Installing required Python packages..."
pip install --disable-pip-version-check boto3 awscli python-dotenv >> "$LOG_FILE" 2>&1
if [ $? -eq 0 ]; then
  log "Python packages installed successfully."
else
  handle_error "Failed to install some Python packages."
fi

# Confirm installation
pip list --disable-pip-version-check | grep "boto3\|awscli\|python-dotenv" >> "$LOG_FILE" 2>&1
if [ $? -eq 0 ]; then
  log "Confirmed installation of boto3, awscli, and python-dotenv."
else
  handle_error "Some required Python packages are not installed."
fi

# Store AWS profile info (profile name)
profile_name="bedrock-serverless"

configure_aws_profile "$profile_name"

# Ensure bedrock.py is present; if not, download it
if [ ! -f "bedrock.py" ]; then
  log "bedrock.py not found. Downloading from repository..."
  curl -sL "https://raw.githubusercontent.com/GDP-ADMIN/codehub/main/aws-ai/bedrock.py" -o "bedrock.py" >> "$LOG_FILE" 2>&1
  if [ $? -eq 0 ]; then
    log "bedrock.py downloaded successfully."
  else
    handle_error "Failed to download bedrock.py."
    exit 1
  fi
else
  log "bedrock.py is already present."
fi

# Run the bedrock.py script and capture the model response
if [ -f "bedrock.py" ]; then
  log "Running bedrock.py script..."

  # Execute bedrock.py, capture stdout (model response), and log all errors
  MODEL_RESPONSE=$("$PYTHON_CMD" bedrock.py 2>> "$LOG_FILE")

  # Check if the Python script executed successfully
  if [ $? -eq 0 ]; then
    # Print the model response to the terminal
    echo "$MODEL_RESPONSE"
    log "bedrock.py executed successfully."
  else
    handle_error "bedrock.py encountered an error during execution."
  fi
else
  handle_error "bedrock.py script not found in the execution directory."
fi

# Deactivate the virtual environment if it's activated
if [[ "$VIRTUAL_ENV" != "" ]]; then
  deactivate
  log "Virtual environment 'my_venv' deactivated."
else
  log "No virtual environment to deactivate."
fi

# Print completion messages to the terminal
echo "AWS environment setup and bedrock.py script execution complete."
echo "Check 'setup.log' in '$EXECUTION_DIR' for detailed logs."

# Log completion messages
log "AWS environment setup and bedrock.py script execution complete."
log "Check 'setup.log' in '$EXECUTION_DIR' for detailed logs."
