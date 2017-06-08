Windows 10 Installation Guide
=============================
*Version 0.1 - Initial Commit*  
*Version 0.2 - Added SysPrep information (in progress), Download links, expanded instructions*  
&copy; 2017 - School District #57 (Prince George)

TODOs:
-
- SysPrep testing and imaging
- WinEnabler method for creating Default Profile

Introduction:
-
This guide is created for creating your Windows 10 base images. With
Group Policy being its own beast, that will be added in a different
document. This guide assumes that you have the RSAT (Remote Server
Administration Tools) installed, and that you have an Active Directory
Domain Controller at your site.

---

Required Software
-
- Windows 10 {Pro | Edu}
- Windows Automated Installation Kit (SysPrep Method) (WAIK)
	- [Windows 10](https://developer.microsoft.com/en-us/windows/hardware/windows-assessment-deployment-kit) (Use the current version for the update)
	- Whatever is downloaded, ensure you have System Image Manager installed (SIM)
	- You must run the WAIK or ADK setup from Windows 10 - It will NOT WORK in Windows 7 or 8.x
	- UPDATE - It *can* work on Windows 7/8.x - instructions unknown
- [Windows Enabler](https://windows-enabler.en.uptodown.com/windows/download) (WinEnabler Method)
	- Extract to the desktop of the built-in Administrator folder

---

Stage 1 - Installation
======================
-   Wipe hard drive
	-   During Windows Install, on the first screen, press **Shift**+**F10**
	-   Type `DISKPART` and press **Enter**

```
sel dis 0
cle
exi
exit
```

	-   Continue with the installation
-   Install to blank space (partitions will be created automatically)
-   Next steps depend on whether you are using SysPrep or Win Enabler method
Windows Enabler Method
-
- On first reboot
	-   Let's start with region. Is this right? - **Canada**
	-   Is this the right keyboard layout? - **US**
	-   Want to add a second keyboard layout? - **Skip**
	-   Educational Edition
		-   Domain join instead
	-   Who's going to use this PC? - **Xpr0file**
		-   Password - SD57 Standard for your school
		-	Password Hint - SD57 Standard for <SCHOOL>
	-	Make Cortana your personal assistant? - **No**
	-	Choose privacy settings for your device
		-	Location: Off
		-	Diagnostics: Basic
		-	Relevant Ads: Off
		-	Speech recognition: Off
		-	Tailored experiences with diagnostic data: Off
	-   Continue to Stage 2 - Initial Configuration, using this new account

SysPrep Method
-
- On first reboot
    -   Press <kbd>Ctrl</kbd>+<kbd>Shift</kbd>+<kbd>F3</kbd>
    -   Continue with Stage 2 - Initial Configuration
    -   **TODO - Add Answer file configuration**

---

Stage 2 - Initial Configuration
===============================
-   Check all drivers are installed (<kbd>Windows</kbd>+<kbd>X</kbd>, <kbd>M</kbd>)
-   Any programs which can't update on their own should have updates TURNED OFF
-   Internet Explorer and Edge should be available, pinned to taskbar
    -   IE 11 - Accept the defaults. It will be set in Group Policy
-   Install KM Printers as needed
    -   Ensure "Auto" feature is turned off
    -   Can also be deployed via Group Policy, based on staff division. Cannot turn off the Auto feature, or set printer defaults, yet. Recommended to still use the Drive Packages for now.
-   Snipping Tool is accessible
-   Do NOT remove games
-   Turn off System Restore, check Remote Settings
    -   <kbd>Windows</kbd>+<kbd>Pause</kbd>
    -   System Protection
    -   Configure
    -   Disable System Protection
    -   OK
    -   Remote (tab)
    -   Uncheck "Allow Remote Assistance connections to this computer"
    -   Choose if you want Remote Desktop connections (default in Windows is Off)
    -   OK to close the window.
-   Disable automatic System Repair
	-   This is to prevent users from interrupting startup, and gaining SYSTEM privileges
    -   <kbd>Windows</kbd>, `cmd`, <kbd>Ctrl</kbd>+<kbd>Shift</kbd>+<kbd>Enter</kbd> to open the Admin Command Prompt (*NOT Powershell*)
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
	-   Remove un-usable apps
		- Mail
		- Other apps that REQUIRE a Microsoft Account
	-   Set default programs
		- PC Settings -> Apps -> Default Apps
		- Web browser should be Internet Explorer, not Edge. Important for Administrator
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
- Install FOG Client (http://10.Y.30.2/fog/client)
- Install [FirstClass](http://mail.sd57.bc.ca/Clients)
	- Ensure the Settings file created
	- Server name: mail.sd57.bc.ca
- Install a PDF reader (i.e. Adobe Reader XI)
- **Windows Enabler method** - SysPrep method to follow.
	- Restart the computer, and log in as the built in Administrator account
	- Open the System Properties (<kbd>Windows</kbd>+<kbd>X</kbd>, <kbd>Y</kbd>)
	- Go to ???
	- Go to Performance Tab
	- Click on the **Properties** button under *User Profiles*
	- Run the WinEnabler program as an Administrator
	- Right-click on the WinEnabler icon in the System Tray to enable it
	- Click on Xpr0file, and select Copy Profile
	- Copy it over `C:\Users\Default`. Change the Security to allow the "Everyone" group access to the profile, then click **OK**.
	- Reboot the computer, and continue to "Add to Domain"

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
    -   <kbd>Windows</kbd>+<kbd>X</kbd>, <kbd>Y</kbd>
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
---
-   Must remove from Domain to capture image in FOG (?)

SysPrep Method
---
- Create your Answer file in the Windows Automated Installation Kit (WAIK)
	- Generate the Answer File on a "tech machine", not the machine you're attempting to image
	- Download and install the packages listed:
		- Deployment Tools
		- Windows Preinstallation Environment (Windows PE)
		- Configuration Designer
	- Open the **Windows System Image Manager** (WSIM) tool
		- Start->Windows Kits->Windows System Image Manager
	- File->Select Windows Image...
		- Browse to *X:\sources\install.WIM*, replacing the *X:* with the drive letter for the Windows 10 Install file
		- Click on **Yes** to create a catalog file (if prompted)
	- File->Create new Answer file
		- Browse the list of items, and add them as necessary
		- A demo file is available on the Tech Server - GitHub is too public
		- Critical Setting - Ensure "Copy Profile" is set to "True"
			- This copies the built-in Administrator profile to the Default User during SysPrep
- Save the .XML file to a shared drive, and move it to your computer under `C:\Windows\System32\SysPrep\<filename>.XML`
- Open the Administrative Command Prompt (<kbd>Windows</kbd>+<kbd>X</kbd>, <kbd>A</kbd>)
- Navigate to `C:\Windows\System32\SysPrep`
- Execute `sysprep /quiet /generalize /oobe /shutdown /unattend:<filename>.XML`
	- This command will read the XML file (ensure it's done correctly!), and reseal Windows
	- This command will shut down the system
	- On the NEXT BOOT, boot to FOG and grab an image. If Windows boots up (even partially), it will start generating the SIDs that need to be unique to each Windows system. Try, try again. If it's on a VM, save a snapshot BEFORE starting the VM back up, just in case
