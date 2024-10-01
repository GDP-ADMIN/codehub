#!/bin/bash
# Version Script Information
VERSION="1.0.1"

# Print Version Script Information
echo "Running script version: $VERSION"

ORIGINAL_DIR="$(cd "$(dirname "$0")" && pwd)"

# Detect if the system is running on Windows or Unix
OS="$(uname -s)"
# Function to check if Python is installed
check_python_installed() {
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
}

# Function to install Python on Unix-based systems
install_python_unix() {
  echo "Python not found. Installing Python on Unix-like system..."
  curl -O https://raw.githubusercontent.com/GDP-ADMIN/codehub/refs/heads/main/devsecops/install_python.sh
  chmod +x install_python.sh
  ./install_python.sh
}

# Function to install Python on Windows
install_python_windows() {
  echo "Python not found. Installing Python on Windows system..."
  # Set Execution Policy for PowerShell
  echo "Ensuring PowerShell Execution Policy is set to RemoteSigned..."
  powershell -Command "Set-ExecutionPolicy RemoteSigned -Scope CurrentUser -Force"
  Invoke-WebRequest -Uri "https://raw.githubusercontent.com/GDP-ADMIN/codehub/refs/heads/main/devsecops/install_python.ps1" -OutFile "install_python.ps1"
  ./install_python.ps1
}

# OS-specific logic
case "$OS" in
  Linux*|Darwin*)
    # For Unix-like systems (Linux/macOS)
    echo "Detected Unix-like system ($OS)."
    if ! check_python_installed; then
      install_python_unix
    fi
    ;;
  CYGWIN*|MINGW*|MSYS*)
    # For Windows-like systems
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

# Function to update the .env file with the selected model
update_env_file() {
  model_choice=$1

  # Get the existing AZURE_ENDPOINT_NAME from the .env file
  existing_endpoint_name=$(grep '^AZURE_ENDPOINT_NAME=' .env | cut -d '=' -f2 | tr -d '"')

  # Remove existing AZURE_ML_REGISTRY, AZURE_LLM_MODEL, and AZURE_ENDPOINT_NAME lines from the .env file
  grep -v '^AZURE_ML_REGISTRY=' .env > temp.env && mv temp.env .env
  grep -v '^AZURE_LLM_MODEL=' .env > temp.env && mv temp.env .env
  grep -v '^AZURE_ENDPOINT_NAME=' .env > temp.env && mv temp.env .env
  grep -v '^AZURE_ENDPOINT_PRIMARY_KEY=' .env > temp.env && mv temp.env .env
  grep -v '^AZURE_ENDPOINT_SCORING_URI=' .env > temp.env && mv temp.env .env

  # Add the chosen model configuration and append the model-specific suffix to AZURE_ENDPOINT_NAME
  if [ "$model_choice" -eq 1 ]; then
    echo 'AZURE_ML_REGISTRY="azureml://registries/azureml-meta/models/Meta-Llama-3-8B-Instruct"' >> .env
    echo 'AZURE_LLM_MODEL="Meta-Llama-3-8B-Instruct"' >> .env
    echo "AZURE_ENDPOINT_NAME=\"${existing_endpoint_name}-meta-llama-3-8b-instruct\"" >> .env
    echo "Model set to Meta-Llama-3-8B-Instruct and endpoint name updated."
  elif [ "$model_choice" -eq 2 ]; then
    echo 'AZURE_ML_REGISTRY="azureml://registries/azureml/models/Phi-3.5-vision-instruct"' >> .env
    echo 'AZURE_LLM_MODEL="Phi-3.5-vision-instruct"' >> .env
    echo "AZURE_ENDPOINT_NAME=\"${existing_endpoint_name}-phi-3-5-vision-instruct\"" >> .env
    echo "Model set to Phi-3.5-vision-instruct and endpoint name updated."
  else
    echo "Invalid choice."
    exit 1
  fi
}

# Prompt user to choose between two models
echo "Choose the model to deploy:"
echo "1. Meta-Llama-3-8B-Instruct"
echo "2. Phi-3.5-vision-instruct"
read -p "Enter the number corresponding to the model: " model_choice

# Store the original value of AZURE_ENDPOINT_NAME
original_endpoint_name=$(grep '^AZURE_ENDPOINT_NAME=' .env | cut -d '=' -f2 | tr -d '"')

# Check if original_endpoint_name is empty
if [ -z "$original_endpoint_name" ]; then
  echo "AZURE_ENDPOINT_NAME=\"default_value\"" >> .env
  echo "INFO: AZURE_ENDPOINT_NAME not found in .env. Added with default value."
else
  echo "INFO: Found existing AZURE_ENDPOINT_NAME value: $original_endpoint_name"
fi

# Update the .env file based on user input
update_env_file "$model_choice"

# Load environment variables from the .env file
if [ -f .env ]; then
  # Export all variables in the .env file, ignoring commented lines and empty lines
  set -a
  # Use a more robust approach to source the .env file and handle quotes
  while IFS='=' read -r key value; do
    # Ignore lines starting with '#', empty lines, or lines without '='
    if [[ ! $key =~ ^# && $key && $value ]]; then
      # Strip quotes from values, if any
      value=$(echo "$value" | sed 's/^"\(.*\)"$/\1/')
      export "$key=$value"
    fi
  done < .env
  set +a
else
  echo ".env file not found. Please ensure it exists in the directory."
  exit 1
fi

# Check if AZURE_TENANT_ID is set
if [ -z "$AZURE_TENANT_ID" ]; then
  echo "AZURE_TENANT_ID is not set in the .env file."
  exit 1
fi

# Check if Python is installed
$PYTHON_CMD --version &>/dev/null
if [ $? -ne 0 ]; then
  echo "Python 3.x is required. Please install Python 3."
  exit 1
fi

# Create and activate a Python virtual environment based on OS
case "$OS" in
  Linux*|Darwin*)
    # Create and activate a Python virtual environment on Unix systems
    echo "Creating and activating virtual environment for Unix..."
    $PYTHON_CMD -m venv my_venv
    source my_venv/bin/activate
    ;;
  CYGWIN*|MINGW*|MSYS*)
    # Create and activate a Python virtual environment on Windows systems
    echo "Creating and activating virtual environment for Windows..."
    $PYTHON_CMD -m venv my_venv
    source my_venv/Scripts/activate
    ;;
esac

# Clone the repository and navigate to the project directory
git clone --filter=blob:none --sparse https://github.com/GDP-ADMIN/codehub.git && cd codehub && git sparse-checkout set azure-ai && cd azure-ai

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

# Reverting ENDPOINT_NAME back to its original value
if [[ "$OSTYPE" == "darwin"* ]]; then
  # macOS specific sed command
  sed -i '' -e "/^AZURE_ENDPOINT_NAME=/c\\
AZURE_ENDPOINT_NAME=\"$original_endpoint_name\"" "$ORIGINAL_DIR/.env"
else
  # Linux specific sed command
  sed -i "/^AZURE_ENDPOINT_NAME=/c\\
AZURE_ENDPOINT_NAME=\"$original_endpoint_name\"" "$ORIGINAL_DIR/.env"
fi