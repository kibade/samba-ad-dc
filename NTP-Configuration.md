# NTP (Network Time Protocol) Configuration

__Summary:__
This document describes the configuration of the NTP service on a Debian
linux server, version 9.0 ("stretch") or newer.

__Version:__ 1.0

__Updated:__ July 9, 2017

__Change Log:__
+ v.1.0, released July 9, 2017:
  - Initial commit.

---
### Ensure the `ntp` package is installed
+ As root, run the following:
```
apt-get update
apt-get install ntp
```

---
### Common NTP configuration
+ Replace the entire content of __/etc/ntp.conf__ with the following:
```
##
## Server control options
##

driftfile /var/lib/ntp/ntp.drift
statsdir /var/log/ntpstats/

statistics loopstats peerstats clockstats
filegen loopstats  file loopstats  type day enable
filegen peerstats  file peerstats  type day enable
filegen clockstats file clockstats type day enable

tos orphan 7

##
## Upstream time servers
##

server time.sd57.bc.ca iburst burst
server pool.ntp.org iburst burst
pool 0.pool.ntp.org iburst burst
pool 1.pool.ntp.org iburst burst
pool 2.pool.ntp.org iburst burst
pool 3.pool.ntp.org iburst burst

##
## Access control lists
##

# Base case: Exchange time with all, but disallow configuration or peering.
restrict default kod limited notrap nomodify noquery nopeer

# To allow pool discovery, apply same rules as base case, but do allow peering.
restrict source kod limited notrap nomodify noquery

# Allow localhost full control over the time service.
restrict 127.0.0.1
restrict ::1
```

---
### Domain-Controller-only configuration
+ Only perform this step if this server is a Domain Controller (DC)
  for Active Directory.
+ Add the following line to the **end** of the "Server control options"
  section of __/etc/ntp.conf__:
```
ntpsigndsocket /var/lib/samba/ntp_signd/
```
+ Add the following lines to the **bottom** of __/etc/ntp.conf__:
```
# Provide AD signed time sync to the local LAN
restrict ${NET_ADDRESS} mask ${SUBNET_MASK} kod limited notrap nomodify noquery nopeer mssntp
```
Be certain to replace the placeholders `${NET_ADDRESS}` and `${SUBNET_MASK}`
with their actual values. `${NET_ADDRESS}` is the LAN's network address
(e.g. `10.45.10.0`), and `${SUBNET_MASK}` is the LAN's subnet mask
(e.g. `255.255.254.0`).

---
### VM-only configuration
+ Only perform this step if this server is a VM.
+ Add the following line to the **top** of the "Server control options"
  section of __/etc/ntp.conf__:
```
tinker panic 0
```
+ Identify all **physical** servers (**not** VMs) at the local site that
  are running (or are planned to be running) NTP servers for the network. 
+ Configure all such NTP servers as time **servers** for the VM (i.e. with
  the VM as a **client**.)
+ Example: Assume there are two physical NTP servers running on the LAN,
  as follows:
  - `fs1` (the main file server) and
  - `bu1` (the backups server).
+ With the above assumptions, you would insert the following lines into the
  **top** of the "Upstream time servers" section of __/etc/ntp.conf__:
```
server fs1 iburst burst
server bu1 iburst burst
```

---
### Physical-server-only configuration
+ Only perform this step if this server is a **physical** server (**not** a
  VM).
+ Append the following lines to the end of __/etc/ntp.conf__:
```
##
## Peers: Physical hosts running NTP to serve time.
## Connect peers into a mesh (or clique), to improve time quality/stability.
##
```
+ Identify all **physical** servers (**not including** this server) at the
  local site that are running (or are planned to be running) NTP servers
  for the network.
+ Configure all such NTP servers as **peers** to this server.
+ Example: Assume that this server is `fs1`, and that there is one other
  physical server on the LAN, named `bu1`.
+ With the above assumptions, you would append the following lines to the
  end of __/etc/ntp.conf__ on this physical server:
```
peer bu1
restrict bu1 kod limited notrap nomodify noquery
```
This configures `bu1` as a peer of this server. (Of course, `fs1` will also
be configured as a peer of the `bu1` server, by appending the analgous lines
to __/etc/ntp.conf__ on `bu1`. But that is done when `bu1` is configured,
not now.)
+ Essentially, all physical servers running NTP at a site will name all the
  other physical servers at the same site as peers in their respective
  __/etc/ntp.conf__ files.

---
### Restart NTP, and verify it is running
+ As root, run the following:
```
systemctl stop ntp
systemctl start ntp
systemctl status ntp
```
The last command should state that the service is `active (running)`.
Otherwise, there is likely some error in __/etc/ntp.conf__ that needs to
be corrected.

---
### Done

