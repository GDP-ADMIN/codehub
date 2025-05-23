sudo tee /root/vmm-config.json <<EOF
{
  "boot-source": {
    "kernel_image_path": "/root/vmlinux-6.1.128",
    "boot_args": "console=ttyS0 reboot=k panic=1 pci=off"
  },
  "drives": [
    {
      "drive_id": "rootfs",
      "path_on_host": "/root/ubuntu-24.04.ext4",
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
echo " Remember to quit with type reboot in the VM console"
sleep 4

sudo ./firecracker --api-sock /tmp/firecracker.socket --config-file /root/vmm-config.json
