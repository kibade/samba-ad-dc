Group Policies
==============
*Version 0.7*

- Added Microsoft Office User Policy Guide
- Added Drive Mapping Policy
- Added information regarding Item Level Targeting
- Added section for creating Group Policy Central Store
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

To create a new policy:
---
1.  Run `gpmc.msc` as a Domain Admin user.
2.  Expand the Forest \\ Domains \\ &lt;*School Code*&gt;.ad.sd57.bc.ca
3.  Ensure you are on your primary Domain Controller. Right-click on `SCHOOLCODE.ad.sd57.bc.ca` and click *Change Domain Controller...*. Ensure that the "Current domain controller" is your primary DC. If it's on your secondary DC, and your primary DC is up, we do not believe the SysVol Syncing Script will copy it the other way.
4.  Right-click on the domain, choose "**Create a GPO in this domain, and Link it here…**".
5.  Name the GPO to indicate what section you're in (i.e. "*Default\_Computer*)
6.  After you click <kbd>OK</kbd>, right-click on the new GPO and click **Edit...**. You'll be brought in to the Group Policy Management Editor. Make your changes, then close the window. You settings should apply to the Domain Controller right away.

If you need to see your settings take effect right away (i.e. test workstation), you can run `gpupdate /force` to download the latest GPOs for your session. This command **does not require Admin Privileges**. If that does not work, log off and back on. Finally, try rebooting. If that still does not work, then ensure your computer is talking to the domain controller with the GPOs. If you have dual-domain controllers setup (recommended), you may need to wait for your `cron` job to start and finish to copy the policies to all the domain controllers.

Forest Structure
--- 

*SCHOOLCODE*.ad.sd57.bc.ca  
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

Preferences also differ by Policies in regards to how many times you apply the setting, or what groups/users/items receive it. We will use "Item Level Targeting" to determine which groups received the settings, for example, mapped network drives. Because competing settings will only choose one, this is the simplest way to ensure the proper drives are mounted automatically for each user, depending on their group membership.

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
					- Click on the <kbd>Show Files...</kbd> button
						- Drop the scripts in the folder that appears
						- You may use `.cmd` and `.ps1` scripts
					- <kbd>Add...</kbd>
						- <kbd>Browse...</kbd> and select the script
						- Repeat for other scripts (Wireless, Printer Queue, etc)
						- Ensure you do NOT browse AWAY from this folder!
						- Again, KEEP THE SCRIPTS HERE
		-   Security Settings
			-   Local Policies
				-   Security Options
					-   Block Microsoft Accounts = **Users cannot add or logon with Microsoft Accounts** (**Requires Edu**)
					-   Domain member: Digitally encrypt or sign secure channel data (always) = **Enabled**
					-   Interactive Logon: Do not require CTRL+Alt+Del = **ENABLED**
					-   Interactive Logon: Prompt user to change password before expiration = **14 days**
					-   Microsoft network client: Digitally sign communications (always) = **Enabled**
					-   Microsoft network server: Digitally sign communications (always) = **Enabled**
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
						-   App Runtime
							-   Allow Microsoft Accounts to be optional = **Enabled**
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
						-   OneDrive
							-   Prevent the usage of OneDrive for file storage = **Enable**
							-   Prevent the usage of OneDrive for file storage on Windows 8.1 = **Enable**
						-   Search
							-   Allow Cortana = **Disabled**
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
         -   Microsoft Office 2013
             -   Disable items in User Interface
                 -   Disable commands under File tab | Account = **Enabled**
             -   First Run
                 -   Disable First Run Movie = **Enabled**
                 -   Disable Office First Run on Application Boot = **Enabled**
             -   Miscellaneous
                 -   Block signing into Office = **Enabled**, **None allowed**
                 -   Disable the Office Start screen for all Office applications = **Enabled**
                 -   Show OneDrive Sign In = **Disabled**
                 -   Supress recommended settings dialog = **Enabled**
             -   Privacy
                 -   Trust Center
                     -   Automatically receive small updates to improve reliability = **Enabled**
                     -   Disable Opt-In Wizard on First Run = **Enabled**
                     -   Enable Customer Experience Improvement Program = **Enabled**
                     -   Send Office Feedback = **Disabled**
             -   Telemetry Dashboard
                 -   Turn on telemetry data collection = **Disabled**
         -   Microsoft *Program* 2013
             -   *Program* Options
                 -   Security
                     -   Trust Center
                         -   Trusted Locations
                             -   Allow Trusted Locations on the network = **Enabled**
                             -   Trusted Location #1
                                 -   Path: **\\\\fs1.SCHOOLCODE.ad.sd57.bc.ca**
                                 -   Allow sub folders: **Enabled**
         -   Repeat above for Access, Excel, Powerpoint, Publisher, Word
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

Map\_Network\_Drives
---


-   User configuration
    -   Preferences
        -   Windows Settings
            -   Drive Maps
                -   New-&gt; Mapped Drive
                    -   Action: Create
                    -   Location: \\\\FS1.SCHOOLCODE.ad.sd57.bc.ca\\Staff
                    -   Reconnect: Yes
                    -   Label as: Staff Drive
                    -   Use: S: Drive
                    -   Show this Drive
                    -   Common (tab)
                        -   [x] Item Level Filtering
                        -   <kbd>Targeting...</kbd>
                            -   New Item - Security Group
                            -   <kbd>...</kbd>
                                -   Search for "Staff", and click <kbd>Check Names</kbd>
                                -   <kbd>OK</kbd>
                            -   <kbd>OK</kbd>
                        -   <kbd>OK</kbd>
                -   New-&gt; Mapped Drive
                    -   Action: Create
                    -   Location: \\\\FS1.SCHOOLCODE.ad.sd57.bc.ca\\Office
                    -   Reconnect: Yes
                    -   Label as: Office Drive
                    -   Use: O: Drive
                    -   Show this Drive
                    -   Common (tab)
                        -   [x] Item Level Filtering
                        -   <kbd>Targeting...</kbd>
                            -   New Item - Security Group
                            -   <kbd>...</kbd>
                                -   Search for "Office", and click <kbd>Check Names</kbd>
                                -   <kbd>OK</kbd>
                            -   <kbd>OK</kbd>
                        -   <kbd>OK</kbd>
                -   New-&gt; Mapped Drive
                    -   Action: Create
                    -   Location: \\\\FS1.SCHOOLCODE.ad.sd57.bc.ca\\Hand-in
                    -   Reconnect: Yes
                    -   Label as: Hand-in Folder
                    -   Use: I: Drive
                    -   Show this Drive
               -   New-&gt; Mapped Drive
                    -   Action: Create
                    -   Location: \\\\FS1.SCHOOLCODE.ad.sd57.bc.ca\\Hand-out
                    -   Reconnect: Yes
                    -   Label as: Hand-outs Folder
                    -   Use: J: Drive
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

---

Creating a Group Policy Central Store
---

A Group Policy *Central Store* is where you can have all the group policy definition files (`*.adm{x,l}`) files stored, and be able to use them anywhere in your domain. Applications that support Group Policy settings should come with two files: The `.admx` file that defines the settings; and the `.adml` file that defines the language strings for each setting.

To get setup, you need to first copy your local Group Policy Definitions and Language files to the server. Because of replication being a scheduled one-way job, you will need to force the command to connect to `dc1` (or your primary domain controller). This will assume you are on the latest version of Windows 10, logged in as the Domain Administrator (*Replace `SCHOOLCODE` with your 3-4 character code*):

```
    mkdir \\dc1.SCHOOLCODE.ad.sd57.bc.ca\sysvol\SCHOOLCODE.ad.sd57.bc.ca\Policies\PolicyDefinitions
    robocopy %SystemRoot%\PolicyDefinitions \\dc1.SCHOOLCODE.ad.sd57.bc.ca\sysvol\SCHOOLCODE.ad.sd57.bc.ca\Policies\PolicyDefinitions /s /xo

```

Expect to see around 400 files copied. Open the `PolicyDefinitions` folder on the server in Windows Explorer. Any of the `.ADM[x]` files you receive can go into this folder. Drag any language definition files into your `\PolicyDefinitions\EN-US\` directory on the domain controller.

Examples of Policy Definitions you can download:

- Adobe Reader XI (ftp://ftp.adobe.com/pub/adobe/reader/win/11.x/11.0.00/misc/)
- Adobe Acrobat XI (ftp://ftp.adobe.com/pub/adobe/acrobat/win/11.x/11.0.00/misc/)
- Adobe Reader DC 2017 (Classic Track) (ftp://ftp.adobe.com/pub/adobe/reader/win/Acrobat2017/misc/)
- [Microsoft Office 2016](https://www.microsoft.com/en-ca/download/details.aspx?id=49030)
- [Microsoft Office 2013](https://www.microsoft.com/en-ca/download/details.aspx?id=35554)
