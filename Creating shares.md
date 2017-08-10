Creating Base Shares
===
Version 1.00 - Initial Commit (Luke Barone)

Setup Domain Admin Permissions
-
- Grant the required rights to the Domain Admins

`net rpc rights grant "<SCHOOLCODE>\Domain Admins" SeDiskOperatorPrivilege -U "<SCHOOLCODE>\Administrator"` <br />
`net rpc rights grant "<SCHOOLCODE>\Domain Admins" SeSecurityPrivilege -U "<SCHOOLCODE>\Administrator"`

- Add yourself to the Domain Admins group (to be discussed)
	- Log in to Windows with the Domain Administrator account
	- Launch the RSAT Tool Active Directory Users and Computers
	- Navigate to the Users container
	- Find "Domain Admins" in the list
	- Right-click, Properties
	- Members tab
	- Add...
	- Enter your username or full name under the Search
	- Click OK. Changes take effect immediately

Create the folders on the server
-

- Create the home folders base
	- On the server console (as root), create a directory for your school code under `/home`. For example:  
    `mkdir /home/sfg`
    - Change the owner group to the Domain Admins. For example:  
    `chown root:"SFG/Domain Admins" /home/sfg` (take note of the forward slash)
    - Change the permissions for the Owner and Group to have Full Control. For example:
    `chmod 0770 /home/sfg`
    - Edit your `/etc/samba/smb.conf` file to add the share declaration **as below**:  
    `[Users]`  
    `path = /home/sfg`  
    `writeable = yes`
    - Restart Samba (unless you're adding more shares at this time)
    - Continue on Windows
- Create shared folders
	- On the server console (as root), create the directories to share under `/usr/local/share`. For example, `/usr/local/share/Staff`
	- Change the owner group to the Domain Admins. For example: `chown root:"SFG/Domain Admins" /usr/local/share/Staff`
	- Change the permissions for the Owner and Group to have Full Control. For example: `chmod 0770 /usr/local/share/Staff`
	- Edit your `/etc/samba/smb.conf` file to add the share declaration **as below**:  
	`[Staff]`  
    `path = /usr/local/share/Staff`  
    `writeable = yes`
    - Restart Samba (unless you're adding more shares at this time)
    - Continue in Windows

Setting the Windows Permissions
-
- Ensure you have a group setup for the shares. It makes it MUCH easier to later for maintaining the shares
	- Open the RSAT tool ADUC (Active Directory Users and Computers)
	- Expand the forest for your domain, and go to Users
	- Right-click a blank area, select New->Group
	- Name the group, accept the defaults and click OK.
	- Double-click the group, and click the Members tab
	- Search for and add all the users who need to be in the group
	- Click OK
- Open your Computer Management window (Right-click on Computer/This PC, click Manage). Ensure you're logged in as the Domain Administrator.
	- Right-click on the top entry (*Computer Management (Local)*), and click *Connect to another computer...*.
	- Type in your **file server name/IP address** in the box, and click OK
	- Expand System Tools->Shared Folders->Shares
	- Right-click the share, and click on Properties.
		- Share tab should be basic - who has access
		- Security Tab is more fine-tuned - who can delete, rename, etc

Standard Shares/Permissions
-
- Home Folders (User personal folders)
	- We are using "Users" for the example here (as above)
	- Share Permissions
		- Authenticated Users - Change and Read ALLOW
		- Domain Admins - Full Control ALLOW
	- Security
		- Go to Advanced
		- Remove all permissions listed
		- Click on Add for each item (in Windows 10, choose Select a Principal at the top of the new window)
			- Domain Admins - Full Control (This folder, subfolders and files)
			- CREATOR OWNER - Full Control (Subfolders and files only)
			- Authenticated Users - Read & Execute (This folder only)
	- Add the Home Folders for the users
		- Open the ADUC
		- Browse to your list of users
		- Select all the users (if only users, press <kbd>Ctrl</kbd>+<kbd>A</kbd>)
		- Right-click and click Properties
		- Click on Profile
		- `[X] Home Folder`
			- `(o)Connect: H: To: \\fileserver\Users\%USERNAME%`
		- Click on OK. If it went OK, you will see no confirmation. If an error message appears, *read the message* to figure out where to troubleshoot. Don't continue until this works!
- Staff Folder
	- Share Permissions
		- `Staff` - Full Control ALLOW
	- Security
		- ADD `Staff` - Modify, Read & Execute, List folder contents, Read, Write ALLOW (This folder, subfolders and files)
		- ADD `Domain Admins` - Full Control ALLOW (This folder, subfolders and files)

- Yearbook
	- Share Permissions
		- Yearbook - Full Control ALLOW
	- Security
		- Remove all
		- Domain Admins - Full Control ALLOW (This folder, subfolders and files)
		- Yearbook - Modify, Read & Execute, List folder contents, Read, Write ALLOW (This folder, subfolders and files)
- Office
	- Share Permissions
		- Office - Full Control ALLOW
	- Security
		- Domain Admins - Full Control ALLOW (This folder, subfolders and files)
		- Office - Modify, Read & Execute, List folder contents, Read, Write ALLOW (This folder, subfolders and files)
- Hand-out
	- Share Permissions
		- Staff - Change and Read ALLOW
		- Students - Read ALLOW
	- Security
		- Everyone - Read & execute ALLOW (This folder only)
		- Domain Admins - Full Control ALLOW (This folder, subfolders and files)
		- CREATOR OWNER - Full control ALLOW (Subfolders and files only)
		- CREATOR GROUP - Read & execute ALLOW (Subfolders and files only)
		- Staff - Read & execute, Create folders (This folder only)
	- Have each teacher create their own Hand Out folder. Everyone automatically has "Read" access, while the `CREATOR` still has Full Control access
- Hand-in
	- Share Permissions
		- Staff - Change and Read ALLOW
		- Students - Change and Read ALLOW
	- Security
		- Domain Admins - Full control ALLOW (This folder, subfolder and files)
		- Everyone - Read & execute ALLOW (This folder only)
		- CREATOR OWNER - Full control ALLOW (Subfolders and files only)
		- CREATOR GROUP - Read & Execute ALLOW (subfolders and files only)
		- Everyone - Write ALLOW (Subfolders and files only)
		- Staff - Read & execute, Create folders ALLOW (This folder only)
