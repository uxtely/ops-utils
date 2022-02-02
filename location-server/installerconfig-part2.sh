#!/bin/sh

set -o errexit
set -o nounset
set -o xtrace

# Only one server can be installed at a time, as they always use the /setups mount.
ASSETS=https://orch.example.com/setups
URL_CONF_BASE=$ASSETS/base.tar
URL_CONF_JAILS=$ASSETS/jails.tar
URL_SCRIPT_AFTER_REBOOT=$ASSETS/installerconfig-part3.sh

JAILS="nginx_j node_j pg_j"

# Patch OS
PAGER=cat freebsd-update --not-running-from-cron fetch install

# Fetch and Extract config files
fetch $URL_CONF_BASE -qo- |\
  tar --no-same-owner --no-same-permissions -xf- -C /

# Install packages
pkg install -y openssh-portable openntpd vim-console devcpu-data rsync

# UTC Time Zone
cp /usr/share/zoneinfo/UTC /etc/localtime
touch /etc/wall_cmos_clock
adjkerntz -a

# Use Blowfish to encrypt passwords. It's more expensive to bruteforce.
sed -i '' 's/passwd_format=sha512/passwd_format=blf/' /etc/login.conf
cap_mkdb /etc/login.conf # Updates /etc/login.conf.db

# Default shell
chsh -s /bin/sh

# Disable toor account
pw lock toor

# Create template jail
# bsdinstall is chroot'd into /mnt, so /jails gets mounted as /mnt/jails
zfs create -o mountpoint=/jails zroot/jails
zfs create zroot/jails/template
JAIL=/mnt/jails/template

tar -xf /mnt/iso/usr/freebsd-dist/base.txz -C $JAIL
umount /mnt/iso # That CD ISO was mounted in the previous installer script

cp /etc/login.conf    $JAIL/etc/
cp /etc/login.conf.db $JAIL/etc/
cp /etc/localtime     $JAIL/etc/
cp /etc/resolv.conf   $JAIL/etc/
cp /etc/periodic.conf $JAIL/etc/
cp /etc/motd.template $JAIL/etc/
cp /etc/ttys          $JAIL/etc/
cp /etc/hosts         $JAIL/etc/
cp -R /root/          $JAIL/root/

PAGER=cat freebsd-update --not-running-from-cron -b $JAIL fetch install
zfs snapshot zroot/jails/template@fresh

# Create jails
for j in $JAILS; do
  zfs clone zroot/jails/template@fresh zroot/jails/$j
done

# Fetch and Install jail configs
fetch $URL_CONF_JAILS -qo- |\
  tar --no-same-owner --no-same-permissions -xf- -C /mnt


# Prepend host-specific settings (NIC driver names)
/bin/ed -s /etc/rc.conf << EOF
1i
ifconfig_`/bin/cat /etc/xnic_name`_name="xnic"
ifconfig_`/bin/cat /etc/inic_name`_name="inic"
.
w
EOF

rm /etc/xnic_name
rm /etc/inic_name


# Fetch and install the after-reboot script
mkdir -p /usr/local/etc/rc.d/
fetch $URL_SCRIPT_AFTER_REBOOT -o /usr/local/etc/rc.d/
chmod +x /usr/local/etc/rc.d/$(basename $URL_SCRIPT_AFTER_REBOOT)

echo "Done with part2..."
sleep 4
shutdown -r now

