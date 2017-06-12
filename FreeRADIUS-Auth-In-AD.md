# How to Get FreeRADIUS to Authenticate Users in Active Directory

__Summary:__
This document describes a sequence of steps intended to configure FreeRADIUS
to authenticate users against an Active Directory (AD) domain.

__Version:__ 0.1

__Updated:__ June 11, 2017

__Change Log:__
+ v.0.1, released June 11, 2017:
  - Initial commit, currently just a stub.

__References:__
+ Still to come...

__Assumptions:__
+ FreeRADIUS is installed on a domain member server joined to an AD domain.

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
### Configure MSCHAP in FreeRADIUS
+ (ADD DETAILS HERE)

---
### Done

