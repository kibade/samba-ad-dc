# How To Add A New Samba4 Member Server To An Existing Samba4 AD
__Version:__ 1.0 DRAFT

__Updated:__ (NOT YET RELEASED)

__Change Log:__
+ v.1.0 DRAFT, NOT YET RELEASED:
  - Work in progress.

__References:__
+ https://wiki.samba.org/index.php/Setting_up_Samba_as_a_Domain_Member

__Assumptions:__
+ The new member server will be installed on Debian Stretch.
+ The new member server will be joining an existing Samba4 AD domain.
+ The new member server will have precisely one network interface (other than
	 loopback) that is actively serving samba file shares.
+ The new member server will begin as a DHCP client on the network.
+ The existing AD domain has a "master" DC with most/all of the FSMO roles.

---
### Discover or choose parameter values for the new DC
```
INTERFACE_NAME          name of the network interface for samba
IP_ADDRESS              static IP address
SUBNET_MASK             network subnet mask
GATEWAY                 network gateway address (default route)
DOMAIN_FQDN             fully-qualified domain name
HOSTNAME                host name
NTP_SERVER1             FQDN of NTP server to synch with
DC1_ADDRESS             IP address of the existing "master" DC
DC1_HOSTNAME            host name of the existing "master" DC
IDMAP_RANGE             unique range of IDs for winbind idmap
```
Example settings:
```
INTERFACE_NAME		enp0s17
IP_ADDRESS		172.16.0.1
SUBNET_MASK		255.255.255.0
GATEWAY			172.16.0.254
DOMAIN_FQDN		testy.sd57.bc.ca
HOSTNAME		fs1
NTP_SERVER1		time.sd57.bc.ca
DC1_ADDRESS		172.16.0.2
DC1_HOSTNAME		dc1
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

---
### Install the necessary software packages
+ As root, run the following:
```
apt-get update
apt-get install samba winbind ntp krb5-user dnsutils ldap-utils \
        ldb-tools smbclient libnss-winbind acl rsync
```

---
### Stop and disable the samba services
+ As root, run the following:
```
systemctl stop    smbd nmbd winbind
systemctl disable smbd nmbd winbind
```

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
### Configure samba
+ As root, run the following:
```
DOMAIN=$(echo "${DOMAIN_FQDN}" | cut -f1 -d.)
REALM=$(echo "${DOMAIN_FQDN}" | tr 'a-z' 'A-Z')
```
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

        # Enable extended ACLs globally
        vfs objects = acl_xattr
        map acl inherit = yes
        store dos attributes = yes
```

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
+ Edit `/etc/nsswitch.conf`, as per the following fragment:
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
### Allow `Domain Admins` to configure share permissions
+ As root, run the following:
```
DOMAIN=$(echo "${DOMAIN_FQDN}" | cut -f1 -d.)
net rpc rights grant "${DOMAIN}\Domain Admins" \
        SeDiskOperatorPrivilege -U "${DOMAIN}\administrator"
```

### Done


