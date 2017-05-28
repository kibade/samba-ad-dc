# How To Add A New Samba4 Domain Controller (DC) To An Existing Samba4 AD
__Version:__ 3.0

__Updated:__ May 28, 2017

__Change Log:__
+ v.3.0, released May 28, 2017:
  - Changed the DNS backend from SAMBA_INTERNAL to BIND9_DLZ.
  - Added DOMAIN, REALM, ADMIN_PASSWORD to "... paramater values ..." section.
  - Several minor additions made (more tests), and some tests rearranged.
+ v.2.1, released May 26, 2017:
  - Added "Configure pull-style `sysvol` replication", using an rsync cronjob.
  - Updated "Configure local host name resolution" to add a check.
  - Updated "Install the necessary software ..." to advise accepting defaults.
  - Updated "Stop and disable the samba services" to add a check.
  - Updated "... parameter values ..." examples to use 10.Y.x.x/23 network.
+ v.2.0, May 22, 2017:
  - Updated "Configure local ... resolution" to add "hostname" cmd.
  - Updated "Join this host ..." to add "winbind separator" option.
  - Renamed "Test the Directory" to "Test Winbind".
  - Moved "Test Winbind" to just after "Start the samba-ad-dc service".
  - Added "Check that Directory Replication is working".
+ v.1.1, May 20, 2017:
  - Copied Add-DC-to-Samba4-AD.txt and reformatted in Markdown.
  - Numerous formatting and clarity tweaks. 
+ v.1.0, May 14, 2017:
  - Initial release.

__References:__
+ https://wiki.samba.org/index.php/Joining_a_Samba_DC_to_an_Existing_Active_Directory

__Assumptions:__
+ The new DC will be installed on a new minimal install of Debian Stretch.
+ The new DC will be joining an existing Samba4 AD domain.
+ The new DC will have precisely one network interface (other than loopback).
+ The new DC will begin as a DHCP client on the network.
+ The existing AD domain has a "master" DC that holds the master copy of sysvol.

---
### Discover or choose parameter values for the new DC
```
INTERFACE_NAME          name of the network interface
IP_ADDRESS              static IP address
SUBNET_MASK             network subnet mask
GATEWAY                 network gateway address (default route)
DOMAIN_FQDN             fully-qualified domain name
DOMAIN                  short domain name, in ALL CAPS
REALM                   same as ${DOMAIN_FQDN}, but in ALL CAPS
ADMIN_PASSWORD          the Administrator password
HOSTNAME                host name
NTP_SERVER1             FQDN of NTP server to synch with
DNS_FORWARDER           IP address of the DNS forwarder
REV_DNS_ZONE            FQDN of the reverse DNS zone
DC1_ADDRESS             IP address of the existing "master" DC
DC1_HOSTNAME            host name of the existing "master" DC
```
Example settings:
```
INTERFACE_NAME          enp0s17
IP_ADDRESS              10.45.10.4
SUBNET_MASK             255.255.254.0
GATEWAY                 10.45.11.254
DOMAIN_FQDN             sfg.ad.sd57.bc.ca
DOMAIN                  SFG
REALM                   SFG.AD.SD57.BC.CA
ADMIN_PASSWORD          secret!23
HOSTNAME                dc2
NTP_SERVER1             time.sd57.bc.ca
DNS_FORWARDER           199.175.16.2
REV_DNS_ZONE            10.45.10.in-addr.arpa
DC1_ADDRESS             10.45.10.3
DC1_HOSTNAME            dc1
```

---
### Configure a static IP address
+ (N.B.: Do the following steps in a console, as the network will drop.)
+ As root, run the following:
```
ifdown ${INTERFACE_NAME}
```
+ Edit __/etc/network/interfaces__, as per the following fragment:
```
allow-hotplug ${INTERFACE_NAME}
iface ${INTERFACE_NAME} inet static
    address ${IP_ADDRESS}
    netmask ${SUBNET_MASK}
    gateway ${GATEWAY}
```
Be certain to replace the placeholders `${INTERFACE_NAME}`, `${IP_ADDRESS}`,
`${SUBNET_MASK}`, and `${GATEWAY}` with their actual values.
+ As root, run the following:
```
ifup ${INTERFACE_NAME}
```

---
### Configure local host name resolution
+ (From here on, it is okay to continue in an SSH session.)
+ As root, run the following:
```
echo "${HOSTNAME}" >/etc/hostname
```
+ Edit __/etc/hosts__, as per the following fragment:
```
${IP_ADDRESS}    ${HOSTNAME}.${DOMAIN_FQDN}    ${HOSTNAME}
```
Be certain to replace the placeholders `${IP_ADDRESS}`, `${HOSTNAME}`,
and `${DOMAIN_FQDN}` with their actual values.
+ As root, run the following:
```
hostname --file /etc/hostname
getent hosts "${HOSTNAME}"
```
Expect the output of `getent` to look as follows:
```
${IP_ADDRESS}    ${HOSTNAME}.${DOMAIN_FQDN}    ${HOSTNAME}
```

---
### Install the necessary software packages
+ As root, run the following:
```
apt-get update
apt-get install samba winbind ntp krb5-user dnsutils ldap-utils \
        ldb-tools smbclient libnss-winbind acl rsync bind9
```
When/if asked questions related to kerberos domain/realm, simply accept
the defaults, since kerberos will be reconfigured later, anyway.

---
### Stop and disable the samba and bind9 services
+ As root, run the following:
```
systemctl stop    smbd nmbd winbind bind9
systemctl disable smbd nmbd winbind bind9
systemctl status  smbd nmbd winbind bind9
```
The last command must show the services as "inactive (dead)".
If not, then troubleshooting is necessary before continuing.
+ As root, run the following:
```
ps -ax | egrep -i 'samba|smbd|nmbd|winbind|named'
```
Expect to see at most one line of output, probably for the `grep`
process. If any samba processes are found running, they need to be
stopped before continuing.

---
### Deconfigure samba and kerberos
+ As root, run the following:
```
CONFIGFILE=$(smbd -b |egrep CONFIGFILE |cut -f2- -d':' |sed 's/^ *//')
rm "${CONFIGFILE}"
rm /etc/krb5.conf
```

---
### Remove all local samba cache and database files
+ As root, run the following:
```
LOCKDIR=$(smbd -b |egrep LOCKDIR |cut -f2- -d':' |sed 's/^ *//')
STATEDIR=$(smbd -b |egrep STATEDIR |cut -f2- -d':' |sed 's/^ *//')
CACHEDIR=$(smbd -b |egrep CACHEDIR |cut -f2- -d':' |sed 's/^ *//')
PRIVATE_DIR=$(smbd -b |egrep PRIVATE_DIR |cut -f2- -d':' |sed 's/^ *//')
find "${LOCKDIR}" "${STATEDIR}" "${CACHEDIR}" "${PRIVATE_DIR}" \
        \( -iname '*.tdb' -o -iname '*.ldb' -o -iname '*.dat' \) \
        -print -delete
```

---
### Configure time synch
+ Edit __/etc/ntp.conf__, as per the following fragment:
```
tinker panic 0
...     ...
#pool 0.debian.pool.ntp.org iburst
#pool 1.debian.pool.ntp.org iburst
#pool 2.debian.pool.ntp.org iburst
#pool 3.debian.pool.ntp.org iburst
pool ${NTP_SERVER1} iburst
```
i.e.: Comment out the Debian pool servers, and add `${NTP_SERVER1}`.
Be certain to replace the placeholder `${NTP_SERVER1}` with its actual value.

The `tinker panic 0` line is only required if the machine is a VM,
and, when included, it must be the first line in `/etc/ntp.conf`.
+ As root, run the following:
```
systemctl stop ntp
systemctl start ntp
```

---
### Re-configure DNS resolution
+ Edit __/etc/resolv.conf__, to read as follows:
```
domain ${DOMAIN_FQDN}
search ${DOMAIN_FQDN}
nameserver ${DC1_ADDRESS}
```
Be certain to replace the placeholders `${DOMAIN_FQDN}` and `${DC1_ADDRESS}`
with their actual values.
+ As root, run the following:
```
ping -n -c3 ${DC1_HOSTNAME}
```
Expect to see three ping responses from the "master" DC.

---
### Reboot to make all modified settings active (especially the name changes)
+ As root, run the following:
```
reboot
```

---
### Configure SSH pubkey login to the existing "master" DC
+ As root, run the following:
```
ssh-keygen
```
i.e.: Interactively generate an SSH pubkey for root, accepting all defaults.

+ Append the contents of the new `~/.ssh/id_rsa.pub` to the existing DC's
  `/root/.ssh/authorized_keys` file. One way to accomplish this task is:
  - Open each of the above files in text editors in two
    separate PuTTY/SSH sessions; and then
  - copy/paste the contents of `id_rsa.pub` to the end of `authorized_keys`.

---
### Configure kerberos
+ As root, run the following:
```
PRIVATE_DIR=$(smbd -b |egrep PRIVATE_DIR |cut -f2- -d':' |sed 's/^ *//')
cd "${PRIVATE_DIR}"
rsync -aP ${DC1_HOSTNAME}:"${PRIVATE_DIR}/krb5.conf" ./
cd /etc/
ln -s "${PRIVATE_DIR}/krb5.conf"
```

---
### Test availability of kerberos
+ As root, run the following:
```
kinit administrator
klist
```
+ If this test fails, ensure that the existing DC is up, is working,
  and is reachable. Do not continue until this test passes.

---
### Test that DNS correctly resolves key AD records
+ As root, run the following:
```
host -t A ${DC1_HOSTNAME}.${DOMAIN_FQDN}.
host ${DC1_ADDRESS}
```
Expect to see the `A` and `PTR` records of the existing "master" DC.
+ As root, run the following:
```
host -t NS ${DOMAIN_FQDN}.
host -t A ${DOMAIN_FQDN}.
```
Expect to see the AD domain's `NS` and `A` records.
+ As root, run the following:
```
host -t SRV _ldap._tcp.${DOMAIN_FQDN}.
host -t SRV _kerberos._udp.${DOMAIN_FQDN}.
```
Expect to see valid `SRV` records for the AD domain.
+ If these tests fail, ensure that the "master" DC is up, is working,
  and is reachable. Do not continue until all these tests pass.

---
### Join this host as a new DC to the existing AD domain
+ As root, run the following:
```
samba-tool domain join "${DOMAIN_FQDN}" DC -U${DOMAIN}\\Administrator \
        --dns-backend=BIND9_DLZ \
        --option="interfaces=lo ${INTERFACE_NAME}" \
        --option="bind interfaces only=yes" \
        --option="winbind separator=/"
```
Expect to see `Joined domain ... as a DC`.
+ If this fails, troubleshooting is necessary before you can continue.

---
### Add configuration to the new DC's `smb.conf`, to match the "master" DC
+ Copy the following configuration options from
  `/etc/samba/smb.conf` on the existing DC to the new DC:
  - `idmap_ldb:use rfc2307`

---
### Configure the BIND9_DLZ DNS backend
+ As root, run the following:
```
PRIVATE_DIR=$(smbd -b |egrep PRIVATE_DIR |cut -f2- -d':' |sed 's/^ *//')
echo "${PRIVATE_DIR}"
```
+ Append the following line to __/etc/bind/named.conf__:
```
include "${PRIVATE_DIR}/named.conf";
```
Be certain to replace the placeholder `${PRIVATE_DIR}` with its actual value.
+ Insert the following line into the `options {}` block within
  __/etc/bind/named.conf.options__:
```
tkey-gssapi-keytab "${PRIVATE_DIR}/dns.keytab";
```
Be certain to replace the placeholder `${PRIVATE_DIR}` with its actual value.
+ As root, run the following:
```
named-checkconf
```
Expect to see no output. If errors are reported, fix them before continuing.

---
### Configure Name Service Switch (NSS)
+ Edit `/etc/nsswitch.conf`, as per the following fragment:
```
passwd:         compat winbind
group:          compat winbind
```
i.e.: add `winbind` to the end of the `passwd` and `group` lines.

---
### Copy the idmap database from the "master" DC to the new DC
+ As root, run the following:
```
PRIVATE_DIR=$(smbd -b |egrep PRIVATE_DIR |cut -f2- -d':' |sed 's/^ *//')
cd "${PRIVATE_DIR}"
rsync -aAXHP ${DC1_HOSTNAME}:"${PRIVATE_DIR}/idmap.ldb.bak" ./
rsync -aAXHP idmap.ldb.bak idmap.ldb
```

---
### Ensure that the new DC's `A` record exists in DNS
+ As root, run the following:
```
host -t A ${HOSTNAME}.${DOMAIN_FQDN}. ${DC1_ADDRESS}
```
+ If this reports `not found: 3(NXDOMAIN)`, then add the missing `A`
  record, as follows:
```
samba-tool dns add ${DC1_ADDRESS} "${DOMAIN_FQDN}" "${HOSTNAME}" \
        A ${IP_ADDRESS} -UAdministrator
```
+ Do not proceed until the `A` record exists and is correct.

---
### Ensure that the new DC's `PTR` record exists in DNS
+ As root, run the following:
```
host ${IP_ADDRESS} ${DC1_ADDRESS}
```
+ If this reports `not found: 3(NXDOMAIN)`, then add the missing `PTR`
  record, as follows:
```
HOST_NUM=$(echo ${IP_ADDRESS} | cut -f4 -d.)
samba-tool dns add ${DC1_ADDRESS} "${REV_DNS_ZONE}" "${HOST_NUM}" \
        PTR "${HOSTNAME}.${DOMAIN_FQDN}." -UAdministrator
```
+ Do not proceed until the `PTR` record exists and is correct.

---
### Ensure the new DC's `objectGUID` is registered as a `CNAME` in DNS
+ Get a list of all DCs' `objectGUID`s (and other information besides),
  by running the following command as root __on the "master" DC__:
```
ldbsearch -H "${PRIVATE_DIR}/sam.ldb" '(invocationId=*)' \
        --cross-ncs objectguid
```
+ An `objectGUID` is a 5-part hex-string. From the output of the above,
  identify the `objectGUID` of the new DC, then query the DNS for its
  corresponding `CNAME`, as follows (assume `${GUID}` is the new DC's
  `objectGUID`):
```
host -t CNAME ${GUID}._msdcs.${DOMAIN_FQDN}. ${DC1_ADDRESS}
```
+ Expect to see `... is an alias for ...`. If not, then create
  the necessary `CNAME` record, as follows:
```
samba-tool dns add ${DC1_ADDRESS} _msdcs.${DOMAIN_FQDN} ${GUID} \
        CNAME ${HOSTNAME}.${DOMAIN_FQDN}. -UAdministrator
```
+ Do not proceed until the `CNAME` record exists and is correct.

---
### Test and repair DNS updates on the "master" DC
+ As root, run the following __on the "master" DC__:
```
samba_dnsupdate --verbose --all-names
```
Expect to see a lot of output, but no error messages. If a lot of "NOTAUTH"
messages appear, then the DNS backend needs to have its sanity restored, by
running the following, as root (still __on the "master" DC__):
```
samba_upgradedns --dns-backend=BIND9_DLZ
systemctl restart bind9
```
+ Don't forget to switch back to the new DC for the next step!

---
### Start the `bind9` service
+ As root, run the following:
```
systemctl enable bind9
systemctl start  bind9
systemctl status bind9
```
The last command must show the service as `active (running)`.
If not, then troubleshooting is necessary before continuing.

---
### Start the `samba-ad-dc` service
+ As root, run the following:
```
systemctl unmask samba-ad-dc
systemctl enable samba-ad-dc
systemctl start  samba-ad-dc
systemctl status samba-ad-dc
```
The last command must show the service as `active (running)`.
If not, then troubleshooting is necessary before continuing.

---
### Check that Directory Replication is working
+ As root, run the following:
```
samba-tool drs showrepl
```
Expect to see `INBOUND NEIGHBORS` with recent last attempts and no
consecutive failures. Also expect to see `OUTBOUND NEIGHBORS` with
last attempts `@ NTTIME(0)` and no consecutive failures.

The last line of output should likely be
`Warning: No NC replicated for Connection!`, but that is expected.

Replication attempts occur roughly every 5 minutes.
---
### Test Winbind
+ As root, run the following:
```
wbinfo --ping-dc
```
Expect to see `dc connection ... succeeded`.
+ As root, run the following:
```
wbinfo -u
wbinfo -g
```
Expect to see lists of domain users and groups, not errors.
+ As root, run the following:
```
getent passwd Administrator
getent group "Domain Users"
```
Expect to see `Administrator` and `Domain Users` IDs.

---
### Add the new DC to the DNS resolution config on all DCs in the domain
+ Edit `/etc/resolv.conf`, as per the following fragment:
```
nameserver ${IP_ADDRESS}
```
i.e.: Add a `nameserver` entry to the new DC's `/etc/resolv.conf`.
Be certain to replace the placeholder `${IP_ADDRESS}` with its actual value.

+ Add a `nameserver` entry for the new DC to the `/etc/resolv.conf`
of all other DCs in the domain.

Recommendation: Each DC should list itself as the __last__
`nameserver` entry in its own `/etc/resolv.conf` file.

---
### Copy the contents of the `sysvol` share from the "master" DC to the new DC
+ As root, run the following:
```
STATEDIR=$(smbd -b |egrep STATEDIR |cut -f2- -d':' |sed 's/^ *//')
cd "${STATEDIR}"
rsync -aAXHIv --delay-updates --delete-delay \
        ${DC1_HOSTNAME}:"${STATEDIR}/sysvol/" "${STATEDIR}/sysvol/"
```

---
### Test the correctness of ownerships/permissions on `sysvol`
+ As root, run the following:
```
samba-tool ntacl sysvolcheck
```
+ If `sysvolcheck` throws errors, then reset the "master" `sysvol`
  by running the following, as root, __on the "master" DC__:
```
samba-tool ntacl sysvolreset
```
+ If you needed to reset `sysvol`, then go back to the previous
  step ("Copy the contents of the `sysvol` share ...").

---
### Configure pull-style `sysvol` replication
+ As root, create new text file `/etc/cron.d/ad-sysvol-replication`
  with the following contents (__all on one line__):
```
*/5 * * * * root /usr/bin/rsync -aAXHI --delay-updates --delete-delay
        ${DC1_HOSTNAME}:"${STATEDIR}/sysvol/" "${STATEDIR}/sysvol/"
        >/dev/null 2>&1
```
Be certain to replace the placeholders `${DC1_HOSTNAME}` and `${STATEDIR}`
with their actual values.

---
### The remainder of the steps are only tests (no more config changes)

---
### Test availability of the local `sysvol` and `netlogon` samba shares
+ As root, run the following:
```
smbclient -L localhost -U%
```
Expect to see `netlogon`, `sysvol`, and `IPC$` shares.
+ As root, run the following:
```
smbclient //localhost/netlogon -UAdministrator -c ls
```
Should return without error.

---
### Test the local DNS service 
+ As root, run the following:
```
host -t SRV _ldap._tcp.${DOMAIN_FQDN}. {IP_ADDRESS}
host -t SRV _kerberos._udp.${DOMAIN_FQDN}. {IP_ADDRESS}
```
Expect to see valid `SRV` records, not errors.
+ As root, run the following:
```
host -t A ${HOSTNAME}.${DOMAIN_FQDN}. {IP_ADDRESS}
host ${IP_ADDRESS} {IP_ADDRESS}
```
Expect to see the DC's `A` and `PTR` records, not errors.
+ As root, run the following:
```
host -t NS ${DOMAIN_FQDN}. {IP_ADDRESS}
host -t A ${DOMAIN_FQDN}. {IP_ADDRESS}
```
Expect to see the domain's `NS` and `A` records, not errors.

N.B.: The domain must have one `NS` record for every active DC;
there must also be one `A` record for every active DC.
+ As root, run the following:
```
host -t AXFR ${DOMAIN_FQDN}. ${IP_ADDRESS}
host -t AXFR _msdcs.${DOMAIN_FQDN}. ${IP_ADDRESS}
host -t AXFR ${REV_DNS_ZONE}. ${IP_ADDRESS}
```
Expect to see complete dumps (or "zone transfers") of the three DNS zones.

---
### Show the FSMO roles
+ As root, run the following:
```
samba-tool fsmo show
```
Expect to see 7 roles listed. It is likely that the "master" DC
holds all the roles, unless roles were transferred to other
DCs by an administrator.

---
### Done

