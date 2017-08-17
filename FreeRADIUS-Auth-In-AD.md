# How to Get FreeRADIUS to Authenticate Users in Active Directory

__Summary:__
This document describes a sequence of steps intended to configure FreeRADIUS
to authenticate users against an Active Directory (AD) domain.

__Version:__ 3.0

__Updated:__ August 17, 2017

__Change Log:__
+ v.3.0, released August 17, 2017:
  - Modified the Guest Wifi section (download scripts, instead of copy/paste).
+ v.2.1, released August 10, 2017
  - Added Guest Wifi section
  - Added GPO to restrict Guest Wifi user from logging into computers
  - Added scripts for Guest Wifi
+ v.1.1, released July 12, 2017:
  - Added a section to config the wireless controller for MSCHAPv2.
+ v.1.0, released June 24, 2017:
  - Updated the "Get ready to block users ..." section for clarity.
  - Tweaked the formatting of recent additions.
+ v.0.3, released June 13, 2017
  - Added how to block users
+ v.0.2, released June 13, 2017
  - Added "Enable FreeRADIUS to access winbind's privileged socket".
  - Added to "Configure MSCHAP in FreeRADIUS".
  - Added to References.
+ v.0.1, released June 11, 2017:
  - Initial commit, currently just a stub.

__References:__
+ https://wiki.freeradius.org/guide/Active-Directory-direct-via-winbind
+ http://wiki.freeradius.org/guide/freeradius-active-directory-integration-howto

__Assumptions:__
+ FreeRADIUS is installed on a domain member server joined to an AD domain
  via winbind.

---
### Ensure that NTLMv1 authentication is enabled on all DCs
+ Authenticators contacting FreeRADIUS will be using the MSCHAPv2 protocol.
  For technical reasons, this means that FreeRADIUS needs to be able to use
  NTLMv1 protocol for authentication against the AD. However, as of Samba
  v.4.5, unless otherwise configured, the default policy is to reject the
  NTLMv1 protocol.
+ To configure AD DCs to accept NTLMv1 authentication, ensure that the
  following option appears in the `smb.conf` of **all** DCs:
```
[global]
...
        # Allow NTLMv1 auth, for FreeRADIUS/MSCHAPv2 compatibility
        ntlm auth = yes
...
```

---
### Enable FreeRADIUS to access winbind's privileged socket
+ As root, run the following command:
```
adduser freerad winbindd_priv
```
This command adds the `freerad` user to the `winbindd_priv` group, which
grants the FreeRADIUS daemon access to winbind's privileged socket.

---
### Configure MSCHAP in FreeRADIUS
+ Edit __/etc/freeradius/3.0/mods-enabled/mschap__, to uncomment the following
  two options (assume that ${DOMAIN} is the AD short domain name, e.g. "SFG"):
```
mschap {
...
        winbind_username = "%{mschap:User-Name}"
	winbind_domain = "${DOMAIN}"
```
Be certain to replace the placeholder `${DOMAIN}` with its actual value (e.g.
"SFG").

---
### Configure the Wireless Controller to use MSCHAPv2 with RADIUS
+ Login to the wireless controller's administration website.
+ Click on: Home -> Authentication -> Radius Profiles -> Default.
+ In the `Settings` section, set the `Authentication Method` to `MSCHAPv2`.
+ Click `Save`.

---
### Get ready to block users by Username
+ As root, edit __/etc/freeradius/3.0/sites-enabled/default__.
  Search for the `post-auth` stanza (quite long).
  Add the following lines (replacing `ADDOMAINNAME` with your
  short domain name, such as `SFG`):
```
if (User-Name !~ /ADDOMAINNAME\\\\/i) {
        update request {
                User-Name := "ADDOMAINNAME/%{User-Name}"
        }
}
if ((Group == "wifiblocked") ) {
        update reply {
                Reply-Message = "NO %{User-Name} - %{Group}"
        }
        reject
}
```
+ As root, run the following:
```
addgroup wifiblocked
```
This creates a local group named `wifiblocked`.
+ To add users to the `wifiblocked` group, run the following as root:
```
adduser ADDOMAINNAME/username wifiblocked
```
Expect to see (something like) the following:
```
Adding user `ADDOMAINNAME/username' to group `wifiblocked' ...
Adding user ADDOMAINNAME/username to group wifiblocked
Done.
```
+ To remove users from the group, run the following as root:
```
deluser ADDOMAINNAME/username wifiblocked
```
Expect to see (something like) the following:
```
Removing user `ADDOMAINNAME/username' from group `wifiblocked' ...
Done.
```

---
### Enabling Guest Wifi Password
+ On the "master" DC (i.e. the DC that contains the "master" copy of `sysvol`,
  probably `dc1`), run the following, as root:
```
cd /usr/local/sbin/
wget "https://github.com/smonaica/samba-ad-dc/raw/master/scripts/words67.txt"
chown root:root words67.txt
chmod 0640 words67.txt
wget "https://github.com/smonaica/samba-ad-dc/raw/master/scripts/guestwifiaccount.sh"
chown root:root guestwifiaccount.sh
chmod 0750 guestwifiaccount.sh
cd /etc/cron.d/
wget "https://github.com/smonaica/samba-ad-dc/raw/master/scripts/MailWifi"
chown root:root MailWifi
chmod 0644 MailWifi
```
+ Still on the "master" DC, edit the `/etc/aliases` file to append the
following line:
```
guestwifi: infoSCHOOLCODE@sd57.bc.ca
```
Be certain to replace the placeholder `SCHOOLCODE` with its actual 3- or
4-letter code (e.g.: `HHLD` for "Hart Highlands Elementary").
+ In Active Directory Users and Computers (i.e. in the RSAT tool), create
a new user in the domain under the **Users** context, as follows:
  - Username: guestwifi
  - First name: Guestwifi
  - Last name: User
+ Disable this user from logging in locally on workstations, as follows:

Open up the Group Policy Management Console, Edit the Default\_Computer
policy, and add the following setting:

- Computer Configuration
    - Windows Settings
        -   Security Settings
            -   Local Policies
                -   User rights Assignment
                    -   Deny log on locally
                        -   [X] Define these policy settings:
                        -   <kbd>Add User or Group...</kbd>
                            -   Choose your Guest Wifi user, and click <kbd>OK</kbd>
                        -   <kbd>OK</kbd>

Close the window. The "guestwifi" user will not be able to log in to a
workstation, but can still be authenticated with the Wifi Controller through
FreeRADIUS.

---
### Done

