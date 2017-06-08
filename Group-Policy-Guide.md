Group Policies
==============
*Version 0.3*

- Create Starter GPO for Firewall rules
	- Windows Firewall rules have been MOVED
- Added notes from Samba about Password Policy
- Added samba-tool settings for Default Password Policies*  

&copy; 2017 - School District #57 (Prince George)

---
These settings should be created on the domain controller, then have the
Cron Job setup to `rsync` the primary to the secondary controllers. You
will need to make sure your AD Structure is setup properly to start. We
will be setting 6 policies - User configurations and Computer
configurations, for Everyone, Staff, and Students.

Default\_Computer and Default\_User will apply to everyone. The Computer
settings will follow the computers wherever they are, whereas User
settings will follow the specific users logging in. If settings are not
applying, ensure that you are setting the right types of
polices/preferences in the right area.

Samba recommends a few certain items in regards to Group Policy with Samba:

- Password policies do NOT get set via Group Policy. Use `samba-tool` instead to set it.
- Do not adjust the Default Domain Policy. It must be left at its default.

Preparing to Manage Group Policies
---
1.  Install the RSAT (Remote System Administration Tools) for your version of Windows (NOTE: many policies for Windows 10 require you to login with a Windows 10 Pro or higher machine, and therefore, you need Windows 10 to set the GPs for those machines)
    
    [[Windows 10 RSAT](https://www.microsoft.com/en-us/download/details.aspx?id=45520)] - [[Windows 8.1 RSAT](https://www.microsoft.com/en-ca/download/details.aspx?id=39296)] - [[Windows 7 RSAT](https://www.microsoft.com/en-ca/download/details.aspx?id=7887)]
2. (Windows 7 and 8.x) After installing the above tools, go to the **Control Panel -> Programs and Features -> Turn Windows Features on and off**. Search the list for *Remote Server Administration Tools*, and enable the option. After clicking <kbd>OK</kbd>, you may need to reboot your computer.
3. The tools should be installed under All Programs->Windows Server Admin Tools (Win 10) or Administrative Tools (Win 7/8.x)

To create a new policy:
---
1.  Run `gpmc.msc` as a Domain Admin user.
2.  Expand the Forest \\ Domains \\ &lt;*School Code*&gt;.ad.sd57.bc.ca
3.  Ensure you are on your primary Domain Controller. Right-click on `SCHOOLCODE.ad.sd57.bc.ca` and click *Change Domain Controller...*. Ensure that the "Current domain controller" is your primary DC. If it's on your secondary DC, and your primary DC is up, we do not believe the SysVol Syncing Script will copy it the other way.
4.  Right-click on the domain, choose "**Create a GPO in this domain, and
    Link it here…**".
5.  Name the GPO to indicate what section you're in (i.e.
    "*Default\_Computer*)
6.  After you click <kbd>OK</kbd>, right-click on the new GPO and click **Edit...**. You'll be brought in to the Group Policy Management Editor. Make your changes, then close the window. You settings should apply to the Domain Controller right away.

If you need to see your settings take effect right away (i.e. test workstation), you can run `gpupdate /force` to download the latest GPOs for your session. This command **does not require Admin Privileges**. If that does not work, log off and back on. Finally, try rebooting. If that still does not work, then ensure your computer is talking to the domain controller with the GPOs. If you have dual-domain controllers setup (recommended), you may need to wait for your `cron` job to start and finish to copy the policies to all the domain controllers.

Forest Structure
--- 
| -- Users  
| -- Computers  
| -- Domain Controllers  
| -- Staff  
.... | -- Staff\_Users  
.... | -- Staff\_Computers  
| -- Student  
.... | -- Student\_Users  
.... | -- Student\_Computers  

On each of the OUs (i.e. containers) above, you can apply Group Policy Objects (GPOs) to those groups. Apply the **Default\_Computer** and **Default\_User** policies to the Forest level (the local domain - ***&lt;schoolcode&gt;*.ad.sd57.bc.ca**). Under the extra OUs you create, attach policies for those areas.

The Group Policies will work from the top down, until it finds the User logged in, and the Computer logged in. GPOs from the server will run first, then the Local Group Policy will take effect on settings (the ones created with `gpedit.msc` on the local workstations). As of now, we will NOT be setting Local Group Policies on workstations, once Active Directory is setup and working. This will help prevent conflicts, and trying to find out where "different" settings are coming from.

With the forest structure, this will make it easier to "target" GPOs to different groups. After the structure has been created, you are free to fill it in with more OUs as you require for your site. We will want to work on keeping the 'Users' and 'Computers' container as *clean as possible*. Active Directory relies heavily on being maintained to keep it working well.

Policies vs Preferences
---
When you create a new GPO, you'll see two main sections under Computer or User Configuration: **Policies** and **Preferences**. Policies are *mandated* settings that are not to be changed. The programs that support Group Policy will not allow these settings to be changed within their respected programs if a policy is in place. This includes for Administrators.

Preferences are *preferred* and can be chosen to be policy or preference. For example, in the *Folder Options* window, you can specify certain settings that are set and *cannot be changed later*. The options can be chosen using the <kbd>F5</kbd> to <kbd>F8</kbd> keys. When the color is red/white the setting will not be able to be changed by the end users. In other words, you disable the option completely from being edited, but you still assign what value belongs there.

- <kbd>F5</kbd> activates all the options you see. Turning every option Green
- <kbd>F6</kbd> activates only the chosen setting. Turning it green (you can use TAB to choose or click it with your mouse)
- <kbd>F7</kbd> Disables only the chosen setting. Turning the color to red/white
- <kbd>F8</kbd> Disables all the settings. Turning every option into red/white

Starter GPOs
-
These policies are default "good configurations" that Microsoft recommends. Right-click "Group Policy Remote Update Firewall Ports" GPO, and click *New GPO from Starter GPO...*, name it "Firewall Policy", then link it to the top level (`SCHOOLCODE.ad.sd57.bc.ca`). 

The Windows Firewall policies that used to exist below are no longer available.

The Policies to Apply
---

**Default\_Computer**

- Computer Configuration
  - Policies
     - Windows Settings
	     - Scripts (Startup/Shutdown)
		     - Startup
					- <kbd>Show Files...</kbd>
						- Drop the scripts in the folder that appears
					- <kbd>Add...</kbd>
						- <kbd>Browse...</kbd> and select the script
						- Repeat for other scripts (Wireless, Printer Queue, etc)
						- Ensure you do NOT browse AWAY from this folder!
						- Again, KEEP THE SCRIPTS HERE
         -   Security Settings
                 -   Local Policies
                     -   Security Options
                         -   Block Microsoft Accounts = **Users cannot add or logon with Microsoft Accounts** (**Requires Edu**)
                         -   Interactive Logon: Do not require CTRL+Alt+Del = **ENABLED**
                         -   Interactive Logon: Prompt user to change password before expiration = **14 days**
                         -   User Account Control: Behavior of the elevation prompt for administrators in Admin Approval Mode = **Elevate Without Prompting**
                         -   User Account Control: Behavior of the elevation prompt for standard users = **Prompt for Credentials**
                 -   Network List Manager Policies
                     -   &lt;*SCHOOL CODE*&gt;.ad.sd57.bc.ca
                         -   Name: **School District \#57 (Prince George) - &lt;School Code&gt;**
                         -   User permissions: **User cannot change the name**
                 -   System Services
                     -   Windows Media Player Network Sharing Service = **Disabled**
  -   Administrative Templates
     -   Control Panel
         -   User Accounts
             -   Apply the default account picture to all users = **ENABLED**
         -   Network
             -   Network Connections
                 -   Do not show the "Local Access Only" network icon = **Enabled**
             -   Offline Files
                 -   Allow or Disallow use of the Offline Files feature = **DISABLE**
         -   Printers
             -   Allow Printers to be Published = **DISABLE**
         -   System
             -   Enable Windows NTP Server
	             -   Windows Time Service
    	             -   Time Providers
    	                 -   Configure Windows NTP client = **ENABLE,NTPServer=SCHOOLCODE.ad.sd57.bc.ca,Type=NTP**
    	                 -   Enable Windows NTP client = **ENABLE**
             -   Logon
                 -   Show first sign-in animation = **Disable**
                 -   Turn off Windows Startup sound = **Enable** (Windows 7 only)
             -   Recovery
                 -   Allow restore of system to default state = **Disabled** (Win 7 only)
             -   Remote Assistance
                 -   Solicited Remote Assistance = **DISABLE**
             -   Scripts
	             -   Run logon scripts synchronously = **Enabled**
	             -   Run startup scripts asynchronously = **Enabled**
             -   System Restore
                 -   Turn Off System Restore = **ENABLE**
             -   User Profiles
                 -   Only Allow Local User Profiles = **ENABLE**
                 -   Turn off the advertising ID = **Enable**
         -   Windows Components
             -   Add Features to Windows 10
                 -   Prevent the wizard from running = **Enabled**
             -   AutoPlay Policies
	             -   Turn off Autoplay = **Enabled, Turn off Autoplay on CD-ROM and removable media drives**
             -   Cloud Content
                 -   Do not show Windows tips = **Enabled**
                 -   Turn off Microsoft Consumer Experiences = **Enabled**
             -   Data Collection and Preview Builds
                 -   Allow Telemetry = **Enabled, 0 (Educational Edition Only)**
                 -   Disable pre-release features or settings = **Disabled**
                 -   Do not show feedback notifications = **Enabled**
                 -   Toggle user control over Inside builds = **Disabled**
             -   Desktop Gadgets
                 -   Turn off desktop gadgets = **ENABLE** (Windows 7 only)
             -   Edge UI
                 -   Disable help tips = **Enabled**
             -   File Explorer
                 -   Do not show the 'new application installed' notification = **Enabled**
             -   HomeGroup
                 -   Prevent the Computer from joining a HomeGroup = **ENABLE**
             -   Internet Explorer
                 -   Prevent running First Run wizard = **ENABLE**
                 -   Make proxy settings per-machine = **ENABLE**
             -   Microsoft Accounts
	             -   Block all consumer Microsoft account user authentication = **Enabled**
             -   Microsoft Edge
	             -   Configure Start pages = **Enabled, `<https://www.sd57.bc.ca/school/SCHOOLCODE/Pages/default.aspx>`** (*Use the angle brackets*)
	             -   Disable lockdown of Start pages = **Enabled**
	             -   Keep favorites in sync between Internet Explorer and Microsoft Edge = **Enabled**
	             -   Prevent the First Run webpage from opening on Microsoft Edge = **Enabled**
             -   OneDrive (**Education Only**)
                 -   Prevent the usage of OneDrive for file storage = **Enable**
                 -   Prevent the usage of OneDrive for file storage on Windows 8.1 = **Enable**
             -   Store (**Education only**)
                 -   Turn off the Store application = **Enabled**
             -   Sync your settings
                 -   Do not sync = **Enabled**
             -   Windows Anytime Upgrade (Windows 7 only - Windows 10 option above matches this entry)
                 -   Prevent Windows Anytime Upgrade from running = **ENABLE**
             -   Windows customer experience improvement program
                 -   Allow corporate redirection of Customer Experience Improvement uploads = **DISABLE**
             -   Windows Error Reporting
                 -   Configure Error Reporting = **DISABLE**
             -   Windows Mail
                 -   Turn off Windows Mail application = **ENABLE**
             -   Windows Media Center
                 -   Do not allow Windows Media Center to run = **ENABLE**
             -   Windows Media Player
                 -   Do not show first use dialog boxes = **ENABLE**
             -   Windows Messenger
                 -   Do not allow Windows Messenger to be run = **ENABLE**
             -   Windows UPDATE
                 -   Configure Automatic Updates = **4: Auto download and schedule the install; Install during automatic maintenance; 4: Every Wednesday; 15:00; Install updates for other Microsoft products**
             -   Delay Restart for scheduled installations = **ENABLED, 5 minutes**
             -   Allow non-administrators to receive update notifications = **ENABLED**

Default\_user
-------------
-   User Configuration
 -   Policies
     -   Software Settings
     -   Windows Settings
     -   Administrative Templates
         -   Control Panel
             -   Personalization
                 -   Enable screen saver = **ENABLE**
                 -   Screen Saver Timeout = **300 seconds**
                 -   Force specific screen saver = **ssText3d.scr**
             -   Printers
                 -   Browse the network to find printers = **Disabled**
             -   Start Menu and Taskbar
                 -   Turn off feature advertisement balloon notifications = **Enabled**
 -   Preferences
     -   Control Panel Settings
         -   Folder Options
             -   New -&gt; Folder Options (At least Windows Vista)
                 -   Always show menus
                 -   UNCHECK Hide extensions for known file types
                 -   Hide protected operating system files (Recommended)
                 -   Launch folder windows in a separate process
                 -   UNCHECK Use Sharing Wizard (Recommended)
         -   Internet Settings
             -   New-&gt;Internet Explorer 10 Properties
                 -   General
                     -   Home page: https://www.sd57.bc.ca/school/&lt;SCHOOLCODE&gt;/Pages/default.aspx
                     -   Start with home page
         		-   Connections
            	 -   LAN Settings
            	     -   UNCHECK Automatically detect settings­
         -   Start Menu
             -   New -&gt; Start Menu (At least Windows Vista)
                 -   Computer -&gt; Display as Link
                 -   Games -&gt; Do not display this item
                 -   *UNCHECK* Highlight newly installed programs
                 -   Music -&gt; Do not display this item


Staff\_Users\_Policy
---

-   User Configuration
    -   Policies
        -   Administrative Templates
            -   Control Panel
                -   Personalization
                    -   Password protect the screen save = **Enabled**
    -   Preferences
        -   Windows Settings
            -   Drive Maps
                -   New-&gt; Mapped Drive
                    -   Action: Create
                    -   Location: \\\\FS1\\Staff
                    -   Reconnect: Yes
                    -   Label as: Staff Drive
                    -   Use: S: Drive
                    -   Show this Drive


Password Policy on Server
===

To show the password policies, log in to the Domain Controller as root and execute `samba-tool domain passwordsettings show`. You'll see output like below:

    Password informations for domain 'DC=SCHOOLCODE,DC=ad,DC=sd57,DC=bc,DC=ca'
    
    Password complexity: on
    Store plaintext passwords: off
    Password history length: 24
    Minimum password length: 7
    Minimum password age (days): 1
    Maximum password age (days): 42
    Account lockout duration (mins): 30
    Account lockout threshold (attempts): 0
    Reset account lockout after (mins): 30
    

Recommended settings:

    Password complexity: on
    Store plaintext passwords: off
    Password history length: 1 *
    Minimum password length: 8 *
    Minimum password age (days): 1
    Maximum password age (days): 400 *
    Account lockout duration (mins): 30
    Account lockout threshold (attempts): 0
    Reset account lockout after (mins): 30

Items with an asterisk (`*`) are the recommended policies to set. To change settings:

    samba-tool domain passwordsettings set <setting>=<value>
    
    --complexity={ on* | off }
    --store-plaintext={ on | off* }
    --history-length=<integer>
    --min-pwd-length=<integer>
    --min-pwd-age=<integer>
    --max-pwd-age=<integer>
    --account-lockout-duration=<integer>
    --account-lockout-threshold=<integer>
    --reset-account-lockout-after=<integer>
    
To view a full help of the commands, execute `samba-tool domain passwordsettings set --help` as root.
