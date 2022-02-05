#!/bin/sh

set -o errexit
set -o nounset
set -o xtrace


HOST_USER=efortis
PWD_DIR=/home/$HOST_USER/$(hostname)-root-passwords


# Postgres dataset.
# As this script runs on the first boot, there's in no more /mnt chroot.
# Presentation: Postgres + ZFS Best Practices (Slide 85) @SeanChittenden
#   https://www.youtube.com/watch?v=T_1Zo4m4v_M
#   https://www.percona.com/live/17/sites/default/files/slides/PostgreSQL%20%2B%20ZFS%20Best%20Practices.pdf
zfs create \
  -o mountpoint=/jails/pg_j/var/db/postgres \
  -o atime=off \
  -o compression=lz4 \
  -o recordsize=16k \
  -o primarycache=metadata \
  zroot/jails/pg_j/data


# Setup jails
for j in $(jls name); do
  jexec $j /bin/sh /setup.sh
done


# Add Host User
pw useradd -n $HOST_USER -w no -G wheel
chown -R $HOST_USER /home/$HOST_USER/
chmod -R 700 /home/$HOST_USER/.ssh
# Passwordless (-w no). Only logins via ssh+pubkey are allowed.


# Create random root passwords
mkdir $PWD_DIR
make_password() {
  cat /dev/urandom | LC_CTYPE=C tr -cd [:graph:] | head -c 12
}

make_password > $PWD_DIR/host
cat $PWD_DIR/host | pw mod user root -h 0

for j in $(jls name); do
  make_password > $PWD_DIR/$j
  export PASS=$(cat $PWD_DIR/$j)
  jexec $j sh -c 'echo $PASS | pw mod user root -h 0'
  unset PASS
done

# Archive root passwords
tar -cf $PWD_DIR.tar -C $PWD_DIR/.. $(basename $PWD_DIR)
chown $HOST_USER:$HOST_USER $PWD_DIR.tar
rm -rf $PWD_DIR


cat << EOF
==============================
DONE INSTALLING
Please Reboot
==============================
EOF

rm $0

