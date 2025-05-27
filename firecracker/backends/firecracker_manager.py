from flask import Flask, request, jsonify, render_template
import os
import subprocess
import json
import shutil
import uuid
import time

app = Flask(__name__)

# Base directory to store VM configuration and data
VM_CONFIG_DIR = "./vm_configs"
VM_DATA_DIR = "./vm-data"

# Define language-specific image paths (assuming they are stored in a base directory)
BASE_IMAGE_DIR = "./base_images"
NODEJS_IMAGE_PATH = f"{BASE_IMAGE_DIR}/ubuntu-24.04-nodejs.ext4"
PYTHON_IMAGE_PATH = f"{BASE_IMAGE_DIR}/ubuntu-24.04-python3.ext4"

# Function to initialize directories
def init_directories():
    for directory in [VM_CONFIG_DIR, VM_DATA_DIR]:
        if not os.path.exists(directory):
            os.makedirs(directory)

# # Function to copy base image to unique VM directory
# def copy_base_image(vm_id, image_path):
#     vm_directory = os.path.join(VM_DATA_DIR, f"vm_{vm_id}")
#     if not os.path.exists(vm_directory):
#         os.makedirs(vm_directory)

#     image_filename = os.path.basename(image_path)
#     destination_path = os.path.join(vm_directory, image_filename)
#     # shutil.copyfile(image_path, destination_path)

#     # Only run the Python image creation script if the image is the Python base image
#     if "python3" in image_filename:
#         create_image_script = os.path.abspath("create_images_python.sh")
#         subprocess.run(["bash", create_image_script, str(vm_id)], check=True)

#         # Move the result image if it exists (ubuntu-24.04-python3_${vm_id}.ext4)
#         result_image_name = f"ubuntu-24.04-python3_{vm_id}.ext4"
#         result_image_path = os.path.join(os.path.dirname(image_path), result_image_name)
#         if os.path.exists(result_image_path):
#             final_image_path = os.path.join(vm_directory, result_image_name)
#             shutil.move(result_image_path, final_image_path)
#             return final_image_path


# Function to create VM configuration file
def create_vm_config(vm_id, vm_type):
    # Generate a unique MAC address for this VM
    mac_suffix = format(vm_id % 256, '02x')
    guest_mac = f"AA:FC:00:00:00:{mac_suffix}"
    vm_directory = os.path.join(VM_DATA_DIR, f"vm_{vm_id}")
    if not os.path.exists(vm_directory):
        os.makedirs(vm_directory)
    final_image_path = None
    if vm_type == "nodejs":
        create_image_script = os.path.abspath("create_images_nodejs.sh")
        subprocess.run(["bash", create_image_script, str(vm_id)], check=True)

        result_image_name = f"ubuntu-24.04-nodejs_{vm_id}.ext4"
        result_image_path = os.path.join(os.getcwd(), result_image_name)
        final_image_path = os.path.join(vm_directory, result_image_name)
        if os.path.exists(result_image_path):
            shutil.move(result_image_path, final_image_path)
    elif vm_type == "python":
        create_image_script = os.path.abspath("create_images_python.sh")
        subprocess.run(["bash", create_image_script, str(vm_id)], check=True)

        result_image_name = f"ubuntu-24.04-python3_{vm_id}.ext4"
        result_image_path = os.path.join(os.getcwd(), result_image_name)
        final_image_path = os.path.join(vm_directory, result_image_name)
        if os.path.exists(result_image_path):
            shutil.move(result_image_path, final_image_path)

    # Create the VM configuration JSON
    config = {
        "boot-source": {
            "kernel_image_path": f"{BASE_IMAGE_DIR}/vmlinux-6.1.128",
            "boot_args": "console=ttyS0 reboot=k panic=1 pci=off"
        },
        "drives": [
            {
                "drive_id": "rootfs",
                "path_on_host": final_image_path,
                "is_root_device": True,
                "is_read_only": False,
                "io_engine": "Sync",
                "rate_limiter": None,
                "socket": None,
                "cache_type": "Unsafe"
            }
        ],
        "network-interfaces": [
            {
                "iface_id": "eth0",
                "guest_mac": guest_mac,
                "host_dev_name": "tap0",
                "rx_rate_limiter": None,
                "tx_rate_limiter": None
            }
        ],
        "machine-config": {
            "vcpu_count": 2,
            "mem_size_mib": 1024,
            "smt": False,
            "track_dirty_pages": False
        },
        "vsock": None,
        "logger": None,
        "metrics": None,
        "mmds-config": None,
        "entropy": None,
        "balloon": None
    }
    
    # Write the configuration to a file
    config_path = os.path.join(VM_DATA_DIR, f"vm_{vm_id}", f"vmm.json")
    config_dir = os.path.dirname(config_path)
    if not os.path.exists(config_dir):
        os.makedirs(config_dir)
    with open(config_path, 'w') as f:
        json.dump(config, f, indent=2)

    return config



# Function to start a VM
def start_vm(vm_id):
    vm_directory = os.path.join(VM_DATA_DIR, f"vm_{vm_id}")

    # Create start script for this VM
    start_script_path = os.path.join(vm_directory, f"start-vm.sh")
    with open(start_script_path, 'w') as f:
        f.write(f"""#!/bin/bash
# Remove any existing socket file
sudo rm /tmp/firecracker-{vm_id}.socket || true

# Start firecracker with the VM configuration
sudo firecracker --api-sock /tmp/firecracker-{vm_id}.socket --config-file {vm_directory}/vmm.json
""")
    
    # Make the script executable
    os.chmod(start_script_path, 0o755)
    
    # Run the start script in the background
    subprocess.Popen(f"nohup {start_script_path} > {vm_directory}/vm.log 2>&1 &", shell=True)
    # Add iptables rule to redirect SSH_PORT on host to port 22 on VM IP (tap0), if not already present
    # Calculate VM IP and SSH port
    vm_ip = f"172.16.0.{vm_id}"
    if 1 <= vm_id <= 9:
        ssh_port = int(f"2200{vm_id}")
    else:
        ssh_port = 220 + vm_id

    # PREROUTING: Host port -> VM IP:22 via tap0
    iptables_check_cmd = [
        "sudo", "iptables", "-t", "nat", "-C", "PREROUTING",
        "-p", "tcp", "-d", "127.0.0.1", "--dport", str(ssh_port),
        "-j", "DNAT", "--to-destination", f"{vm_ip}:22", "-i", "tap0"
    ]
    iptables_add_cmd = [
        "sudo", "iptables", "-t", "nat", "-A", "PREROUTING",
        "-p", "tcp", "-d", "127.0.0.1", "--dport", str(ssh_port),
        "-j", "DNAT", "--to-destination", f"{vm_ip}:22", "-i", "tap0"
    ]
    try:
        subprocess.run(iptables_check_cmd, check=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    except subprocess.CalledProcessError:
        subprocess.run(iptables_add_cmd, check=True)

    # POSTROUTING: VM IP:22 -> MASQUERADE via tap0
    iptables_check_cmd2 = [
        "sudo", "iptables", "-t", "nat", "-C", "POSTROUTING",
        "-p", "tcp", "-d", vm_ip, "--dport", "22",
        "-j", "MASQUERADE", "-o", "tap0"
    ]
    iptables_add_cmd2 = [
        "sudo", "iptables", "-t", "nat", "-A", "POSTROUTING",
        "-p", "tcp", "-d", vm_ip, "--dport", "22",
        "-j", "MASQUERADE", "-o", "tap0"
    ]
    try:
        subprocess.run(iptables_check_cmd2, check=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    except subprocess.CalledProcessError:
        subprocess.run(iptables_add_cmd2, check=True)
    # Calculate VM IP and HTTP port
    vm_ip = f"172.16.0.{vm_id}"
    http_port = 80
    http_url = f"http://{vm_ip}:{http_port}"

    # Calculate SSH port
    if 1 <= vm_id <= 9:
        ssh_port = int(f"2200{vm_id}")
    else:
        ssh_port = 220 + vm_id

    # Save VM metadata
    vm_meta = {
        "vm_id": vm_id,
        "status": "running",
        "vm_type": get_vm_type(vm_id),
        "pid": None,  # We don't track PID in this implementation
        "socket": f"/tmp/firecracker-{vm_id}.socket",
        "ip": vm_ip,
        "ssh_port": ssh_port,
        "http_port": http_port,
        "http_url": http_url
    }
    
    # Wait until the VM responds to ping (timeout 30s)
    timeout = 30
    start_time = time.time()
    while True:
        try:
            result = subprocess.run(
                ["ping", "-c", "1", "-W", "1", vm_ip],
                stdout=subprocess.DEVNULL,
                stderr=subprocess.DEVNULL,
            )
            if result.returncode == 0:
                break
        except Exception:
            pass
        if time.time() - start_time > timeout:
            print(f"Timeout: VM {vm_id} at {vm_ip} did not respond to ping within {timeout} seconds.")
            break
        time.sleep(1)
    with open(os.path.join(VM_CONFIG_DIR, f"vm-{vm_id}.json"), 'w') as f:
        json.dump(vm_meta, f, indent=2)
    
    return vm_meta

# Function to get VM type from config
def get_vm_type(vm_id):
    meta_path = os.path.join(VM_CONFIG_DIR, f"vm-{vm_id}.json")
    if os.path.exists(meta_path):
        with open(meta_path, 'r') as f:
            vm_meta = json.load(f)
            return vm_meta.get("vm_type", "unknown")
    return None

# Function to stop a VM
def stop_vm(vm_id):
    # Create a script to stop the VM
    socket_path = f"/tmp/firecracker-{vm_id}.socket"
    
    # Use the kill command to terminate the firecracker process
    try:
        subprocess.run(f"sudo pkill -f 'firecracker.*{socket_path}'", shell=True)
        # Remove iptables rules for this VM's SSH port forwarding
        # Calculate VM IP and SSH port
        vm_ip = f"172.16.0.{vm_id}"
        if 1 <= vm_id <= 9:
            ssh_port = int(f"2200{vm_id}")
        else:
            ssh_port = 220 + vm_id

        # Delete PREROUTING rule (must match the rule added)
        iptables_del_cmd = [
            "sudo", "iptables", "-t", "nat", "-D", "PREROUTING",
            "-p", "tcp", "-d", "127.0.0.1", "--dport", str(ssh_port),
            "-j", "DNAT", "--to-destination", f"{vm_ip}:22", "-i", "tap0"
        ]
        subprocess.run(iptables_del_cmd, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)

        # Delete POSTROUTING rule (must match the rule added)
        iptables_del_cmd2 = [
            "sudo", "iptables", "-t", "nat", "-D", "POSTROUTING",
            "-p", "tcp", "-d", vm_ip, "--dport", "22",
            "-j", "MASQUERADE", "-o", "tap0"
        ]
        subprocess.run(iptables_del_cmd2, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        # Update VM metadata
        meta_path = os.path.join(VM_CONFIG_DIR, f"vm-{vm_id}.json")
        if os.path.exists(meta_path):
            with open(meta_path, 'r') as f:
                vm_meta = json.load(f)
            
            vm_meta["status"] = "stopped"
            
            with open(meta_path, 'w') as f:
                json.dump(vm_meta, f, indent=2)
                
        return True
    except Exception as e:
        print(f"Error stopping VM {vm_id}: {str(e)}")
        return False

# Function to delete a VM
def delete_vm(vm_id):
    # First stop the VM if it's running
    stop_vm(vm_id)
    
    # Remove VM configuration files and directory
    vm_directory = os.path.join(VM_DATA_DIR, f"vm_{vm_id}")
    if os.path.exists(vm_directory):
        shutil.rmtree(vm_directory)
    
    # Remove VM metadata
    meta_path = os.path.join(VM_CONFIG_DIR, f"vm-{vm_id}.json")
    if os.path.exists(meta_path):
        os.remove(meta_path)
    
    return True

# Function to list all VMs
def list_vms():
    vms = []
    if os.path.exists(VM_CONFIG_DIR):
        for filename in os.listdir(VM_CONFIG_DIR):
            if filename.startswith("vm-") and filename.endswith(".json"):
                with open(os.path.join(VM_CONFIG_DIR, filename), 'r') as f:
                    vm_meta = json.load(f)
                    vms.append(vm_meta)
    return vms

# Initialize directories
init_directories()

@app.route('/')
def index():
    """Render the main page."""
    return render_template('index.html')

@app.route('/create_vm_nodejs', methods=['POST'])
def create_vm_nodejs():
    vm_id = request.json.get("vm_id")
    if not vm_id:
        # Generate a random VM ID if not provided
        vm_id = int(uuid.uuid4().hex[:8], 16) % 10000
    
    # Create VM configuration for Node.js
    config = create_vm_config(vm_id, "nodejs")
    if not config:
        return jsonify({"error": "Failed to create VM configuration"}), 500
    
    return jsonify({
        "status": "created",
        "vm_id": vm_id,
        "type": "nodejs",
        "command_to_start_vm": f"curl -X POST http://localhost:5000/start_vm/{vm_id}"
    })

@app.route('/create_vm_python', methods=['POST'])
def create_vm_python():
    vm_id = request.json.get("vm_id")
    if not vm_id:
        # Generate a random VM ID if not provided
        vm_id = int(uuid.uuid4().hex[:8], 16) % 10000
    
    # Create VM configuration for Python
    config = create_vm_config(vm_id, "python")
    if not config:
        return jsonify({"error": "Failed to create VM configuration"}), 500
    
    return jsonify({
        "status": "created",
        "vm_id": vm_id,
        "type": "python",
        "command_to_start_vm": f"curl -X POST http://localhost:5000/start_vm/{vm_id}"
    })

@app.route('/stop_vm/<int:vm_id>', methods=['POST'])
def stop_vm_route(vm_id):
    if not os.path.exists(os.path.join(VM_CONFIG_DIR, f"vm-{vm_id}.json")):
        return jsonify({"error": "VM not found"}), 404
    
    if stop_vm(vm_id):
        return jsonify({"status": "stopped", "vm_id": vm_id})
    else:
        return jsonify({"error": "Failed to stop VM"}), 500

@app.route('/start_vm/<int:vm_id>', methods=['POST'])
def start_vm_route(vm_id):
    # if not os.path.exists(os.path.join(VM_CONFIG_DIR, f"vm-{vm_id}.json")):
    #     return jsonify({"error": "VM not found"}), 404

    vm_meta = start_vm(vm_id)
    if vm_meta:
        return jsonify(vm_meta)
    else:
        return jsonify({"error": "Failed to start VM"}), 500


@app.route('/delete_vm/<int:vm_id>', methods=['DELETE'])
def delete_vm_route(vm_id):
    if not os.path.exists(os.path.join(VM_CONFIG_DIR, f"vm-{vm_id}.json")):
        return jsonify({"error": "VM not found"}), 404
    
    if delete_vm(vm_id):
        return jsonify({"status": "deleted", "vm_id": vm_id})
    else:
        return jsonify({"error": "Failed to delete VM"}), 500

@app.route('/list_vms', methods=['GET'])
def list_vms_route():
    """List all microVMs and their configurations."""
    return jsonify(list_vms())

@app.route('/vm_logs/<int:vm_id>', methods=['GET'])
def vm_logs(vm_id):
    """Get logs for a specific VM"""
    log_path = os.path.join(VM_DATA_DIR, f"vm_{vm_id}/vm.log")
    if not os.path.exists(log_path):
        return jsonify({"error": "VM logs not found"}), 404
    
    try:
        with open(log_path, 'r', encoding='utf-8', errors='replace') as f:
            log_lines = f.readlines()
            logs = [line.strip() for line in log_lines if '\u0000' not in line]
    except Exception as e:
        return jsonify({"error": f"Failed to read VM logs: {str(e)}"}), 500
    return jsonify({"vm_id": vm_id, "logs": logs})

@app.route('/test', methods=['GET'])
def test_endpoint():
    return jsonify({
        "status": "ok",
        "vm_config_dir": VM_CONFIG_DIR,
        "vm_data_dir": VM_DATA_DIR,
        "nodejs_image": NODEJS_IMAGE_PATH,
        "python_image": PYTHON_IMAGE_PATH
    })

@app.route('/load_file', methods=['POST'])
def load_file():
    data = request.json
    file_path = data.get("file_path")
    
    if not file_path:
        return jsonify({"error": "Missing file_path"}), 400

    try:
        with open(file_path, 'r') as f:
            content = f.read()
        return jsonify({"content": content})
    except FileNotFoundError:
        return jsonify({"error": "File not found"}), 404
    except Exception as e:
        return jsonify({"error": f"Error reading file: {str(e)}"}), 500

@app.route('/edit_file', methods=['POST'])
def edit_file():
    data = request.json
    file_path = data.get("file_path")
    content = data.get("content")
    
    if not file_path or not content:
        return jsonify({"error": "Missing file_path or content"}), 400

    try:
        # Ensure the directory exists
        os.makedirs(os.path.dirname(file_path), exist_ok=True)
        
        # Write the content to the file
        with open(file_path, 'w') as f:
            f.write(content)
        
        return jsonify({"message": "File saved successfully"})
    except Exception as e:
        return jsonify({"error": f"Error saving file: {str(e)}"}), 500


if __name__ == '__main__':
    # Print some diagnostic information
    print(f"Starting Flask server with the following configuration:")
    print(f"VM config directory: {VM_CONFIG_DIR}")
    print(f"VM data directory: {VM_DATA_DIR}")
    print(f"Base image directory: {BASE_IMAGE_DIR}")
    print(f"Node.js image: {NODEJS_IMAGE_PATH}")
    print(f"Python image: {PYTHON_IMAGE_PATH}")
    
    app.run(host='0.0.0.0', port=5000, debug=True)
