# How to Get FreeRADIUS to Authenticate Users in Active Directory

__Summary:__
This document describes a sequence of steps intended to configure FreeRADIUS
to authenticate users against an Active Directory (AD) domain.

__Version:__ 0.2

__Updated:__ June 13, 2017

__Change Log:__
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
### Done

