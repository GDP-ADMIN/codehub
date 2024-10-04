#!/bin/bash
# Version Script Information
VERSION="1.0.4"

# Print Version Script Information
echo "Running script version: $VERSION"

ORIGINAL_DIR="$(cd "$(dirname "$0")" && pwd)"

# Detect if the system is running on Windows or Unix
OS="$(uname -s 2>/dev/null || echo "Windows")"

# Function to check if Python is installed
check_python_installed() {
  case "$OS" in
    WINDOWS*|CYGWIN*|MINGW*|MSYS*)
      # On Windows-like systems (Cygwin, MinGW, MSYS)
      if command -v python &>/dev/null; then
        PYTHON_CMD="python"
        echo "Python (likely Python 3) is already installed on Windows."
        return 0
      elif command -v python3 &>/dev/null; then
        PYTHON_CMD="python3"
        echo "Python3 is already installed on Windows."
        return 0
      else
        return 1
      fi
      ;;
    Linux*|Darwin*)
      # On Unix-like systems (Linux/macOS)
      if command -v python3 &>/dev/null; then
        PYTHON_CMD="python3"
        echo "Python3 is already installed."
        return 0
      elif command -v python &>/dev/null; then
        PYTHON_CMD="python"
        echo "Python is already installed."
        return 0
      else
        return 1
      fi
      ;;
    *)
      echo "Unsupported OS: $OS. Exiting..."
      exit 1
      ;;
  esac
}

# Function to install Python3 and venv on Debian/Ubuntu-based systems
install_python3_venv() {
  echo "Python3 or python3-venv not found. Installing necessary packages..."
  if [[ "$OS" == "Linux" ]]; then
    sudo apt update
    sudo apt install -y python3 python3-venv
    if [ $? -eq 0 ]; then
      echo "Successfully installed python3 and python3-venv."
    else
      echo "Failed to install python3 or python3-venv. Exiting..."
      exit 1
    fi
  fi
}

# Function to install Python on Unix-based systems (if not already installed)
install_python_unix() {
  echo "Python not found. Installing Python on Unix-like system..."
  curl -O https://raw.githubusercontent.com/GDP-ADMIN/codehub/refs/heads/main/devsecops/install_python.sh
  chmod +x install_python.sh
  ./install_python.sh
}

# Function to install Python on Windows
install_python_windows() {
  echo "Python not found. Installing Python on Windows system..."
  powershell -Command "Set-ExecutionPolicy RemoteSigned -Scope CurrentUser -Force"
  powershell -Command "Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/GDP-ADMIN/codehub/refs/heads/main/devsecops/install_python.ps1' -OutFile 'install_python.ps1'"
  powershell -File install_python.ps1
}

# OS-specific logic
case "$OS" in
  Linux*|Darwin*)
    echo "Detected Unix-like system ($OS)."
    if ! check_python_installed; then
      install_python_unix
    else
      # Check if python3-venv is installed, and install if not
      if ! dpkg -s python3-venv >/dev/null 2>&1; then
        echo "python3-venv is not installed. Installing it now..."
        install_python3_venv
      fi
    fi
    ;;
  CYGWIN*|MINGW*|MSYS*|Windows*)
    echo "Detected Windows system ($OS)."
    if ! check_python_installed; then
      install_python_windows
    fi
    ;;
  *)
    echo "Unsupported OS. Exiting..."
    exit 1
    ;;
esac

# Function to ensure a variable doesn't exceed the specified character length
validate_and_set_env_var() {
  local var_name=$1
  local var_value=$2
  local max_length=$3

  # Truncate the variable value if it exceeds the maximum length
  if [ ${#var_value} -gt $max_length ]; then
    echo "INFO: $var_name is too long (${#var_value} characters). Truncating to ${max_length} characters."
    var_value="${var_value:0:max_length}"
  fi

  echo "$var_name=\"$var_value\"" >> .env
  echo "INFO: $var_name set to: $var_value"
}

# Function to update the .env file with the selected model
update_env_file() {
  model_choice=$1

  # Get the existing AZURE_ENDPOINT_NAME and AZURE_WORKSPACE_NAME from the .env file
  existing_endpoint_name=$(grep '^AZURE_ENDPOINT_NAME=' .env | cut -d '=' -f2 | tr -d '"')
  existing_workspace_name=$(grep '^AZURE_WORKSPACE_NAME=' .env | cut -d '=' -f2 | tr -d '"')

  # Remove existing variables from the .env file
  grep -v '^AZURE_ML_REGISTRY=' .env > temp.env && mv temp.env .env
  grep -v '^AZURE_LLM_MODEL=' .env > temp.env && mv temp.env .env
  grep -v '^AZURE_ENDPOINT_NAME=' .env > temp.env && mv temp.env .env
  grep -v '^AZURE_WORKSPACE_NAME=' .env > temp.env && mv temp.env .env
  grep -v '^AZURE_ENDPOINT_PRIMARY_KEY=' .env > temp.env && mv temp.env .env
  grep -v '^AZURE_ENDPOINT_SCORING_URI=' .env > temp.env && mv temp.env .env

  # Determine model-specific suffix
  case "$model_choice" in
    1)
      model_registry='azureml://registries/azureml-meta/models/Meta-Llama-3-8B-Instruct'
      model_name='Meta-Llama-3-8B-Instruct'
      model_suffix='meta-llama-3-8b-instruct'
      ;;
    2)
      model_registry='azureml://registries/azureml/models/Phi-3.5-vision-instruct'
      model_name='Phi-3.5-vision-instruct'
      model_suffix='phi-3-5-vision-instruct'
      ;;
    *)
      echo "Invalid choice."
      exit 1
      ;;
  esac

  # Add the chosen model configuration
  echo "AZURE_ML_REGISTRY=\"$model_registry\"" >> .env
  echo "AZURE_LLM_MODEL=\"$model_name\"" >> .env

  # Validate and set AZURE_ENDPOINT_NAME
  new_endpoint_name="${existing_endpoint_name}-${model_suffix}"
  validate_and_set_env_var "AZURE_ENDPOINT_NAME" "$new_endpoint_name" 52

  # Validate and set AZURE_WORKSPACE_NAME
  validate_and_set_env_var "AZURE_WORKSPACE_NAME" "$existing_workspace_name" 33
}

# Store the original value of AZURE_ENDPOINT_NAME and AZURE_WORKSPACE_NAME
original_endpoint_name=$(grep '^AZURE_ENDPOINT_NAME=' .env | cut -d '=' -f2 | tr -d '"')
original_workspace_name=$(grep '^AZURE_WORKSPACE_NAME=' .env | cut -d '=' -f2 | tr -d '"')

# Check if original_endpoint_name is empty and set a default if necessary
if [ -z "$original_endpoint_name" ]; then
  default_endpoint_name="default-value"
  validate_and_set_env_var "AZURE_ENDPOINT_NAME" "$default_endpoint_name" 52
  echo "INFO: AZURE_ENDPOINT_NAME not found in .env. Added with default value."
else
  echo "INFO: Found existing AZURE_ENDPOINT_NAME value: $original_endpoint_name"
fi

# Check if original_workspace_name is empty and set a default if necessary
if [ -z "$original_workspace_name" ]; then
  default_workspace_name="default-workspace"
  validate_and_set_env_var "AZURE_WORKSPACE_NAME" "$default_workspace_name" 33
  echo "INFO: AZURE_WORKSPACE_NAME not found in .env. Added with default value."
else
  echo "INFO: Found existing AZURE_WORKSPACE_NAME value: $original_workspace_name"
fi

# Prompt user to choose between two models
echo "Choose the model to deploy:"
echo "1. Meta-Llama-3-8B-Instruct"
echo "2. Phi-3.5-vision-instruct"
read -p "Enter the number corresponding to the model: " model_choice

# Update the .env file based on user input
update_env_file "$model_choice"

# Load environment variables from the .env file
if [ -f .env ]; then
  # Export all variables in the .env file, ignoring commented lines and empty lines
  set -a
  while IFS='=' read -r key value; do
    if [[ ! $key =~ ^# && $key && $value ]]; then
      value=$(echo "$value" | sed 's/^"\(.*\)"$/\1/')
      export "$key=$value"
    fi
  done < .env
  set +a
else
  echo ".env file not found. Please ensure it exists in the directory."
  exit 1
fi

# Create and activate a Python virtual environment based on OS
case "$OS" in
  Linux*|Darwin*)
    echo "Creating and activating virtual environment for Unix..."
    $PYTHON_CMD -m venv my_venv
    source my_venv/bin/activate
    ;;
  CYGWIN*|MINGW*|MSYS*|Windows*)
    echo "Creating and activating virtual environment for Windows..."
    $PYTHON_CMD -m venv my_venv
    source my_venv/Scripts/activate
    ;;
esac

# Clone the repository if not already present and navigate to the directory
if [ ! -d "codehub" ]; then
  git clone --filter=blob:none --sparse https://github.com/GDP-ADMIN/codehub.git
fi

cd codehub || { echo "Failed to navigate to the codehub directory."; exit 1; }

# Sparse-checkout only if azure-ai folder is not present
if [ ! -d "azure-ai" ]; then
  git sparse-checkout set azure-ai
fi

cd azure-ai || { echo "Failed to navigate to the azure-ai directory."; exit 1; }

# Install required libraries
pip install --disable-pip-version-check python-dotenv==1.0.1 azure-ai-ml==1.19.0 azure-identity==1.17.1

# Confirm installation
pip list --disable-pip-version-check | grep "azure-ai-ml\|azure-identity\|python-dotenv"

# Run create_workspaces_project.py to create workspaces and project
$PYTHON_CMD create_workspaces_project.py

# Run create_model_serverless.py to deploy the model
$PYTHON_CMD create_model_serverless.py "$ORIGINAL_DIR"

# Test the deployed model
$PYTHON_CMD model_testing.py

# Reverting AZURE_ENDPOINT_NAME and AZURE_WORKSPACE_NAME back to their original values
if [[ "$OSTYPE" == "darwin"* ]]; then
  # macOS specific sed command
  sed -i '' -e "/^AZURE_ENDPOINT_NAME=/c\\
AZURE_ENDPOINT_NAME=\"$original_endpoint_name\"" "$ORIGINAL_DIR/.env"
  sed -i '' -e "/^AZURE_WORKSPACE_NAME=/c\\
AZURE_WORKSPACE_NAME=\"$original_workspace_name\"" "$ORIGINAL_DIR/.env"
elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
  # Linux specific sed command
  sed -i "/^AZURE_ENDPOINT_NAME=/c\\
AZURE_ENDPOINT_NAME=\"$original_endpoint_name\"" "$ORIGINAL_DIR/.env"
  sed -i "/^AZURE_WORKSPACE_NAME=/c\\
AZURE_WORKSPACE_NAME=\"$original_workspace_name\"" "$ORIGINAL_DIR/.env"
elif [[ "$OS" == "Windows_NT" || "$OSTYPE" == "msys"* || "$OSTYPE" == "cygwin"* || "$OSTYPE" == "win"* ]]; then
  # Windows PowerShell command to modify .env file
  # Use escaped paths and double backslashes
  windows_env_path=$(echo "$ORIGINAL_DIR/.env" | sed 's|/|\\|g')
  powershell -Command "(Get-Content -Path '$windows_env_path') -replace '^AZURE_ENDPOINT_NAME=.*', 'AZURE_ENDPOINT_NAME=\"$original_endpoint_name\"' | Set-Content -Path '$windows_env_path'"
  powershell -Command "(Get-Content -Path '$windows_env_path') -replace '^AZURE_WORKSPACE_NAME=.*', 'AZURE_WORKSPACE_NAME=\"$original_workspace_name\"' | Set-Content -Path '$windows_env_path'"
else
  echo "Unsupported OS. Unable to modify AZURE_ENDPOINT_NAME and AZURE_WORKSPACE_NAME in the .env file."
  exit 1
fi