# FreeBSD ISO

## NOTE
This is guide for injecting a file into a FreeBSD
ISO, so it can run an automatic installation.

**But I don't create them anymore.** That's to say, you can also boot from a normal
release ISO and simply download and run the installation script. For example,
select **Shell** from the initial screen (Install, **Shell**, Live CD) and:
```shell
ifconfig em0 192.0.0.2.111/24
route add default 192.0.2.1
ORCHIP=192.0.0.2.200

cd /tmp
fetch https://$ORCHIP/setups/installerconfig
/usr/sbin/bsdinstall script /tmp/installerconfig
```


## But if you want to create the ISO:
Building this ISO is just a one time step, new servers can reuse it.

This guide injects an auto-installer script into
a FreeBSD ISO, in FreeBSD. That script does:
- Disk layout, encryption, and setups the ZFS datasets.
- Installs the OS (kernel and base).
- Fetches and runs a remote script to continue the installation.
	- `https://orch.example.com/setups/installerconfig-part2.sh`

The script is `/etc/installerconfig`. Its presence in the
boot ISO is what triggers the auto-install. Under the hood,
it's mainly a file that exports variables for `bsdinstall`.

As it fetches a pre-determined continuation script, we can reuse the ISO to
install location servers. Besides convenience, this way prevents exposing
configs and setup scripts in the provider's ISOs pool. The downside, only
one server can be created at a time, the ISO is served from a fixed URL.


## Build an ISO
`sh /root/bootstrap-iso-creation.sh`

But if Orch is a local VM, pass Orch's IP. Otherwise it uses the external IP.
```shell script
sh /root/bootstrap-iso-creation.sh 10.0.0.220
```

## Notes
- FreeBSD updates are not includable in the ISO. Copying over
	`var/db/updates` doesn't work (as google says, but haven't tried it).
- An option is to compile it. Check out
	FreeBSD's [releng tree](https://svnweb.freebsd.org/base/releng/12.1/).
	I think (not sure) that that tree tracks patches.


