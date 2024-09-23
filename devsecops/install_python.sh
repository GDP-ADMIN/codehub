#!/bin/bash

# Function to install Python on Debian-based systems (Debian, Ubuntu)
install_python_debian() {
    echo "Detected Debian/Ubuntu. Installing Python..."
    sudo apt update
    sudo apt install -y python3 python3-pip
}

# Function to install Python on CentOS-based systems
install_python_centos() {
    echo "Detected CentOS/RHEL. Installing Python..."
    sudo yum install -y python3
}

# Function to install Python on macOS
install_python_macos() {
    echo "Detected macOS. Installing Python..."
    # Check if Homebrew is installed, install if necessary
    if ! command -v brew &> /dev/null; then
        echo "Homebrew not found, installing Homebrew first..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    fi
    brew install python3
}

# Detect the operating system
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    if [[ -f /etc/debian_version ]]; then
        install_python_debian
    elif [[ -f /etc/redhat-release ]]; then
        install_python_centos
    else
        echo "Unsupported Linux distribution. Please install Python manually."
        exit 1
    fi
elif [[ "$OSTYPE" == "darwin"* ]]; then
    install_python_macos
else
    echo "Unsupported OS. Please install Python manually."
    exit 1
fi

# Verify installation
python3 --version && pip3 --version
