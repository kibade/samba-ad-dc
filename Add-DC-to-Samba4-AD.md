# How To Add A New Samba4 Domain Controller (DC) To An Existing Samba4 AD
__Version:__ 1.1

__Updated:__ May 20, 2017

__Change Log:__
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
HOSTNAME                host name
NTP_SERVER1             FQDN of NTP server to synch with
DNS_FORWARDER           IP address of the DNS forwarder
REV_DNS_ZONE            FQDN of the reverse DNS zone
DC1_ADDRESS             IP address of the existing "master" DC
DC1_HOSTNAME            host name of the existing "master" DC
```
Example settings:
```
INTERFACE_NAME		enp0s17
IP_ADDRESS		172.16.0.3
SUBNET_MASK		255.255.255.0
GATEWAY			172.16.0.1
DOMAIN_FQDN		testy.sd57.bc.ca
HOSTNAME		dc2
NTP_SERVER1		time.sd57.bc.ca
DNS_FORWARDER           199.175.16.2
REV_DNS_ZONE		0.16.172.in-addr.arpa
DC1_ADDRESS		172.16.0.2
DC1_HOSTNAME		dc1
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

---
### Install the necessary software packages
+ As root, run the following:
```
apt-get update
apt-get install samba winbind ntp krb5-user dnsutils ldap-utils \
        ldb-tools smbclient libnss-winbind acl rsync
```
+ Stop and disable the samba services, by running the following as root:
```
systemctl stop    smbd nmbd winbind
systemctl disable smbd nmbd winbind
```
+ Deconfigure samba and kerberos, by running the following as root:
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
Also: The `tinker panic 0` line must be the first line in `ntp.conf`.
+ As root, run the following:
```
systemctl restart ntp
```

---
### Re-configure DNS resolution
+ Edit __/etc/resolv.conf__, to read as follows:
```
domain ${DOMAIN_FQDN}
search ${DOMAIN_FQDN}
nameserver ${DC1_ADDRESS}
```

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
DOMAIN=$(echo "${DOMAIN_FQDN}" | cut -f1 -d.)
samba-tool domain join "${DOMAIN_FQDN}" DC -U${DOMAIN}\\Administrator \
        --dns-backend=SAMBA_INTERNAL \
        --option="interfaces=lo ${INTERFACE_NAME}" \
        --option="bind interfaces only=yes"
```
Expect to see `Joined domain ... as a DC`.
+ If this fails, troubleshooting is necessary before you can continue.

---
### Add configuration to the new DC's `smb.conf`, to match the "master" DC
+ Copy the following configuration option lines from
  `/etc/samba/smb.conf` on the existing DC to the new DC:
```
dns forwarder = ${DNS_FORWARDER}
idmap_ldb:use rfc2307 = yes
```

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
cp idmap.ldb.bak idmap.ldb
```

---
### Unmask, enable and start the `samba-ad-dc` service
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
### Add the new DC to the DNS resolution config on all DCs in the domain
+ Edit `/etc/resolv.conf`, as per the following fragment:
```
nameserver ${IP_ADDRESS}
```
i.e.: Append a `nameserver` entry to the new DC's `/etc/resolv.conf`

Also: Add a `nameserver` entry for the new DC to the `resolv.conf`
of all other DCs in the domain.

---
### Ensure that the new DC's `A` record exists in DNS
+ As root, run the following:
```
host -t A ${HOSTNAME}.${DOMAIN_FQDN}.
```
+ If this reports `not found: 3(NXDOMAIN)`, then add the missing `A`
  record, as follows:
```
samba-tool dns add localhost "${DOMAIN_FQDN}" "${HOSTNAME}" \
        A ${IP_ADDRESS} -UAdministrator
```
+ Do not proceed until the `A` record exists and is correct.

---
### Ensure that the new DC's `PTR` record exists in DNS
+ As root, run the following:
```
host ${IP_ADDRESS}
```
+ If this reports `not found: 3(NXDOMAIN)`, then add the missing `PTR`
  record, as follows:
```
HOST_NUM=$(echo ${IP_ADDRESS} | cut -f4 -d.)
samba-tool dns add localhost "${REV_DNS_ZONE}" "${HOST_NUM}" \
        PTR "${HOSTNAME}.${DOMAIN_FQDN}." -UAdministrator
```
+ Do not proceed until the `PTR` record exists and is correct.

---
### Ensure that all DCs' `objectGUID`s are registered as `CNAME`s in DNS
+ List all DCs' `objectGUID`s, by running the following command as root:
```
ldbsearch -H "${PRIVATE_DIR}/sam.ldb" '(invocationId=*)' \
        --cross-ncs objectguid
```
+ An `objectGUID` is a 5-part hex-string. For each DC in the domain,
  query the DNS for its `objectGUID`, as follows (assume `${GUID}`
  is a DC's corresponding `objectGUID`):
```
host -t CNAME ${GUID}._msdcs.${DOMAIN_FQDN}.
```
+ Expect to see `... is an alias for ...`. If not, then create
  the necessary `CNAME` record, as follows (assume `${DC_NAME}` is
  the corresponding DC's host name):
```
samba-tool dns add localhost _msdcs.${DOMAIN_FQDN} ${GUID} \
        CNAME ${DC_NAME}.${DOMAIN_FQDN}. -UAdministrator
```
+ Do not proceed until all DCs' `objectGUIDs` are verified in DNS.

---
### Copy the contents of the `sysvol` share from the "master" DC to the new DC
+ As root, run the following:
```
STATEDIR=$(smbd -b |egrep STATEDIR |cut -f2- -d':' |sed 's/^ *//')
cd "${STATEDIR}"
rsync -aAXHP --del ${DC1_HOSTNAME}:"${STATEDIR}/sysvol" ./
```

---
### Test the correctness of ownerships/permissions on `sysvol`
+ As root, run the following:
```
samba-tool ntacl sysvolcheck
```
+ If `sysvolcheck` throws errors, then reset `sysvol` on the
  "master" DC, as follows:
```
ssh ${DC1_HOSTNAME} samba-tool ntacl sysvolreset
```
+ If you needed to reset `sysvol`, then go back to the previous
  step ("Copy the contents of the 'sysvol' share ...").

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
host -t SRV _ldap._tcp.${DOMAIN_FQDN}. localhost
host -t SRV _kerberos._udp.${DOMAIN_FQDN}. localhost
```
Expect to see valid `SRV` records, not errors.
+ As root, run the following:
```
host -t A ${HOSTNAME}.${DOMAIN_FQDN}. localhost
host ${IP_ADDRESS} localhost
```
Expect to see the DC's `A` and `PTR` records, not errors.
+ As root, run the following:
```
host -t NS ${DOMAIN_FQDN}. localhost
host -t A ${DOMAIN_FQDN}. localhost
```
Expect to see the domain's `NS` and `A` records, not errors.

N.B.: The domain must have one `NS` record for every active DC;
  there must also be one `A` record for every active DC.

---
### Test the Directory
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


