#!/bin/bash
set -eu

###############################################################################
### Config Variables
###############################################################################

vm="dc2"
host_nic="eno1"
boot_iso="$HOME/mini.iso"
ram_megabytes=1024
disk_megabytes=20000
console_rdp_port=5012
autostart_delay_seconds=120

###############################################################################
### End of Config Variables
###############################################################################

disk_vdi="$HOME/VMs/$vm/$vm.vmdk"

echo
echo "Configuring the virtual machine..."
echo

vboxmanage createvm \
	--name "$vm" \
	--ostype Debian_64 \
	--register

vboxmanage modifyvm "$vm" \
	--memory $ram_megabytes \
	--cpus 2 \
        --vram 12 \
	--nic1 bridged \
	--nictype1 virtio \
	--bridgeadapter1 "$host_nic" \
        --mouse usbtablet \
	--audio none \
	--vrde on \
	--vrdeport $console_rdp_port \
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

# Example of using an LVM logical volume (/dev/vg0/vm_dc2)
# as the disk medium:
vboxmanage internalcommands createrawvmdk \
	-filename "$disk_vdi" \
	-rawdisk /dev/vg0/vm_dc2

vboxmanage storageattach "$vm" \
	--storagectl SATA \
	--port 1 \
	--type hdd \
	--medium "$disk_vdi"

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

