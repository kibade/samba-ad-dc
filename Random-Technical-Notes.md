### Samba4 AD - Random Tech Notes
+ File shares should **only** be served from domain-member servers,
  never from domain controllers.
+ File shares are defined minimally in __smb.conf__ with exactly two
  directives:
```
[myfileshare]
        path = /path/to/share/directory
        writeable = yes|no
```
The remainder of file share configuration is done on the Windows side.
+ FreeRADIUS can authenticate against AD via `mschap`, but it is only
  possible to use NTLMv1 via the `mschap` protocol, and not NTLMv2.
  Newer Samba defaults to disabling NTLMv1 auth, which prevents `mschap`
  from working.
+ To enable `mschap` to successfully authenticate against Samba AD,
  put this into __/etc/smb.conf__ on the DC(s):
```
[global]
        ...
        ntlm auth = yes
        ...
```
+ Default GPOs are always empty on a provisioned domain, and they should
  **not** be altered. If GPOs are needed, **new** ones should be created.
+ On the topic of idmap backends:
  - If you do not want to add anything to AD, then you use the 'rid'
    backend and 'ID' numbers will be calculated for you. You will also have
    to place 'template' shell & homedir lines in smb.conf
  - If you want/need some of your users to have different login shells or
    home directories, you will need to use the 'ad' backend. This will use
    the contents of attributes in AD.
  - Either will work equally well on windows & Unix
+ Although optional, it is recommended to map the domain Adminstrator user
  to the root user on domain member servers. This will allow someone logged
  on as the domain admin to perform file operations with root privileges.
+ The password complexity settings are controlled **only** by `samba-tool`
  on the server; the Windows GPO settings are **not** honoured.
+ More on password complexity in AD:
  For Windows DCs this setting is managed using GPOs and each DC applies 
  this setting. However, Samba is currently not able to process GPOs. For 
  this reason this feature was implemented in samba-tool.
+ To list the users/groups with a particular privilege on a member server:
```
net rpc rights list privileges SeDiskOperatorPrivilege -UAdministrator
```
+ Documented method to set up DNS updates for clients:
https://wiki.samba.org/index.php/Configure_DHCP_to_update_DNS_records_with_BIND9

---
### Install and Configure Time Service (NTP) to serve to guests
+ Virtual guests will require an accurate time source, and the VM host server
  hosting those guests is the most logical candidate to serve time to them.
+ As root, run the following:
```
apt-get install ntp
ntp-keygen -M
chgrp ntp /etc/ntp.keys
mv ntp.keys ntpkey_* /etc/
```
+ Configure __/etc/ntp.conf__ as follows:
```
##
## Server control options
##

keys /etc/ntp.keys
driftfile /var/lib/ntp/ntp.drift
statsdir /var/log/ntpstats/
statistics loopstats peerstats clockstats

filegen loopstats  file loopstats  type day enable
filegen peerstats  file peerstats  type day enable
filegen clockstats file clockstats type day enable

tos orphan 10

##
## Upstream time servers
##

pool 0.pool.ntp.org iburst
pool 1.pool.ntp.org iburst
pool 2.pool.ntp.org iburst
pool 3.pool.ntp.org iburst

##
## Access control lists
##

# Base case: Exchange time with all, but disallow configuration or peering.
restrict -4 default kod limited notrap nomodify noquery nopeer
restrict -6 default kod limited notrap nomodify noquery nopeer

# To allow pool discovery, apply same rules as base case, but do allow peering.
restrict source kod limited notrap nomodify noquery

# Allow localhost full control over the service.
restrict 127.0.0.1
restrict ::1

##
## Peering partners
##

peer ${PEER_IP_1}
restrict ${PEER_IP_1} ntpport kod limited notrap nomodify noquery

peer ${PEER_IP_2}
restrict ${PEER_IP_2} ntpport kod limited notrap nomodify noquery

...

peer ${PEER_IP_N}
restrict ${PEER_IP_N} ntpport kod limited notrap nomodify noquery
```

---

