# How To Create a New Active Directory (AD) Domain Controller (DC) with Samba4

__Version:__ 1.1

__Updated:__ May 20, 2017

__Change Log:__
+ v.1.1, released May 20, 2017:
  - Copied Create-AD-DC-Samba4.txt, and reformatted it in Markdown.
+ v.1.0, released May 14, 2017:
  - Added Version, Change Log, and References sections to the doc.
  - Updated "Install ... packages" to add the 'rsync' package.
  - Updated "Configure time synch" to correct the placement of the
    "tinker panic 0" line in ntp.conf.
  - Updated "Provision ... AD" to add the "interfaces" and "bind
    only interfaces" options to the command line.
  - Made a few little cosmetic/aesthetic changes to text and formatting.
+ v.0.9, released May 10, 2017:
  - Initial release.

__References:__
+ https://wiki.samba.org/index.php/Setting_up_Samba_as_an_Active_Directory_Domain_Controller

__Assumptions:__
  + The AD DC will be installed on a new minimal install of Debian Stretch.
  + The AD DC will be the first DC of a brand new AD domain.
  + The AD DC will have precisely one network interface (other than loopback).
  + The AD DC will begin as a DHCP client on the network.

---
### Discover or choose parameter values for the AD DC:
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
```
Example settings:
```
INTERFACE_NAME          enp0s17
IP_ADDRESS              172.16.0.2
SUBNET_MASK             255.255.255.0
GATEWAY                 172.16.0.1
DOMAIN_FQDN             testy.sd57.bc.ca
HOSTNAME                dc1
NTP_SERVER1             time.sd57.bc.ca
DNS_FORWARDER           199.175.16.2
REV_DNS_ZONE            0.16.172.in-addr.arpa
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
i.e.: Comment out the Debian pool servers, and add ${NTP_SERVER1}.
Also: The "tinker panic 0" line must be the first line in ntp.conf.
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
nameserver ${IP_ADDRESS}
```

---
### Reboot to make all modified settings active (especially the name changes)
+ As root, run the following:
```
reboot
```

---
### Provision the new AD domain
+ As root, run the following:
```
samba-tool domain provision --use-rfc2307 \
        --option="interfaces=lo ${INTERFACE_NAME}" \
        --option="bind interfaces only=yes" \
        --interactive
```
Interactive mode: Accept all the default answers, except for:
- DNS forwarder: set to: ${DNS_FORWARDER}
- Administrator password: "Let's Pick" with last letter repeated

---
### Configure kerberos
+ As root, run the following:
```
cd /etc/
PRIVATE_DIR=$(smbd -b |egrep PRIVATE_DIR |cut -f2- -d':' |sed 's/^ *//')
ln -s "${PRIVATE_DIR}/krb5.conf"
```

---
### Configure Name Service Switch (NSS)
+ Edit __/etc/nsswitch.conf__, as per the following fragment:
```
passwd:         compat winbind
group:          compat winbind
```
i.e.: add 'winbind' to the end of the 'passwd' and 'group' lines.
+ As root, run this to unmask, enable and start the samba-ad-dc service:
```
systemctl unmask samba-ad-dc
systemctl enable samba-ad-dc
systemctl start  samba-ad-dc
systemctl status samba-ad-dc
```
The last command must show the service as "active (running)".
If not, then troubleshooting is necessary before continuing.

---
### Create the reverse DNS lookup zone
+ As root, run the following:
```
    samba-tool dns zonecreate localhost ${REV_DNS_ZONE} -UAdministrator
```

---
### Add a PTR record for the DC to the reverse lookup zone
+ As root, run the following:
```
HOST_NUM=$(echo ${IP_ADDRESS} | cut -f4 -d.)
samba-tool dns add localhost ${REV_DNS_ZONE} ${HOST_NUM} PTR \
        ${HOSTNAME}.${DOMAIN_FQDN}. -UAdministrator
```

---
### Save a backup of the local idmap (for later, when adding DCs)
+ As root, run the following:
```
PRIVATE_DIR=$(smbd -b |egrep PRIVATE_DIR |cut -f2- -d':' |sed 's/^ *//')
tdbbackup -s .bak "${PRIVATE_DIR}/idmap.ldb"
```

---
### Test the correctness of ownerships/permissions on sysvol
+ As root, run the following:
```
samba-tool ntacl sysvolcheck
```
+ If sysvolcheck throws errors, then reset sysvol, as follows:
```
samba-tool ntacl sysvolreset
```

---
### The remaining steps are only tests (no more config changes)

---
### Test availability of kerberos
+ As root, run the following:
```
kinit administrator
klist
```

---
### Test availability of the local 'sysvol' and 'netlogon' samba shares
+ As root, run the following:
```
smbclient -L localhost -U%
```
Expect to see 'netlogon', 'sysvol', and 'IPC$' shares.
+ As root, run the following:
```
smbclient //localhost/netlogon -UAdministrator -c ls
```
Should return without error.

---
### Test the local DNS service 
+ As root, run the following:
```
host -t SRV _ldap._tcp.${DOMAIN_FQDN}.
host -t SRV _kerberos._udp.${DOMAIN_FQDN}.
```
Expect to see valid SRV records, not errors.
+ As root, run the following:
```
host -t A ${HOSTNAME}.${DOMAIN_FQDN}.
host ${IP_ADDRESS}
```
Expect to see the DC's A and PTR records, not errors.
+ As root, run the following:
```
host -t NS ${DOMAIN_FQDN}.
host -t A ${DOMAIN_FQDN}.
```
Expect to see the domain's NS and A records, not errors.

---
### Test the Directory
+ As root, run the following:
```
wbinfo --ping-dc
```
Expect to see "dc connection ... succeeded".
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
Expect to see Administrator and "Domain Users" IDs.

---
### Show the FSMO roles
+ As root, run the following:
```
samba-tool fsmo show
```
Expect to see 7 roles listed, all held by the new DC.

---
### Done
+ Done.


