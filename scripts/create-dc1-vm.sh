#!/bin/bash
set -eu

###############################################################################
### Config Variables
###############################################################################

vm="dc1"
host_nic="eno1"
boot_iso="$HOME/stretch-mini-amd64.iso"
ram_megabytes=2048
disk_megabytes=20000
console_rdp_port=5011
autostart_delay_seconds=60

###############################################################################
### End of Config Variables
###############################################################################

##
## Function to generate a random MAC address that is both:
## - a unicast address (LSB of first octet is 0)
## - a Locally Administrated Address (2nd LSB of first octet is 1)
##
random_mac () {
	local -a octets
	octets=( $( hexdump -e '1/1 "%02x" 5/1 " %02x"' -n 6 /dev/urandom ) )
	octets[0]=$( printf "%02x" $[ 0x${octets[0]} & 0xfe | 0x02 ] )
	echo "${octets[*]}" | sed 's/ //g'
}

##
## One-time setup commands for the current user. They are shown here
##   commented-out, since they should already have been run.
##
# vboxmanage setproperty machinefolder "$HOME/VMs"
# vboxmanage setproperty autostartdbpath "/etc/vbox/autostart.d"

echo
echo "Configuring the virtual machine..."
echo

vboxmanage createvm \
	--name "$vm" \
	--ostype Debian_64 \
	--register

vboxmanage modifyvm "$vm" \
	--memory $ram_megabytes \
        --vram 12 \
	--cpus 2 \
	--nic1 bridged \
	--nictype1 virtio \
	--bridgeadapter1 "$host_nic" \
	--macaddress1 "$(random_mac)" \
        --mouse usbtablet \
	--audio none \
	--vrde on \
	--vrdeport $console_rdp_port \
        --vrdereusecon on \
	--paravirtprovider kvm \
	--rtcuseutc on \
	--boot1 dvd \
	--boot2 disk \
	--boot3 none \
	--boot4 none \
	--autostart-enabled on \
	--autostart-delay $autostart_delay_seconds

vboxmanage storagectl "$vm" \
	--name SATA \
	--add sata \
	--portcount 2 \
	--hostiocache on

vboxmanage storageattach "$vm" \
	--storagectl SATA \
	--port 0 \
	--type dvddrive \
	--medium "$boot_iso"

echo
echo "Creating the virtual disk image file..."
echo

## Create a fixed-size image file to be the virtual disk.
## Omit the "--variant fixed" option to make it grow dynamically.

disk_file="$HOME/VMs/$vm/$vm.vdi"

vboxmanage createmedium disk \
	--filename "$disk_file" \
	--size $disk_megabytes \
	--variant fixed

## Alternative: Use an LVM logical volume (LV) as the disk medium.
## Requirements for the LV to work in this context:
## - It must already exist.
## - It must must be named "vg0/vm_$vm".
## - It must be fully r/w accessible by vboxuser, which means there
##   needs to be a ".rules" script in /etc/udev/rules.d/ for it.
#
#disk_file="$HOME/VMs/$vm/$vm.vmdk"
#
#vboxmanage internalcommands createrawvmdk \
#	-filename "$disk_file" \
#	-rawdisk "/dev/vg0/vm_$vm"


vboxmanage storageattach "$vm" \
	--storagectl SATA \
	--port 1 \
	--type hdd \
	--medium "$disk_file"

echo
echo "VM \"$vm\" created. Ready for first boot and OS install."
echo
echo "Run this to start the VM:"
echo
echo "    vboxheadless --startvm \"$vm\""
echo
echo "Connect to port $console_rdp_port with an RDP client, and install the OS."
echo
echo "Later, remove the boot iso from the virtual DVD drive, as follows:"
echo
echo "    vboxmanage storageattach \"$vm\" --storagectl SATA --port 0 --medium emptydrive"
echo

