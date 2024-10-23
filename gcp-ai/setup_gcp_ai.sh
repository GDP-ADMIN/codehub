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

# Clone the repository if not already present and navigate to the directory
if [ ! -d "codehub" ]; then
  git clone --filter=blob:none --sparse https://github.com/GDP-ADMIN/codehub.git
fi

cd codehub || { echo "Failed to navigate to the codehub directory."; exit 1; }

# Sparse-checkout only if azure-ai folder is not present
if [ ! -d "gcp-ai" ]; then
  git sparse-checkout set gcp-ai
fi

cd gcp-ai || { echo "Failed to navigate to the gcp-ai directory."; exit 1; }

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

# Run Python script
echo "Running Python script..."
$PYTHON_CMD setup-phi-3-mini-vertex.py

echo "Python script executed successfully."