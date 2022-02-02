# Installing a Location Server
[Installer Configs](./Installer%20Configs.md) documents the scripts used here.

## Pre-Install (One Time Only)
```shell
source $THISREPO/shell-utils.sh

VAULTDIR=~/.SomeSecretDirectory/passwords
mkdir -p $VAULTDIR
make_password 32 > $VAULTDIR/spiped.key
make_password 16 > $VAULTDIR/appserver.db.pass
make_password 16 > $VAULTDIR/replicator.db.pass
```


- Make sure your laptops Nginx Installer certificate is not expired. e.g.
    - `curl -v --insecure https://orch.example.com 2>&1 | grep expire`
- [Create a TLS certificate](../orchestration/jails/tls_j/TLS%20Certs.md) for the `nginx_j`

### If installing in a local VM: 
- Make sure there's a `vboxnet0` `192.168.56.1/24` (no DHCP) in File -> Host Network Manager.
- In `$THISREPO/freebsd-setup/etc/ips_martians`: 
  - remove the location server subnet (e.g. **`10/8`**) from the **`<martians>`** table . 
  - TODO @Verify if it's still needed for runtime I think it was only needed for the compiled packages?


### If installing in a remote:
- [Forward your laptop to a VPS](INSTALL InstallerConfig Server Forwarding.md)
- Connect to Hivelocity's VPN, and mount the FreeBSD ISO in the IPMI 
  - [Hivelocity Guide](../README%20VPN.md)
  - Fill up disks with random data
  
  
## Create installer scripts 
In your laptop:
```shell script
sh $THISREPO/freebsd-setup/init-location-installer-bundle.sh
```
That script:
- Creates the disk encryption key in `~/.SomeSecretDirectory/passwords/`
- Prompts for the server info (name, IP, etc.). 
- Uploads the installation scripts to Orch. 


## Install
- Boot with a FreeBSD ISO mounted OR `../make-virtualbox-vm.sh`
  - F11 Invokes the boot menu in the Supermicro bootstrap screen 
- Select **Shell** in the initial screen:
    - `Install` **`(Shell)`** `Live CD`

If for **VM**: (.110 qam, .111 qas)
```shell script
ifconfig vtnet0 10.0.0.110/24
route add default 10.0.0.1
ORCHIP=10.0.0.220
```

If for **Hivelocity**: (.155 hvm, .165 hvs)
```shell script
ifconfig em0 192.0.2.155/29
route add default 192.0.0.2.153
# Use Vultr's IP (of the forwarder)
ORCHIP=
```

Then for any:
```shell script
cd /tmp
fetch https://$ORCHIP/setups/installerconfig.sh 
/usr/sbin/bsdinstall script /tmp/installerconfig.sh
```

The installer will ask for the:
- Disk Encryption Password
- Orch's IP (again)

Then it auto-runs, and reboots. It continues with `-part3.sh` on the next boot.
- Type the disk encryption password
- Unmount the ISO. 
- **`shutdown -r now`**


## Post-Install 
### Root Passwords
Copy the root passwords tar to your laptop. 

```shell script
SERVER=qam
HOSTUSER=efortis
```

```shell script
_tar=${SERVER}.uxtely.lan-root-passwords.tar

mkdir -p ~/.SomeSecretDirectory
cd ~/.SomeSecretDirectory

rsync ${SERVER}:/home/${HOSTUSER}/$_tar .
tar -xf $_tar
rm $_tar
```
Copy them in a paper.

Delete the root passwords tar from the server.
```shell script
ssh $SERVER rm /home/${HOSTUSER}/$_tar
```

### If it's for a QA location
**IMPORTANT TODO**
Replace stripe_vars.json with `stripe_vars.test.json`


## Reboot
```shell script
shutdown -r now
```

### Database Passwords
These passwords are in `~/.SomeSecretDirectory/passwords`

```shell script
SERVER=qam

ssh $SERVER
su -
jexec pg_j
```

If **PrimaryDB**
```shell script
/usr/local/bin/psql -U postgres -d ab -c "\password appserver"
/usr/local/bin/psql -U postgres -d ab -c "\password replicator"
```

If **ReplicaDB**
```shell script
su - postgres 
PGDATA=/var/db/postgres/data13
/usr/local/bin/pg_basebackup \
  --host=127.0.0.1 \
  --port=5435 \
  --username=replicator \
  --pgdata=$PGDATA \
  --wal-method=stream \
  --progress \
  --write-recovery-conf
```

In the PrimaryDB, we don't use ALTER so we don't have to clear the `.psql_history`

The ReplicaDB uses the local spipe (which targets the PrimaryDB), then
`pg_basebackup` sets it up as standby by creating `$PGDATA/standby.signal`

### Deploy the TLS certificate
See [create-tls-certs](../create-tls-certs.md)


### .profile
TODO automate. copy the /home/efortis/.profile to all the home accounts within the jails

### Deploy the apps
TODO

### Reboot
```shell script
shutdown -r now "First boot after install"
```


### After Install (if it was local)
`/etc/hosts` 
```shell script
10.0.0.110        example.com
10.0.0.110    www.uxtely.com
10.0.0.110   docs.uxtely.com
10.0.0.110   blog.uxtely.com
10.0.0.110   free.uxtely.com
10.0.0.110     my.uxtely.com
```


### Add a copy of the pub keys to apu (log server)
