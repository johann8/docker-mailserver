<h1 align="center">Install Roundcube plugin enigma</h1>


```bash
# add enigma plugin in .env file
cd /opt/mailserver
vim .env
--------------------
...
# Roundcube plugins
ROUNDCUBEMAIL_PLUGINS=archive,zipdownload,password,emoticons,identicon,markasjunk,vcard_attachments,managesieve,enigma
...
--------------------

# create folder and set rights (33:33 alpine web user uid and gid)
cd /opt/mailserver
mkdir -p ./data/roundcube/enigma/pgp_homedir
chown 33:33 ./data/roundcube/enigma/pgp_homedir

# copy and edit enigma config file
cp /opt/mailserver/data/roundcube/appdata/plugins/enigma/config.inc.php.dist /opt/mailserver/data/roundcube/appdata/plugins/enigma/config.inc.php
vim /opt/mailserver/data/roundcube/appdata/plugins/enigma/config.inc.php
-------------
...
// REQUIRED! Keys directory for all users.
// Must be writeable by PHP process, and not in the web server document root
$config['enigma_pgp_homedir'] = '/var/roundcube/enigma_pgp_homedir';
...
------------

# restart docker container
cd /opt/mailserver 
docker-compose down && docker-compose up -d
```
