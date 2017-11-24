NextCloud Installation Guide
==

Version 1.00 - Initial Document by Kiba D

---

## Prerequisites

- Setup Samba Domain
- Add a user to the domain (i.e. "NextCloudAdmin")
- Join Samba file server to the above AD

## Login to the server console

The following steps can be done through SSH or the console session in the VM.

```

    apt-get update
    apt-get install apache2 php7.0 mysql-server libapache2-mod-php7.0 php7.0-zip \
    php7.0-iconv php7.0-gd php7.0-json php7.0-mysql php7.0-curl php7.0-mbstring \
    php7.0-ldap php7.0-dom

```

Due to security changes on MySQL/MariaDB, you can not just use `root` during the NextCloud install; you need to create a user `nextcloud`. In the following commands, replace `'MYSQL_PASSWORD'` with the password you are using for MySQL; replace `NCPASSWORD` with your NextCloud Admin Password (which should be documented and different).

```

    mysql -u root
    USE mysql;
    # skip the next line if you already have mysql with a root password.
    UPDATE user SET password=PASSWORD('MYSQL_PASSWORD') WHERE User='root' AND Host = 'localhost';
    CREATE USER 'nextcloud'@'localhost' IDENTIFIED BY 'NCPASSWORD';
    GRANT ALL PRIVILEGES ON *.* to 'nextcloud’@’localhost’ WITH GRANT OPTION;
    FLUSH PRIVILEGES;

```

Make sure you add your `root` and `NextCloud Admin` password into your FirstClass repos. If you already have MySQL, just make a note of the password you already use, you will need it later.

1.  Download NextCloud
    1.  *[https://nextcloud.com/install](https://nextcloud.com/install/)*
    2.  Unpack the installation file into `/var/www/nextcloud`
    3.  Create and edit `/etc/apache2/sites-available/nextcloud.conf`. Paste the following:
    
    ```
    
          Alias /nextcloud "/var/www/nextcloud/"
          <Directory /var/www/nextcloud/>
              Options +FollowSymlinks
              AllowOverride All
              Satisfy Any
              <IfModule mod_dav.c>
                  Dav off
              </IfModule>
              SetEnv HOME /var/www/nextcloud
              SetEnv HTTP_HOME /var/www/nextcloud
              Satisfy Any
          </Directory>
          
      ```

2.  Enable the site:

        a2ensite nextcloud

3.  Turn on `mod_rewrite`:

        a2enmod rewrite

4.  Additional recommended modules are `mod_headers`, `mod_env`, `mod_dir` and `mod_mime`

        a2enmod headers env dir mime
        service apache2 restart

5. Enabling simple SSL

        a2enmod ssl
        a2ensite default-ssl
        service apache2 reload

6. Create a custom location to store the user data:

```

    mkdir /usr/local/share/nextcloud
    cd /usr/local/share/
    mkdir nextcloud/data
    chown -R www-data:www-data nextcloud
    chmod 0770 -R nextcloud

```

7. Change to ownership temporary for the install only as follows:

       chown -R www-data:www-data /var/www/nextcloud/

8. Goto http://nc1/nextcloud in your web browser to complete the installation.

   - ***Do not login yet***. Click on "Storage & database"
   - Change the `Data folder` to our custom location created in the earlier step `/usr/local/share/nextcloud`
   - Change the `Database user` to `nextcloud`
   - Change the `Database password` to what you assigned for NCPASSWORD above
   - Change the `Database name` to `nextcloud`
   - Under *Create an admin account*:
        - User = `admin`
        - Password = `NCPASSWORD`
   - Now click on finish setup.

Adding external storage e.g. Mount Samba shares
===============================================

-   Login to nextcloud web interface as the NextCloud Admin
-   First delete the default folders and files, we don’t need them.
-   Connect to the server console and run the following command:

        cd /var/www/nextcloud/core/skeleton/

-   Delete all folders and files. If you are brave: `rm -R *`
-   Go back to your browser session
-   Click on the gear in the top left and then click on "Apps", then "Disabled apps"
-   Click enable for "External storage support" and type in the NC admin password if asked.
-   To enable access to AD shares, insert the below just before the last
    closed bracket in the `/var/www/nextcloud/config.php` file:

```

'user_backends' => array (
    0 => array (
        'class' => 'OC_User_SMB',
        'arguments' => array (
            0 => 'localhost'
         ),
    ),
),

```

-   Back to NextCloud as Admin, click on the gear (top right corner) and select "Admin"
-   On the left click on “External Storage”
-   Uncheck the "[ ] Enable User External Storage" box, so users can not add their own external shares.
-   Above the list there is a section to create external drives. Under "Folder name" fill in "Home drive"
-   On the "Add storage" pull down, select "smb/cifs". You should now have an extended list to fill in
-   Change "Username and password" to "Log-in credentials, save in session"
-   Host = `fs1.SCHOOLCODE.ad.sd57.bc.ca` (The host name that holds the users files)
-   Share = `Users` (Note: if you are connecting to a share e.g. classwork, change "users" to "classwork")
-   Remote subfolder = `$users` (for home folders, blank for other shares)
-   Domain = SCHOOLCODE (NetBIOS name for your domain - the part before `.ad.sd57.bc.ca` in your domain name)
-   Repeat for each share you want the user to have access to.

# Block Desktop, Android and IOS Client Access, Only allow web access
- Back to NextCloud as Admin, click on the gear (top right corner) and select "Admin"
- On left click on "File access control

- Click on Add rule group and type "Desktop Client"
- Click on Add rule and select "Request user agent" from the pull down list.
- On the next box to your right select "is" from the pull down list.
- On the next box to your right slect "Desktop Client" from the pull down list.
- Click on Add rule group and type "IOS Client"
- Click on Add rule and select "Request user agent" from the pull down list.
- On the next box to your right select "is" from the pull down list.
- On the next box to your right slect "IOS Client" from the pull down list.
- Click on Add rule group and type "Android Client"
- Click on Add rule and select "Request user agent" from the pull down list.
- On the next box to your right select "is" from the pull down list.
- On the next box to your right slect "Android Client" from the pull down list.

# Increasing upload file limit

-   Edit `/var/www/nextcloud/.htaccess`

```

    php_value upload_max_filesize = 16G
    php_value post_max_size = 16G

```
# Backup

To backup configuration files:

```
        rsync -Aax /var/www/nextcloud/ nextcloud-dirbkp_`date +"%Y%m%d"`/
        mysqldump --lock-tables -h localhost -u nextcloud -pNCPASSWORD nextcloud > nextcloud-sqlbkp_`date +"%Y%m%d"`.bak

```

# Performance improvements

**Memcache**

1. Install `php7-apcu`:

```

    apt-get install php7-apcu

```

2. Edit your `/var/www/nextcloud/config/config.php` file, and add the following line:

```

    'memcache.local' => '\\OC\\Memcache\\APCu',
    
```

# Enabling WebDAV Access on clients

If you wish for your Windows PCs to access their NextCloud folders through a WebDAV share, you need to make a Registry change:

```

Windows Registry Editor Version 5.00

[HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\WebClient\Parameters]
"BasicAuthLevel"=dword:00000002
```

The default value is 1, if you choose to turn it back. Refer to [Microsoft KB841215](https://support.microsoft.com/en-us/help/841215/error-message-when-you-try-to-connect-to-a-windows-sharepoint-document) for more information.

Once this is done, the user is able to connect using clients or their OS. For example, in Windows, the user can run a `net use` command:

```

net use Z: http://nc1.sfg.ad.sd57.bc.ca/nextcloud/remote.php/webdav/ /user:%username% *
```

Note: the address in the example above only works where it can see that URL. We will need a proper URL for external access, which has not been fully set yet.
