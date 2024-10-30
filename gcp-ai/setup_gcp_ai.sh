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

# Function to set GOOGLE_APPLICATION_CREDENTIALS based on the OS
set_google_application_credentials() {
  case "$OS" in
    WINDOWS*|CYGWIN*|MINGW*|MSYS*)
      CREDENTIALS_PATH="C:\\path\\to\\key.json"  # Use Windows path
      ;;
    Linux*|Darwin*)
      CREDENTIALS_PATH="$ORIGINAL_DIR/key.json"  # Use Unix-like path
      ;;
    *)
      echo "Unsupported OS: $OS. Exiting..."
      exit 1
      ;;
  esac

  # Check if the key file exists
  echo "Checking if credentials file exists at: $CREDENTIALS_PATH"
  if [ ! -f "$CREDENTIALS_PATH" ]; then
    echo "Error: GOOGLE_APPLICATION_CREDENTIALS file not found at $CREDENTIALS_PATH"
    exit 1
  else
    echo "GOOGLE_APPLICATION_CREDENTIALS file found."
  fi
}

# OS-specific logic to install Python if needed
case "$OS" in
  Linux*|Darwin*)
    echo "Detected Unix-like system ($OS)."
    if ! check_python_installed; then
      echo "Error: Python not found. Exiting..."
      exit 1
    fi
    ;;
  CYGWIN*|MINGW*|MSYS*|Windows*)
    echo "Detected Windows system ($OS)."
    if ! check_python_installed; then
      echo "Error: Python not found on Windows. Exiting..."
      exit 1
    fi
    ;;
  *)
    echo "Unsupported OS: $OS. Exiting..."
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

  # Get the existing GCP_MODEL_NAME and GCP_ENDPOINT_NAME from the .env file
  existing_model_name=$(grep '^GCP_MODEL_NAME=' .env | cut -d '=' -f2 | tr -d '"')
  existing_endpoint_name=$(grep '^GCP_ENDPOINT_NAME=' .env | cut -d '=' -f2 | tr -d '"')

  # Remove existing variables from the .env file
  grep -v '^GCP_MODEL_NAME=' .env > temp.env && mv temp.env .env
  grep -v '^GCP_ENDPOINT_NAME=' .env > temp.env && mv temp.env .env
  grep -v '^GCP_MACHINE_TYPE=' .env > temp.env && mv temp.env .env
  grep -v '^GCP_ACCELERATOR_TYPE=' .env > temp.env && mv temp.env .env
  grep -v '^GCP_ACCELERATOR_COUNT=' .env > temp.env && mv temp.env .env
  grep -v '^GCP_VLLM_DOCKER_URI=' .env > temp.env && mv temp.env .env
  grep -v '^GCP_MODEL_ID=' .env > temp.env && mv temp.env .env

  # Determine model-specific suffix and settings
  case "$model_choice" in
    1)
      gcp_machine_type='g2-standard-48'
      gcp_accelerator_type='NVIDIA_L4'
      gcp_accelerator_count='4'
      gcp_vllm_docker_url='us-docker.pkg.dev/vertex-ai/vertex-vision-model-garden-dockers/pytorch-vllm-serve:20240919_0916_RC00'
      gcp_model_id='microsoft/Phi-3.5-mini-instruct'
      gcp_model_suffix='phi-3-5-mini-instruct'
      script_to_run="setup-phi-3-mini-vertex.py"
      ;;
    2)
      gcp_machine_type='g2-standard-4'
      gcp_accelerator_type='NVIDIA_L4'
      gcp_accelerator_count='1'
      gcp_vllm_docker_url='us-docker.pkg.dev/vertex-ai/vertex-vision-model-garden-dockers/pytorch-vllm-serve:20241016_0916_RC00_maas'
      gcp_model_id='meta-llama/Llama-3.1-8B-Instruct'
      gcp_model_suffix='llama-3-1-8b-instruct'
      script_to_run="setup-llama-3-1-8b-instruct.py"
      ;;
    *)
      echo "Invalid choice."
      exit 1
      ;;
  esac

  # Add the chosen model configuration to .env
  echo "GCP_MODEL_ID=\"$gcp_model_id\"" >> .env

  # Add the specification model configuration to .env
  echo "GCP_MACHINE_TYPE=\"$gcp_machine_type\"" >> .env
  echo "GCP_ACCELERATOR_TYPE=\"$gcp_accelerator_type\"" >> .env
  echo "GCP_ACCELERATOR_COUNT=\"$gcp_accelerator_count\"" >> .env
  echo "GCP_VLLM_DOCKER_URI=\"$gcp_vllm_docker_url\"" >> .env
 
  # Validate and set GCP_ENDPOINT_NAME and GCP_MODEL_NAME
  new_endpoint_name="${existing_endpoint_name}-${gcp_model_suffix}"
  validate_and_set_env_var "GCP_ENDPOINT_NAME" "$new_endpoint_name" 50
  validate_and_set_env_var "GCP_MODEL_NAME" "$existing_model_name" 33
}

# Store the original values of GCP_ENDPOINT_NAME and GCP_MODEL_NAME
original_endpoint_name=$(grep '^GCP_ENDPOINT_NAME=' .env | cut -d '=' -f2 | tr -d '"')
original_model_name=$(grep '^GCP_MODEL_NAME=' .env | cut -d '=' -f2 | tr -d '"')

# Set default values if not found in .env
if [ -z "$original_endpoint_name" ]; then
  default_endpoint_name="default-value"
  validate_and_set_env_var "GCP_ENDPOINT_NAME" "$default_endpoint_name" 50
  echo "INFO: GCP_ENDPOINT_NAME not found in .env. Added with default value."
else
  echo "INFO: Found existing GCP_ENDPOINT_NAME value: $original_endpoint_name"
fi

if [ -z "$original_model_name" ]; then
  default_model_name="default-model"
  validate_and_set_env_var "GCP_MODEL_NAME" "$default_model_name" 33
  echo "INFO: GCP_MODEL_NAME not found in .env. Added with default value."
else
  echo "INFO: Found existing GCP_MODEL_NAME value: $original_model_name"
fi

# Prompt user to choose between two models
echo "Choose the model to deploy:"
echo "1. phi-3-5-mini-instruct"
echo "2. llama-3-1-8B-instruct"
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

# Set GOOGLE_APPLICATION_CREDENTIALS
set_google_application_credentials

# Activate virtual environment
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

# Verify virtual environment activation
echo "Python version after activation: $($PYTHON_CMD --version)"
echo "GOOGLE_APPLICATION_CREDENTIALS is set to: $GOOGLE_APPLICATION_CREDENTIALS"

# Export credentials
export GOOGLE_APPLICATION_CREDENTIALS="$CREDENTIALS_PATH"
echo "GOOGLE_APPLICATION_CREDENTIALS set to $GOOGLE_APPLICATION_CREDENTIALS"

# Install required libraries in the virtual environment
pip install --disable-pip-version-check python-dotenv google-cloud-aiplatform

# Verify installation
pip list | grep "google-cloud-aiplatform\|python-dotenv"

# Run Python script based on the selected model
echo "Running Python script..."
$PYTHON_CMD "$script_to_run"

# Test the deployed model
echo "Running Model Testing script..."
$PYTHON_CMD model_testing.py

echo "Python script executed successfully."

# Reverting GCP_ENDPOINT_NAME and GCP_MODEL_NAME back to their original values
if [[ "$OSTYPE" == "darwin"* ]]; then
  # macOS specific sed command
  sed -i '' -e "/^GCP_ENDPOINT_NAME=/c\\
GCP_ENDPOINT_NAME=\"$original_endpoint_name\"" "$ORIGINAL_DIR/.env"
  sed -i '' -e "/^GCP_MODEL_NAME=/c\\
GCP_MODEL_NAME=\"$original_model_name\"" "$ORIGINAL_DIR/.env"
elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
  # Linux specific sed command
  sed -i "/^GCP_ENDPOINT_NAME=/c\\
GCP_ENDPOINT_NAME=\"$original_endpoint_name\"" "$ORIGINAL_DIR/.env"
  sed -i "/^GCP_MODEL_NAME=/c\\
GCP_MODEL_NAME=\"$original_model_name\"" "$ORIGINAL_DIR/.env"
elif [[ "$OSTYPE" == "msys"* || "$OSTYPE" == "cygwin"* || "$OSTYPE" == "win"* || "$OSTYPE" == "MINGW"* ]]; then
  # Windows and MINGW PowerShell command to modify .env file

  # Convert the path to Windows format using built-in Git Bash conversion
  windows_env_path=$(cygpath -w "$ORIGINAL_DIR/.env")

  # Check if the path conversion was successful
  if [ -z "$windows_env_path" ]; then
    echo "ERROR: Failed to convert the path to Windows format. Please check the .env file path."
    exit 1
  fi

  echo "Using Windows path for .env: $windows_env_path"

  # Use PowerShell commands to update the .env file
  powershell -Command "(Get-Content -Path '$windows_env_path') -replace '^GCP_ENDPOINT_NAME=.*', 'GCP_ENDPOINT_NAME=\"$original_endpoint_name\"' | Set-Content -Path '$windows_env_path'"
  powershell -Command "(Get-Content -Path '$windows_env_path') -replace '^GCP_MODEL_NAME=.*', 'GCP_MODEL_NAME=\"$original_model_name\"' | Set-Content -Path '$windows_env_path'"

else
  echo "Unsupported OS. Unable to modify GCP_ENDPOINT_NAME and GCP_MODEL_NAME in the .env file."
  exit 1
fi