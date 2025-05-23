#!/bin/bash
set -x
# Variables
IMAGE_SIZE=2048  # Size in MiB
IMAGE_NAME="debian_bookworm_rootfs.ext4"
MOUNT_POINT="/mnt/debian_rootfs"
DEBIAN_VERSION="bookworm"
MIRROR_URL="http://deb.debian.org/debian/"

# Create an empty ext4 image
dd if=/dev/zero of=$IMAGE_NAME bs=1M count=$IMAGE_SIZE
mkfs.ext4 $IMAGE_NAME

# Create mount point if it doesn't exist
sudo mkdir -p $MOUNT_POINT
sudo mkdir -p $MOUNT_POINT/dev
sudo mkdir -p $MOUNT_POINT/proc
sudo mkdir -p $MOUNT_POINT/sys

# Mount the image
sudo mount -o loop $IMAGE_NAME $MOUNT_POINT

# Debootstrap Debian into the image
sudo debootstrap --arch=amd64 $DEBIAN_VERSION $MOUNT_POINT $MIRROR_URL

# Mount necessary filesystems for chroot
sudo mount --bind /dev $MOUNT_POINT/dev
sudo mount --bind /proc $MOUNT_POINT/proc
sudo mount --bind /sys $MOUNT_POINT/sys

# Chroot into the new system and configure it
sudo chroot $MOUNT_POINT /bin/bash -c "
  # Set up environment
  export DEBIAN_FRONTEND=noninteractive
  # Install necessary packages
  apt update
  apt install -y systemd-sysv openssh-server sudo python3 nodejs npm nano vim neofetch nginx htop
  # Configure automatic root login on serial console
  mkdir -p /etc/systemd/system/serial-getty@ttyS0.service.d
  echo '[Service]' > /etc/systemd/system/serial-getty@ttyS0.service.d/override.conf
  echo 'ExecStart=' >> /etc/systemd/system/serial-getty@ttyS0.service.d/override.conf
  echo 'ExecStart=-/sbin/agetty --autologin root --noclear %I \$TERM' >> /etc/systemd/system/serial-getty@ttyS0.service.d/override.conf
  # Set root password to empty
  passwd -d root
  # Enable necessary systemd services
  systemctl enable serial-getty@ttyS0
  # Set up fstab for essential filesystems
  echo 'proc            /proc           proc    defaults        0       0' > /etc/fstab
  echo 'sysfs           /sys            sysfs   defaults        0       0' >> /etc/fstab
  echo 'devpts          /dev/pts        devpts  defaults        0       0' >> /etc/fstab
  echo 'tmpfs           /run            tmpfs   defaults        0       0' >> /etc/fstab
  # Set alias for python to point to python3
  echo 'alias python=python3' >> /etc/bash.bashrc
"

# Exit chroot and unmount filesystems
sudo umount $MOUNT_POINT/dev
sudo umount $MOUNT_POINT/proc
sudo umount $MOUNT_POINT/sys
sudo umount $MOUNT_POINT

# Clean up
sudo rmdir $MOUNT_POINT

echo "Root filesystem image '$IMAGE_NAME' has been created and configured with Python 3, Node.js, Nano, Vim, Neofetch, and an alias for 'python' pointing to 'python3'."
