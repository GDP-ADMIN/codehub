ARCH="$(uname -m)"
release_url="https://github.com/firecracker-microvm/firecracker/releases"
latest_version=$(basename $(curl -fsSLI -o /dev/null -w  %{url_effective} ${release_url}/latest))
CI_VERSION=${latest_version%.*}
latest_kernel_key=$(curl "http://spec.ccfc.min.s3.amazonaws.com/?prefix=firecracker-ci/$CI_VERSION/$ARCH/vmlinux-&list-type=2" \
    | grep -oP "(?<=<Key>)(firecracker-ci/$CI_VERSION/$ARCH/vmlinux-[0-9]+\.[0-9]+\.[0-9]{1,3})(?=</Key>)" \
    | sort -V | tail -1)

# Download a linux kernel binary
wget "https://s3.amazonaws.com/spec.ccfc.min/${latest_kernel_key}"

latest_ubuntu_key=$(curl "http://spec.ccfc.min.s3.amazonaws.com/?prefix=firecracker-ci/$CI_VERSION/$ARCH/ubuntu-&list-type=2" \
    | grep -oP "(?<=<Key>)(firecracker-ci/$CI_VERSION/$ARCH/ubuntu-[0-9]+\.[0-9]+\.squashfs)(?=</Key>)" \
    | sort -V | tail -1)
ubuntu_version=$(basename $latest_ubuntu_key .sqashfs | grep -oE '[0-9]+\.[0-9]+')

# Download a rootfs
wget -O ubuntu-$ubuntu_version.squashfs.upstream "https://s3.amazonaws.com/spec.ccfc.min/$latest_ubuntu_key"

# Create an ssh key for the rootfs
unsquashfs ubuntu-$ubuntu_version.squashfs.upstream
ssh-keygen -f id_rsa -N ""
cp -v id_rsa.pub squashfs-root/root/.ssh/authorized_keys
mv -v id_rsa ./ubuntu-$ubuntu_version.id_rsa
# create ext4 filesystem image
sudo chown -R root:root squashfs-root
truncate -s 400M ubuntu-$ubuntu_version.ext4
sudo mkfs.ext4 -d squashfs-root -F ubuntu-$ubuntu_version.ext4

# Verify everything was correctly set up and print versions
echo "Kernel: $(ls vmlinux-* | tail -1)"
echo "Rootfs: $(ls *.ext4 | tail -1)"
echo "SSH Key: $(ls *.id_rsa | tail -1)"
