Maintenance List for Active Directory
===

Version 1.00 - Initial Commit

**Description**: Active Directory works great when  it is well-maintained. While we do not have Powershell access to the domain, we still need to ensure that it is cared for, like a growing tree in a small forest.

Connecting to Active Directory with RSAT Tools
-

As found out, you can run the RSAT tools, even from a non-domain-joined computer.

1. Open the Command Prompt (or Powershell) As Administrator (<kbd>Windows</kbd>+<kbd>X</kbd>, <kbd>A</kbd>)
2. Ensure your DNS server addresses are pointed to the Domain Controllers (`10.YY.10.3` and `10.YY.10.4`)
3. Execute `runas /netonly /user:DOMAIN\USERNAME mmc` - replacing your DOMAIN and USERNAME with a Domain Administrator account.
4. Assuming MMC launches, you should be able to load your RSAT tools for that site. If you did not save a custom layout, you can access them as per below (from `%WINDIR%\System32`):

 >  - **Active Directory Users and Computers** - `dsa.msc`
 - **Group Policy Management Console** - `gpmc.msc`
 - **DNS** - `dnsmgmt.msc`
 - **Shared Folders** - `fsmgmt.msc`
 - **Printer Management** - `printmanagement.msc`

5. When you open them, you may get messages about not being able to connect to the Domain Servers. You can right-click on the top level for each snap-in, and choose `Connect to domain...`. Type in your Domain Name (`SCHOOLCODE.ad.sd57.bc.ca`).
6. To ensure you're working on your Master Domain Controller, right-click the domain and choose `Connect to Domain Controller...`. Ensure you are working on your main Domain Controller that feeds the rest of the controllers on your network.
7. Ensure you close the Command Prompt / Powershell windows when you are done, as they will still have your login credentials available to them.

Daily tasks:
-

Weekly tasks:
-
- Ensure replication between all Domain Controllers is occuring
	- On your primary DC (`dc1`) as `root`, run the following: `samba-tool drs showrepl` Expect to see `INBOUND NEIGHBORS` with recent last attempts and no consecutive failures. Also expect to see `OUTBOUND NEIGHBORS` with last attempts `@ NTTIME(0)` and no consecutive failures. Optionally, `grep` the output to look for `"consecutive failure"` - you should see lots of zeroes. Option two is to `echo $?` to show the error level - if it's 0, you're good to go!
	- If this fails, double check that DNS is resolving DC1 and DC2's hostname, the domain hostname, as well as the IP addresses.
- Review disk space
	- On each Domain Controller, execute `df -h` as root. Ensure you have lots of free space on your `/` partition.
	- On each file server, execute `df -h` as root. Ensure you have lots of free space where required.
	- To view the size in folders, sorted from lowest to highest, execute `du -h -d 1 $1 | sort -h`, replacing `$1` with the folder to check (i.e. `/home/sfg`). The largest folders are on the bottom.
- Run your Samba upgrades
	- Run on DC1 first. If the upgrade goes well, and Samba comes back up, run the upgrade on DC 2
	- Once both Domain Controllers are active and syncing again, attempt the upgrade on your File Server when usage is low/non-existent. To check how used your file server is, execute as root `smbstatus`. If no one is using it, feel free to run the upgrade. You may choose to run the upgrade after hours though.
	- Remember to schedule reboots when new Linux Kernels get downloaded and installed

Monthly tasks:
-
- Check your DNS server entries
	- Old computer names should be removed
	- Ensure you have your DC and File Server entries with both A records (in Forward Lookup Zone), as well as PTR records (in Reverse Lookup Zone), pointing to the correct location
	- Ensure you have a CNAME entry in the Forward Lookup Zone for "fogserver", pointing to "fog"
	- Check that your DNS forwarder is still set to the SD57 Name Server (`199.175.16.2`)

Yearly tasks:
-
- Clear out any old student and staff accounts.
	- If you are unsure of the status of a user, you should **DISABLE** the account instead of deleting it.
- Check for elevated accounts
	- Open your Active Directory Users and Computers program (`dsa.msc`)
	- Expand your forest, then your domain, then Users
	- Open the built-in groups and ensure you recognize all the accounts listed for:
		- Domain Admins
		- Enterprise Admins
		- Schema Admins
	- Remove user accounts who should not be in here.
- Check group memberships are accurate
	- Staff users should ALL be in the Staff group, and the Staff OU
	- Student accounts (if not wiping each year) should be in the Student OU and group.
	- Clear out the Yearbook group of any student accounts