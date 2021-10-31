#!/usr/bin/sudo bash
set -ex

KERNEL_RELEASE="$(uname -r)"
yum -y install "kernel-devel-${KERNEL_RELEASE}" "kernel-headers-${KERNEL_RELEASE}"

wget https://github.com/linux-apfs/linux-apfs-rw/archive/HEAD.zip
unzip ./HEAD.zip
rm ./HEAD.zip
make -C ./linux-apfs-rw-*
insmod ./linux-apfs-rw-*/apfs.ko
