#!/bin/bash
set -e  # Exit immediately on failure

# Version Script Information
VERSION="1.0.0"
echo "Running script version: $VERSION"

ORIGINAL_DIR="$(cd "$(dirname "$0")" && pwd)"
echo "Original directory: $ORIGINAL_DIR"

# Detect if the system is running on Windows or Unix
OS="$(uname -s 2>/dev/null || echo "Windows")"
echo "Detected OS: $OS"

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

# OS-specific logic to install Python if needed
if ! check_python_installed; then
  echo "Error: Python not found. Exiting..."
  exit 1
fi

# Prompt user to choose between two models
echo "Choose the model to deploy:"
echo "1. Serverless Llama 3-1"
echo "2. Serverless Gemini 1-0"
read -p "Enter the number corresponding to the model: " model_choice

# Function to update the .env file with the selected model
update_env_file() {
  model_choice=$1

  # Remove existing variables from the .env file
  grep -v '^GCP_MODEL_NAME=' .env > temp.env && mv temp.env .env
  grep -v '^GCP_ENDPOINT_NAME=' .env > temp.env && mv temp.env .env
  grep -v '^GCP_SERVICE_ACCOUNT_FILE=' .env > temp.env && mv temp.env .env

  # Determine model-specific suffix and settings
  case "$model_choice" in
    1)
      gcp_model_name="meta/llama-3.1-405b-instruct-maas"
      gcp_endpoint_name="us-central1-aiplatform.googleapis.com"
      script_to_run="serverless-llama-3-1.py"
      ;;
    2)
      gcp_model_name="gemini-1.0-pro"
      gcp_endpoint_name="https://us-central1-aiplatform.googleapis.com/v1/projects/glx-exploration/locations/us-central1/publishers/google/models/gemini-1.0-pro:streamGenerateContent"
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
  # Export all variables in the .env file, ignoring commented lines and empty lines
  set -a
  while IFS='=' read -r key value; do
    # Trim any leading and trailing whitespace from key and value
    key=$(echo "$key" | xargs)
    value=$(echo "$value" | sed 's/#.*//' | xargs)  # Remove comments and trim whitespace
    
    if [[ ! $key =~ ^# && $key && $value ]]; then
      # Remove surrounding quotes from the value if they exist
      value=$(echo "$value" | sed 's/^"\(.*\)"$/\1/')
      export "$key=$value"
    fi
  done < .env
  set +a
else
  echo ".env file not found. Please ensure it exists in the directory."
  exit 1
fi

# Set the GCP_SERVICE_ACCOUNT_FILE in .env dynamically
echo "GCP_SERVICE_ACCOUNT_FILE=\"$ORIGINAL_DIR/key.json\"" >> .env
echo "GCP_SERVICE_ACCOUNT_FILE has been set in .env to: $ORIGINAL_DIR/key.json"

# Activate virtual environment
echo "Setting up virtual environment..."
$PYTHON_CMD -m venv my_venv
if [[ "$OS" == "Windows" ]]; then
  source my_venv/Scripts/activate
else
  source my_venv/bin/activate
fi

# Clone the repository if not already present and navigate to the directory
if [ ! -d "codehub" ]; then
  git clone --filter=blob:none --sparse git@github.com:mbukhori-gdp/GCP-AI.git codehub
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
$PYTHON_CMD "$script_to_run"

echo "Python script executed successfully."