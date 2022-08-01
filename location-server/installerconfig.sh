DISTRIBUTION="kernel.txz base.txz"

export nonInteractive="YES"

# https://github.com/freebsd/freebsd/blob/master/usr.sbin/bsdinstall/scripts/zfsboot
export ZFSBOOT_DISKS="ada0 ada1" # geom disk list | grep Name
export ZFSBOOT_VDEV_TYPE=mirror
export ZFSBOOT_SWAP_ENCRYPTION=1
export ZFSBOOT_GELI_ENCRYPTION=1


#!/bin/sh

set -o errexit
set -o nounset
set -o xtrace

# Mount ISO FreeBSD-13.1
mkdir /mnt/iso
mount_cd9660 /dev/iso9660/13_1_RELEASE_AMD64_CD /mnt/iso

read -p "Orch IP: " ORCHIP
echo "$ORCHIP orch.example.com" >> /etc/hosts

echo "nameserver 1.1.1.1" >> /etc/resolv.conf
echo "nameserver 8.8.8.8" >> /etc/resolv.conf

fetch https://orch.example.com/setups/installerconfig-part2.sh -qo- | /bin/sh

