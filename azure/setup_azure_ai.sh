#!/bin/bash
ORIGINAL_DIR="$(cd "$(dirname "$0")" && pwd)"

# Function to update the .env file with the selected model
update_env_file() {
  model_choice=$1

  # Remove existing AZURE_ML_REGISTRY and AZURE_LLM_MODEL lines from the .env file
  grep -v '^AZURE_ML_REGISTRY=' .env > temp.env && mv temp.env .env
  grep -v '^AZURE_LLM_MODEL=' .env > temp.env && mv temp.env .env
  grep -v '^AZURE_ENDPOINT_PRIMARY_KEY=' .env > temp.env && mv temp.env .env
  grep -v '^AZURE_ENDPOINT_SCORING_URI=' .env > temp.env && mv temp.env .env

  # Add the chosen model configuration to the .env file
  if [ "$model_choice" -eq 1 ]; then
    echo 'AZURE_ML_REGISTRY="azureml://registries/azureml-meta/models/Meta-Llama-3-8B-Instruct"' >> .env
    echo 'AZURE_LLM_MODEL="Meta-Llama-3-8B-Instruct"' >> .env
    echo "Model set to Meta-Llama-3-8B-Instruct"
  elif [ "$model_choice" -eq 2 ]; then
    echo 'AZURE_ML_REGISTRY="azureml://registries/azureml/models/Phi-3.5-vision-instruct"' >> .env
    echo 'AZURE_LLM_MODEL="Phi-3.5-vision-instruct"' >> .env
    echo "Model set to Phi-3.5-vision-instruct"
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
python --version &>/dev/null
if [ $? -ne 0 ]; then
  echo "Python 3.x is required. Please install Python 3."
  exit 1
fi

# Detect if the system is running on Windows or Unix
OS="$(uname -s)"
case "$OS" in
  Linux*|Darwin*) 
    # Create and activate a Python virtual environment on Unix systems
    echo "Creating and activating virtual environment for Unix..."
    python -m venv my_venv
    source my_venv/bin/activate
    ;;
  CYGWIN*|MINGW*|MSYS*)
    # Create and activate a Python virtual environment on Windows systems
    echo "Creating and activating virtual environment for Windows..."
    python -m venv my_venv
    source my_venv/Scripts/activate
    ;;
  *)
    echo "Unsupported OS. Exiting..."
    exit 1
    ;;
esac

# Clone the repository and navigate to the project directory
echo "Cloning the repository..."
git clone git@github.com:GDP-ADMIN/gdplabs-exploration.git
cd gdplabs-exploration || exit
git checkout -b azure-ai-serverless-api-endpoint-exploration
git fetch --all
git reset --hard origin/azure-ai-serverless-api-endpoint-exploration
cd azure/ai-serverless-api-endpoint || exit

# Install required libraries
echo "Installing required libraries..."
pip install --disable-pip-version-check python-dotenv==1.0.1 azure-ai-ml==1.19.0 azure-identity==1.17.1

# Confirm installation
echo "Checking installed libraries..."
pip list --disable-pip-version-check | grep "azure-ai-ml\|azure-identity\|python-dotenv"

# Login to Azure using the tenant ID from .env
echo "Logging in to Azure..."
az login --tenant "$AZURE_TENANT_ID"

# Run create_hub.py to create Azure AI Hub - ADMINISTRATOR ONLY
# echo "Creating Azure AI Hub..."
# python create_hub.py

# Run create_workspaces_project.py to create workspaces and project
echo "Creating workspaces and project..."
python create_workspaces_project.py

# Run create_model_serverless.py to deploy the model
echo "Deploying model to serverless API..."
python create_model_serverless.py "$ORIGINAL_DIR"

# Test the deployed model
echo "Testing the deployed model..."
python model_testing.py

echo "Setup complete. Your model is live and tested!"
