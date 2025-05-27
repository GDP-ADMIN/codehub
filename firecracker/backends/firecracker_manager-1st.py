from flask import Flask, request, jsonify, render_template
import os
import subprocess
import json
import shutil

app = Flask(__name__)

# Using absolute path for Firecracker binary
FIRECRACKER_BINARY = "firecracker"  # Without ./ as specified
FIRECRACKER_SOCKET = "/tmp/firecracker.sock"

# Directory to store VM configuration files
VM_CONFIG_DIR = "./vm_configs"

# Define kernel path using environment variable
# KERNEL_PATH = f"{os.environ.get('PWD')}/../vmlinux-6.1.128"
KERNEL_PATH = f"./../vmlinux-6.1.128"

# Define available base images and runtimes
BASE_IMAGES = {
    "ubuntu": "./ubuntu-rootfs.img.gz",
    "alpine": "./alpine-rootfs.img.gz"
}

# Define language-specific image paths
NODEJS_IMAGE = "./ubuntu-24.04-nodejs.ext4"
PYTHON_IMAGE = "./ubuntu-24.04-python.ext4"

RUNTIMES = {
    "node": "node:latest",
    "python": "python:latest"
}

# Initialize the VM config directory
def init_config_dir():
    if not os.path.exists(VM_CONFIG_DIR):
        os.makedirs(VM_CONFIG_DIR)

# Function to save VM configuration to a file
def save_vm_config(vm_id, status, config, vm_type="general"):
    vm_data = {
        "vm_id": vm_id,
        "status": status,
        "config": config,
        "vm_type": vm_type
    }
    
    with open(os.path.join(VM_CONFIG_DIR, f"vm_{vm_id}.json"), 'w') as f:
        json.dump(vm_data, f, indent=2)

# Function to get VM configuration from file
def get_vm_config(vm_id):
    config_path = os.path.join(VM_CONFIG_DIR, f"vm_{vm_id}.json")
    if os.path.exists(config_path):
        with open(config_path, 'r') as f:
            return json.load(f)
    return None

# Function to retrieve all VM configurations
def list_vms():
    vms = []
    if os.path.exists(VM_CONFIG_DIR):
        for filename in os.listdir(VM_CONFIG_DIR):
            if filename.startswith("vm_") and filename.endswith(".json"):
                with open(os.path.join(VM_CONFIG_DIR, filename), 'r') as f:
                    vm_data = json.load(f)
                    vms.append(vm_data)
    return vms

# Initialize the VM config directory
init_config_dir()

@app.route('/')
def index():
    """Render the main page."""
    return render_template('index.html')

@app.route('/create_vm', methods=['POST'])
def create_vm():
    vm_id = request.json.get("vm_id")  # Get ID from request
    if not vm_id:
        return jsonify({"error": "Missing vm_id"}), 400

    # Create a new microVM configuration
    config = {
        "boot-source": {
            "kernel_image_path": KERNEL_PATH,  # Updated kernel path
            "boot_args": "console=ttyS0 reboot=k panic=1 pci=off"
        },
        "drives": [{
            "drive_id": f"rootfs{vm_id}",
            "path_on_host": f"./ubuntu-rootfs-{vm_id}.img.gz",
            "is_root_device": True,
            "is_read_only": False
        }],
        "network-interfaces": [{
            "iface_id": f"eth0",
            "host_dev_name": f"tap0-{vm_id}"
        }]
    }

    status = "running"

    # Start Firecracker instance and load configuration
    subprocess.run([FIRECRACKER_BINARY, "--api-sock", FIRECRACKER_SOCKET], stdout=subprocess.PIPE)
    cmd = f"curl -X PUT --header 'Accept: application/json' --header 'Content-Type: application/json' --data-binary '{json.dumps(config)}' http://localhost:8080/microvm-{vm_id}/boot-source"
    os.system(cmd)

    # Start the microVM
    os.system(f"curl -X PUT --header 'Accept: application/json' --header 'Content-Type: application/json' --data-binary '{{\"action\":\"Start\"}}' http://localhost:8080/microvm-{vm_id}/actions")

    # Store the VM info and configuration in a file
    save_vm_config(vm_id, status, config)

    return jsonify({"status": "created", "vm_id": vm_id})

@app.route('/create_vm_nodejs', methods=['POST'])
def create_vm_nodejs():
    vm_id = request.json.get("vm_id")  # Get ID from request
    if not vm_id:
        return jsonify({"error": "Missing vm_id"}), 400

    # Create a new microVM configuration specifically for Node.js
    config = {
        "boot-source": {
            "kernel_image_path": KERNEL_PATH,  # Updated kernel path
            "boot_args": "console=ttyS0 reboot=k panic=1 pci=off"
        },
        "drives": [{
            "drive_id": f"rootfs{vm_id}",
            "path_on_host": NODEJS_IMAGE,  # Use the Node.js specific image
            "is_root_device": True,
            "is_read_only": False
        }],
        "network-interfaces": [{
            "iface_id": f"eth0",
            "host_dev_name": f"tap0-{vm_id}"
        }]
    }

    status = "running"

    # Start Firecracker instance and load configuration
    subprocess.run([FIRECRACKER_BINARY, "--api-sock", FIRECRACKER_SOCKET], stdout=subprocess.PIPE)
    cmd = f"curl -X PUT --header 'Accept: application/json' --header 'Content-Type: application/json' --data-binary '{json.dumps(config)}' http://localhost:8080/microvm-{vm_id}/boot-source"
    os.system(cmd)

    # Start the microVM
    os.system(f"curl -X PUT --header 'Accept: application/json' --header 'Content-Type: application/json' --data-binary '{{\"action\":\"Start\"}}' http://localhost:8080/microvm-{vm_id}/actions")

    # Store the VM info and configuration in a file with type
    save_vm_config(vm_id, status, config, "nodejs")

    return jsonify({"status": "created", "vm_id": vm_id, "type": "nodejs"})

@app.route('/create_vm_python', methods=['POST'])
def create_vm_python():
    vm_id = request.json.get("vm_id")  # Get ID from request
    if not vm_id:
        return jsonify({"error": "Missing vm_id"}), 400

    # Create a new microVM configuration specifically for Python
    config = {
        "boot-source": {
            "kernel_image_path": KERNEL_PATH,  # Updated kernel path
            "boot_args": "console=ttyS0 reboot=k panic=1 pci=off"
        },
        "drives": [{
            "drive_id": f"rootfs{vm_id}",
            "path_on_host": PYTHON_IMAGE,  # Use the Python specific image
            "is_root_device": True,
            "is_read_only": False
        }],
        "network-interfaces": [{
            "iface_id": f"eth0",
            "host_dev_name": f"tap0-{vm_id}"
        }]
    }

    status = "running"

    # Start Firecracker instance and load configuration
    subprocess.run([FIRECRACKER_BINARY, "--api-sock", FIRECRACKER_SOCKET], stdout=subprocess.PIPE)
    cmd = f"curl -X PUT --header 'Accept: application/json' --header 'Content-Type: application/json' --data-binary '{json.dumps(config)}' http://localhost:8080/microvm-{vm_id}/boot-source"
    os.system(cmd)

    # Start the microVM
    os.system(f"curl -X PUT --header 'Accept: application/json' --header 'Content-Type: application/json' --data-binary '{{\"action\":\"Start\"}}' http://localhost:8080/microvm-{vm_id}/actions")

    # Store the VM info and configuration in a file with type
    save_vm_config(vm_id, status, config, "python")

    return jsonify({"status": "created", "vm_id": vm_id, "type": "python"})

@app.route('/stop_vm/<int:vm_id>', methods=['POST'])
def stop_vm(vm_id):
    vm_config = get_vm_config(vm_id)
    if not vm_config:
        return jsonify({"error": "VM not found"}), 404

    # Stop the microVM
    os.system(f"curl -X PUT --header 'Accept: application/json' --header 'Content-Type: application/json' --data-binary '{{\"action\":\"Stop\"}}' http://localhost:8080/microvm-{vm_id}/actions")

    # Update the VM status in the file
    vm_config["status"] = "stopped"
    save_vm_config(vm_id, "stopped", vm_config["config"], vm_config["vm_type"])

    return jsonify({"status": "stopped", "vm_id": vm_id})

@app.route('/delete_vm/<int:vm_id>', methods=['DELETE'])
def delete_vm(vm_id):
    vm_config = get_vm_config(vm_id)
    if not vm_config:
        return jsonify({"error": "VM not found"}), 404

    # Stop the microVM if it's running
    if vm_config["status"] == "running":
        os.system(f"curl -X PUT --header 'Accept: application/json' --header 'Content-Type: application/json' --data-binary '{{\"action\":\"Stop\"}}' http://localhost:8080/microvm-{vm_id}/actions")

    # Remove the VM configuration file
    config_path = os.path.join(VM_CONFIG_DIR, f"vm_{vm_id}.json")
    if os.path.exists(config_path):
        os.remove(config_path)

    return jsonify({"status": "deleted", "vm_id": vm_id})

@app.route('/list_vms', methods=['GET'])
def list_vms_route():
    """List all microVMs and their configurations."""
    return jsonify(list_vms())

@app.route('/edit_file', methods=['POST'])
def edit_file():
    data = request.json
    file_path = data.get("file_path")
    content = data.get("content")

    # Save the content to the specified file
    with open(file_path, 'w') as f:
        f.write(content)

    return jsonify({"message": "File updated successfully."})

@app.route('/create_image', methods=['POST'])
def create_image():
    data = request.json
    os_name = data.get("os")
    runtime = data.get("runtime")

    if os_name is None or runtime is None:
        return jsonify({"error": "os and runtime must be specified"}), 400

    if os_name not in BASE_IMAGES:
        return jsonify({"error": "Unsupported base OS"}), 400

    # Create the image using Firecracker-compatible methods
    print(f"Creating image for {os_name} with runtime {runtime}...")

    # Example command to create the base image (replace this with actual image creation command)
    base_image_path = BASE_IMAGES[os_name]

    # Simulating the image creation process
    create_command = f"echo 'Creating image file at {base_image_path}'"  # Placeholder; replace with actual logic
    subprocess.run(create_command, shell=True)

    # Simulating the completion of image creation
    return jsonify({"message": f"Image created at {base_image_path}"}), 201

# Add a test endpoint to check if the server is working
@app.route('/test', methods=['GET'])
def test_endpoint():
    return jsonify({
        "status": "ok",
        "kernel_path": KERNEL_PATH,
        "nodejs_image": NODEJS_IMAGE,
        "python_image": PYTHON_IMAGE
    })

if __name__ == '__main__':
    # Print some diagnostic information
    print(f"Starting Flask server with following configuration:")
    print(f"Firecracker binary: {FIRECRACKER_BINARY}")
    print(f"Firecracker socket: {FIRECRACKER_SOCKET}")
    print(f"Kernel path: {KERNEL_PATH}")
    print(f"Node.js image: {NODEJS_IMAGE}")
    print(f"Python image: {PYTHON_IMAGE}")
    print(f"VM config directory: {VM_CONFIG_DIR}")
    
    app.run(host='0.0.0.0', port=5000, debug=True)
