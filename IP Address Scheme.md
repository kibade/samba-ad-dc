SD57 IP Address Standard PROPOSAL
===
Version 1.0 - Initial Commit (LBarone, 2017 May 25)


10.Y.0.0/16 - Use the `Y` codes for your assigned schools. Refer to the Tech Analysts\Projects\NGN\New IPs.xlsx file for your school.


- 10.Y.10.0/24 for the Data network
  - 10.Y.10.1-69 reserved
  - 10.Y.10.70-250 DHCP pool
- 10.Y.40.0/30 for Public Wireless (Should be already done)
- 10.Y.50.0/30 (Should be already done)
- 10.Y.60.0/24 for EM/Sec (Must be coordinated with Maintenance and Security)

Extras if desired

- 10.Y.12.0/24 for the Office
- 10.Y.16.0/24 for the labs
- 10.Y.30.0/24 for DMZ/Servers
  - .1 - File Server
  - .2 - FOG server (VM or physical)
  - .3 - DC1 (VM on File Server)
  - .4 - DC2 (VM on Backup Server)
  - .5 - Backup Server (physical)
- 10.Y.99.0/24 for Management (Switches, controller, PA Management, etc)
  - .69 - Wireless Controller
