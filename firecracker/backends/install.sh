#!/bin/bash

# Setup network interface
TAP_DEV="tap0"
TAP_IP="172.16.0.1"
MASK_SHORT="/16"

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

# download the latest Firecracker kernel 
ARCH="$(uname -m)"
release_url="https://github.com/firecracker-microvm/firecracker/releases"
latest_version=$(basename $(curl -fsSLI -o /dev/null -w  %{url_effective} ${release_url}/latest))
CI_VERSION=${latest_version%.*}
latest_kernel_key=$(curl "http://spec.ccfc.min.s3.amazonaws.com/?prefix=firecracker-ci/$CI_VERSION/$ARCH/vmlinux-&list-type=2" \
    | grep -oP "(?<=<Key>)(firecracker-ci/$CI_VERSION/$ARCH/vmlinux-[0-9]+\.[0-9]+\.[0-9]{1,3})(?=</Key>)" \
    | sort -V | tail -1)

# Download a linux kernel binary
latest_kernel_name=$(basename $latest_kernel_key)

wget -O ${latest_kernel_name}  "https://s3.amazonaws.com/spec.ccfc.min/${latest_kernel_key}"
mkdir -p base_images
cp -f ${latest_kernel_name} base_images

# isntall docker 
# Add Docker's official GPG key:
sudo apt-get update > /dev/null 2>&1
sudo apt-get install ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

# Add the repository to Apt sources:
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update > /dev/null 2>&1
sudo apt-get install docker-ce -y

apt install python3-full sqlite3 e2fsprogs debootstrap supervisor -y -f
python -m venv ~/.firecracker

~/.firecracker/bin/pip install --upgrade pip
~/.firecracker/bin/pip install flask

sed -i "s|/root/firecracker/backends/firecracker_manager.py|$PWD/firecracker_manager.py|g" $PWD/firecracker_manager.conf
sed -i "s|directory=.*|directory=$PWD|g" $PWD/firecracker_manager.conf

cp $PWD/firecracker_manager.conf /etc/supervisor/conf.d/firecracker_manager.conf
supervisorctl reread; supervisorctl update
supervisorctl restart firecracker_manager
