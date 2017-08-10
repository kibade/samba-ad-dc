# How to Get FreeRADIUS to Authenticate Users in Active Directory

__Summary:__
This document describes a sequence of steps intended to configure FreeRADIUS
to authenticate users against an Active Directory (AD) domain.

__Version:__ 2.1

__Updated:__ August 10, 2017

__Change Log:__
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
Expect to see (something) like the following:
```
Adding user `ADDOMAINNAME/username' to group `wifiblocked' ...
Adding user ADDOMAINNAME/username to group wifiblocked
Done.
```
+ To remove users from the group, run the following as root:
```
deluser ADDOMAINNAME/username wifiblocked
```
Expect to see (something) like the following:
```
Removing user `ADDOMAINNAME/username' from group `wifiblocked' ...
Done.
```

Enabling Guest Wifi Password
---

On the DC1 system, create the following script under `/usr/local/sbin/guestwifiaccount.sh`:

```
#!/bin/bash
set -eu

# Pick a password at random from the passcodes list.
p=`shuf -n1 < /usr/local/sbin/passcodes.txt`

# Set guest password to the chosen password.
samba-tool user setpassword --filter=samaccountname=guestwifi --newpassword=$p -U Administrator

date=`date +"%A, %b %d, %Y"`

msg="Below is the account and password for the Guest-SD57 wireless network \
as of $date:

Username:               guestwifi
Password:               $p
"

echo "$msg" | mailx -s "$date: Public Wireless" guestwifi

exit 0
```

Create a password list, and save it under `/usr/local/sbin/passcodes.txt`. Due to Active Directory requiring stronger passwords than we're used to, I recommend going to [Random.ORG Password Generator](https://www.random.org/passwords/?num=100&len=8&format=plain&rnd=new). This link will constantly change the passwords presented each time you click it.

Create the `/etc/cron.d/MailWifi` script, containing:

```
# Executes guestwifiaccount.sh @2:50am Mon to Friday
PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
50 2 * * 1-5 root  /usr/local/sbin/guestwifiaccount.sh >/dev/null
```

Enable execution on the script:

```
chmod +x /usr/local/sbin/guestwifiaccount.sh
```

Edit your `/etc/aliases` file to append the following line:

```
guestwifi: infoSCHOOLCODE@sd57.bc.ca
```

In your Active Directory Users and Computers, create a new user in your domain under the **Users** context called "guestwifi". You can use whatever first name and last name, as long as the username is "guestwifi". To disable this user from logging in locally on workstations, you need to open up the Group Policy Management Console.

Edit your Default\_Computer policy, and add the following setting:

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

Once you close the window, that user will not be able to log in to a workstation, but can still be authenticated with the Wifi Controller through FreeRADIUS.

---
### Done

