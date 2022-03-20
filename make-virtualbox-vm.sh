#!/bin/sh

# https://blog.uidrafter.com/scripted-virtualbox-vm-installation

# Downloads an ISO (only once) and creates a VM.
# It needs VirtualBox -> File -> Host Network Manager
#   vboxnet0 192.168.56.1/24 (no DHCP)

mkdir -p ~/VirtualBox\ VMs
cd ~/VirtualBox\ VMs

read -p "VM Name [qam]: " NAME

NAME=${NAME:=qam}
DISK_MB=$((8 * 1024))
MEMORY_MB=$((4 * 1024))
CPU_COUNT=2

BRIDGED_NIC=enp7s0 # VBoxManage list bridgedifs
#BRIDGED_NIC=en0  # macOS
#BRIDGED_NIC="Realtek PCIe GbE Family Controller" # Windows

OS=FreeBSD_64 # VBoxManage list ostypes
DOWNLOAD=https://download.freebsd.org/ftp/releases/ISO-IMAGES/13.0/FreeBSD-13.0-RELEASE-amd64-disc1.iso


iso=$(basename $DOWNLOAD)
test -f $iso || curl -O $DOWNLOAD

disk0=./$NAME/$NAME.disk0.vdi
disk1=./$NAME/$NAME.disk1.vdi

VBoxManage createvm \
  --name $NAME \
  --ostype $OS \
  --register

VBoxManage createmedium disk  --filename $disk0  --size $DISK_MB
VBoxManage createmedium disk  --filename $disk1  --size $DISK_MB

VBoxManage storagectl $NAME \
  --add sata \
  --portcount 3 \
  --name SATA

VBoxManage storageattach $NAME \
  --storagectl SATA \
  --port 0 \
  --type hdd \
  --medium $disk0 \
  --nonrotational on

VBoxManage storageattach $NAME \
  --storagectl SATA \
  --port 1 \
  --type hdd \
  --medium $disk1 \
  --nonrotational on

VBoxManage storageattach $NAME \
  --storagectl SATA \
  --port 2 \
  --type dvddrive \
  --medium $iso


VBoxManage modifyvm $NAME --cpus $CPU_COUNT
VBoxManage modifyvm $NAME --memory $MEMORY_MB

VBoxManage modifyvm $NAME --nic1 bridged
VBoxManage modifyvm $NAME --nictype1 virtio
VBoxManage modifyvm $NAME --bridgeadapter1 "$BRIDGED_NIC"

VBoxManage modifyvm $NAME --nic2 intnet
VBoxManage modifyvm $NAME --nictype2 virtio
VBoxManage modifyvm $NAME --nicpromisc2 allow-all # For FreeBSD's if_bridge

VBoxManage modifyvm $NAME --boot1 disk
VBoxManage modifyvm $NAME --boot2 dvd
VBoxManage modifyvm $NAME --boot3 none
VBoxManage modifyvm $NAME --boot4 none

VBoxManage modifyvm $NAME --audio none
VBoxManage modifyvm $NAME --vram 16
VBoxManage modifyvm $NAME --rtcuseutc on
VBoxManage modifyvm $NAME --nested-hw-virt on

VBoxManage startvm $NAME
