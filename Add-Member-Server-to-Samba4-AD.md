# How To Add A New Samba4 Member Server To An Existing Samba4 AD
__Version:__ 3.0

__Updated:__ June 16, 2017

__Change Log:__
+ v.3.0, released June 16, 2017:
  - Added DC1_TECHUSER parameter, and updated "Configure Kerberos" accordingly.
+ v.2.1, released June 13, 2017:
  - Added to "Troubleshooting Winbind", instructions for clearing cache.
+ v.2.0, released June 6, 2017:
  - Numerous minor tweaks and clarifications.
+ v.1.2, released June 6, 2017:
  - Added "Troubleshooting Winbind", to warn about `/etc/krb5.keytab`.
+ v.1.1, released May 31, 2017:
  - Added clarification & example to "Configure local host name resolution".
+ v.1.0, released May 26, 2017:
  - Initial release.

__References:__
+ https://wiki.samba.org/index.php/Setting_up_Samba_as_a_Domain_Member

__Assumptions:__
+ The new member server will be installed on Debian Jessie (or newer).
+ The new member server will be joining an existing Samba4 AD domain.
+ The new member server will have precisely one network interface (other than
	 loopback) that is actively serving samba file shares.
+ The new member server will begin as a DHCP client on the network.
+ The existing AD domain has a "master" DC with most/all of the FSMO roles.

---
### Discover or choose parameter values for the new domain-member server
```
INTERFACE_NAME          name of the network interface for samba
IP_ADDRESS              static IP address
SUBNET_MASK             network subnet mask
GATEWAY                 network gateway address (default route)
DOMAIN_FQDN             fully-qualified domain name
DOMAIN                  short domain name, in ALL CAPS
REALM                   same as ${DOMAIN_FQDN}, but in ALL CAPS
HOSTNAME                host name
NTP_SERVER1             FQDN of NTP server to synch with
DC1_ADDRESS             IP address of the existing "master" DC
DC1_HOSTNAME            host name of the existing "master" DC
DC1_TECHUSER            user on the existing "master" DC, allowed to SSH
IDMAP_RANGE             unique range of IDs for winbind idmap
```
Example settings:
```
INTERFACE_NAME          eth0
IP_ADDRESS              10.45.10.1
SUBNET_MASK             255.255.254.0
GATEWAY                 10.45.11.254
DOMAIN_FQDN             sfg.ad.sd57.bc.ca
DOMAIN                  SFG
REALM                   SFG.AD.SD57.BC.CA
HOSTNAME                fs1
NTP_SERVER1             time.sd57.bc.ca
DC1_ADDRESS             10.45.10.3
DC1_HOSTNAME            dc1
DC1_TECHUSER            tech
IDMAP_RANGE             100000-199999
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
Be certain to replace the placeholders `${IP_ADDRESS}`, `${HOSTNAME}`,
and `${DOMAIN_FQDN}` with their actual values.

Be certain to remove the `127.0.1.1` entry for the host, if it exists,
while leaving the `127.0.0.1 localhost` entry intact. The above entry
needs to be the __only__ line that mentions the server's DNS name,
otherwise local name resolution is ambiguous, which can cause problems
for the domain-join process.

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
        ldb-tools smbclient libnss-winbind acl rsync
```
When/if asked questions related to kerberos domain/realm, simply accept
the defaults, since kerberos will be reconfigured later, anyway.

---
### Stop and disable the samba services
+ As root, run the following:
```
systemctl stop    smbd nmbd winbind
systemctl disable smbd nmbd winbind
systemctl status  smbd nmbd winbind
```
The last command must show the services as "inactive (dead)".
If not, then troubleshooting is necessary before continuing.
+ As root, run the following:
```
ps -ax | egrep -i 'samba|smbd|nmbd|winbind'
```
Expect to see at most one line of output, probably for the `grep`
process. If any samba processes are found running, they need to be
stopped before continuing.

---
### Deconfigure samba and kerberos
+ Run the following as root:
```
CONFIGFILE=$(smbd -b |egrep CONFIGFILE |cut -f2- -d':' |sed 's/^ *//')
rm "${CONFIGFILE}"
rm /etc/krb5.conf
```

---
### Remove all local samba cache and database files
+ Run the following as root:
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

The above config is merely the minimum requirement.
If the domain to be joined has multiple DCs, then be certain that 
__/etc/resolv.conf__ has exactly one`nameserver` line for each DC.
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
### Configure samba
+ Edit __/etc/samba/smb.conf__ to read as follows:
```
[global]
        server role = member server
        security = ADS
        workgroup = ${DOMAIN}
        realm = ${REALM}

        interfaces = lo ${INTERFACE_NAME}
        bind interfaces only = yes

        log file = /var/log/samba/%m.log
        log level = 1

        # Default ID mapping configuration for local BUILTIN accounts
        # and groups on a domain member. The default (*) domain:
        # - must not overlap with any domain ID mapping configuration!
        # - must use an read-write-enabled back end, such as tdb.
        idmap config * : backend = tdb
        idmap config * : range = 70000-99999

        # Use idmap_rid for domain accounts
        idmap config ${DOMAIN} : backend = rid
        idmap config ${DOMAIN} : range = ${IDMAP_RANGE}

        # Configure winbind
        winbind nss info = template
        template shell = /bin/false
        template homedir = /home/%U
        winbind separator = /
        winbind cache time = 1

        # Enable extended ACLs globally
        vfs objects = acl_xattr
        map acl inherit = yes
        store dos attributes = yes
```
Be certain to replace the placeholders `${DOMAIN}`, `${REALM}`,
`${INTERFACE_NAME}`, and `${IDMAP_RANGE}` with their actual values.

---
### Configure kerberos
+ As root, run the following:
```
PRIVATE_DIR=$(smbd -b |egrep PRIVATE_DIR |cut -f2- -d':' |sed 's/^ *//')
cd "${PRIVATE_DIR}"
rsync -aP ${DC1_TECHUSER}@${DC1_HOSTNAME}:"${PRIVATE_DIR}/krb5.conf" ./
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
### Join this host as a member server to the existing AD domain
+ As root, run the following:
```
net ads join -U Administrator
```
Expect to see `Joined '${HOSTNAME}' to dns domain ${DOMAIN_FQDN}`.
+ If this fails, troubleshooting is necessary before you can continue.
+ (N.B.: At this point, no samba services have been started yet.)

---
### Configure Name Service Switch (NSS)
+ Edit __/etc/nsswitch.conf__, as per the following fragment:
```
passwd:         compat winbind
group:          compat winbind
```
i.e.: add `winbind` to the end of the `passwd` and `group` lines.

---
### Enable and start the winbind, smbd, and nmbd services
+ As root, run the following:
```
systemctl enable winbind smbd nmbd
systemctl start  winbind smbd nmbd
systemctl status winbind smbd nmbd
```
+ The last command must show each of the services as `active (running)`.
  If not, then troubleshooting is necessary before continuing.

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
getent passwd "${DOMAIN}/Administrator"
getent group "${DOMAIN}/Domain Users"
```
Expect to see `Administrator` and `Domain Users` IDs.

---
### Allow `Domain Admins` to configure share permissions
+ As root, run the following:
```
net rpc rights grant "${DOMAIN}/Domain Admins" \
        SeDiskOperatorPrivilege -U "${DOMAIN}/administrator"
```

---
### Troubleshooting Winbind
+ If `winbind` tests are failing, check to make sure you do not have
  a "stray" kerberos `keytab` file. Such a file can cause `winbind`
  to have trouble when starting up. A symptom of this is the appearance
  of `Kinit ... Preauthentication failed` messages in the status
  report generated by `systemctl status winbind.service`.
  - As root, check whether __/etc/krb5.keytab__ exists. If so, delete it,
    and then run `systemctl restart winbind`.

+ When updating a user's group membership(s) in Active Directory, check
  that the membership(s) are reflected correctly on the member server, as
  follows:
```
watch id ${DOMAIN}/user.name
```
This command reruns the `id` command every 2 seconds.
If group membership(s) are not reflected correctly after 10 to 15 seconds
(at most), then you may need to forcibly clear the winbind cache as follows:
```
CACHEDIR=$(smbd -b |egrep CACHEDIR |cut -f2- -d':' |sed 's/^ *//')
systemctl stop winbind
rm "${CACHEDIR}/netsamlogon_cache.tdb"
systemctl start winbind
```

---
### Done

