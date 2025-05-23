apt update; apt install squashfs-tools debootstrap acl -f -y


lsmod | grep kvm


[ $(stat -c "%G" /dev/kvm) = kvm ] && sudo usermod -aG kvm ${USER} \
&& echo "Access granted."
