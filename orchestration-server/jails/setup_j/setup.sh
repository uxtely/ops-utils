#!/bin/sh

PORTS="
databases/postgresql13-server
editors/vim-console
ftp/wget
net/openntpd
net/rsync
security/ca_root_nss
security/doas
security/openssh-portable
sysutils/devcpu-data
sysutils/spiped
www/node14
www/nginx
"

REPOKEY=/root/repo.key

echo "Setting up setup_j..."

echo "Create repo key"
openssl genrsa -out $REPOKEY 2048
chmod 0400 $REPOKEY
openssl rsa -in $REPOKEY -out /root/repo.pub -pubout

echo "Set root user shell"
chsh -s /bin/sh

echo "Disable toor"
pw lock toor

USER=dispatcher
echo "Create user $USER"
HOMEDIR=/home/$USER
pw useradd -n $USER -w no
chsh -s /bin/sh $USER

echo "Setup location installers"
chmod u+x $HOMEDIR/wipe-setups-dir
mkdir $HOMEDIR/setups
chown -R $USER:$USER $HOMEDIR

echo "Fetch ports collection"
rm -rf /usr/local/etc/pkg # This jail needs the FreeBSD default package server.
portsnap fetch extract

PACKAGES=/usr/ports/packages
mkdir $PACKAGES

echo "Installing pkg..."
cd /usr/ports/ports-mgmt/pkg && make install

echo "Configuring Ports. See 'Package Server.md' to select the options."
sleep 3
for p in $PORTS; do
  echo "Configuring $p"
  sleep 1
  cd /usr/ports/$p
  make config

  echo "Again. But now recursively for the deps..."
  sleep 1
  make config-recursive
done

for p in $PORTS; do
  echo "Fetching $p"
  echo "Sleeping for 2 seconds, to avoid rate limits..."
  sleep 2
  cd /usr/ports/$p
  make fetch-recursive
done

for p in $PORTS; do
  echo "Compiling $p"
  cd /usr/ports/$p
  make package-recursive
done

echo "Build Catalog"
mkdir -p /usr/local/sbin
cat > /usr/local/sbin/rebuild-pkg-catalog << EOF
pkg repo $PACKAGES $REPOKEY
EOF
chmod +x /usr/local/sbin/rebuild-pkg-catalog
/usr/local/sbin/rebuild-pkg-catalog

echo "Install packages"
pkg add $PACKAGES/All/vim*
pkg add $PACKAGES/All/rsync*
pkg add $PACKAGES/All/nginx*
pkg add $PACKAGES/All/openssh*
service nginx start

echo "Done setup_j"
rm $0
