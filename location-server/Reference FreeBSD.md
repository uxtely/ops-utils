# FreeBSD Quick Reference

Also see: https://github.com/sbz/freebsd-commands

## General
- `poweroff`
- `shutdown -r now` Not `reboot`, it won't gracefully stop the jails.
- `su -` Because `sudo` and `doas` are not installed by default.
- `sockstat -4l` Shows listening sockets (ipv4).
- `tail -f /var/log/messages` Shows the syslog stream.


## Main Configs
- `/etc/rc.conf` Configs, daemons, net, etc.
- `/usr/local/etc/` Configs for user-installed programs.
- `/boot/loader.conf.local` and `/etc/sysctl.conf.local` Kernel tuning
    
    
## Services
- `service openssh restart` We don't use the default _sshd_.
- `service netif restart` Restart network configs.
- `service routing restart`
  - `netstat -rn` Shows the routing table.
  - `route add default 10.0.0.1` If 'routing restart' fails.
- Startup and Control scripts
  - `/etc/rc.d/` Base.
  - `/usr/local/etc/rc.d/` User installed, e.g. node.

## Jails
- `/etc/jail.conf` ip's, resources, etc.
- `jls` Lists jails.
- `service jail restart` Restarts all jails.
- `service jail stop myjail` Jails can't be `poweroff`.

Options for executing in jail:
- `jexec -U root myjail` Enters a jail sh. Then just `exit`.
- `jexec myjail mycommand` 
- `jexec -U <jailuser> myjail mycommand`. Runs as a user of the jail.
- `chroot /jails/myjail/ mycommand` 
- Or ssh into them

Jails can have higher `secure_level` than the host.

The ACL's on jails, when viewed from the host
won't reflect the actual users. But the host user.


## Firewall
- `pfctl -sa` show everything it can show (rules, state)
- `/etc/pf.conf` Main conf. Handles the jails' NAT.
- `pfctl -vf /etc/pf.conf` Reloads firewall rules. `-v` shows the expanded rules.
- `tcpdump -lnettti pflog0` Shows live logged traffic.
  - e.g. needs rules like `block log`, or `pass log`
- `pfctl -t mytablename -T show`
- `pfctl -t mytablename -T add 10.0.0.10`
- We have a `<ratelimited>` table for manually denying access to abusers if needed 
    - Keep in mind that the Nginx logs won't show their full IP, as the last octect is
     anonymized to "0"


## ZFS
- `zfs list` Shows datasets.
- `zfs snapshot zroot/jails@my_snapshot_name` Creates a snap.
- `zfs list -t snapshot`
- Snapshots can be `clone`, `rollback`, `diff`, `send`, `receive`. 
- `zpool scrub zpool` Repairs (this is done via cron)
  - `zpool status`
  - https://www.freebsd.org/doc/handbook/zfs-zpool.html


# Fixing FreeBSD
## Read-Write mount in Single-User mode
For example, if system doesn't boot. BTW, needs the root password. If the root
account doesn't have password, this won't work, we disallowed it in `/etc/ttys`.
In that case see Live CD Boot.
```shell script
mount -u /
zfs mount -a 
```
We don't use UFS, but for reference:
```shell script
mount -u /
mount -a -t ufs 
```

## Live CD Boot
This will also ask for the GELI encryption password.
```shell script
cd /tmp/
mkdir mounted

# For all disks
geli attach /dev/ada0p3
geli attach /dev/ada1p3

zpool import -f -R /tmp/mounted zroot
zfs mount zroot/ROOT/default
```
https://forums.freebsd.org/threads/boot-folder-in-encrypted-zfs-in-freebsd-11.60830/

## Without Disk Encryption password
- Type a wrong password three times (for each disk) 
- Then you can reinstall


## Troubleshooting ports
https://wiki.freebsd.org/BenWoods/DebuggingPorts


## Hardening Guide 
https://vez.mrsk.me/freebsd-defaults.html


# Forensics
See `savecore` for dumping a memory image.
