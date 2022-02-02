#!/bin/sh

set -o errexit
set -o nounset
set -o xtrace

# Based on https://www.opsdash.com/blog/postgresql-streaming-replication-howto.html

echo "Setup pg_j..."

test -f /dbrole
test -f /Database.sql
test -f /Database-Users.sql

test -f /etc/hostname
test -f /etc/ip_ipg_b
test -f /etc/ip_peer_ipg_b
test -f /etc/spiped.key


pkg install -y postgresql13-server postgresql13-client openssh-portable spiped vim-console

chsh -s /bin/sh
pw lock toor

UPSTREAM_APP_SERVER=10.0.4.30
PGDATA=/var/db/postgres/data13
DB_NAME=ab


configure_primary() {
  echo "Configuring DB as Primary..."
  service postgresql initdb

  mv $PGDATA/postgresql.conf $PGDATA/postgresql.conf.original
  mv $PGDATA/pg_hba.conf $PGDATA/pg_hba.conf.original

  cat > $PGDATA/postgresql.conf << EOF
listen_addresses = '*'
hot_standby = on
wal_level = 'hot_standby'

# Prevent Write Amplication as it's not needed with ZFS, and we
# don't do cascading replication https://youtu.be/T_1Zo4m4v_M?t=580
full_page_writes = off

# All the following are the defaults in the FreeBSD port
max_wal_size = 1GB
min_wal_size = 80MB

max_connections = 100
shared_buffers = 128MB
dynamic_shared_memory_type = posix

log_destination = 'syslog'
log_timezone = 'UTC'
update_process_title = off
datestyle = 'iso, mdy'
timezone = 'UTC'
lc_messages = 'C'
lc_monetary = 'C'
lc_numeric = 'C'
lc_time = 'C'
default_text_search_config = 'pg_catalog.english'
EOF

  cat > $PGDATA/pg_hba.conf << EOF
local all postgres trust
host $DB_NAME appserver $UPSTREAM_APP_SERVER/32 password
host $DB_NAME appserver `/bin/cat /etc/ip_ipg_b`/32 password
host replication replicator `/bin/cat /etc/ip_ipg_b`/32 password
EOF

  chown postgres:postgres $PGDATA/postgresql.conf
  chown postgres:postgres $PGDATA/pg_hba.conf

  service postgresql start
  /usr/local/bin/psql -U postgres -c "CREATE DATABASE $DB_NAME"
  /usr/local/bin/psql -U postgres -d $DB_NAME -f /Database.sql
  /usr/local/bin/psql -U postgres -d $DB_NAME -f /Database-Users.sql
}


configure_replica() {
  echo "You should setup the Replica manually with pg_basebackup"
  # it can't be here because the jail was started without spiped installed,
  # so it doesn't have the pipe it needs for the initial backup.
}


case `/bin/cat /dbrole` in
  PrimaryDB) configure_primary ;;
  ReplicaDB) configure_replica ;;
  *) echo "Invalid /dbrole"; exit 1
esac


cat << EOF
==============================
     DONE pg_j
==============================
EOF

rm /dbrole
rm /Database.sql
rm /Database-Users.sql
rm $0
