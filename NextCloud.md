Modified for nextcloud install guide Linux Jessie Debian 8.2.0 amd 64

**Server side:**

**Prerequisite**

**Setup sambaAD. **

**Add a user called admin**

**Join samba files system to the above AD.**

**Login into server and run the following commands**

> apt-get update
>
> apt-get install apache2 php7.0 mysql-server libapache2-mod-php7.0
> php7.0-zip php7.0-iconv
>
> apt-get install php7.0-gd php7.0-json php7.0-mysql php7.0-curl
> php7.0-mbstring php5-ldap
>
> Due to security changed on mysql/Mariadb, you can not just use root
> during nextcloud install, you need to create a user ‘nextcloud’
>
> mysql -u root
>
> USE mysql;
>
> \#\#skip the next line if you already have mysql with a root password.
>
> UPDATE user SET password=PASSWORD('&lt;MYSQL PASSWORD&gt;') WHERE
> User='root' AND Host = 'localhost';
>
> CREATE USER 'nextcloud'@'localhost' IDENTIFIED BY 'Wibble';
>
> GRANT ALL PRIVILEGES ON \*.\* to 'nextcloud’@’localhost’ WITH GRANT
> OPTION;
>
> FLUSH PRIVILEGES;
>
> Make sure you add your root and nextcloud password into firstclass
> repos. If you already have mysql, just make a note of the password you
> already use, you will need it later.

1.  Download nextcloud

    a.  [*https://nextcloud.com/install/*](https://nextcloud.com/install/)

    b.  unpack into /home/tech/nextcloud

    c.  copy into /var/www/

        i.  cp -r nextcloud /var/www/

    d.  vim /etc/apache2/sites-available/nextcloud.conf

    e.  Paste the following in nextcloud.conf

> Alias /nextcloud "/var/www/nextcloud/"
>
> &lt;Directory /var/www/nextcloud/&gt;
>
> Options +FollowSymlinks
>
> AllowOverride All
>
> Satisfy Any
>
> &lt;IfModule mod\_dav.c&gt;
>
> Dav off
>
> &lt;/IfModule&gt;
>
> SetEnv HOME /var/www/nextcloud
>
> SetEnv HTTP\_HOME /var/www/nextcloud
>
> Satisfy Any
>
> &lt;/Directory&gt;

f.  Create symbolic link

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


