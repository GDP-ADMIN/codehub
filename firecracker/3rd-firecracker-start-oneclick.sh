#!/bin/bash 
set -xe
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
    "kernel_image_path": "${PWD}/vmlinux-6.1.128",
    "boot_args": "console=ttyS0 reboot=k panic=1 pci=off"
  },
  "drives": [
    {
      "drive_id": "rootfs",
      "path_on_host": "${PWD}/ubuntu-24.04.ext4",
      "is_root_device": true,
      "is_read_only": false
    }
  ],
  "network-interfaces": [
    {
      "iface_id": "eth0",
      "guest_mac": "AA:FC:00:00:00:01",
      "host_dev_name": "tap0"
    }
  ],
  "machine-config": {
    "vcpu_count": 2,
    "mem_size_mib": 512,
    "smt": false
  }
}
EOF

echo "Starting Firecracker VM..."
echo "Remember to quit shell with type "reboot" in the VM console"
echo -e "\nAdd the following commands to your shell to networking inside VM:\n"
echo "ip addr add 172.16.0.2/30 dev eth0"
echo "ip link set eth0 up"
echo "ip route add default via 172.16.0.1 dev eth0"
sleep 4

sudo rm /tmp/firecracker.socket || true
firecracker --version
sudo firecracker --api-sock /tmp/firecracker.socket --config-file ${PWD}/vmm-config.json
