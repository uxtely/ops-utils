#!/bin/sh

set -o errexit
set -o nounset
set -o xtrace

echo "Setup nginx_j..."

test -f /etc/hostname

pkg install -y nginx-full openssh-portable doas vim-console rsync

chsh -s /bin/sh
pw lock toor

USER=deployer
HOMEDIR=/home/$USER
APPS="Website UserDocs Blog AccountSPA AppSPA"

mkdir $HOMEDIR/certs-collector

pw useradd -n $USER -w no -G wheel
chown -R $USER:wheel $HOMEDIR
chmod -R 700 $HOMEDIR/.ssh

for app in $APPS; do
  mkdir -p "$HOMEDIR/$app"
  chown $USER:wheel "$HOMEDIR/$app"
  mkdir -p "/usr/local/DistBundles/$app"
done

# For explicitely mounting an empty 'root'
mkdir "/usr/local/DistBundles/null"
chmod 000 "/usr/local/DistBundles/null"

chmod 550 /usr/local/sbin/reload-nginx
chmod 550 /usr/local/sbin/rotate-nginx-logs
chmod u+x $HOMEDIR/deploy*

chmod -R g+w /usr/local/DistBundles

chmod u+x /usr/local/bin/ip-histogram

cat << EOF
==============================
    DONE nginx_j
==============================
EOF

rm $0
