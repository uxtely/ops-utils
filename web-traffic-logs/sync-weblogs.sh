#!/bin/sh

set -o errexit
set -o nounset

sync_logs() {
  local server_name=$1
  dest=$server_name.access.log
  lockfile=$server_name.log.lock

  if [ ! $server_name ]; then
    echo "Usage: $0 <server_name>" >&2
    exit 1
  elif [ -e $lockfile ]; then
    echo "Aborting. $server_name's previous sync wasn't successful" >&2
    exit 1
  else
    touch $lockfile
  fi

  ssh $server_name doas /usr/local/sbin/rotate-nginx-logs
  rsync --compress $server_name:/var/log/nginx/access.log.0 $dest
  sed -i \
    -e '/"UxtelyHealthCheckBot"/d' \
    -e "s/'/_/g" \
    -e "s/\"/'/g" \
    -e "s/^/CALL insert_log(/" \
    -e "s/$/,'$server_name');/" $dest
  psql --username=wlogger --dbname=logs --quiet --single-transaction -f $dest

  rm $dest $lockfile
}

# Execute both in concurrently
sync_logs hvm_nginx_j &
pids=$!
sync_logs hvs_nginx_j &
pids="$pids $!"
wait $pids

# - access.log.0 is always the last rotation
# - sed expressions (-e):
#   1) Deletes lines containing "UxtelyHealthCheckBot"
#   2,3) These two steps swap double quotes by single ones
#   4) Prepends the stored procedure call
#   5) Appends the server name field and closes the call parentheses
