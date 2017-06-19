Installing FOG on Debian Stretch
===

Version 1.00 - Initial Commit

Prerequisites
-
- File server setup with Virtualbox
- Stretch ISO saved to VBoxUser's home directory
- 250 GB of free spare on `/home`
- FOG is version 1.4.3 - Check on FOG's site for the latest version, update as required.

VM Setup
-
- Create a new VM
	- 250 GB Virtual Hard Drive
	- 2   GB of RAM
	- Disk image living in `/home/vboxuser/` folder structure
- Install Debian Stretch.
	- Add proxy settings (for `apt-cacher-ng`)
	- Install as little as possible for package
	- No RAID in the VM
- Install required packages to prepare
	- As root, execute `apt-get update && apt-get install ssh ca-certificates vim`
	- Ensure you can SSH from your workstation before continuing
	- Set a static IP address for the server (FOG standard IP is 10.YY.10.2)
	- Ensure you can connect by name and IP address.
- Get the latest FOG software
	- As root, go into your tech folder (`/home/tech`)
	- As root, execute `wget https://downloads.sourceforge.net/project/freeghost/FOG/fog_1.4.3/fog_1.4.3.tar.gz`
	- As root, execute `tar xzf ./fog_1.4.3.tar.gz`. This should create a folder called `fog_1.4.3`.
	- As root, enter the `/home/tech/fog_1.4.3/bin` directory
	- As root, execute `./installfog.sh`
		- Debian based system
		- Normal install (not storage)
		- Configure DHCP
		- DNS with DHCP
		- DO NOT USE FOG to handle DNS and DHCP
		- Y to continue
	- When prompted, go to `http://10.YY.10.2/fog/management` in your web browser. This will update or install the database for this version of FOG.
		- If not updates will need to be applied, the page you log in to will take you to the FOG dashboard
		- Once the Database Upgrade / Install completes, go back to your SSH session, and press <kbd>Enter</kbd>. Setup continues.

Create the DNS entries
-
- Using Windows RSAT tools:
	- Open DNS Manager
	- Navigate to `DNS\dc1\Forward Lookup Zones\<SCHOOLCODE>.ad.sd57.bc.ca` on the left side
	- Right-click on a blank area on the right, choose **New Host (A or AAAA)...**
		- Name: `fog`
		- IP Address: `10.YY.10.2` (adjust your YY code)
		- [X] Create associated pointer (PTR) record
		- [ ] Allow any authenticated user to update DNS records with the same owner name
		- **Add Host**
	- Right-click a blank area on the right, choose **New Alias (CNAME)...**
		- Alias name: `fogserver`
		- FQDN for target host: `fog.SCHOOLCODE.ad.sd57.bc.ca` (adjust your SCHOOLCODE)
		- [ ] Allow any authenticated user to update all DNS records with the same name
		- **OK**
- Using `samba-tool` on the Domain Controller
	- As root, execute the lines below, substituting you SCHOOLCODE and YY code as necessary:	
    
```

    samba-tool dns add localhost SCHOOLCODE.ad.sd57.bc.ca fog A 10.YY.10.2 -UAdministrator
    samba-tool dns add localhost SCHOOLCODE.ad.sd57.bc.ca fogserver CNAME fog.SCHOOLCODE.ad.sd57.bc.ca -UAdministrator
    samba-tool dns add localhost 10.YY.10.in-addr.arpa 2 PTR fog.SCHOOLCODE.ad.sd57.bc.ca -UAdministrator

```

   - Your zones should be updated. Check your DNS output for errors, replacing SCHOOLCODE and YY as necessary:

```

    samba-tool dns query localhost SCHOOLCODE.ad.sd57.bc.ca fog A -UAdministrator
    samba-tool dns query localhost SCHOOLCODE.ad.sd57.bc.ca fogserver CNAME -UAdministrator
    samba-tool dns query localhost 10.YY.10.in-addr.arpa 2 PTR -UAdministrator
    host fog
    host fogserver
    host 10.YY.10.2
```

Add images to FOG
-
