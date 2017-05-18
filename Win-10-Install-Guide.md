Windows 10 Installation Guide
=============================
*Version 0.1 - Initial Commit*  
&copy; 2017 - School District #57 (Prince George)

This guide is created for creating your Windows 10 base images. With
Group Policy being its own beast, that will be added in a different
document. This guide assumes that you have the RSAT (Remote Server
Administration Tools) installed, and that you have an Active Directory
Domain Controller at your site.

Stage 1 - Installation
======================
-   Wipe hard drive
	-   During Windows Install, on the first screen, press **Shift**+**F10**
	-   Type `DISKPART` and press **Enter**
	-   `sel dis 0`
	-   `cle`
	-   `exi`
	-   `exit`
	-   Continue with the installation
-   Install to blank space (partitions will be created automatically)
-   On first reboot (non-sysprep version)
-   Get Going Fast
    -   Customize
        -   Off for all (page 1 and 2)
        -   On for all (page 3 - Browser Protection and Update)
    -   Create an account for this PC
        -   Xpr0file
        -   Password: Let's Pick for your school
    -   Cortana
        -   Disable
    -   Join a domain later
-   On first reboot (SysPrep version)
    -   Press **Ctrl**+**Shift**+**F3**
    -   **TODO - Add Answer file configuration**

Stage 2 - Initial Configuration
===============================
-   Check all drivers are installed (**Windows**+**X**, **Device Manager**)
-   Any programs which can't update on their own should have updates TURNED OFF
-   Internet Explorer and Edge should be available, pinned to taskbar
    -   IE 11 - Accept the defaults. It will be set in Group Policy
-   Install KM Printers as needed
    -   Ensure "Auto" feature is turned off
    -   Can also be deployed via Group Policy, based on staff division. Cannot turn off the Auto feature, or set printer defaults, yet. Recommended to still use the Drive Packages for now.
-   Snipping Tool is accessible
-   Do NOT remove games
-   Turn off System Restore, check Remote Settings
    -   **Windows**+**X**, **Y**
    -   System Protection
    -   Configure
    -   Disable System Protection
    -   OK
    -   Remote (tab)
    -   Uncheck "Allow Remote Assistance connections to this computer"
    -   Choose if you want Remote Desktop connections (default in
        Windows is Off)
    -   OK to close the window.
-   Disable automatic System Repair
	-   This is to prevent users from interrupting startup, and gaining SYSTEM privileges
    -   **Windows**+**X**, **A** to open the Admin Command Prompt (or Powershell)
    -   `bcdedit /set {current} recoveryenabled No`
    -   `bcdedit /set {current} bootstatuspolicy ignoreallfailures`
-   Customization of the OS
    -   Activate Windows (even if you're in Audit Mode…) -.-
        -   **Windows**+**X**, **A**
        -   `slmgr /ipk &lt;Product Key here&gt;`
        -   `slmgr /ato`
    -   Right-click on Desktop -&gt;Personalize-&gt;Themes-&gt;Desktop
        icon settings
        -   Computer
        -   User's Files
        -   Recycle Bin
    -   Pin IE and Edge to taskbar
    -   Remove other icons from Start Menu that you don't want
    -   Remove Microsoft OneDrive
        -   **Windows**+**X**, **F**
        -   Remove Microsoft OneDrive
    -   Taskbar Settings (Right-click Taskbar -&gt; Settings)
        -   Notification Area
            -   Select which icons appear on the taskbar
                -   Always show all icons in the notification area -&gt;
                    ON
    -   Start
        -   Occasionally show suggestions in Start -&gt; OFF
        -   Show recently added apps -&gt; OFF
        -   Choose which folders appear on Start
            -   File Explorer
            -   Documents
            -   Personal Folder
    -   Lock Screen
        -   Setup as per your school standard
    -   Open File Explorer (**Windows**+**E**)
        -   View -&gt; Options
            -   View (NOTE: Set in Group Policy as well)
                -   Always show menus
                -   Show hidden files, folders and drives
                -   UNCHECK Hide extensions for known file types
                -   Launch folder windows in a separate process
                -   UNCHECK Use Sharing Wizard (Recommended)
            -   Search
                -   UNCHECK Include system directories
    -   Windows Firewall with Advanced Security (Admin Tools)
        -   Inbound Rules
            -   File and Printer Sharing (Echo Request - ICMPv3-In)
               (Domain) - Enable
            -   File and Printer Sharing (Echo Request - ICMPv3-In)
                (Private) - Enable
    -   Control Panel -&gt; Power Options
        -   High Performance -&gt; Change settings
            -   Turn off display after 15 minutes
            -   Enable wake timers
            -   Power buttons and lid \\ Power button action \\ Power
                button = Shut down
            -   Processor power management \\ Minimum processor state \\
                On battery = 50
Install Applications
---
- Ensure at least one other browser is available (such as Mozilla Firefox or Google Chrome)
	- Ensure homepages are set to school's home page in other browsers
	- Group Policy should take care of IE and Edge's homepage
- Install AVG 2016. Ensure the Remote Admin points to your Remote Admin Console station
- Install Microsoft Office.
	- Optional: Add Microsoft Office Group Policy objects to Samba server
	- Disable first-run wizard
- Install Windows Updates
- Install FOG Client (http://
- Install [FirstClass](http://mail.sd57.bc.ca/Clients)
	- Ensure the Settings file created
	- Server name: mail.sd57.bc.ca
- Install a PDF reader (i.e. Adobe Reader XI)

Add to Domain
---
-   This assumes you have Group Policies enabled and setup already on
    the Domain Controllers
-   Ensure network access is enabled, and it's set to Private
    -   **Windows**+**E**, choose "Network" from the address bar
    -   **Enable file and printer sharing** (info bar at top of window)
    -   **No, make this network a private network**
-   Change computer name (need to verify if Fog does this perfectly or
    not)
    -   **Windows**+**X**, **Y**
    -   Change Settings (under **Computer name, domain and workgroup
        settings**)
    -   Click on **Change**
    -   Enter the computer name, and the domain name (&lt;school
        code&gt;.ad.sd57.bc.ca). Press OK
    -   Enter a Domain Admin's username and password (remember to use
        &lt;SCHOOL CODE&gt;\\Username formatting), then press OK.
    -   If it works, you will see the Welcome message. Press **OK**, then
        let the computer reboot

Remove from domain
-   Must remove from Domain to capture image in FOG (?)

Group Policies
==============

These settings should be created on the domain controller, then have the
Cron Job setup to rsync the primary to the secondary controllers. You
will need to make sure your AD Structure is setup properly to start. We
will be setting 6 policies - User configurations and Computer
configurations, for Everyone, Staff, and Students.

Default\_Computer and Default\_User will apply to everyone. The Computer
settings will follow the computers wherever they are, whereas User
settings will follow the specific users logging in. If settings are not
applying, ensure that you are setting the right types of
polices/preferences in the right area.

To create a new policy:

1.  Install the RSAT (Remote System Administration Tools) for your
    version of Windows (NOTE: many policies for Windows 10 require you
    to login with a Windows 10 Pro or higher machine, and therefore, you
    need Windows 10 to set the GPs for those machines)
    
    [Windows 10 RSAT](https://www.microsoft.com/en-us/download/details.aspx?id=45520)  
    [Windows 8.1 RSAT](https://www.microsoft.com/en-ca/download/details.aspx?id=39296)  
    [Windows 7 RSAT](https://www.microsoft.com/en-ca/download/details.aspx?id=7887)
2. After installing the above tools, go to the **Control Panel -> Programs and Features -> Turn Windows Features on and off**. Search the list for *Remote Server Administration Tools*, and enable the option. After clicking OK, you may need to reboot your computer.
3.  Run `gpmc.msc` as a Domain Admin user.
4.  Expand the Forest \\ Domains \\ &lt;*School Code*&gt;.ad.sd57.bc.ca
5.  Right-click on the domain, choose "**Create a GPO in this domain, and
    Link it here…**".
6.  Name the GPO to indicate what section you're in (i.e.
    "*Default\_Computer*)
7.  After you click <kbd>OK</kbd>, you'll be brought in to the Group Policy
    Management Editor. Make your changes, then close the window. You
    settings should apply to the Domain Controller right away.

Forest  
 | -- Users  
 | -- Computers  
 | -- Domain Controllers  
 | -- Staff  
..... | -- Staff\_Users  
.... | -- Staff\_Computers  
 | -- Students  
.... | -- Student\_Users  
.... | -- Student\_Computers  

**Default\_Computer**

- Computer Configuration
  - Policies
     - Windows Settings
         -   Security Settings
             -   Account Policies
                 -   Password Policies - TODO: Staff Only
                     -   Enforce Password History - **3 passwords**
                     -   Maximum Password Age - **400 days**
                     -   Minimum Password Age - **30 days**
                     -   Password must meet complexity requirements - **Enabled**
                     -   Store passwords using reversible encryption - **Disabled**
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
             -   Windows Firewall
                 -   Domain Profile
                     -   Allow ICMP exceptions = **Enabled, Allow inbound echo requests**
                     -   Allow inbound remote administration exceptions = **Enabled, localsubnet**
             -   Offline Files
                 -   Allow or Disallow use of the Offline Files feature = **DISABLE**
             -   Printers
                 -   Allow Printers to be Published = **DISABLE**
         -   System
             -   Logon
                 -   Show first sign-in animation = **Disable**
                 -   Turn off Windows Startup sound = **Enable**
             -   Recovery
                 -   Allow restore of system to default state = **Disabled** (Win 7 only)
             -   Remote Assistance
                 -   Solicited Remote Assistance = **DISABLE**
             -   System Restore
                 -   Turn Off System Restore = **ENABLE**
             -   User Profiles
                 -   Only Allow Local User Profiles = **ENABLE**
                 -   Turn off the advertising ID = **Enable**
             -   Windows Time Service
                 -   Time Providers
                     -   Configure Windows NTP client = **ENABLE,NTPServer=SCHOOLCODE.ad.sd57.bc.ca,Type=NTP**
                     -   Enable Windows NTP client = **ENABLE**
         -   Windows Components
             -   Add Features to Windows 10
                 -   Prevent the wizard from running = **Enabled**
             -   Cloud Content
                 -   Do not show Windows tips = **Enabled**
                 -   Turn off Microsoft Consumer Experiences = **Enabled**
             -   Data Collection and Preview Builds
                 -   Allow Telemetry = **Enabled, 0 (Educational Edition Only)**
                 -   Disable pre-release features or settings = **Disabled**
                 -   Do not show feedback notifications = **Enabled**
                 -   Toggle user control over Inside builds = **Disabled**
             -   Desktop Gadgets
                 -   Turn off desktop gadgets = **ENABLE**
             -   Edge UI
                 -   Disable help tips = **Enabled**
             -   File Explorer
                 -   Do not show the 'new application installed' notification = **Enabled**
             -   HomeGroup
                 -   Prevent the Computer from joining a HomeGroup = **ENABLE**
             -   Internet Explorer
                 -   Prevent running First Run wizard = **ENABLE**
                 -   Make proxy settings per-machine = **ENABLE**
             -   OneDrive (**Education Only**)
                 -   Prevent the usage of OneDrive for file storage = **Enable**
                 -   Prevent the usage of OneDrive for file storage on Windows 8.1 = **Enable**
             -   Store (**Education only**)
                 -   Turn off the Store application = **Enabled**
             -   Sync your settings
                 -   Do not sync = **Enabled**
             -   Windows Anytime Upgrade
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
-   Preferences
 -   Control Panel Settings
     -   Local Users and Groups
         -   Administrator:
             -   Update
             -   Administrator (built-in)
             -   User cannot change password
             -   Password never expires
             -   Account never expires
         -   Guest:
             -   Update
             -   Guest (built-in)
             -   Account is disabled

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
                     -   Press **F5** to allow user to change settings (outlined with Green)
                     -   Home page: https://www.sd57.bc.ca/school/<SCHOOLCODE>/Pages/default.aspx
                     -   Start with home page
         -   Connections
             -   LAN Settings
                 -   UNCHECK Automatically detect settings­
         -   Start Menu
             -   New -&gt; Start Menu (At least Windows Vista)
                 -   Computer -&gt; Display as Link
                 -   Games -&gt; Do not display this item
                 -   UNCHECK Highlight newly installed programs
                 -   Music -&gt; Do not display this item

Staff\_Users\_Policy
--------------------

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
                    -   Location:
                    -   Reconnect: Yes
                    -   Label as: Staff Drive
                    -   Use: S: Drive
                    -   Show this Drive
