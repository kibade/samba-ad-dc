#!/bin/bash
###############################################################################
### VirtualBox VM-creation script
###############################################################################
set -eu

###############################################################################
### Config Variables
###############################################################################

# VM name. Must be unique among the guest VMs.
vm="dc1"

# Guest O/S. Choices include: Debian_64, Windows10_64
os_type="Debian_64"

# Host NIC to bridge with the guest NIC.
host_nic="eno1"

# ISO image to boot from. Use "emptydrive" to leave the CD/DVD drive empty.
boot_iso="$HOME/stretch-mini-amd64.iso"

# RAM size, in mebibytes; e.g.: 2048 == 2G, 4096 == 4G, 8192 == 8G, etc.
ram_mebibytes=2048

# RDP port to connect to on the host to view the VM guest's console.
# Every guest must have a unique port on the host.
console_rdp_port=5011

# Seconds to wait after the host boots before autostarting the VM.
autostart_delay_seconds=60

# Type of virtual HDD to use with this VM. Choices are: vdi, lvm
#   vdi == create a new (or reuse an existing) VDI image file
#   lvm == use a pre-created Logical Volume (LV)
hdd_type="vdi"

# Only relevant when hdd_type is "vdi".
# Size of the virtual HDD image file to create, in mebibytes.
vdi_mebibytes=19074

# Only relevant when hdd_type is "vdi".
# Type of the virtual HDD image file to create. Choices are: fixed, standard
#   fixed == the disk image is a fixed-size (never changing)
#   standard == the disk image grows dynamically as data fills the virtual HDD
vdi_variant="fixed"

# Only relevant when hdd_type is "lvm"
# Full path name of the LV device to be the virtual HDD. It must exist.
lvm_lv_device="/dev/vg0/vm_$vm"

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
## Set up the assumed VirtualBox environment for the current user.
##

vboxmanage setproperty machinefolder   "$HOME/VMs"
vboxmanage setproperty autostartdbpath "/etc/vbox/autostart.d"

##
## Check whether the VM already exists (i.e. is registered, or files exist).
## If so, abort now, to avoid accidentally clobbering an existing VM.
##

uuid=$(vboxmanage list vms | awk -v VM=\"${vm}\" '$1==VM {print $2}')

if [ -n "$uuid" ]; then

	echo
	echo "VM '$vm' is already registered."
	echo
	echo "Script aborted."
	echo
	exit 1
fi

vbox="$HOME/VMs/$vm/${vm}.vbox"

if [ -e "$vbox" ]; then

	echo
	echo "VM '$vm' is not registered, but a configuration state file"
	echo "    already exists for it:"
	echo
	echo "    $vbox"
	echo
	echo "Script aborted."
	echo
	echo "You may want to register the VM manually, with this command:"
	echo
	echo "    vboxmanage registervm \"$vbox\""
	echo
	exit 2

fi

##
## Check the hdd_type and set the disk_file accordingly.
##

case "$hdd_type" in

	"vdi")
		disk_file="${vbox%.vbox}.vdi"
		;;
	"lvm")
		disk_file="${vbox%.vbox}.vmdk"

		if [ ! -r "$lvm_lv_device" ]; then

			echo
			echo "Error: LV '$lvm_lv_device' does not exist, or"
			echo "    it is not readable."
			echo
			echo "Script aborted."
			echo
			exit 3

		fi
		;;
	*)
		echo
		echo "Configuration error: Unknown hdd_type: '$hdd_type'"
		echo
		echo "Script aborted."
		echo
		exit 4
		;;
esac

if [ "${os_type:0:7}" = "Windows" ]; then

##
## Settings specifc to Windows guests.
##

	paravirtprovider="hyperv"
	rtcuseutc="off"
	nictype1="82540EM"

else

##
## Settings for non-Windows (assumed Linux) guests.
##

	paravirtprovider="kvm"
	rtcuseutc="on"
	nictype1="virtio"
fi

echo
echo "Configuring the virtual machine..."
echo

vboxmanage createvm \
	--name "$vm" \
	--ostype "$os_type" \
	--register

vboxmanage modifyvm "$vm" \
	--memory $ram_mebibytes \
	--vram 36 \
	--cpus 2 \
	--pae on \
	--hwvirtex on \
	--paravirtprovider $paravirtprovider \
	--biosapic x2apic \
	--rtcuseutc $rtcuseutc \
	--nictype1 $nictype1 \
	--nic1 bridged \
	--bridgeadapter1 "$host_nic" \
	--macaddress1 "$(random_mac)" \
        --mouse usbtablet \
	--audio none \
	--vrde on \
	--vrdeport $console_rdp_port \
        --vrdereusecon on \
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
	--port 1 \
	--type dvddrive \
	--medium "$boot_iso"

if [ ! -e "$disk_file" ]; then

	echo
	echo "Creating the virtual disk image file..."
	echo

	case "$hdd_type" in

		"vdi")
			vboxmanage createmedium disk \
				--filename "$disk_file" \
				--size      $vdi_mebibytes \
				--variant   $vdi_variant
			;;
		"lvm")
			vboxmanage internalcommands createrawvmdk \
				-filename "$disk_file" \
				-rawdisk  "$lvm_lv_device"
			;;
	esac

else

	echo
	echo "An existing virtual disk file was found:"
	echo
	echo "    $disk_file"
	echo
	echo "This file will be used as the VM's virtual disk image."
	echo

fi

vboxmanage storageattach "$vm" \
	--storagectl SATA \
	--port 0 \
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
echo "    vboxmanage storageattach \"$vm\" --storagectl SATA --port 1 --medium emptydrive"
echo

