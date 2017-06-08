# Installing VirtualBox for Headless Operation on a Debian Host
__Version:__ 1.0

__Updated:__ June 8, 2017

__Change Log:__
+ v.1.0, released June 8, 2017:
  - Initial release.

__Assumptions:__
+ The Debian host is version 9.0 ("stretch") or newer.
+ The Debian host is running on bare metal (is **not** itself a VM).

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
cd ~
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
Make note of the version of virtualbox-5.1 that is Installed. (In this example,
the version is `5.1.22-115126`.)

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
cat > /etc/vbox/autostart.cfg << EOF1
default_policy = deny
vboxuser = {
  allow = true
}
EOF1
cat > /etc/default/virtualbox << EOF2
VBOXAUTOSTART_DB=/etc/vbox/autostart.d
VBOXAUTOSTART_CONFIG=/etc/vbox/autostart.cfg
EOF2
su -s /bin/bash - vboxuser
```
The last command above opens a new command-line shell running as `vboxuser`.
+ As the `vboxuser` user, run the following commands:
```
vboxmanage setproperty autostartdbpath "/etc/vbox/autostart.d"
exit
```

---
### Install the `virtualbox-guest-vms` helper script
+ As root, run the following:
```
cd /etc/init.d/
rsync -aP tech@duch.sd57.bc.ca:/etc/init.d/virtualbox-guest-vms ./
cd /etc/systemd/system/
rsync -aP tech@duch.sd57.bc.ca:/etc/systemd/system/virtualbox-guest-vms.service ./
systemctl enable virtualbox-guest-vms.service
systemctl start virtualbox-guest-vms.service
```

---
### Create VMs
+ VMs are created using the `vboxuser` account. There are example scripts
  for creating Windows and Debian VMs located on the DUCH main server,
  named __/home/vboxuser/*.sh__.

---
### Done
