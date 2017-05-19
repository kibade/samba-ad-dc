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
- Attempt to deploy a package with PDQ Deploy (Using local admin)
- Attempt to Inventory with PDQ (Using local admin)
	- You can try using the script located at 
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
