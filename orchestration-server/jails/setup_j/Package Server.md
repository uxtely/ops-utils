# FreeBSD package server

## How it works?
#### 1. Compile
We compile packages in a way that are ready to use with `pkg
install` on the clients. This compilation step is what this document explains.

#### 2. Serve
`orch_setup_j` serves those built packages (`/usr/ports/packages`)
with this [nginx.conf](./usr/local/etc/nginx/nginx.conf)

#### 3. Consume
Setup the Server-clients consume packages from `orch_setup_j` with:
`/usr/local/etc/pkg/repos/myrepo.conf` 
```
myrepo: {
	url: https://orch.appbrainstorm.com
}
```

and `/usr/local/etc/pkg/repos/FreeBSD.conf`
```
FreeBSD: { enabled: no }
```


## Recompiling

```shell script
zfs snapshot zroot/jails/nginx_j@ngx_snap_12_2
```

Notes: Not using `portmaster -gDy $PORTS` because it installs them too. But
there's hope `PT_NO_INSTALL_PACKAGE=true` in `/etc/make.conf`
>>  For those who wish	to be sure that	specific ports are always compiled in-
stead of being installed from packages the	PT_NO_INSTALL_PACKAGE variable
can be defined in the make(1) environment,	perhaps	in
/usr/local/etc/ports.conf if using	/usr/ports/ports-mgmt/portconf,	or in
/etc/make.conf.  This setting is not compatible with the
-PP/--packages-only option.


Always recompile all ports at once
```shell script
jexec setup_j
portsnap fetch update
# See setup.sh

/usr/local/sbin/rebuild-pkg-catalog
```

## Emergency Patching
If the patch is not available in ports yet:
- `make extract`
- Patch
- Recompile

## Upgrading Clients
Repeat this in the Host
```shell script
SSL_NO_VERIFY_PEER=1 \
  SSL_NO_VERIFY_HOSTNAME=1 \
  pkg upgrade -y
```
That can also be used for the jails **except**: `node14` and
`postgresql13-server`. Those have numbers and have to manually installed.
For those, it's better to copy/paste the pkg install part of their setup.sh.

For `setup_j`, don't run `pkg upgrade` see its setup, as they're installed there with `pkg add`.



# Config Options
This part has many interactive pop-ups for selecting the compilation options. After
that, the compilation takes 59 minutes in a 4CPU/6GB on VirtualBox.

It will first compile and install `ccache`. Then it will configure the
other packages. The configuration phase is two steps per package. First
`make config` for the main options, and then it runs again (recursively) to
correctly configure the dependencies. All the dependencies use the default
options. There's a 2-second pause after configuring each package dependencies.

After that config phase, it will start compiling.


### devel/ccache
Keep defaults.

This port speeds up recompilation.

### ports-mgmt/portmaster
Disable all.

### ports-mgmt/pkg
Keep defaults.

This port is needed because the client's `pkg` fetches `pkg`
from this repo. That's odd, maybe it's to ensure compat.

### databases/postgresql13
Deselect
- Docs
- SSL
- When GIT appears deselect all
- **When Curl appears deselect TLS_SRP** Won't compile otherwise due to libressl

### editors/vim-console
Deselect all.

### ftp/wget
Deselect IPv6 and NLS. And select (*) OpenSSL.

This port is needed just for `acme.sh`

### net/openntpd
Has no options.

This port is more secure than the one in base.

### net/rsync
Keep defaults.

### security/ca_root_nss
Keep defaults.

This port has the root certificates of the certificate authorities.

### security/doas
Has no options.

### security/openssh-portable
Deselect all.

This port is more secure than the one in base.

### sysutils/devcpu-data
Keep defaults.

This port updates microcode.

### sysutils/spiped
Keep defaults.

This port is for creating "tunnel alike" links.

### www/node14
- Select "Bundled OpenSSL", and deselect the rest (on the main screen).
	Node won't compile with LibreSSL, but that's ok as we don't process TLS in Node.

### www/nginx

Only select:
- file_aio
- http
- http_rewrite
- http_ssl
- http_status
- httpV2
- brotli

Keep ModSecurity deselected for now. It depends on curl, which cannot be compiled
with LibreSSL. And modsecurity3 seems (not sure) to have even more problematic deps.


# Misc
`make fetch-recursive` is optional but prevents hanging a long compilation due
to connectivity issues, or facing rate-limits due to fetching many patch{001..N}

There's no need for `make -jN`, the ports themselves have thread safe flag.

## Finding a port
```shell script
cd /usr/ports 
make search name="nginx"
```

## Why Compiling?
To use Nginx with LibreSSL, headers_more, and brotli. And in
the future, with ModSecurity.

- It's the only way to use LibreSSL instead of OpenSSL.
- No need to rely and wait on package maintainers.
- Avoids `root` from fetching the open internet.



## Troubleshooting
#### Deps Versions
e.g. Perl 5.30.0 is installed, but after a `portsnap fetch update`
there's a port that needs Perl 5.31.1

Solution:
```shell script
cd /usr/ports/lang/perl
make clean install
```

#### OpenSSL
As we don't use OpenSSL, we use LibreSSL, so some ports can't be installed. e.g. curl
