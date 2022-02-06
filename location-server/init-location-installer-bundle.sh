#!/bin/sh

# Diagram: https://blog.uxtely.com/freebsd-jails-network-setup
# TODO copy the certs to jails/nginx_j/usr/local/DistBundles/certs

set -o errexit
set -o nounset

cd $(dirname $0)
. ../shell-utils.sh


cat << EOF
------------------------
   Server Templates
------------------------
qam  | VirtualBox Main
qas  | VirtualBox Secondary
hvm  | Hivelocity Main
hvs  | Hivelocity Secondary
EOF

SERVER=$(    user_input "Template"                 "none")
ORCHIP=$(    user_input "Orch IP"                  "10.0.0.220")
MYIP=$(      user_input "My IP (curl ifconfig.me)" "10/24")
HOSTUSER=$(  user_input "Host User"                "efortis")
PASSPHRASE=$(user_input "SSH Passphrase"           "")

test "$PASSPHRASE" || abort "Empty SSH Passphrase"

VLAN=2000
INTNET=192.168.56

case $SERVER in
  qam)
    DBROLE=PrimaryDB
    PEER=10.0.0.111
    XNIC=vtnet0
    XADDR=10.0.0.110
    XMASK=255.255.255.0
    GW=10.0.0.1
    INIC=vtnet1
    IOPTS=""
    ;;

  hvm)
    DBROLE=PrimaryDB
    PEER=192.0.2.165
    XNIC=em0
    XADDR=192.0.2.155
    XMASK=255.255.255.248
    GW=192.0.2.153
    INIC=igb0
    IOPTS="broadcast $INTNET.255 vlanhwtag $VLAN"
    ;;


  qas)
    DBROLE=ReplicaDB
    PEER=10.0.0.110
    XNIC=vtnet0
    XADDR=10.0.0.111
    XMASK=255.255.255.0
    GW=10.0.0.1
    INIC=vtnet1
    IOPTS=""
    ;;

  hvs)
    DBROLE=ReplicaDB
    PEER=192.0.2.155
    XNIC=em0
    XADDR=192.0.2.165
    XMASK=255.255.255.248
    GW=192.0.2.161
    INIC=igb0
    IOPTS="broadcast $INTNET.255 vlanhwtag $VLAN"
    ;;

  *) abort "Invalid option: $SERVER" ;;
esac


case $SERVER in
  qam|hvm)
            IADDR=$INTNET.110
          NODE_IP=$INTNET.30
            PG_IP=$INTNET.40
    IPEER_NODE_IP=$INTNET.31
      IPEER_PG_IP=$INTNET.41
      ;;

  qas|hvs)
            IADDR=$INTNET.111
          NODE_IP=$INTNET.31
            PG_IP=$INTNET.41
    IPEER_NODE_IP=$INTNET.30
      IPEER_PG_IP=$INTNET.40
      ;;
esac


NGINX_J=jails/nginx_j
NODE_J=jails/node_j
PG_J=jails/pg_j

TEMPFILES="
~/.SomeSecretDirectory/passwords/${SERVER}.diskpass
base.tar
jails.tar
etc/hosts
etc/hostname
etc/xnic
etc/xnic_name
etc/inic
etc/inic_name
etc/gateway
etc/ips_xnic_peers
etc/ip_ipg_b
etc/ip_inode_b
etc/ip_peer_ipg_b
etc/ip_peer_inode_b
home/$HOSTUSER/.ssh/authorized_keys
$NGINX_J/etc/hostname
$NGINX_J/home/deployer/.ssh/authorized_keys
$NODE_J/etc/hostname
$NODE_J/etc/ip_inode_b
$NODE_J/etc/ip_peer_ipg_b
$NODE_J/etc/spiped.key
$NODE_J/home/deployer/.ssh/authorized_keys
$NODE_J/home/node/appserver.db.pass
$NODE_J/home/node/email_credentials.json
$NODE_J/home/node/stripe_vars.json
$NODE_J/dbrole
$PG_J/etc/hostname
$PG_J/etc/ip_ipg_b
$PG_J/etc/ip_peer_ipg_b
$PG_J/etc/spiped.key
$PG_J/Database.sql
$PG_J/Database-Users.sql
$PG_J/dbrole
"

for f in $TEMPFILES; do
  test ! -e $f || abort "Found temporary file $f"
done


# GELI password
mkdir -p ~/.SomeSecretDirectory/passwords
make_password 12 > ~/.SomeSecretDirectory/passwords/${SERVER}.diskpass
chmod -w ~/.SomeSecretDirectory/passwords/${SERVER}.diskpass


# SSH Keys
PUBK=id_ed25519.pub

make_ssh ${SERVER}         $XADDR 22 $HOSTUSER "$PASSPHRASE"
make_ssh ${SERVER}_nginx_j $XADDR 2220 deployer "$PASSPHRASE"
make_ssh ${SERVER}_node_j  $XADDR 2230 deployer "$PASSPHRASE"

# Pre-pack Host pubkey
mkdir -p home/$HOSTUSER/.ssh
cp ~/.ssh/${SERVER}/$PUBK               home/${HOSTUSER}/.ssh/authorized_keys
cp ~/.ssh/${SERVER}_nginx_j/$PUBK $NGINX_J/home/deployer/.ssh/authorized_keys
cp ~/.ssh/${SERVER}_node_j/$PUBK   $NODE_J/home/deployer/.ssh/authorized_keys


# Retrieve passwords and keys
SECRETS=~/.SomeSecretDirectory/passwords
cp $SECRETS/appserver.db.pass      $NODE_J/home/node/
cp $SECRETS/email_credentials.json $NODE_J/home/node/
cp $SECRETS/stripe_vars.json       $NODE_J/home/node/
cp $SECRETS/spiped.key             $NODE_J/etc/
cp $SECRETS/spiped.key             $PG_J/etc/


# Hostnames
echo "$SERVER.example.lan"     >          etc/hostname
echo "$SERVER-db.example.lan"  >    $PG_J/etc/hostname
echo "$SERVER-app.example.lan" >  $NODE_J/etc/hostname
echo "$SERVER-rp.example.lan"  > $NGINX_J/etc/hostname


# xpeers firewall table
cat > etc/ips_xnic_peers << EOF
$PEER
$ORCHIP
$MYIP
EOF

echo "$XNIC" > etc/xnic_name
echo "$INIC" > etc/inic_name

echo "inet $XADDR netmask $XMASK" > etc/xnic
echo "inet $IADDR/24 $IOPTS"      > etc/inic
echo $GW                          > etc/gateway

echo $PG_IP         > etc/ip_ipg_b
echo $NODE_IP       > etc/ip_inode_b
echo $IPEER_PG_IP   > etc/ip_peer_ipg_b
echo $IPEER_NODE_IP > etc/ip_peer_inode_b

echo $NODE_IP     > $NODE_J/etc/ip_inode_b
echo $IPEER_PG_IP > $NODE_J/etc/ip_peer_ipg_b
echo $PG_IP       >   $PG_J/etc/ip_ipg_b
echo $IPEER_PG_IP >   $PG_J/etc/ip_peer_ipg_b

# Save db confs
cp ../../ServerSide/src/Database*.sql $PG_J/
echo $DBROLE >   $PG_J/dbrole
echo $DBROLE > $NODE_J/dbrole

# Make hosts file
cat > etc/hosts << EOF
::1       localhost localhost.my.domain
127.0.0.1 localhost localhost.my.domain
$ORCHIP orch.example.com
EOF


# Pack configs
tar -cf base.tar boot etc home root usr
tar -cf jails.tar jails

# Copy config packs and scripts
mkdir -p /tmp/UxtelyInstallConfigs/setups
cp *.tar installerconfig*.sh /tmp/UxtelyInstallConfigs/setups


# Remove temporary files
for f in $TEMPFILES; do
  if [ -e $f ]; then
    rm -f $f
  else
    abort "Did not find temporary file $f"
  fi
done


cat << EOF
==============================
  DONE location setup init
==============================
EOF

