# How To Create a New Active Directory (AD) Domain Controller (DC) with Samba4
__Version:__ 3.3

__Updated:__ June 9, 2017

__Change Log:__
+ v.3.3, released June 9, 2017:
  - 
+ v.3.2, released June 6, 2017:
  - Added `ntlm auth = yes` to the smb.conf file ("Update the samba config").
+ v.3.1.2 released June 5, 2017:
  - Added OU script creation (Student and Staff OUs)
+ v.3.1.1 released May 31, 2017:
  - Added clarification & example to "Configure local host name resolution".
  - Added clarifying text to "Provision the new AD domain".
+ v.3.0, released May 28, 2017:
  - Changed the DNS backend from SAMBA_INTERNAL to BIND9_DLZ.
  - Added DOMAIN, REALM, ADMIN_PASSWORD to "... paramater values ..." section.
  - Several minor additions made (more tests), and some tests rearranged.
+ v.2.1, released May 26, 2017:
  - Updated "Configure local host name resolution" to add a check.
  - Updated "Install the necessary software ..." to advise accepting defaults.
  - Updated "Stop and disable the samba services" to add a check.
  - Updated "... parameter values ..." examples to use 10.Y.x.x/23 network.
+ v.2.0, released May 22, 2017:
  - Updated "Provision the ... domain" to add "winbind separator".
  - Updated "Configure local ... resolution" to add "hostname" cmd.
  - Split "Install the ... packages" into three separate sections.
  - Renamed "Test the Directory" to "Test Winbind".
  - Moved "Test Winbind" ahead of "Save a backup of the local idmap ...".
  - Updated the formatting of "Start the samba-ad-dc service".
  - Added status checks to several sections.
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
DOMAIN                  short domain name, in ALL CAPS
REALM                   same as ${DOMAIN_FQDN}, but in ALL CAPS
ADMIN_PASSWORD          the Administrator password
HOSTNAME                host name
NTP_SERVER1             FQDN of NTP server to synch with
DNS_FORWARDER           IP address of the DNS forwarder
REV_DNS_ZONE            FQDN of the reverse DNS zone
```
Example settings:
```
INTERFACE_NAME          enp0s17
IP_ADDRESS              10.45.10.3
SUBNET_MASK             255.255.254.0
GATEWAY                 10.45.11.254
DOMAIN_FQDN             sfg.ad.sd57.bc.ca
DOMAIN                  SFG
REALM                   SFG.AD.SD57.BC.CA
ADMIN_PASSWORD          secret!23
HOSTNAME                dc1
NTP_SERVER1             time.sd57.bc.ca
DNS_FORWARDER           199.175.16.2
REV_DNS_ZONE            10.45.10.in-addr.arpa
```
+ Recommendation: Copy the above list of settings into a script file, so that
  the file can be conveniently "sourced" to define its variables in the
  current shell session.  E.g.: Create a file named __/root/params.sh__ with
  the following contents (using the example settings above):
```
INTERFACE_NAME="enp0s17"
IP_ADDRESS="10.45.10.3"
SUBNET_MASK="255.255.254.0"
GATEWAY="10.45.11.254"
DOMAIN_FQDN="sfg.ad.sd57.bc.ca"
DOMAIN="SFG"
REALM="SFG.AD.SD57.BC.CA"
ADMIN_PASSWORD="secRet!23"
HOSTNAME="dc1"
NTP_SERVER1="time.sd57.bc.ca"
DNS_FORWARDER="199.175.16.2"
REV_DNS_ZONE="10.45.10.in-addr.arpa"
```
+ To "source" this file in your shell session, run the following command:
```
. /root/params.sh
```
Bear in mind that the variables will not survive the end of a shell session,
so you will need to source __/root/params.sh__ every time you start a new
session in which you intend to use those variables.

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

Be certain to remove the `127.0.1.1` entry for the host, if it exists,
while leaving the `127.0.0.1 localhost` entry intact. The above entry
needs to be the __only__ line that mentions the server's DNS name,
otherwise local name resolution is ambiguous, which causes problems
for the domain provisioning process.

Example __/etc/hosts__ file:
```
127.0.0.1       localhost
10.45.10.3      dc1.sfg.ad.sd57.bc.ca   dc1
...
```
+ As root, run the following:
```
hostname --file /etc/hostname
getent hosts "${HOSTNAME}"
```
Expect the output of `getent` to look as follows:
```
${IP_ADDRESS}    ${HOSTNAME}.${DOMAIN_FQDN}    ${HOSTNAME}
```
i.e. the output should match the server's line in __/etc/hosts__.

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
The last command must show the services as `inactive (dead)`.
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
nameserver ${IP_ADDRESS}
```
Be certain to replace the placeholders `${DOMAIN_FQDN}` and `${IP_ADDRESS}`
with their actual values.

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
        --option="winbind separator=/" \
        --interactive
```
Be certain to replace the placeholder `${INTERFACE_NAME}` in the above
command with its actual value.

Interactive mode: questions and answers, as follows (be certain to replace
the placeholders `${REALM}`, `${DOMAIN}`, and `${ADMIN_PASSWORD}` with
their actual values):
- Q.: Realm
  - A.: ${REALM}
- Q.: Domain
  - A.: ${DOMAIN}
- Q.: Server Role
  - A.: dc
- Q.: DNS backend
  - A.: BIND9_DLZ
- Q.: Administrator password
  - A.: ${ADMIN_PASSWORD}

---
### Update the samba config file
+ Edit __/etc/samba/smb.conf__, to add the following lines to the `[global]`
  section:
```
[global]
...
        # Allow NTLMv1 authentication, for MSCHAPv2 / FreeRADIUS compatibility
        ntlm auth = yes
...
```

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
### Test availability of kerberos
+ As root, run the following:
```
kinit administrator
klist
```
Should return without error.

---
### Check the DNS zones
+ As root, run the following:
```
samba-tool dns zonelist localhost -UAdministrator
```
Expect to see three DNS zones listed (not necessarily in this order):
```
pszZoneName  : ${DOMAIN_FQDN}
...
pszZoneName  : ${REV_DNS_ZONE}
...
pszZoneName  : _msdcs.${DOMAIN_FQDN}
```
In Samba versions up to v.4.5.8, the domain provisioning tool fails to
create the reverse DNS lookup zone `${REV_DNS_ZONE}`, which means that
the above command may only show two DNS zones. The next step will remedy
this problem.

---
### Create the reverse DNS lookup zone (if necessary)
+ If the previous step found the `${REV_DNS_ZONE}` was missing, then
run following command as root:
```
samba-tool dns zonecreate localhost ${REV_DNS_ZONE} -UAdministrator
```
Expect to see `Zone ... .in-addr.arpa created successfully`.
Otherwise, troubleshooting is necessary before continuing.

---
### Add a PTR record for the DC to the reverse lookup zone
+ As root, run the following:
```
HOST_NUM=$(echo ${IP_ADDRESS} | cut -f4 -d.)
samba-tool dns add localhost ${REV_DNS_ZONE} ${HOST_NUM} PTR \
        ${HOSTNAME}.${DOMAIN_FQDN}. -UAdministrator
```
Expect to see `Record added successfully`.
Otherwise, troubleshoot and resolve before continuing.

---
### Test the correctness of ownerships/permissions on sysvol
+ As root, run the following:
```
samba-tool ntacl sysvolcheck
```
+ If sysvolcheck throws errors, then run the following, as root:
```
samba-tool ntacl sysvolreset
samba-tool ntacl sysvolcheck
```

---
### Save a backup of the local idmap (for later, when adding DCs)
+ As root, save the following into a script, then run the script:
```
#!/bin/bash
set -eu
echo "USERS:"
samba-tool user list |
while read u; do
        if ! getent passwd "$u" >&/dev/null; then
                getent passwd "BUILTIN/$u" || echo "NOT FOUND: $u"
        else
                getent passwd "$u" || echo "NOT FOUND: $u"
        fi
done
echo "GROUPS:"
samba-tool group list |
while read g; do
        if ! getent group "$g" >&/dev/null; then
                getent group "BUILTIN/$g" || echo "NOT FOUND: $g"
        else
                getent group "$g" || echo "NOT FOUND: $g"
        fi
done
```
This script queries all users and groups, to ensure that all
entities are allocated in the local idmap.
If any users or groups are "NOT FOUND", then there is a problem
that needs to be resolved before continuing.
+ As root, run the following:
```
PRIVATE_DIR=$(smbd -b |egrep PRIVATE_DIR |cut -f2- -d':' |sed 's/^ *//')
tdbbackup -s .bak "${PRIVATE_DIR}/idmap.ldb"
ls "${PRIVATE_DIR}/idmap.ldb.bak"
```
The last command should list the idmap backup file: `idmap.ldb.bak`.

---
### Create the default OUs
- Copy the text below into a new file on the Domain Controller:
```
dn: OU=Staff,DC=SCHOOLCODE,DC=ad,DC=sd57,DC=bc,DC=ca
changetype: add
objectClass: top
objectClass: organizationalunit
description: Staff OU

dn: OU=Staff_Computers,OU=Staff,DC=SCHOOLCODE,DC=ad,DC=sd57,DC=bc,DC=ca
changetype: add
objectClass: top
objectClass: organizationalunit
description: Staff Computers

dn: OU=Staff_Users,OU=Staff,DC=SCHOOLCODE,DC=ad,DC=sd57,DC=bc,DC=ca
changetype: add
objectClass: top
objectClass: organizationalunit
description: Staff Users

dn: OU=Student,DC=SCHOOLCODE,DC=ad,DC=sd57,DC=bc,DC=ca
changetype: add
objectClass: top
objectClass: organizationalunit
description: Student OU

dn: OU=Student_Computers,OU=Student,DC=SCHOOLCODE,DC=ad,DC=sd57,DC=bc,DC=ca
changetype: add
objectClass: top
objectClass: organizationalunit
description: Student Computers

dn: OU=Student_Users,OU=Student,DC=SCHOOLCODE,DC=ad,DC=sd57,DC=bc,DC=ca
changetype: add
objectClass: top
objectClass: organizationalunit
description: Staudent Users
```
- Search and replace `SCHOOLCODE` with your DC's school code
- Save the file as `/root/ous.txt`
- Execute `ldbadd --url=/var/lib/samba/private/sam.ldb /root/ous.txt`.
  If no errors, then your OUs have been added successfully.
---
### Create default Groups
+ As root, run the following:
```
samba-tool group add Staff
samba-tool group add Students
samba-tool group add Office
samba-tool group add Yearbook
```

---
### The remaining steps are only tests (no more config changes)

---
### Test Winbind
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
+ As root, run the following script:
```
getent passwd Administrator
getent group "Domain Users"
```
Expect to see `Administrator` and `Domain Users` IDs.

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
host -t SRV _ldap._tcp.${DOMAIN_FQDN}. ${IP_ADDRESS}
host -t SRV _kerberos._udp.${DOMAIN_FQDN}. ${IP_ADDRESS}
```
Expect to see valid SRV records, not errors.
+ As root, run the following:
```
host -t A ${HOSTNAME}.${DOMAIN_FQDN}. ${IP_ADDRESS}
host ${IP_ADDRESS} ${IP_ADDRESS}
```
Expect to see the DC's A and PTR records, not errors.
+ As root, run the following:
```
host -t NS ${DOMAIN_FQDN}. ${IP_ADDRESS}
host -t A ${DOMAIN_FQDN}. ${IP_ADDRESS}
```
Expect to see the domain's NS and A records, not errors.
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
Expect to see 7 roles listed, all held by the new DC.

---
### Done

