# SSH Key Generator and Python Installer for GitHub
This repository contains scripts to help you generate SSH keys for GitHub and install Python on different operating systems. The scripts are simple to use, and instructions are provided to make the process easy.

## Features

- [**Generate an SSH key pair**](#ssh-key-generator) with `create_ssh_key_github.sh`
- **Install Python** automatically using `install_python.sh` [(for Linux/macOS)](#install-python-on-linuxmacos) or install_python.ps1` [(for Windows)](#install-python-on-windows-powershell).

## Installation & Usage

### SSH Key Generator
To generate a new SSH key pair and output the public key:
```bash
curl -O https://raw.githubusercontent.com/GDP-ADMIN/codehub/refs/heads/main/devsecops/create_ssh_key_github.sh && bash create_ssh_key_github.sh [-e <email>] [-k <key_name>]
```

###  Install Python on Linux/macOS
```
curl -O https://raw.githubusercontent.com/GDP-ADMIN/codehub/refs/heads/main/devsecops/install_python.sh && chmod +x install_python.sh
./install_python.sh
```

### Install Python on Windows Powershell
```
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/GDP-ADMIN/codehub/refs/heads/main/devsecops/install_python.ps1" -OutFile "install_python.ps1"
./install_python.ps1
```