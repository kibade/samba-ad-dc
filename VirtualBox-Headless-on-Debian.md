# Installing VirtualBox for Headless Operation on a Debian Host
__Version:__ 4.0

__Updated:__ July 9, 2017

__Change Log:__
+ v.4.0, released July 9, 2017:
  - Updated the "Time Service (NTP)" section, to use the new doc.
  - Updated the "virtualbox-guest-vms helper" section, to point to the repo.
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
wget "https://github.com/smonaica/samba-ad-dc/raw/master/scripts/virtualbox-guest-vms"
chown root:root virtualbox-guest-vms
chmod 0755 virtualbox-guest-vms
cd /etc/systemd/system/
wget "https://github.com/smonaica/samba-ad-dc/raw/master/scripts/virtualbox-guest-vms.service"
chown root:root virtualbox-guest-vms.service
chmod 0644 virtualbox-guest-vms.service
systemctl enable virtualbox-guest-vms.service
systemctl start virtualbox-guest-vms.service
systemctl status virtualbox-guest-vms.service
```
The last command above should report that the service is `active (exited)`.

---
### Install and Configure Time Service (NTP) to serve to VM guests
+ Virtual guests will require accurate time sources, and the VM host server
  hosting those guests is one logical candidate to serve time to them.
+ Ideally, two or more physical hosts should be arranged into a "mesh"
  or "clique" of time peer servers, and VM guests should list all such
  servers in their own NTP client configurations.
+ Configure the NTP service on this server by following the instructions
  described in the following document:
https://github.com/smonaica/samba-ad-dc/blob/master/NTP-Configuration.md

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
  - Run `create-thing-vm.sh` to create the VM.

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
    an LVM LV (logical volume) for a VM's virtual disk.
    The following are the steps to take to accomplish this.
  - One time setup step: Copy the `99-virtualbox-lv.rules` script
    to `/etc/udev/rules.d/`. The script can be found here:
    https://github.com/smonaica/samba-ad-dc/raw/master/scripts/99-virtualbox-lv.rules
  - Note that the `.rules` script assumes your LVM Volume Group
    is named `vg0`. If it's not, then you will need to replace
    all instances of `vg0` in the script with your VG's name.
  - IMPORTANT NOTE: VG and LV names are CASE-SENSITIVE!
  - Create an LV for the VM, by running this (assuming you want
    to create an LV of size 20G, for a VM named `thing`, in
    the VG named `vg0`):  `lvcreate -n vm_thing -L 20G vg0`
  - Configure the `create-thing-vm.sh` script as usual, but
    set the `hdd_type="lvm"` and `lvm_lv_device="/dev/vg0/vm_$vm"`.
    You can ignore the `vdi_mebibytes` and `vdi_variant` variables,
    since they are not relevant when using `hdd_type="lvm"`.
  - Run `create-thing-vm.sh` to create the VM.

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

