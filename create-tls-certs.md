# Create TLS Certs

This guide is for generating Let's Encrypt certificates from your laptop

[This blog post](https://blog.uxtely.com/isolated-tls-certificate-creation)
explains why they're issued this way.


## 0. Installation
```shell
curl https://get.acme.sh | sh -s email=contact@example.com --force
```
Forcing in Arch because the installation script doesn't find any `cron`.

### CAA Record (one time only)
This is for restricting which CA can issue certificates. Add `CAA` records in Cloudflare
```
CAA @   letsencrypt.org
```
I'm not sure why Cloudflare doesn't allow setting Flag 128 as recommended by:
https://blog.qualys.com/ssllabs/2017/03/13/caa-mandated-by-cabrowser-forum


## 1. Create a token in Cloudflare
Go to [Cloudflare's API Tokens](https://dash.cloudflare.com/profile/api-tokens)

Click **Create Custom Token**

**Token name**
```text
acme
```

**Permissions**
```text
Zone | Zone | Read
Zone | DNS  | Edit
```

**Zone Resources**
```text
Include | Specific Zone | example.com
```

Click **Continue to summary**

**Copy** the token (it's not visible afterwards)


## 2. Create and Deploy the certificates

**Paste** the token below.
```shell script
TOKEN=EYj9ESiadttN4j4KzUBKllCss3xVhqSP_ipa405M
$REPO/Infrastructure/tls/./create-tls-certs $TOKEN
```
**Repeat** for each production server.


## 3. Delete the token
Go to [Cloudflare's API Tokens](https://dash.cloudflare.com/profile/api-tokens)

## 4. Verify Cloudflare DNS
Make sure `acme.sh` deleted all the `TXT` records it temporarily created.


# View all Issued Certs
https://crt.sh/?q=example.com

# How does it work?
There are a few ways in which LetsEncrypt validates you. We use the one that's only about
adding `TXT` records. `acme.sh` takes care of deleting them after the cert is ready.

We don't use the one that requires a webserver. That creates a page and needs to be in
port 80. Plus for security, I don't want `acme.sh` modifying our `nginx.conf`, or even be
there.

This is not fully automated (e.g. in cron) because it seems insecure to let acme run as
root, and mess up with Nginx.


