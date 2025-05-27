from flask import Flask, request, jsonify, render_template
import os
import subprocess
import json
import sqlite3

app = Flask(__name__)

FIRECRACKER_SOCKET = "/tmp/firecracker.sock"
DB_NAME = "vms.db"

# Define available base images and runtimes (removing Debian)
BASE_IMAGES = {
    "ubuntu": "./ubuntu-rootfs.img.gz",
    "alpine": "./alpine-rootfs.img.gz"  # Keeping Alpine if it is still needed
}

RUNTIMES = {
    "node": "node:latest",
    "python": "python:latest"
}

# Initialize the database and create necessary tables
def init_db():
    conn = sqlite3.connect(DB_NAME)
    c = conn.cursor()
    c.execute('''CREATE TABLE IF NOT EXISTS vms
                 (id INTEGER PRIMARY KEY AUTOINCREMENT,
                  vm_id INTEGER UNIQUE,
                  status TEXT,
                  config TEXT)''')  # Added column to store configuration
    conn.commit()
    conn.close()

# Function to add or update VM info and configuration in the database
def upsert_vm(vm_id, status, config):
    conn = sqlite3.connect(DB_NAME)
    c = conn.cursor()
    c.execute('''INSERT INTO vms (vm_id, status, config) VALUES (?, ?, ?)
                 ON CONFLICT(vm_id) DO UPDATE SET status=excluded.status, config=excluded.config''',
               (vm_id, status, json.dumps(config)))
    conn.commit()
    conn.close()

# Function to retrieve VM info from the database
def list_vms():
    conn = sqlite3.connect(DB_NAME)
    c = conn.cursor()
    c.execute('SELECT vm_id, status, config FROM vms')
    vms = []
    for row in c.fetchall():
        vms.append({"vm_id": row[0], "status": row[1], "config": json.loads(row[2])})
    conn.close()
    return vms

# Initialize the database
init_db()

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
            "kernel_image_path": "${PWD}/../vmlinux-6.1.128",
            "boot_args": "console=ttyS0 reboot=k panic=1 pci=off"
        },
        "drives": [{
            "drive_id": f"rootfs{vm_id}",
            "path_on_host": f"./ubuntu-rootfs-{vm_id}.img.gz",  # Update to use Ubuntu rootfs
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
    subprocess.run([f"firecracker", "--api-sock", FIRECRACKER_SOCKET], stdout=subprocess.PIPE)
    cmd = f"curl -X PUT --header 'Accept: application/json' --header 'Content-Type: application/json' --data-binary '{json.dumps(config)}' http://localhost:8080/microvm-{vm_id}/boot-source"
    os.system(cmd)

    # Start the microVM
    os.system(f"curl -X PUT --header 'Accept: application/json' --header 'Content-Type: application/json' --data-binary '{{\"action\":\"Start\"}}' http://localhost:8080/microvm-{vm_id}/actions")

    # Store the VM info and configuration in the database
    upsert_vm(vm_id, status, config)

    return jsonify({"status": "created", "vm_id": vm_id})

@app.route('/stop_vm/<int:vm_id>', methods=['POST'])
def stop_vm(vm_id):
    if vm_id not in [vm['vm_id'] for vm in list_vms()]:
        return jsonify({"error": "VM not found"}), 404

    # Stop the microVM
    os.system(f"curl -X PUT --header 'Accept: application/json' --header 'Content-Type: application/json' --data-binary '{{\"action\":\"Stop\"}}' http://localhost:8080/microvm-{vm_id}/actions")

    # Update the VM status in the database
    upsert_vm(vm_id, "stopped", None)  # Optionally keep the config

    return jsonify({"status": "stopped", "vm_id": vm_id})

@app.route('/delete_vm/<int:vm_id>', methods=['DELETE'])
def delete_vm(vm_id):
    if vm_id not in [vm['vm_id'] for vm in list_vms()]:
        return jsonify({"error": "VM not found"}), 404

    # Stop the microVM if it's running
    if any(vm['vm_id'] == vm_id and vm['status'] == "running" for vm in list_vms()):
        os.system(f"curl -X PUT --header 'Accept: application/json' --header 'Content-Type: application/json' --data-binary '{{\"action\":\"Stop\"}}' http://localhost:8080/microvm-{vm_id}/actions")

    # Remove the VM from the database
    conn = sqlite3.connect(DB_NAME)
    c = conn.cursor()
    c.execute('DELETE FROM vms WHERE vm_id = ?', (vm_id,))
    conn.commit()
    conn.close()

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

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
