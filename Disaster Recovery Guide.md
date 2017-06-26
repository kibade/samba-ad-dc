Disaster Recovery Guide for Active Directory sites
===

Version 1.00 - Luke B

Assumptions:
-
- Both DC1 and DC2 are offline, not expected to wake up
	- ***DO NOT CONTINUE*** if either Domain Controllers will come back online. *You have been warned!*
- Homer has a backup of your DC2 VBox image and settings
- The backup is less than 180 days old (Tombstone Lifetime)
- RSync is installed
- A new File Server has been setup and created, via Server Standards
	- Includes VirtualBox Setup
	- Static IP assigned as .1, DNS to .3 and .4

---

First off, **do not panic**. You have prepared for this moment, and you need to be *relaxed* to follow the instructions closely. Techs have tested the crap out of these instructions to verify they work. As long as you were doing backups like we told you to do, you'll be fine! So breath! Print out these instructions if you wish, and push through!

The first real action you should be taking is to contact Ming and Morris at the board office to prepare the Homer backups for restoring. Let them know that you will contact them once you have your File Server (AKA your VBox Host) up and running - we don't care about the files yet, they will come later.

From the Document Listing, follow the following steps in order:

1. **Setup File Server** - Ensure you have a BASE Linux Install, with `rsync` and a text editor installed. Include the instructions for setting up DHCP, and hand out the District DNS servers to the clients.
2. **Virtualbox Headless Setup** - We need to get the Virtualbox Hypervisor available.
3. At this point, follow the instructions below to get your backed-up Domain Controller (dc2) online:
	1. Contact Morris and/or Ming to `rsync` your DC's image to your newly built server. Place the files in `/home/vboxuser/`, recreating the exact folder struture you had before.
	2. Ensure that file permissions are correct. All the files within `vboxuser` are owned by both the user and group, `vboxuser`, with full permissions.
	3. Login as `vboxuser`, using the `su - -s/bin/bash vboxuser` command as `root`. Your bash prompt should change itself to be a dollar sign (`$`), and the username should read `vboxuser`.
	4. Run `vboxmanage list vms`. Ensure you see dc2-vm listed. If you do, run it by executing `vboxheadless --startvm "dc2-vm"`. This will tell you what port the VRDP port is, and you can connect using that port with Remote Desktop.
	5. Verify that you can connect to the Domain Controller with your tech laptop. You should test Active Directory Users and Computers, and Group Policies at the minimum. If not, troubleshoot until this step is completed.
	6. Seize the roles. Log in to the current DC's `root` session, and execute the following commands:
	    
     ```

        samba-tool fsmo transfer --role=all      # This will take a while...
        samba-tool fsmo show     # Check the roles have been seized successfully
        ldbsearch -H /var/lib/samba/private/sam.ldb '(invocationId=*)' --cross-ncs objectguid | grep -A1 DC1    # Get the IP Address, DNS Hostname and GUID
        samba-tool domain demote --remove-other-dead-server=DC1
        rm /etc/cron.d/ad-sysvol-replication
        samba-tool ntacl sysvolreset    # Check for errors
        samba-tool ntacl sysvolcheck
     ```
    7. Edit `/etc/resolv.conf`, and make sure it has the following three lines in it:
    
    ```

        domain SCHOOLCODE.ad.sd57.bc.ca
        search SCHOOLCODE.ad.sd57.bc.ca
        nameserver 10.YY.10.4
    ```

    8. Run through the **Checks** sections on the Create-AD-DC document.
    9. Download and execute the following script: `wget https://github.com/smonaica/samba-ad-dc/blob/master/scripts/ug-dump.sh -O /root/ug-dump.sh`. This will list all the users and groups, and ensure the idmap is up to date. Run `tdbbackup -s .bak /var/lib/samba/private/idmap.ldb` to create `idmap.ldb.bak` *after* running the above script.

4. **Add DC to Samba4 AD** - This will get your replication going again. When following the document, remember to substitude `dc2` with `dc3` - Your DC2 is going to be your main Domain Controller, and this needs to also be **updated in the First Class School Repository**. When replication has started/is working, continue on.

    DC3 will take the old DC1's IP address, which will likely be 10.YY.10.4. Update as necessary, but leave DC2's IP address as-is.
5. **Add Member Server to Samba4 AD** - This will get your VBox Host (aka FS1) connected as a computer, and then you can start restoring its backups from Homer (again, coordinate with Ming and/or Morris). When restoring, **do not import the `/etc/samba/smb.conf` file directly into your working setup**.
  
    You will need to open your **currently-running** `smb.conf` file in one window (i.e. Notepad++ on your tech laptop), then move over the shares from your backup `smb.conf` file. Use your human-intervention to ensure that the parameters line up with what need to be there for this server.

6. **Creating Shares**. Your `/etc/samba/smb.conf` file should be updated and recreated. Since you had Morris/Ming copy your files from Homer already, the files should be available. Ensure the shared folders are in the correct location as per your `smb.conf` file. Before bring samba back online, run `testparm` to ensure there are no errors.
7. **FreeRADIUS Auth in AD** - Get your Guest Wi-Fi up and running.
