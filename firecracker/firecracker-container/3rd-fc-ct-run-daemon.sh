#!/bin/bash
set -ex

mkdir -p /var/lib/firecracker-containerd
sudo firecracker-containerd --config /etc/firecracker-containerd/config.toml &> /var/log/firecracker-containerd.log &

sudo tee /etc/systemd/system/firecracker-containerd.service > /dev/null <<EOF
[Unit]
Description=Firecracker Containerd Service
After=network.target

[Service]
Type=simple
ExecStart=/usr/local/bin/firecracker-containerd --config /etc/firecracker-containerd/config.toml
WorkingDirectory=/var/lib/firecracker-containerd
StandardOutput=append:/var/log/firecracker-containerd.log
StandardError=append:/var/log/firecracker-containerd.log
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF


sudo systemctl daemon-reload
sudo systemctl enable firecracker-containerd
sudo systemctl start firecracker-containerd
sudo systemctl status firecracker-containerd
