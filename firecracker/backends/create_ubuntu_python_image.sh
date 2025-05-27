#!/bin/bash
set -e  # Exit immediately if a command exits with a non-zero status

# Set Ubuntu version - use the same as in the Dockerfile
UBUNTU_VERSION="24.04"

# Set variables
OUTPUT_IMAGE="./ubuntu-${UBUNTU_VERSION}-python3.ext4"
IMAGE_SIZE_MB=1024  # 1GB
DOCKER_IMAGE="ubuntu-python3-temp"
MOUNT_POINT="/mnt/ext4-image"
# Generate a random IP address in the range 172.16.0.2 - 172.16.0.254
IP_ADDRESS="172.16.0.$((RANDOM % 253 + 2))"

# Clean up any existing files
echo "Cleaning up previous runs..."
rm -f "$OUTPUT_IMAGE"
sudo umount "$MOUNT_POINT" 2>/dev/null || true
sudo rmdir "$MOUNT_POINT" 2>/dev/null || true
mkdir -p "$MOUNT_POINT"

# Create a Dockerfile to build Ubuntu with python
echo "Creating Dockerfile..."
cat > Dockerfile << EOF
FROM ubuntu:${UBUNTU_VERSION}

# Avoid prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive

# Update and install required packages
RUN apt-get update && \\
    apt-get install -y \\
    curl \\
    build-essential \\
    iproute2 \\
    net-tools \\
    iputils-ping \\
    systemd \\
    vim \\
    procps \\
    udev \\
    kmod \\
    util-linux \\
    sudo \\
    python3-full \\
    python3-pip \\
    python3-venv \\
    python-is-python3 \\
    openssh-server \\
    && apt-get clean

RUN python -m venv /root/.python3 && \
    echo 'export PATH="/root/.python3/bin:$PATH"' >> /root/.bashrc

# Create a more robust init script for Firecracker
RUN echo '#!/bin/bash' > /sbin/init && \\
    echo 'mount -t proc none /proc' >> /sbin/init && \\
    echo 'mount -t sysfs none /sys' >> /sbin/init && \\
    echo 'mount -t devpts none /dev/pts' >> /sbin/init && \\
    echo '' >> /sbin/init && \\
    echo '# Setup networking' >> /sbin/init && \\
    echo 'ip link set eth0 up' >> /sbin/init && \\
    echo 'ip addr add ${IP_ADDRESS}/24 dev eth0' >> /sbin/init && \\
    echo 'ip route add default via 172.16.0.1' >> /sbin/init && \\
    echo 'ip route add default via 172.16.0.1' >> /sbin/init && \\
    echo 'echo "nameserver 8.8.8.8" > /etc/resolv.conf' >> /sbin/init && \\
    echo 'source /root/.python3/bin/activate' >> /sbin/init && \\
    echo "echo firecracker-python-\$(python3 --version | grep -oP '\\d+\\.\\d+\\.\\d+' | sed 's/\\./-/g') > /etc/hostname" >> /sbin/init && \
    echo 'hostname -F /etc/hostname' >> /sbin/init && \\
    echo 'echo "Welcome to python on Firecracker"' >> /sbin/init && \\
    echo 'cd /app' >> /sbin/init && \\
    echo 'echo "You can run the python test script with: python --version"' >> /sbin/init && \\
    echo '' >> /sbin/init && \\
    echo '# Start sshd for remote access' >> /sbin/init && \\
    echo 'mkdir -p /run/sshd' >> /sbin/init && \\
    echo '/usr/sbin/sshd' >> /sbin/init && \\
    echo '' >> /sbin/init && \\
    echo '# Start a proper shell' >> /sbin/init && \\
    echo 'setsid /bin/bash -c "exec /bin/bash </dev/ttyS0 >/dev/ttyS0 2>&1"' >> /sbin/init && \\
    chmod +x /sbin/init

# Create a script for safely rebooting
RUN echo '#!/bin/sh' > /sbin/reboot && \\
    echo 'echo "Rebooting system..."' >> /sbin/reboot && \\
    echo 'sync' >> /sbin/reboot && \\
    echo 'echo 1 > /proc/sys/kernel/sysrq' >> /sbin/reboot && \\
    echo 'echo b > /proc/sysrq-trigger' >> /sbin/reboot && \\
    chmod +x /sbin/reboot

# Create a user with sudo access
RUN useradd -m -s /bin/bash pythonuser && \\
    echo "pythonuser:password" | chpasswd && \\
    adduser pythonuser sudo && \\
    echo "pythonuser ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/pythonuser

WORKDIR /app
CMD ["/bin/bash"]
EOF

# Build the Docker image
echo "Building Docker image..."
docker build -t "$DOCKER_IMAGE" .

# Create an empty file for the ext4 filesystem
echo "Creating empty file for EXT4 filesystem..."
dd if=/dev/zero of="$OUTPUT_IMAGE" bs=1M count="$IMAGE_SIZE_MB"

# Create an ext4 filesystem
echo "Formatting the file as EXT4..."
mkfs.ext4 "$OUTPUT_IMAGE"

# Mount the filesystem
echo "Mounting the EXT4 filesystem..."
sudo mount -o loop "$OUTPUT_IMAGE" "$MOUNT_POINT"

# Create a container and export its filesystem
echo "Exporting Docker container filesystem..."
CONTAINER_ID=$(docker create "$DOCKER_IMAGE")
docker export "$CONTAINER_ID" | sudo tar -x -C "$MOUNT_POINT"
docker rm "$CONTAINER_ID"

# Unmount the filesystem
echo "Unmounting the EXT4 filesystem..."
sudo umount "$MOUNT_POINT"
sudo rmdir "$MOUNT_POINT"

# Clean up Docker image
echo "Cleaning up Docker resources..."
docker rmi "$DOCKER_IMAGE"
rm -f Dockerfile

echo "Ubuntu ${UBUNTU_VERSION} python EXT4 image created at: $OUTPUT_IMAGE"
echo "You can use this image with Firecracker as a root filesystem."
