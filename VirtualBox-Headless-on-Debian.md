# Installing VirtualBox for Headless Operation on a Debian Host
__Version:__ 3.0

__Updated:__ July 1, 2017

__Change Log:__
+ v.3.0, released July 1, 2017:
  - Updated the "Creating VMs" section, with new info and recommendations.
+ v.2.1, released June 24, 2017:
  - Updated "Configure boot-time VM auto-starting", to make it clearer.
+ v.2.0, released June 24, 2017:
  - Added some Assumptions referring to hardware virtualization.
  - Added "Install and Configure Time Service (NTP) to serve to VM guests".
  - Updated "Creating VMs", telling where to find VM-creation scripts.
  - Updated "Install the ... helper script", to ensure correct owner/perms.
+ v.1.3, released June 8, 2017:
  - Added explanation to "Install the `virtualbox-guest-vms` helper script".
  - Did some minor rewording in a couple of paragraphs.
+ v.1.2, released June 8, 2017:
  - Added "Ensure Debian is fully update" section.
  - Added tests and clarification to "Install the VirtualBox Extension Pack".
  - Added to "Creating VMs" and "Managing VMs" sections.
+ v.1.1, released June 8, 2017:
  - Added "Create VMs" and "Managing VMs" sections.
+ v.1.0, released June 8, 2017:
  - Initial release.

__Assumptions:__
+ The Debian host is version 9.0 ("stretch") or newer.
+ The Debian host is running on bare metal (is **not** itself a VM).
+ The Debian host's processor is capable of hardware virtualization.
+ The Debian host has all hardware virtualization features enabled in its
  system/BIOS setup.

---
### Ensure Debian is fully updated
+ As root, run the following:
```
apt-get update
apt-get dist-upgrade
```
If the latter command upgraded the kernel, then reboot before continuing.

---
### Configure the Debian host server's APT sources
+ As root, run the following:
```
echo "deb http://download.virtualbox.org/virtualbox/debian stretch contrib" \
        > /etc/apt/sources.list.d/virtualbox.list
```

---
### Import the Oracle VirtualBox repo key into the APT keyring
+ As root, run the following:
```
apt-get install ca-certificates
cd
wget "https://www.virtualbox.org/download/oracle_vbox_2016.asc"
gpg --import oracle_vbox_2016.asc
gpg -o oracle_vbox_2016.gpg --export A2F683C52980AECF
cp -p oracle_vbox_2016.gpg /etc/apt/trusted.gpg.d/
apt-get update
```
The last command should update the APT package lists without errors.

---
### Install virtualbox-5.1
+ As root, run the following:
```
apt-get install dkms
apt-get --no-install-recommends install virtualbox-5.1
apt-cache policy virtualbox-5.1
```
The output of the last command above should look (something) like this:
```
virtualbox-5.1:
  Installed: 5.1.22-115126~Debian~stretch
  Candidate: 5.1.22-115126~Debian~stretch
  Version table:
 *** 5.1.22-115126~Debian~stretch 500
        500 http://download.virtualbox.org/virtualbox/debian stretch/contrib amd64 Packages
        100 /var/lib/dpkg/status
```
Make note of the version of `virtualbox-5.1` that is Installed. (In this
example, the version is `5.1.22-115126`.)

---
### Install the VirtualBox Extension Pack
+ Download the VirtualBox Extension Pack from the VirtualBox downloads
  web page (https://www.virtualbox.org/wiki/Downloads). Be certain that the
  Extension Pack's version matches the version of virtualbox-5.1 installed.

  At the time of this writing, the download URL is:
  http://download.virtualbox.org/virtualbox/5.1.22/Oracle_VM_VirtualBox_Extension_Pack-5.1.22-115126.vbox-extpack
+ Assuming the above download URL, run the following as root:
```
wget "http://download.virtualbox.org/virtualbox/5.1.22/Oracle_VM_VirtualBox_Extension_Pack-5.1.22-115126.vbox-extpack"
```
This will create a file named 
`Oracle_VM_VirtualBox_Extension_Pack-5.1.22-115126.vbox-extpack`.
+ If this is an initial install of VirtualBox, then run the following
  command as root:
```
vboxmanage extpack install Oracle_VM_VirtualBox_Extension_Pack-5.1.22-115126.vbox-extpack
```
+ Otherwise, if you are upgrading VirtualBox, run the following as root:
```
vboxmanage extpack install --replace Oracle_VM_VirtualBox_Extension_Pack-5.1.22-115126.vbox-extpack
```
+ In either case, you may be asked whether to accept a long license
  agreement. Of course, you need to answer 'y'.

+ If the `extpack install` command throws errors about "kernel modules", then
  it's possible you are running an out-of-date kernel. Try
  `apt-get update && apt-get dist-upgrade && reboot` before continuing.
+ Check that the extpack installed correctly, by running this as root:
```
vboxmanage list extpacks
```
Expect to see information about the extpack. Expect **not** to see anything
that looks like an error message (otherwise, something has gone wrong, and
VirtualBox probably will not work until fixed).

Example output:
```
Extension Packs: 1
Pack no. 0:   Oracle VM VirtualBox Extension Pack
Version:      5.1.22
Revision:     115126
Edition:
Description:  USB 2.0 and USB 3.0 Host Controller, Host Webcam, VirtualBox RDP, PXE ROM, Disk Encryption, NVMe.
VRDE Module:  VBoxVRDP
Usable:       true 
Why unusable: 
```

---
### Create the user `vboxuser`
+ For security and manageability, create a regular, non-privileged user 
  named `vboxuser` that will own all VirtualBox virtual machine files and
  running processes. As root, run the following:
```
useradd --comment 'VirtualBox User' --home /home/vboxuser --groups vboxusers \
        --shell /bin/false --create-home --user-group  vboxuser
su -s /bin/bash - vboxuser
vboxmanage setproperty machinefolder "$HOME/VMs"
exit
```

---
### Configure boot-time VM auto-starting
+ As root, run the following:
```
mkdir --parents --mode=1775 /etc/vbox/autostart.d
chown root:vboxusers /etc/vbox/autostart.d
touch /etc/vbox/autostart.cfg
touch /etc/default/virtualbox
```
+ Enter the following text into __/etc/vbox/autostart.cfg__:
```
default_policy = deny
vboxuser = {
  allow = true
}
```
+ Enter the following text into __/etc/default/virtualbox__:
```
VBOXAUTOSTART_DB=/etc/vbox/autostart.d
VBOXAUTOSTART_CONFIG=/etc/vbox/autostart.cfg
```
+ As root, run the following:
```
su -s /bin/bash - vboxuser
vboxmanage setproperty autostartdbpath "/etc/vbox/autostart.d"
exit
```

---
### Install the `virtualbox-guest-vms` helper script
+ The `virtualbox-guest-vms` helper script is installed as a service that
  runs at system bootup and shutdown time. The script attempts to ensure
  that VMs are gracefully shut down when the host server shuts down.
  For the script to work correctly, VMs must respond to "ACPI powerbutton"
  events by shutting down gracefully. Recent versions of Debian and Windows
  are capable of that when running as VMs.
+ As root, run the following:
```
cd /etc/init.d/
rsync -aP tech@duch.sd57.bc.ca:/etc/init.d/virtualbox-guest-vms ./
chown root:root virtualbox-guest-vms
chmod 0755 virtualbox-guest-vms
cd /etc/systemd/system/
rsync -aP tech@duch.sd57.bc.ca:/etc/systemd/system/virtualbox-guest-vms.service ./
chown root:root virtualbox-guest-vms.service
chmod 0644 virtualbox-guest-vms.service
systemctl enable virtualbox-guest-vms.service
systemctl start virtualbox-guest-vms.service
```
Note that the `virtualbox-guest-vms` and `virtualbox-guest-vms.service` files
can also be found in the __scripts__ subdirectory of this project's git repo.

---
### Install and Configure Time Service (NTP) to serve to VM guests
+ Virtual guests will require accurate time sources, and the VM host server
  hosting those guests is one logical candidate to serve time to them.
+ Ideally, two or more physical hosts should be arranged into a "mesh"
  or "clique" of time peer servers, and VM guests should list all such
  servers in their own NTP client configurations.
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

tos orphan 5

##
## Upstream time servers
##

server time.sd57.bc.ca iburst burst
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

##
## Peers: Physical hosts running NTP to serve time.
## Connect peers into a mesh (or clique), to improve time quality/stability.
##

peer ${PEER_1}
restrict ${PEER_1} kod limited notrap nomodify noquery

peer ${PEER_2}
restrict ${PEER_2} kod limited notrap nomodify noquery

...

peer ${PEER_N}
restrict ${PEER_N} kod limited notrap nomodify noquery
```
Replace the placeholders `${PEER_1}`, `${PEER_2}`, ..., `${PEER_N}` with
either the IP addresses or the DNS names of the **physical** hosts on the LAN
serving time to clients via NTP.

Each such peer needs to list all other peers in its __/etc/ntp.conf__
file, as demonstrated above, in order to create a mesh network between the
entire clique of peers.

DO NOT include VMs as peers. Only physical hosts should be made peers, since
VMs are almost never stable timekeepers.

---
### Initial setup is done

---
### Creating VMs
+ VMs are created **exclusively** using the `vboxuser` account.
+ Reminder: To open a shell running as the `vboxuser` user, run the
  following as root:
```
su -s /bin/bash - vboxuser
```
+ It is strongly recommended that the following script be used to create
  Debian and Windows VMs:

https://github.com/smonaica/samba-ad-dc/raw/master/scripts/create-virtualbox-vm.sh

+ How to use the `create-virtualbox-vm.sh` script:
  - Assumption: You want to create a VM named `thing`.
  - Put a copy of the script in `/home/vboxuser/`, and rename the copy
    `create-thing-vm.sh`.
  - Configure `create-thing-vm.sh` by editing the Config Variables
    section (at the top of the script).

+ More about the Config Variables in `create-virtualbox-vm.sh`:
  - `vm` is the name of the VM, and must be unique on the VM host.
  - `console_rdp_port` is the port number to which RDP clients
    connect to view the VM's console. It must be unique on the VM host.
    The recommended range of ports to use is 5000-6000.
  - `autostart_delay_seconds` should be configured so that VMs get
    auto-started one-at-a-time at VM host boot-time, with a 15- or
    30-second delay between each VM.

+ Advanced use of the `create-virtualbox-vm.sh` script:
  - Instead of creating an image file for a VM, it is possible to use
    an LVM LV (logical volume) for a VM's virtual disk. Steps to take
    to do this:
    - One time setup step: Copy the `99-virtualbox-lv.rules` script
      to `/etc/udev/rules.d/`. The script can be found here:

https://github.com/smonaica/samba-ad-dc/raw/master/scripts/99-virtualbox-lv.rules

    - Note that the `.rules` script assumes your LVM Volume Group
      is named `vg0`. If it's not, then you will need to replace
      all instances of `vg0` in the script with your VG's name.

    - IMPORTANT NOTE: VG and LV names are CASE-SENSITIVE!

    - Create an LV for the VM, by running this (assuming you want
      to create an LV of size 20G, for a VM named `thing`, in
      the VG named `vg0`):
```
lvcreate -n vm_thing -L 20G vg0
```
    - In your `create-thing-vm.sh` script, comment-out the command
      that begins with `vboxmanage createmedium`, and uncomment the
      command that begins with `vboxmanage internalcommands`
      immediately below it.

    - Configure the `create-thing-vm.sh` script as usual. In this
      instance, you can ignore the `disk_mebibytes` and `disk_variant`
      variables, since they are not relevant when using a pre-created
      LV for the VM's virtual disk.

    - Finally, run `create-thing-vm.sh` to create the VM.

---
### Managing VMs
+ VM management is done **exclusively** as the `vboxuser` user. Only in the
  most dire circumstances should the `root` user be needed to intervene
  (typically to kill a VM process that refuses to terminate normally,
  which should be a very rare occurrence).
+ Reminder: To open a shell running as the `vboxuser` user, run the
  following as root:
```
su -s /bin/bash - vboxuser
```
__The remaining examples must be run as the user `vboxuser`.__
+ List all VMs:
```
vboxmanage list vms
```
+ List all **running** VMs:
```
vboxmanage list runningvms
```
+ Tell a VM (named `my-vm`) to shut down gracefully:
```
vboxmanage controlvm "my-vm" acpipowerbutton
```
The above may not work in rare VMs that don't respond to "ACPI powerbutton"
events (all recent Debian and Windows versions should).
+ Force poweroff a VM (named `my-vm`):
```
vboxmanage controlvm "my-vm" poweroff
```
+ Start a VM (named `my-vm`):
```
nohup setsid vboxheadless --startvm "my-vm" </dev/null >&/dev/null
```
+ Permanently delete a VM (named `my-vm`) and its virtual disk file(s)
  (NOTE: there is no confirmation prompt; the VM is deleted immediately!):
```
vboxmanage unregistervm "my-vm" --delete
```

