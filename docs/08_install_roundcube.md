<h1 align="center">Install Roundcube</h1>

[Roundcube](https://github.com/roundcube/roundcubemail) Webmail is a browser-based multilingual IMAP client with an application-like user interface.

- edit docker-compose.yml file
```bash
# add to docker-compose.yml
cd /opt/mailserver
vim /opt/mailserver/docker-compose.yml
------------------------
...
#
### === Roundcube Container ===
#
  roundcubemail:
    #image: roundcube/roundcubemail:${RC_VERSION}
    image: johann8/alpine-roundcube:${RC_VERSION}
    container_name: roundcubemail
    depends_on:
      - mailserver
      - mariadb
    restart: on-failure:10
    #mem_limit: 4G
    #mem_reservation: 2G
    volumes:
      - ./data/roundcube/config:/var/roundcube/config
      - ./data/roundcube/appdata:/var/www/html
      - ./data/roundcube/dbdata:/var/roundcube/db
      #- ./data/roundcube/enigma/pgp_homedir:/var/roundcube/enigma_pgp_homedir   # For enigma plugin pgp_homedir
    environment:
      - TZ=${TZ}
      # >>> Roundcube config
      - ROUNDCUBEMAIL_DEFAULT_HOST=${ROUNDCUBEMAIL_DEFAULT_HOST}
      - ROUNDCUBEMAIL_DEFAULT_PORT=${ROUNDCUBEMAIL_DEFAULT_PORT}
      - ROUNDCUBEMAIL_SMTP_SERVER=${ROUNDCUBEMAIL_SMTP_SERVER}
      - ROUNDCUBEMAIL_SMTP_PORT=${ROUNDCUBEMAIL_SMTP_PORT}
      - ROUNDCUBEMAIL_SKIN=${ROUNDCUBEMAIL_SKIN}
      - ROUNDCUBEMAIL_UPLOAD_MAX_FILESIZE=${ROUNDCUBEMAIL_UPLOAD_MAX_FILESIZE}
      - ROUNDCUBEMAIL_PLUGINS=${ROUNDCUBEMAIL_PLUGINS}
      - ROUNDCUBEMAIL_ASPELL_DICTS=${ROUNDCUBEMAIL_ASPELL_DICTS}
      - ROUNDCUBEMAIL_USERNAME_DOMAIN=${ROUNDCUBEMAIL_USERNAME_DOMAIN}
      - ROUNDCUBEMAIL_DES_KEY=${ROUNDCUBEMAIL_DES_KEY}
      - ROUNDCUBEMAIL_PLUGINS=${ROUNDCUBEMAIL_PLUGINS}
      - ROUNDCUBEMAIL_INSTALL_PLUGINS=false                                      # true | false - enable /disable install RC plugins
      # <<< Roundcube config

      # >>> MariaDB config
      - ROUNDCUBEMAIL_DB_TYPE=${ROUNDCUBEMAIL_DB_TYPE}
      - ROUNDCUBEMAIL_DB_HOST=${ROUNDCUBE_DB_HOST}
      - ROUNDCUBEMAIL_DB_PORT=${ROUNDCUBE_DB_PORT}
      - ROUNDCUBEMAIL_DB_NAME=${ROUNDCUBE_DB_NAME}
      - ROUNDCUBEMAIL_DB_USER=${ROUNDCUBE_DB_USER}
      - ROUNDCUBEMAIL_DB_PASSWORD=${ROUNDCUBE_DB_PASS}
      # <<< MariaDB config
    security_opt:
      - no-new-privileges:true
    networks:
      mailserverNet:
      openldap_ldapNet:

#
### === NGINX Container ===
#
  roundcubenginx:
    image: nginx:alpine
    container_name: roundcubenginx
    depends_on:
      - roundcubemail
    restart: on-failure:10
    #mem_limit: 4G
    #mem_reservation: 2G
    #links:
      #- roundcubemail
    volumes:
      - ./data/roundcube/appdata:/var/www/html
      - ./data/nginx/templates:/etc/nginx/templates
      # - ./nginx/nginx.conf:/etc/nginx/nginx.conf:ro  # Provide a custom nginx conf
    environment:
      - TZ=${TZ}
      - NGINX_HOST=localhost                # set your local domain or your live domain
      - NGINX_PHP_CGI=roundcubemail:9000    # same as roundcubemail container name
    security_opt:
      - no-new-privileges:true
    networks:
      mailserverNet:
       ipv4_address: ${IPV4_NETWORK}.11
       ipv6_address: ${IPV6_NETWORK:-fd4d:6169:6c63:6f77}::11
...
----------------------

# create folder for nginx and download config file
mkdir -p /opt/mailserver/data/nginx/templates
curl  https://raw.githubusercontent.com/roundcube/roundcubemail-docker/master/examples/nginx/templates/default.conf.template --output /opt/mailserver/data/nginx/templates/default.conf.template
ls -la /opt/mailserver/data/nginx/templates/

# create folder for enigma roundcube plugin (82:82 web user uid and web user group gid)
mkdir -p /opt/mailserver/data/roundcube/enigma/pgp_homedir
chown -R 82:82 /opt/mailserver/data/roundcube/enigma/pgp_homedir/

```
- Current alpine [roundcube](https://hub.docker.com/r/roundcube/roundcubemail/tags) docker image `latest-fpm-alpine` has no package gnupg installed. That's why I built my own image. Below is the Dockerfile.

```bash
# create Docker file
mkdir -p /tmp/roundcube && cd /tmp/roundcube
vim Dockerfile
---------------
FROM roundcube/roundcubemail:latest-fpm-alpine

LABEL Maintainer="JH <jh@localhost>" \
      Description="Docker container with Roundcube and GNUPG based on Alpine Linux."

RUN apk add --update --no-cache gnupg

# Remove alpine cache
RUN rm -rf /var/cache/apk/*
---------------

# build docker image
_VERSION=1.6.7
_TAG=alpine-roundcube

DOCKER_BUILDKIT=0; docker build -t johann8/${_TAG}:${_VERSION} . 2>&1 | tee ./build.log

# adjust roundcube env vars
cd /opt/mailserver
vim .env
```
- Since we use Traefik, he will provide the necessary certificates for us.

```bash
# create file docker-compose.override.yml
cd /opt/mailserver
vim docker-compose.override.yml
--------------
  roundcubenginx:
    labels:
      - "traefik.enable=true"
     ### ==== to https ====
      - "traefik.http.routers.roundcubenginx-secure.rule=Host(`$HOSTNAME0.${DOMAINNAME}`)" # Host(`mail.${DOMAINNAME}`) || Host(`mta-sts.${DOMAINNAME}`)"
      - "traefik.http.routers.roundcubenginx-secure.entrypoints=websecure"
      - "traefik.http.routers.roundcubenginx-secure.tls=true"
      - "traefik.http.routers.roundcubenginx-secure.tls.certresolver=production"  # für eigene Zertifikate
      - "traefik.http.routers.roundcubenginx-secure.tls.domains[0].main=mail.${DOMAINNAME}"   # Für Letsencrypt: Set main domain
      - "traefik.http.routers.roundcubenginx-secure.tls.domains[0].sans=imap.${DOMAINNAME},smtp.${DOMAINNAME},rc.${DOMAINNAME},mta-sts.${DOMAINNAME}" # Add SANs Hosts
      ### ==== to service ====
      - "traefik.http.routers.roundcubenginx-secure.service=roundcubenginx"
      - "traefik.http.services.roundcubenginx.loadbalancer.server.port=$PORT0"
      - "traefik.docker.network=proxy"
      ### ==== redirect to authelia for secure login ====
      #- "traefik.http.routers.roundcubenginx-secure.middlewares=authelia@docker,rate-limit@file,secHeaders@file"
      - "traefik.http.routers.roundcubenginx-secure.middlewares=rate-limit@file,secHeaders@file"
    networks:
      - proxy
-------------
```
- Customize `Roundcube` config file

```bash
# create file local.inc.php
cat > /opt/mailserver/data/roundcube/config/local.inc.php << 'EOL'
// ### === Path inside docker container: /var/roundcube/config/local.inc.php ===

// SMTP username (if required) - wird auch für Auth von managesieve benötigt
// Note: %u variable will be replaced with current user's username
$config['smtp_user'] = '%u';

// SMTP password (if required) - wird auch für Auth von managesieve benötigt
// Note: When set to '%p' current user's password will be used
$config['smtp_pass'] = '%p';

// Make use of the built-in spell checker.
$config['enable_spellcheck'] = true;

// Set the spell checking engine. Possible values:
// - 'googie'  - the default (also used for connecting to Nox Spell Server, see 'spellcheck_uri' setting)
// - 'pspell'  - requires the PHP Pspell module and aspell installed
// - 'enchant' - requires the PHP Enchant module
// - 'atd'     - install your own After the Deadline server or check with the people at http://www.afterthedeadline.com before using their API
// Since Google shut down their public spell checking service, the default settings
// connect to http://spell.roundcube.net which is a hosted service provided by Roundcube.
// You can connect to any other googie-compliant service by setting 'spellcheck_uri' accordingly.
$config['spellcheck_engine'] = 'pspell';

// These languages can be selected for spell checking.
// Configure as a PHP style hash array: ['en'=>'English', 'de'=>'Deutsch'];
// Leave empty for default set of available language.
$config['spellcheck_languages'] = ['en'=>'English', 'de'=>'Deutsch'];


// show up to X items in messages list view
$config['mail_pagesize'] = 50;

// provide an URL where a user can get support for this Roundcube installation
// PLEASE DO NOT LINK TO THE ROUNDCUBE.NET WEBSITE HERE!
$config['support_url'] = 'https://autodiscover.rohrkabel.eu/';
EOL

# Activate SSL in docker-compose.yml if the certificates were created by traefik
cd /opt/mailserver
vim docker-compose.yml
-------------------
...
      # === Enable SSL ===
      - SSL_TYPE=letsencrypt
      - SSL_DOMAIN=mail.rohrkabel.eu
...
--------------------
```
