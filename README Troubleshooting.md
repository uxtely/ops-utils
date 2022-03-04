# Troubleshooting Tips

## local postgres logs (macOS)
```
/opt/homebrew/var/log/postgres.log
```



## Flush Browser DNS Cache
### Hosts file
`sudoedit /etc/hosts` needs to exit `:wq` (`:w` alone doesn't work) 

### Chrome
chrome://net-internals/#dns

### Firefox
about:networking#dns


## Chrome
#### Redirect to https in dev
On the console just Right-Click → Clear Browser Cache (it won't
delete the IndexedDB). In this case trying to delete the HSTS record in
Chrome's internals (chrome://net -internals/#hsts) doesn't do anything.


#### Opening a new Chrome instance
Handy if it's stuck in the one bound to WebStorm's Debug.
- `google-chrome -na` (Ubuntu)
- `open -n https://example.com` (macOS)



## Safari
#### Allow tabbing to buttons
Preferences → Advanced → "Press Tab to highlight each item on a webpage"


## Remote Debugging (Android)
For developing/testing touch with a Galaxy phone using Chrome's Remote devices.
chrome://inspect/#devices

Phone setup:
- Ensure **Developer options** appears in **Settings** (the last item)
    - if not Settings → About → **Build Number** (click it 7 times)
- **Developer options** → **USB Debugging**    
- **Developer options** → **USB configuration** → PTP
- A good USB is important, not all of them work.


  
## VirtualBox
- Avoid **Close** → **Save State**, it messes up the time.
- Host-Only Adapter
  - Ideal when there's no Internet
  - The Host and VM's can talk to each other
  - VM's can't talk to the outside
- Bridged Adapter
  - VM's can talk to the outside

#### Troubleshooting 
The guest connects to the internet, but the host can't access the guest
(e.g. ssh). Maybe the host has both the WiFi and LAN connected. Options:
  - Disconnect the non-bridged one.
  - Trunk the WiFi and LAN (not possible in macOS AFAIK).
  
  
## FreeBSD Jails 
### Can't restart them
VERIFY: It seems that this is no longer an issue.
This is for both orch and location servers.
Currently, we can't easily restart jails. That's because their jail-to-jail
epairs are fixed at startup and for some reason they're getting deleted in FreeBSD
12.1 when doing `service jail restart`. This didn't happen in FreeBSD 12.0.

Workaround: `shutdown -r now` on the host, or try `service netif restart`


## ssh
### Too many authentication failures
...in Linux for no reason? Try:
```shell script
killall ssh-agent
eval `ssh-agent`
```
By the way, this fixes in ~/.ssh/config
```
Host *
IdentitiesOnly yes
```
If that doesn't help, try connecting with `ssh -v` (verbose).

