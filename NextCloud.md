NextCloud Installation Guide
==

Version 1.00 - Initial Document by Kiba D

---

#Server side:

##Prerequisites

- Setup Samba Domain
- Add a user to the domain (i.e. "NextCloudAdmin")
- Join Samba file server to the above AD

##Login to the server console

```

    apt-get update
    apt-get install apache2 php7.0 mysql-server libapache2-mod-php7.0 php7.0-zip php7.0-iconv php7.0-gd php7.0-json php7.0-mysql php7.0-curl php7.0-mbstring php5-ldap php7.0-dom

```

 Due to security changes on MySQL/MariaDB, you can not just use root
 during the NextCloud install; you need to create a user `nextcloud`. In the following commands, replace `'MYSQL_PASSWORD'` with the password you are using for MySQL; replace `NCPASSWORD` with your NextCloud Admin Password.

```

    mysql -u root
    USE mysql;
    ##skip the next line if you already have mysql with a root password.
    UPDATE user SET password=PASSWORD('MYSQL_PASSWORD') WHERE User='root' AND Host = 'localhost';
    CREATE USER 'nextcloud'@'localhost' IDENTIFIED BY 'NCPASSWORD';
    GRANT ALL PRIVILEGES ON *.* to 'nextcloud’@’localhost’ WITH GRANT OPTION;
    FLUSH PRIVILEGES;

```

 Make sure you add your root and NextCloud Admin password into your FirstClass repos. If you already have MySQL, just make a note of the password you already use, you will need it later.

1.  Download NextCloud
    1.  [*https://nextcloud.com/install/*](https://nextcloud.com/install/)
    2.  Unpack the installation file into `/var/www/nextcloud`
    3.  Create and edit `/etc/apache2/sites-available/nextcloud.conf`. Paste the following:
    >     Alias /nextcloud "/var/www/nextcloud/"
    >     <Directory /var/www/nextcloud/>
    >         Options +FollowSymlinks
    >         AllowOverride All
    >         Satisfy Any
    >         <IfModule mod_dav.c>
    >             Dav off
    >         </IfModule>
    >         SetEnv HOME /var/www/nextcloud
    >         SetEnv HTTP_HOME /var/www/nextcloud
    >         Satisfy Any
    >     </Directory&gt;

2.  Create symbolic link

    ln -s /etc/apache2/sites-available/nextcloud.conf
    /etc/apache2/sites-enabled/nextcloud.conf

g.  Turn on rewrite

    a2enmod rewrite

h.  Additional recommended modules
    are mod\_headers, mod\_env, mod\_dir and mod\_mime

    a2enmod headers

    a2enmod env

    a2enmod dir

    a2enmod mime

    service apache2 restart

> Enabling simple SSL
>
> a2enmod ssl
>
> a2ensite default-ssl
>
> service apache2 reload

-   Create a custom location to store the user data

-   mkdir /usr/local/share/nextcloud

-   cd /usr/local/share/

-   mkdir nextcloud/data

-   chown -R www-data:www-data nextcloud

-   chmod 0770 -R nextcloud

> Change to ownership temporary for the install only as follows:-

chown -R www-data:www-data /var/www/nextcloud/

-   Goto http://&lt;your nextcloud server address&gt;/nextcloud

-   ***Do not login yet***. Click on “Storage & database”

    a.  Change the Data folder to our customer location created in an
        earlier step **/usr/local/share/nextcloud**

-   Change database user to nextcloud (Note image is wrong, don’t use
    root.)

-   Database password = wibble

-   Database name = nextcloud

-   Under create an admin account user = admin, password = nextcloud.

-   Now click on finish setup.

![](media/image1.png){width="2.9791666666666665in" height="6.5in"}

Adding external storage e.g. mount samba shares
===============================================

-   Login to nextcloud web interface as admin

-   First delete the default folders and files, we don’t need them.

-   Putty into server and run the following command

-   cd/var/www/nextcloud/core/skeleton/

-   Delete all folders and files. If you are brave rm -R \*

-   Back to the nextcloud via the browser.

-   Click on the cog in the top left and then click on “apps”, then
    “Disabled apps”

-   Click enable “External storage support” and type in the admin
    password if asked.

-   To enable access to AD shares insert the below just before the last
    closed bracket in the config.php file.

> Vim /var/www/nextcloud/config/config.php
>
> 'user\_backends' =&gt; array (
>
> 0 =&gt; array (
>
> 'class' =&gt; 'OC\_User\_SMB',
>
> 'arguments' =&gt; array (
>
> 0 =&gt; 'localhost'
>
> ),
>
> ),
>
> ),

-   []{#__DdeLink__419_1724536427 .anchor}Back to nextcloud as Admin,
    click on the cog (top right corner) select “admin”

-   On the left click on “External Storage”

-   Uncheck the “Enable User External Storage” box, so users can not add
    their own external shares.

-   Above the list there is a section to create external drives. Under
    “Folder name” fill in “Home drive”

> ![](media/image2.png){width="3.0729166666666665in"
> height="1.2708333333333333in"}

-   On the “Add storage” pull down select “smb/cifs” You should now have
    an extended list to fill in

-   Change “Username and password” to “Log-in credentials, save in
    session”

-   Host = fs1 (The host name that holds the users files)

-   Share = users (note if you are connecting to a share e.g. classwork
    change “users” to “classwork”)

-   Remote subfolder = \$users (for home dir, blank for staff etc)

-   Domain = mcbs (for example is the domain of my test server) for
    Valemount secondary it is vals

-   Repeat of each share you want the user to have access to.

    Increasing upload file limit

-   Edit /var/www/nextcloud/.htaccess

    a.  php\_value upload\_max\_filesize = 16G

    b.  php\_value post\_max\_size = 16G

        ***Backup***

        To backup configuration files. Note expecting to access samba
        files, so shouldn’t need to backup date

        rsync -Aax /var/www/nextcloud/ nextcloud-dirbkp\_\`date
        +"%Y%m%d"\`/

        ***sql database***

        mysqldump --lock-tables -h localhost -u nextcloud -pWibble
        nextcloud &gt; nextcloud-sqlbkp\_\`date +"%Y%m%d"\`.bak

***Performance improvements***

*Memcache*

1.  Apt-get install php7-apcu

2.  Add to /var/www/nextcloud/config/config.php

3.  'memcache.local' =&gt; '\\OC\\Memcache\\APCu',


