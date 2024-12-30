#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

# Initialize variables
EMAIL=""
KEY_NAME="id_ed25519_github"

# Function to display usage
usage() {
    echo "Usage: $0 [-e <email>] [-k <key_name>]"
    echo
    echo "This script generates a new SSH key pair and outputs the public key."
    echo
    echo "Options:"
    echo "  -e  Email address for the SSH key (optional)"
    echo "  -k  Key name (optional, default: id_ed25519_github)"
    echo "  -h  Display help"
    exit 1
}

# Parse options
while getopts "e:k:h" opt; do
  case $opt in
    e)
      EMAIL="$OPTARG"
      ;;
    k)
      KEY_NAME="$OPTARG"
      ;;
    h)
      usage
      ;;
    \?)
      echo "Invalid option -$OPTARG"
      usage
      ;;
  esac
done

# Check if ssh-keygen is available
if ! command -v ssh-keygen >/dev/null 2>&1; then
    echo "Error: ssh-keygen is not installed. Please install OpenSSH."
    exit 1
fi

# Set the key file path
KEY_PATH="$HOME/.ssh/$KEY_NAME"

# Generate SSH key pair
echo "Generating SSH key pair..."
if [ -z "$EMAIL" ]; then
    ssh-keygen -t ed25519 -f "$KEY_PATH" -N "" -q
else
    ssh-keygen -t ed25519 -f "$KEY_PATH" -C "$EMAIL" -N "" -q
fi

if [ $? -ne 0 ]; then
    echo "Error: Failed to generate SSH key."
    exit 1
fi

# Read the public key
PUBLIC_KEY=$(cat "${KEY_PATH}.pub")

if [ -z "$PUBLIC_KEY" ]; then
    echo "Error: Failed to read public key."
    exit 1
fi

# Output the public key
echo "SSH key generated successfully."
printf "\e[34mPublic key:\e[0m\n"  # Blue text
printf "\e[32m%s\e[0m\n" "$PUBLIC_KEY"  # Green text for the public key

# Steps to add the SSH key to GitHub
echo ""
printf "Steps to add the SSH key to your GitHub account:\n"
printf "1. Open \e[35mhttps://github.com/settings/keys\e[0m\n"  # Magenta text for the URL
echo "2. Click 'New SSH Key'"
echo "3. Put a Title, select 'Key type: Authentication Key', and paste: "
printf "\e[32m%s\e[0m\n" "$PUBLIC_KEY"  # Green text for the public key
echo "4. Click 'Add SSH key'"