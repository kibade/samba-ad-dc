README
===

Change Log:
+ v.1.1 (S.Monai, July 7, 2017):
  - Added clarification to Steps 4 & 6, explicitly stating the need to create new VMs.
  - Added clarification to Steps 5 & 7, explicitly stating fs1 as the target of the doc.
+ Version 1.00
  - Initial Commit (L.Barone)

Description - Moving forward with Samba AD, you need to do certain things in the correct order. This document will guide you through the process. Please ***DO NOT MOVE ON UNTIL YOU COMPLETE THE PREVIOUS STEPS!***

Preparing to Manage Active Directory
---
1.  Install the RSAT (Remote System Administration Tools) for your version of Windows (NOTE: many policies for Windows 10 require you to login with a Windows 10 Pro or higher machine, and therefore, you need Windows 10 to set the GPs for those machines)
    
    [[Windows 10 RSAT](https://www.microsoft.com/en-us/download/details.aspx?id=45520)] - [[Windows 8.1 RSAT](https://www.microsoft.com/en-ca/download/details.aspx?id=39296)] - [[Windows 7 RSAT](https://www.microsoft.com/en-ca/download/details.aspx?id=7887)]
2. (Windows 7 and 8.x) After installing the above tools, go to the **Control Panel -> Programs and Features -> Turn Windows Features on and off**. Search the list for *Remote Server Administration Tools*, and enable the option. After clicking <kbd>OK</kbd>, you may need to reboot your computer.
3. The tools should be installed under All Programs->Windows Server Admin Tools (Win 10) or Administrative Tools (Win 7/8.x)

Order of Operations:
=
1. [IP Address Scheme](https://github.com/smonaica/samba-ad-dc/blob/master/IP%20Address%20Scheme.md)
	- You need to make sure you have your Address Scheme known, and up to date. Major changes may occur.
	- Map out your current network, and adjust as necessary to move to the correct address range.

2. Setup File Server
	- This is just setting up a server. Use the documentation in the Tech Analyst folder for how to partition the drives, setup RAID, etc. When you get your SSH access, you can move on
	- You will need to know your school's domain name for setting this up correctly the first time
3. [Virtualbox Headless on Debian](https://github.com/smonaica/samba-ad-dc/blob/master/VirtualBox-Headless-on-Debian.md)
	- Required to setup Domain Controllers for File Server to authenticate against
	- Ensure you have enabled Virtual Machine Support turned on in your server's BIOS for speed.
4. [Create AD-DC Samba4](https://github.com/smonaica/samba-ad-dc/blob/master/Create-AD-DC-Samba4.md)
	- FIRST: Create a new VM and install minimal Debian Stretch (64-bit arch) on it.
	- THEN: Follow the instructions in the document linked above.
	- This will setup your first domain controller in your forest
	- Ensure all your tests succeed before continuing on
	- Reboot your host to ensure that the DC VM will start up properly
5. [Add Member Server to Samba4 AD](https://github.com/smonaica/samba-ad-dc/blob/master/Add-Member-Server-to-Samba4-AD.md)
	- Use the document linked above to join the file server `fs1` to the domain.
	- This will get your File Server connecting to the AD for authentication
	- Do not continue until this is complete. We still have the ability to start over until this is completed
	- Once all the tests have passed, move on
6. [Add DC to Samba4 AD](https://github.com/smonaica/samba-ad-dc/blob/master/Add-DC-to-Samba4-AD.md)
	- FIRST: Create a new VM and install minimal Debian Stretch (64-bit arch) on it.
	- THEN: Follow the instructions in the document linked above.
	- This will configure the replication between the two DCs
	- Once replication is working, you will be safe from a single server's failure for authentication and machine accounts (i.e. you won't need to run around to each machine and rejoin them to the domain)
	- Before continuing, ensure your tests pass - including replication and DNS checks.
7. [Creating Shares](https://github.com/smonaica/samba-ad-dc/blob/master/Creating%20shares.md)
	- Use the document linked above on the file server `fs1`.
	- Setup your folder structure on your File Server, and set the correct permissions
	- Do this before creating new Domain users on your network
8. [Group Policy Guide](https://github.com/smonaica/samba-ad-dc/blob/master/Group-Policy-Guide.md)
	- Setup your group policies
	- When computers connect to your domain, they will be further along being setup correctly if this is in place first
9. [Win 10 Install Guide](https://github.com/smonaica/samba-ad-dc/blob/master/Win-10-Install-Guide.md)
	- If using Windows 10, follow the guide. It relies on AD in place, as well as Group Policies being applied
10. FOG Install Guide (to be created)
	- Install FOG to VM
	- Test capturing and deploying with your new Windows 10 Installation
	- Ensure FOG service is running and you can deploy Snapins as required
11. [FreeRADIUS Auth in AD](https://github.com/smonaica/samba-ad-dc/blob/master/FreeRADIUS-Auth-In-AD.md)
	- For Guest-SD57 Wireless Access
