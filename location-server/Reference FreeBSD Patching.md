# Upgrade and Updating FreeBSD

## Preparation
### Get the disk password
Get the disk encryption password (for the reboot) and connect to Hivelocity's
VPN. Or use the "Allow my IP temporarily"
feature. Then __Connect to IPMI__ &rarr; Remote Control &rarr; iKVM/HTML5

### Remove the DNS record
Remove the DNS record for the server (start with ServerA)
```shell
./clouflare-dns-config.js
```
When done, re-enable the DNS using that script too.


## Update
First update the Host then the jails. The host's patch-level has to be greater-or-equal than the jails' one.

```shell script
export PAGER=cat
freebsd-update --not-running-from-cron fetch install
for j in `jls name`; do
  freebsd-update --not-running-from-cron -b /jails/$j fetch install
done
logger "Patched FreeBSD"
```

Then restart the system, or just the affected daemon. For example
[SA-21-07](https://www.freebsd.org/security/advisories/FreeBSD-SA-21:07.openssl.asc)
was only for OpenSSL.Therefore, in that case only Nginx was needed to be restarted.

```shell
shutdown -r now "Rebooting for updates"
```

## Packages 
Reboot after the system upgrade and before pkg upgrades.
Or upgrade the packages before patching the OS.

```shell script
export ASSUME_ALWAYS_YES=YES
pkg upgrade 
for j in `jls name`; do
  pkg -j $j upgrade 
done
unset ASSUME_ALWAYS_YES
logger "Upgraded all packages"
shutdown -r now "Rebooting after upgrading packages"
```


## Upgrade
- First, **Update** to the latest patch level
- Connect to Hivelocity VPN (needed for entering the disk encryption password)
  It upgrades the jails automatically
```shell script
zfs snapshot zroot@freebsd12_2p6
freebsd-update upgrade -r 13.0-RELEASE
logger "Upgraded FreeBSD 12.2 to 13.0"
reboot
freebsd-update install
```

We no longer compile packages. We compiled mainly to use
`libressl`. But it was to complex and time-consuming,
