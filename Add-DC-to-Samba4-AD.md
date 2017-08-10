# How To Add A New Samba4 Domain Controller (DC) To An Existing Samba4 AD

__Summary:__
This document describes a sequence of steps intended to add a new Domain
Controller (DC) to an existing Active Directory (AD) domain.

__Version:__ 9.0

__Updated:__ August 9, 2017

__Change Log:__
+ v.9.0, released August 9, 2017:
  - Added instructions to install the 'backup-samba-tdbs' script to cron.d.
+ v.7.0, released July 9, 2017:
  - Updated the NTP configuration section, pointing to a new doc.
+ v.6.1, released July 7, 2017:
  - Configured bind9 to disallow zone transfers (Matt F.)
+ v.6.0, released July 2, 2017:
  - Added instructions to install cron.d and utility scripts from git repo.
+ v.5.0, released June 28, 2017:
  - Removed all references to the reverse-lookup DNS zone and PTR records.
    The reverse-DNS zone is not needed, and it can break disaster recovery.
  - Switched the order of the "Start bind" and "Start samba" sections, as
    it seems better to have samba up and running before bind.
  - Numerous edits made to improve clarity.
  - Added a "Troubleshooting Hint" to cover a failure mode discovered in testing.
+ v.4.0, released June 23, 2017:
  - Updated "Configure time synch" to provide AD-authenticated time synch.
+ v.3.5, released June 17, 2017:
  - Removed the `DNS_FORWARDER` variable (not needed in BIND9_DLZ backend).
+ v.3.4, released June 11, 2017:
  - For ease of understanding, `smb.conf` is now copied from the "master" DC.
  - Replaced "Test and repair DNS updates" with "Repair ... BIND9_DLZ ...".
  - Added a Summary section, to reduce confusion about what this document is.
+ v.3.3, released June 9, 2017:
  - Added a recommendation to "Discover or choose parameter values...".
+ v.3.2, released June 6, 2017:
  - Added `ntlm auth` to "Add configuration to ... `smb.conf` ..."
+ v.3.1.1 released May 31, 2017:
  - Added clarification & example to "Configure local host name resolution".
  - Added clarifying text to "Join this host as a new DC ...".
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
NET_ADDRESS             network address
SUBNET_MASK             network subnet mask
GATEWAY                 network gateway address (default route)
DOMAIN_FQDN             fully-qualified domain name
DOMAIN                  short domain name, in ALL CAPS
REALM                   same as ${DOMAIN_FQDN}, but in ALL CAPS
ADMIN_PASSWORD          the Administrator password
HOSTNAME                host name
NTP_SERVER1             FQDN of NTP server to synch with
DC1_ADDRESS             IP address of the existing "master" DC
DC1_HOSTNAME            host name of the existing "master" DC
```
Example settings:
```
INTERFACE_NAME          enp0s3
IP_ADDRESS              10.45.10.4
NET_ADDRESS             10.45.10.0
SUBNET_MASK             255.255.254.0
GATEWAY                 10.45.11.254
DOMAIN_FQDN             sfg.ad.sd57.bc.ca
DOMAIN                  SFG
REALM                   SFG.AD.SD57.BC.CA
ADMIN_PASSWORD          secRet!23
HOSTNAME                dc2
NTP_SERVER1             time.sd57.bc.ca
DC1_ADDRESS             10.45.10.3
DC1_HOSTNAME            dc1
```
+ Recommendation: Copy the above list of settings into a script file, so that
  the file can be conveniently "sourced" to define its variables in the
  current shell session.  E.g.: Create a file named __/root/params.sh__ with
  the following contents (using the example settings above):
```
INTERFACE_NAME="enp0s3"
IP_ADDRESS="10.45.10.4"
NET_ADDRESS="10.45.10.0"
SUBNET_MASK="255.255.254.0"
GATEWAY="10.45.11.254"
DOMAIN_FQDN="sfg.ad.sd57.bc.ca"
DOMAIN="SFG"
REALM="SFG.AD.SD57.BC.CA"
ADMIN_PASSWORD="secRet!23"
HOSTNAME="dc2"
NTP_SERVER1="time.sd57.bc.ca"
DC1_ADDRESS="10.45.10.3"
DC1_HOSTNAME="dc1"
```
+ To "source" this file in your shell session, run the following command:
```
. /root/params.sh
```
Bear in mind that the variables will not survive the end of a shell session,
so you will need to source __/root/params.sh__ every time you start a new
session in which you intend to use those variables.

---
### Configure a static IP address __(if necessary)__
+ It is necessary to run a DC as a server with a static IP address.
+ Ideally, the server's IP address will be set to its static value when
  the OS is installed.
+ If that is the case here, then immediately skip to the next section
  ("Configure local hostname resolution").
+ N.B.: Do the steps for this section in a console, as the network will drop.
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
ip addr show ${INTERFACE_NAME}
```
Expect `ip addr` to show that the interface is in the UP state.
Otherwise, do not proceed until it is so.

---
### Configure local host name resolution
+ From here on, it is okay to continue work in an SSH session.
+ Local host name resolution must resolve the server's names to a real
  IP address that is not in the `127.0.0.0/8` range.
+ If the server was configured with a static IP address when the OS
  was installed, then it is likely that the configuration is already done.
+ To check, run the following:
```
getent hosts ${HOSTNAME}
```
The output should be exactly one line, arranged as follows:
```
${IP_ADDRESS}    ${HOSTNAME}.${DOMAIN_FQDN}    ${HOSTNAME}
```
That is, local host name resolution should resolve the server's
hostname and fqdn to its NIC's IP address, and not to a `127.0.0.0/8`
address.
+ If the above check revealed that the server's hostname and fqdn
  resolve to its NIC's static IP address, then immediately skip to
  the next section ("Install the necessary software packages").
+ Otherwise, run the following, as root:
```
echo "${HOSTNAME}" >/etc/hostname
```
+ Edit __/etc/hosts__, as per the following fragment:
```
${IP_ADDRESS}    ${HOSTNAME}.${DOMAIN_FQDN}    ${HOSTNAME}
```
Be certain to replace the placeholders `${IP_ADDRESS}`, `${HOSTNAME}`,
and `${DOMAIN_FQDN}` with their actual values.

Be certain to remove the `127.x.x.x` line for the host, if it exists,
while leaving the `127.0.0.1 localhost` entry intact. The above entry
__must__ be the __only__ line that mentions the server's DNS name,
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
+ Finally, since the server's host name configuration has (possibly)
  changed, reboot the server now. As root, run the following command:
```
reboot
```

---
### Install the necessary software packages
+ As root, run the following:
```
apt-get update
apt-get install samba winbind ntp krb5-user dnsutils ldap-utils \
        ldb-tools smbclient libnss-winbind acl rsync bind9 ca-certificates
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
+ Configure the NTP service on this server by following the instructions
  described in the following document:
https://github.com/smonaica/samba-ad-dc/blob/master/NTP-Configuration.md

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
```
Expect to see the `A` record of the existing "master" DC.
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
Be certain to replace the placeholders `${DOMAIN_FQDN}`, `${DOMAIN}`, and
`${INTERFACE_NAME}` with their actual values.

Expect to see `Joined domain ... as a DC`.
+ If this fails, troubleshooting is necessary before you can continue.

---
### Copy the "master" DC's `smb.conf` to the new DC
+ It is necessary that all DCs in an AD domain have functionally
  identical samba configuration. As root, run the following:
```
CONFIGFILE=$(smbd -b |egrep CONFIGFILE |cut -f2- -d':' |sed 's/^ *//')
rsync -abP ${DC1_HOSTNAME}:"${CONFIGFILE}" "${CONFIGFILE}"
```
The `rsync` command (because of the `-b` option) will save a backup copy
of the existing `smb.conf` file before replacing it with the `smb.conf`
from the "master" DC.
+ As root, run the following:
```
diff -u100 "${CONFIGFILE}" "${CONFIGFILE}~"
```
This command will show the lines that differ between `smb.conf` and
`smb.conf~`. Be certain to update all host-specific configuration options
in `smb.conf` (certainly `netbios name`, possibly `interfaces`, and perhaps
others), while keeping all the common settings unchanged.
+ Once you are done editing `smb.conf`, discard the backup `smb.conf~`,
  and check the validity of `smb.conf`, by running the following:
```
rm "${CONFIGFILE}~"
testparm -s >/dev/null
```
Expect to see (something like) the following:
```
Load smb config files from /etc/samba/smb.conf
rlimit_max: increasing rlimit_max (1024) to minimum Windows limit (16384)
Processing section "[netlogon]"
Processing section "[sysvol]"
Loaded services file OK.
Server role: ROLE_ACTIVE_DIRECTORY_DC
```
If you get error messages instead, then you need to fix `smb.conf` before
continuing.

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
+ Insert the following lines into the `options {}` block within
  __/etc/bind/named.conf.options__:
```
tkey-gssapi-keytab "${PRIVATE_DIR}/dns.keytab";
allow-transfer { "none"; };
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
rsync -aAXHP ${DC1_HOSTNAME}:"/var/backups/samba_tdb_backup/${PRIVATE_DIR}/idmap.ldb" ./
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
### Repair the BIND9_DLZ DNS backend on the "master" DC
+ For some reason, the process of joining a new DC to the AD appears to
  have the unwanted side-effect of messing up the BIND9_DLZ DNS backend
  of the "master" DC. Fortunately, there is a simple command to fix that,
  but it must be run __on the "master" DC__.
+ Therefore, as root, run the following __on the "master" DC__:
```
samba_upgradedns --dns-backend=BIND9_DLZ
systemctl restart bind9
systemctl status bind9
```
The last command must show the service as `active (running)`.
If not, then troubleshooting is necessary before continuing.
+ Troubleshooting Hint:
  - If the `bind9` service reports as `failed`, with some mention of
    "missing NS records" in a reverse-DNS zone (ending with
    `.in-addr.arpa`), then try deleting the offending DNS zone.
    Assuming the DNS zone's name is `${BAD_ZONE}`, run the following
    to delete the zone from the AD domain:
```
samba-tool dns zonedelete ${DC1_HOSTNAME} ${BAD_ZONE} -UAdministrator
```
+ Don't forget to switch back to the new DC for the next steps!

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
### Enable authenticated time synch
+ As root, run the following:
```
STATEDIR=$(smbd -b |egrep STATEDIR |cut -f2- -d':' |sed 's/^ *//')
chgrp ntp "${STATEDIR}/ntp_signd/"
chmod g+rx "${STATEDIR}/ntp_signd/"
systemctl stop ntp
systemctl start ntp
systemctl status ntp
```
The last line should report that `ntp` is `active (running)`.
If not, then troubleshooting is necessary before continuing.

---
### Check that Directory Replication is working
+ Immediately after joining the new DC, AD replication attempts will
  begin. Naturally, the first few attempts will fail. The reason is that
  all the DNS re-configurations (as documented above) need to be done
  before replication can succeed. Replication attempts occur roughly
  every 5 minutes, so wait at least 5 minutes after completing the
  previous steps before continuing with this step.
+ As root, run the following:
```
samba-tool drs showrepl
```
Expect to see `INBOUND NEIGHBORS` with recent last attempts and no
consecutive failures. Also expect to see `OUTBOUND NEIGHBORS` with
last attempts `@ NTTIME(0)` and no consecutive failures.

The last line of output should likely be
`Warning: No NC replicated for Connection!`, but that is expected.

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
### Install `ad-sysvol-replication` script, for pull-style `sysvol` replication
+ As root, run the following:
```
cd /etc/cron.d/
wget "https://github.com/smonaica/samba-ad-dc/raw/master/scripts/ad-sysvol-replication"
chown root:root ad-sysvol-replication
chmod 0644 ad-sysvol-replication
```
Edit the script to set `MASTER_DC="${DC1_HOSTNAME}"` (replacing the placeholder
`${DC1_HOSTNAME}` with its actual value).

As configured, the script runs every 5 minutes, performing a "pull-style"
synchronization of `sysvol` from the "master" DC each time.

---
### Install utility scripts
+ As root, run the following:
```
cd /usr/local/sbin/
wget "https://github.com/smonaica/samba-ad-dc/raw/master/scripts/add-students.sh"
wget "https://github.com/smonaica/samba-ad-dc/raw/master/scripts/backup_samba_tdbs.sh"
wget "https://github.com/smonaica/samba-ad-dc/raw/master/scripts/ug-dump.sh"
chown root:root add-students.sh backup_samba_tdbs.sh ug-dump.sh
chmod 0750 add-students.sh backup_samba_tdbs.sh ug-dump.sh
```

---
### Install `backup-samba-tdbs` script
+ As root, run the following:
```
cd /etc/cron.d/
wget "https://github.com/smonaica/samba-ad-dc/raw/master/scripts/backup-samba-tdbs"
chown root:root backup-samba-tdbs
chmod 0644 backup-samba-tdbs
```
By default, the script runs the `backup_samba_tdbs.sh` utility script daily, at
3:30am.

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
host -t SRV _ldap._tcp.${DOMAIN_FQDN}. ${IP_ADDRESS}
host -t SRV _kerberos._udp.${DOMAIN_FQDN}. ${IP_ADDRESS}
```
Expect to see valid `SRV` records, not errors.
+ As root, run the following:
```
host -t A ${HOSTNAME}.${DOMAIN_FQDN}. ${IP_ADDRESS}
```
Expect to see the DC's `A` record.
+ As root, run the following:
```
host -t NS ${DOMAIN_FQDN}. ${IP_ADDRESS}
host -t A ${DOMAIN_FQDN}. ${IP_ADDRESS}
```
Expect to see the domain's `NS` and `A` records, not errors.

N.B.: The domain must have one `NS` record for every active DC;
there must also be one `A` record for every active DC.
+ As root, run the following:
```
host -t AXFR ${DOMAIN_FQDN}. ${IP_ADDRESS}
host -t AXFR _msdcs.${DOMAIN_FQDN}. ${IP_ADDRESS}
```
Expect to see complete dumps (or "zone transfers") of the two DNS zones.

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

