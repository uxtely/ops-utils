# Web Traffic Logs Database

This is to setup a database for storing the logs from Nginx using our custom format.
See [nginx.conf](../location-server/jails/nginx_j/usr/local/etc/nginx/nginx.conf)


## Install Postgres (e.g. in OpenBSD)
READ: /usr/local/share/doc/pkg-readmes/postgresql-server
```shell
pkg_add postgresql-server postgresql-client
cat /usr/local/share/doc/pkg-readmes/postgresql-server
su - _postgresql
mkdir /var/postgresql/data
initdb -D /var/postgresql/data -U postgres -A scram-sha-256 -E UTF8 -W
```

## Setup the database (named: logs) and table (named: wlogs)
Don't forget to change the passwords in the `WebLogs.sql`.
```shell
createdb -U postgres --owner postgres logs
psql -U postgres -d logs -f ./WebLogs.sql
```

## Password file
Use the same password as above.
```shell
echo '*:*:logs:wlogger:WebLogger-Password' >> ~/.pgpass
chmod 600 ~/.pgpass
```

## pg_hba.conf
Allow access to the computers on the `10/8` private network.
```shell
host logs all 10.0.0.0/24 scram-sha-256
```

## Start Postgres (OpenBSD)
```shell
rcctl set postgresql status on 
rcctl start postgresql
```

## Cron
This cron captures the output and prints it only on error
https://serverfault.com/a/94232 (crontab -e)
```shell
crontab -e

@daily OUT=`/home/efortis/sync-weblogs.sh hvm_ngnix_j 2>&1` || echo "$OUT"
@daily OUT=`/home/efortis/sync-weblogs.sh hvs_ngnix_j 2>&1` || echo "$OUT"
```
