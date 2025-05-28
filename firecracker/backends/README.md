# Firecracker Backends

This directory contains scripts and tools to set up, build, and test Firecracker microVM images for Node.js and Python environments, as well as a web UI for management.

## Prerequisites
- Linux host with sudo privileges
- Docker
- jq
- curl
- wget

## Setup and Image Creation

### 1. Install Networking and Kernel Dependencies
Run the following to set up the network interface and download the latest Firecracker kernel:

```sh
./install.sh
```

### 2. Build Node.js and Python Images
To build the Node.js image:
```sh
./create_ubuntu_nodejs_image.sh
```

To build the Python image:
```sh
./create_ubuntu_python_image.sh
```

## Testing the Images

### Start a Python VM
```sh
./start-custum-rom.sh python3
```

### Start a Node.js VM
```sh
./start-custum-rom.sh nodejs
```

## Web UI

A web-based management UI is available on port 5000 after starting the backend server. Access it at:

```
http://localhost:5000
```

From the UI, you can:
- Create and manage VMs
- Edit and save files inside VMs
- Start/stop VMs
- View VM logs and API responses

## Additional Scripts
- `create_images_nodejs.sh` / `create_images_python.sh`: Advanced or batch image creation

---

For more details, see comments in each script file.
