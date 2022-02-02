#!/bin/sh

set -o errexit
set -o nounset
set -o xtrace

echo "Setup node_j..."

test -f /dbrole

test -f /etc/hostname
test -f /etc/ip_inode_b
test -f /etc/ip_peer_ipg_b
test -f /etc/spiped.key
test -f /home/node/appserver.db.pass
test -f /home/node/email_credentials.json
test -f /home/node/stripe_vars.json

pkg install -y node14 postgresql13-client openssh-portable doas vim-console rsync spiped

chsh -s /bin/sh
pw lock toor

USER=deployer
HOMEDIR=/home/$USER

pw useradd -n $USER -w no -G wheel
chown -R $USER:wheel $HOMEDIR
chmod -R 700 $HOMEDIR/.ssh

USERNODE=node
pw useradd -n $USERNODE -w no -m
chmod +x /usr/local/etc/rc.d/node
chown -R $USERNODE:$USERNODE /home/$USERNODE

chmod 550 /usr/local/sbin/reload-node
chmod u+x $HOMEDIR/deploy

mkdir -p $HOMEDIR/ServerSide
chown $USER:wheel $HOMEDIR/ServerSide
chmod -R g+w /usr/local/DistBundles


# There are two targetable databases:
#   10.0.4.40:5432  same   location pg_j
#   192.168.56.{30,31} an spipe to the remote pg_j
db_dn="db.l.lan"
same_location=10.0.4.40
remote_location=`/bin/cat /etc/ip_inode_b`

update_dn_in_hosts() {
  local dbip=$1

  /bin/cat > /tmp/etc_hosts << EOF
`/usr/bin/grep -v $db_dn /etc/hosts`
$dbip $db_dn
EOF
  /bin/mv /tmp/etc_hosts /etc/hosts
}

case `/bin/cat /dbrole` in
  PrimaryDB) update_dn_in_hosts $same_location ;;
  ReplicaDB) update_dn_in_hosts $remote_location ;;
  *) echo "Invalid /dbrole"; exit 1
esac



cat << EOF
==============================
    DONE node_j
==============================
EOF

rm /dbrole
rm $0
