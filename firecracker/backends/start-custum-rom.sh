#!/bin/bash
set -e

# Display help message if no arguments or help flag is provided
if [ "$1" == "" ] || [ "$1" == "-h" ] || [ "$1" == "--help" ]; then
    echo "Usage: $0 [python|nodejs]"
    echo "Options:"
    echo "  python3    Start VM with Python3 environment"
    echo "  nodejs    Start VM with Node.js environment"
    echo "  -h,--help Show this help message"
    exit 1
fi

# Validate input
if [ "$1" != "python3" ] && [ "$1" != "nodejs" ]; then
    echo "Error: Invalid argument. Use 'python' or 'nodejs'"
    exit 1
fi

# Check if disk image exists, if not create it
DISK_IMAGE="${PWD}/ubuntu-24.04-$1.ext4"
if [ ! -f "$DISK_IMAGE" ]; then
    echo "Disk image for $1 environment not found. Creating it now..."
    if [ "$1" == "python3" ]; then
        ./create_ubuntu_python_image.sh
    else
        ./create_ubuntu_nodejs_image.sh
    fi
    
    if [ ! -f "$DISK_IMAGE" ]; then
        echo "Error: Failed to create disk image"
        exit 1
    fi
    echo "Disk image created successfully"
fi

TAP_DEV="tap0"
TAP_IP="172.16.0.1"
MASK_SHORT="/30"


# Setup network interface
#sudo ip link del "$TAP_DEV" 2> /dev/null || true
sudo ip tuntap add dev "$TAP_DEV" mode tap || true
sudo ip addr add "${TAP_IP}${MASK_SHORT}" dev "$TAP_DEV" || true
sudo ip link set dev "$TAP_DEV" up || true

# Enable ip forwarding
sudo sh -c "echo 1 > /proc/sys/net/ipv4/ip_forward"
sudo iptables -P FORWARD ACCEPT

# This tries to determine the name of the host network interface to forward
# VM's outbound network traffic through. If outbound traffic doesn't work,
# double check this returns the correct interface!
HOST_IFACE=$(ip -j route list default |jq -r '.[0].dev')

# Set up microVM internet access
sudo iptables -t nat -D POSTROUTING -o "$HOST_IFACE" -j MASQUERADE || true
sudo iptables -t nat -A POSTROUTING -o "$HOST_IFACE" -j MASQUERADE

sudo tee ${PWD}/vmm-config.json <<EOF
{
  "boot-source": {
    "kernel_image_path": "${PWD}/../vmlinux-6.1.128",
    "boot_args": "console=ttyS0 reboot=k panic=1 pci=off"
  },
  "drives": [
    {
      "drive_id": "rootfs",
      "path_on_host": "${PWD}/ubuntu-24.04-$1.ext4",
      "is_root_device": true,
      "is_read_only": false,
      "io_engine": "Sync",
      "rate_limiter": null,
      "socket": null,
      "cache_type": "Unsafe"
    }
  ],
  "network-interfaces": [
    {
      "iface_id": "eth0",
      "guest_mac": "AA:FC:00:00:00:01",
      "host_dev_name": "tap0",
      "rx_rate_limiter": null,
      "tx_rate_limiter": null
    }
  ],
  "machine-config": {
    "vcpu_count": 2,
    "mem_size_mib": 1024,
    "smt": false,
    "track_dirty_pages": false
  },
  "vsock": null,
  "logger": null,
  "metrics": null,
  "mmds-config": null,
  "entropy": null,
  "balloon": null
}
EOF

echo -e "\n\nStarting Firecracker VM..."
echo -e "Remember to quit shell with type "reboot" in the VM console\n"
#echo -e "\nAdd the following commands to your shell to networking inside VM:\n"
#echo "ip addr add 172.16.0.2/30 dev eth0"
#echo "ip link set eth0 up"
#echo "ip route add default via 172.16.0.1 dev eth0"

sudo rm /tmp/firecracker.socket || true
firecracker --version
sudo firecracker --api-sock /tmp/firecracker.socket --config-file ${PWD}/vmm-config.json
