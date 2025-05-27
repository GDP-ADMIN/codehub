#!/bin/bash

# Script to create a Firecracker VM with Node.js environment
set -e

# Configuration
KERNEL="vmlinux-5.10.186"
ROOTFS="ubuntu-22.04.ext4"
VM_NAME="node-vm"
SSH_KEY="id_rsa"
TAP_DEV="tap0"
FC_IP="172.16.0.1"
VM_IP="172.16.0.2"

# Check if required files exist
if [ ! -f "$KERNEL" ] || [ ! -f "$ROOTFS" ]; then
    echo "Error: Required kernel or rootfs files not found"
    echo "Please run the download scripts first"
    exit 1
fi

# Create and setup network interface
sudo ip link del "$TAP_DEV" 2> /dev/null || true
sudo ip tuntap add dev "$TAP_DEV" mode tap
sudo ip addr add "${FC_IP}/30" dev "$TAP_DEV"
sudo ip link set "$TAP_DEV" up

# Enable IP forwarding and setup NAT
sudo sh -c "echo 1 > /proc/sys/net/ipv4/ip_forward"
sudo iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
sudo iptables -A FORWARD -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT
sudo iptables -A FORWARD -i tap0 -o eth0 -j ACCEPT

# Create API socket
socket_path="/tmp/firecracker.socket"
rm -f "$socket_path"

# Start Firecracker
KERNEL_BOOT_ARGS="console=ttyS0 reboot=k panic=1 pci=off"

# Configure the VM
cat <<EOF > vm_config.json
{
  "boot-source": {
    "kernel_image_path": "$KERNEL",
    "boot_args": "$KERNEL_BOOT_ARGS"
  },
  "drives": [
    {
      "drive_id": "rootfs",
      "path_on_host": "$ROOTFS",
      "is_root_device": true,
      "is_read_only": false
    }
  ],
  "network-interfaces": [
    {
      "iface_id": "eth0",
      "guest_mac": "AA:FC:00:00:00:01",
      "host_dev_name": "$TAP_DEV"
    }
  ],
  "machine-config": {
    "vcpu_count": 2,
    "mem_size_mib": 1024,
    "ht_enabled": false
  }
}
EOF

# Start Firecracker
firecracker --api-sock "$socket_path" --config-file vm_config.json &

# Wait for VM to boot
sleep 10

# Install Node.js in the VM
ssh -i "$SSH_KEY" -o StrictHostKeyChecking=no "root@$VM_IP" "
    curl -fsSL https://deb.nodesource.com/setup_20.x | bash - &&
    apt-get install -y nodejs &&
    apt-get install -y npm &&
    apt-get install -y git &&
    npm install -g yarn pm2 typescript ts-node
    echo 'Node.js version:' && node --version &&
    echo 'NPM version:' && npm --version
"

echo "Node.js VM is ready!"
echo "Connect using: ssh -i $SSH_KEY root@$VM_IP"
