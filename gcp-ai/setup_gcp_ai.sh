#!/bin/bash
set -e  # Exit immediately on failure

# Load the environment variables from the .env file
source .env

# Version Script Information
VERSION="1.0.0"
echo "Running script version: $VERSION"

ORIGINAL_DIR="$(cd "$(dirname "$0")" && pwd)"
echo "Original directory: $ORIGINAL_DIR"

# Detect if the system is running on Windows or Unix
OS="$(uname -s 2>/dev/null || echo "Windows")"
echo "Detected OS: $OS"

# Function to check for a .json file in ORIGINAL_DIR and set GCP_SERVICE_ACCOUNT_FILE dynamically
check_gcp_service_account_file() {
  # Find any .json file in ORIGINAL_DIR
  json_file=$(find "$ORIGINAL_DIR" -maxdepth 1 -name "*.json" | head -n 1)

  # Check if a .json file was found
  if [ -z "$json_file" ]; then
    echo "Error: No .json file found in $ORIGINAL_DIR"
    exit 1
  fi

  # Set the path to the .json file based on the OS
  case "$OS" in
    WINDOWS*|CYGWIN*|MINGW*|MSYS*)
      GCP_SERVICE_ACCOUNT_FILE="${json_file//\//\\}"  # Convert to Windows path
      ;;
    Linux*|Darwin*)
      GCP_SERVICE_ACCOUNT_FILE="$json_file"  # Use Unix-like path as is
      ;;
    *)
      echo "Unsupported OS: $OS. Exiting..."
      exit 1
      ;;
  esac

  echo "GCP_SERVICE_ACCOUNT_FILE file found at: $GCP_SERVICE_ACCOUNT_FILE"

  # Remove existing entry and add the GCP_SERVICE_ACCOUNT_FILE in .env
  sed -i '/^GCP_SERVICE_ACCOUNT_FILE=/d' .env 2>/dev/null || true
  echo -e "\nGCP_SERVICE_ACCOUNT_FILE=\"$GCP_SERVICE_ACCOUNT_FILE\"" >> .env
}

# Call the function
check_gcp_service_account_file

# Function to check if Python is installed
check_python_installed() {
  case "$OS" in
    WINDOWS*|CYGWIN*|MINGW*|MSYS*)
      if command -v python &>/dev/null; then
        PYTHON_CMD="python"
        echo "Python is already installed on Windows."
        return 0
      elif command -v python3 &>/dev/null; then
        PYTHON_CMD="python3"
        echo "Python3 is already installed on Windows."
        return 0
      else
        echo "Error: Python not found on Windows."
        return 1
      fi
      ;;
    Linux*|Darwin*)
      if command -v python3 &>/dev/null; then
        PYTHON_CMD="python3"
        echo "Python3 is already installed."
        return 0
      elif command -v python &>/dev/null; then
        PYTHON_CMD="python"
        echo "Python is already installed."
        return 0
      else
        echo "Error: Python not found on Unix."
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

# Prompt user to choose between two models
echo "Choose the model to deploy:"
echo "1. Serverless Llama 3-1"
echo "2. Serverless Gemini 1-0"
read -p "Enter the number corresponding to the model: " model_choice

# Function to update the .env file with the selected model
update_env_file() {
  model_choice=$1

  # Remove existing variables from the .env file
  sed -i '/^GCP_MODEL_NAME=/d' .env 2>/dev/null || true
  sed -i '/^GCP_ENDPOINT_NAME=/d' .env 2>/dev/null || true

  # Determine model-specific suffix and settings
  case "$model_choice" in
    1)
      gcp_model_name="meta/llama-3.1-405b-instruct-maas"
      gcp_endpoint_name="us-central1-aiplatform.googleapis.com"
      script_to_run="serverless-llama-3-1.py"
      ;;
    2)
      gcp_model_name="gemini-1.0-pro"
      gcp_endpoint_name="https://us-central1-aiplatform.googleapis.com/v1/projects/$GCP_PROJECT_ID/locations/$GCP_REGION_NAME/publishers/google/models/gemini-1.0-pro:streamGenerateContent"
      script_to_run="serverless-gemini1-0.py"
      ;;
    *)
      echo "Invalid choice."
      exit 1
      ;;
  esac

  # Add the chosen model configuration to .env
  echo "GCP_MODEL_NAME=\"$gcp_model_name\"" >> .env
  echo "GCP_ENDPOINT_NAME=\"$gcp_endpoint_name\"" >> .env
}

# Update the .env file based on user input
update_env_file "$model_choice"

# Load environment variables from the .env file
if [ -f .env ]; then
  set -a
  while IFS='=' read -r key value; do
    key=$(echo "$key" | xargs)
    value=$(echo "$value" | sed 's/#.*//' | xargs)  # Remove comments and trim whitespace
    
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
  git clone --filter=blob:none --sparse git@github.com:GDP-ADMIN/codehub.git codehub
fi

cd codehub || { echo "Failed to navigate to the codehub directory."; exit 1; }

# Sparse-checkout only if gcp-ai folder is not present
if [ ! -d "gcp-ai" ]; then
  git sparse-checkout set gcp-ai
fi

cd gcp-ai || { echo "Failed to navigate to the gcp-ai directory."; exit 1; }

# Verify virtual environment activation
echo "Python version after activation: $($PYTHON_CMD --version)"

# Install required libraries in the virtual environment
pip install --disable-pip-version-check python-dotenv requests google-auth

# Verify installation
pip list | grep "google-auth\|python-dotenv\|requests"

# Run Python script based on the selected model
echo "Running Python script..."
output=$($PYTHON_CMD "$script_to_run" 2>&1)  # Capture both stdout and stderr

# Check for "Status Code: 200" in the output
if echo "$output" | grep -q "Status Code: 200"; then
    echo "Python script executed successfully."
else
    echo "Python script executed unsuccessfully."
fi

# Optionally, print the output for debugging
echo "$output"