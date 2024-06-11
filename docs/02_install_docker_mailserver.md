<h1 align="center">Install docker-mailserver</h1>

- Install `docker-mailserver`

```bash
mkdir /opt/mailserver 
cd /opt/mailserver
DMS_GITHUB_URL="https://raw.githubusercontent.com/docker-mailserver/docker-mailserver/master"
wget "${DMS_GITHUB_URL}/compose.yaml"
wget "${DMS_GITHUB_URL}/mailserver.env"
mv compose.yaml compose.yaml_bck

# create docker-compose.yml
cat > /opt/mailserver/docker-compose.yml << 'EOL'
networks:
  mailserverNet:
    driver: bridge
    driver_opts:
      com.docker.network.bridge.name: br-mailserver
    enable_ipv6: true
    ipam:
      driver: default
      config:
        - subnet: ${IPV4_NETWORK:-172.26.10}.0/24
        - subnet: ${IPV6_NETWORK:-fd4d:6169:6c63:6f77}::/64
  # <<< Allows access to OpenLDAP server - ldap://ldap.myfirma.de
  openldap_ldapNet:
    external: true

services:
#
### === Mailserver Container ===
#
  mailserver:
    image: ghcr.io/docker-mailserver/docker-mailserver:latest
    container_name: mailserver
    depends_on:
      unbound:
        condition: service_started
        # condition: service_healthy
    restart: on-failure:20
    stop_grace_period: 1m
    mem_limit: 2G     # better 4G
    #mem_reservation: 2G

    # Provide the FQDN of your mail server here (Your DNS MX record should point to this value)
    hostname: mail.myfirma.de
    env_file: mailserver.env
    # More information about the mail-server ports:
    # https://docker-mailserver.github.io/docker-mailserver/latest/config/security/understanding-the-ports/
    ports:
      - "25:25"     # SMTP  (explicit TLS => STARTTLS, Authentication is DISABLED => use port 465/587 instead)
      #- "143:143"  # IMAP4 (explicit TLS => STARTTLS)
      - "465:465"   # ESMTP (implicit TLS)
      - "587:587"   # ESMTP (explicit TLS => STARTTLS)
      - "993:993"   # IMAP4 (implicit TLS)
      - "4190:4190" # MANAGESIEVE
    volumes:
      - ./data/dms/mail-data/:/var/mail/
      - ./data/dms/mail-state/:/var/mail-state/
      - ./data/dms/mail-logs/:/var/log/mail/
      - ./data/dms/config/:/tmp/docker-mailserver/
      - /etc/localtime:/etc/localtime:ro
      - /opt/traefik/data/certs/acme.json:/etc/letsencrypt/acme.json:ro                                # Zertifikate von Traefik Instanz
      #- ./data/dms/config/dovecot/10-master.conf:/etc/dovecot/conf.d/10-master.conf                    # Für eigene Konfiguration von dovecot
      - ./data/dms/config/dovecot/fts-xapian-plugin.conf:/etc/dovecot/conf.d/10-plugin.conf:ro         # Für Full-Text Search
      - ./data/dms/config/dovecot/20-managesieve.conf:/etc/dovecot/conf.d/20-managesieve.conf:ro       # Für managesieve
      - ./data/dms/config/rspamd/worker-controller.inc:/etc/rspamd/local.d/worker-controller.inc:ro    # For assess to rspamd Web UI
      #- ./data/dms/config/dovecot/10-custom.conf:/etc/dovecot/conf.d/10-custom.conf                    # Für Mail Encryption plugin
      - ./data/dms/config/dovecot/15-mailboxes.conf:/etc/dovecot/conf.d/15-mailboxes.conf:ro           # Customize IMAP Folders
      #- ./data/dms/config/dovecot/certs:/certs                                                         # Für Mail Encryption Zertifikate
    environment:
      # >>> RSPAMD Integration
      - ENABLE_RSPAMD=1
      - RSPAMD_LEARN=1
      - RSPAMD_GREYLISTING=1
      - RSPAMD_NEURAL=0
      - RSPAMD_LEARN=1
      - SPAM_SUBJECT='***SPAM*** '
      - MOVE_SPAM_TO_JUNK=1
      # wenn rspamd enabled, dann schalte alle anderen Services ab
      - ENABLE_OPENDKIM=0
      - ENABLE_OPENDMARC=0
      - ENABLE_POLICYD_SPF=0
      - ENABLE_AMAVIS=0
      - ENABLE_SPAMASSASSIN=0
      # <<< RSPAMD Integration

      # ==== Enable DNSBL check ====
      - ENABLE_DNSBL=1
      # ==== Enable managesieve ====
      - ENABLE_MANAGESIEVE=1
      # ==== Enable postgray ====
      - ENABLE_POSTGREY=0                  # Set to 1, if RSPAMD_GREYLISTING=0
      # ==== Enable spoof protection ===
      - SPOOF_PROTECTION=1                 # Each user may only send with his own or his alias addresses
      # === Enable fail2ban ===
      - ENABLE_FAIL2BAN=1

      # >>>TLS Level
      # empty => modern
      # modern => Enables TLSv1.2 and modern ciphers only. (default)
      # intermediate => Enables TLSv1, TLSv1.1 and TLSv1.2 and broad compatibility ciphers.
      - TLS_LEVEL=modern
      # <<<TLS Level

      # >>> SSL config
      - SSL_TYPE=letsencrypt
      - SSL_DOMAIN=mail.myfirma.de
      # <<< SSL config

      # >>> Postfix config
      - POSTFIX_MESSAGE_SIZE_LIMIT=20480000                     # 20MB | empty => 10240000 (~10 MB)
      - POSTFIX_MAILBOX_SIZE_LIMIT=2048000000                   # 2.048.000.000 => 2GB
      # <<< Postfix config

      # >>> Postfix LDAP Integration
      - ACCOUNT_PROVISIONER=LDAP                                # Achtung: SPOOF_PROTECTION=1 - muss unbedingt eingeschaltet werden
      - LDAP_START_TLS=yes                                      # Don't use both tls=yes and ldaps URI
      - LDAP_SERVER_HOST=ldap://ldap.myfirma.de
      - LDAP_SEARCH_BASE=ou=Users,dc=myfirma,dc=de
      - LDAP_BIND_DN=cn=techuser,ou=System,dc=myfirma,dc=de
      - LDAP_BIND_PW=${LDAP_BIND_PW}                            # cat /opt/openldap/data/config/ldap/ldif/bind_DN_user_techuser.ldif
      - LDAP_QUERY_FILTER_USER=(&(objectClass=inetOrgPerson)(|(uid=%u)(mail=%u))(mailEnabled=TRUE))
      - LDAP_QUERY_FILTER_GROUP=(&(mailGroupMember=%s)(mailEnabled=TRUE))
      - LDAP_QUERY_FILTER_ALIAS=(&(mailAlias=%s)(mailEnabled=TRUE))
      - LDAP_QUERY_FILTER_DOMAIN=(&(|(mail=*@%s)(mailalias=*@%s)(mailGroupMember=*@%s))(mailEnabled=TRUE))
      # <<< Postfix LDAP Integration

      # >>> Dovecot LDAP Integration
      - DOVECOT_TLS=yes
      - DOVECOT_PASS_ATTRS=mail=user,userPassword=password
      - DOVECOT_USER_ATTRS=homeDirectory=home,=uid=5000,=gid=5000
      - DOVECOT_USER_ATTRS==uid=5000,=gid=5000,=home=/var/mail/%d/%Ln,=mail=maildir:~/,=quota_rule=*:storage=%{ldap:mailQuota}
      - DOVECOT_USER_FILTER=(&(objectClass=inetOrgPerson)(|(uid=%u)(mail=%u))(mailEnabled=TRUE))
      - DOVECOT_PASS_FILTER=(&(objectClass=inetOrgPerson)(|(uid=%u)(mail=%u))(mailEnabled=TRUE))
      - DOVECOT_MAILBOX_FORMAT=maildir
      - DOVECOT_AUTH_BIND=yes
      # <<< Dovecot LDAP Integration

      # >>> SASL LDAP Authentication
      #- ENABLE_SASLAUTHD=1
      #- SASLAUTHD_MECHANISMS=ldap
      #- SASLAUTHD_LDAP_FILTER=(&(mail=%U@example.org)(objectClass=inetOrgPerson))
      # <<< SASL LDAP Authentication

    # Uncomment if using `ENABLE_FAIL2BAN=1`:
    cap_add:
      - NET_ADMIN
    healthcheck:
      test: "ss --listening --tcp | grep -P 'LISTEN.+:smtp' || exit 1"
      timeout: 3s
      retries: 0
    dns:
      - ${IPV4_NETWORK:-172.26.10}.254
    security_opt:
      - no-new-privileges:true
    networks:
      mailserverNet:
        ipv4_address: ${IPV4_NETWORK}.10
        ipv6_address: ${IPV6_NETWORK:-fd4d:6169:6c63:6f77}::10
      # <<< Allows access to OpenLDAP server - ldap://ldap.myfirma.de
      openldap_ldapNet:
EOL

# Set yours Domain 
cd /opt/mailserver
DOMAINNAME=testdomain.de
sed -i "s/myfirma.de/${DOMAINNAME}/" docker-compose.yml

# Customize LDAP section and adjust vars
vim /opt/mailserver/docker-compose.yml
```

```bash
# create file roundcube.env and adjust vars
cat > /opt/mailserver/roundcube.env << 'EOL'
### === SYSTEM ===
TZ=Europe/Berlin
DOCKERDIR=/opt/mailserver

### === Network ===
DOMAINNAME=myfirma.de
HOSTNAME0=rc
PORT0=80
HOSTNAME1=rspamd
PORT1=11334
IPV4_NETWORK=172.26.10
IPV6_NETWORK=fd4d:6169:6c63:6f77

### === APP ROUNDCUBE ===
RC_VERSION=latest
#RC_VERSION=latest-fpm-alpine
#RC_VERSION=1.6.x-apache

# PostgreSQL => pgsql
# MySQL => mysql
# SQLite => sqlite
ROUNDCUBEMAIL_DB_TYPE=mysql

# Use this parameter if you use PostgreSQL or MySQL
#ROUNDCUBEMAIL_DB_HOST=localhost

# Use this parameter if you use PostgreSQL or MySQL
# PostgreSQL => 5432
# MySQL => 3306
#ROUNDCUBEMAIL_DB_PORT=3306

# Use this parameter if you use PostgreSQL or MySQL
#ROUNDCUBEMAIL_DB_NAME=roundcube

# Use this parameter if you use PostgreSQL or MySQL
#ROUNDCUBEMAIL_DB_USER=roundcube

# Use this parameter if you use PostgreSQL or MySQL
#ROUNDCUBEMAIL_DB_PASSWORD=roundcube

# Roundcube Skin
ROUNDCUBEMAIL_SKIN=elastic

# Doc : https://github.com/roundcube/google-spell-pspell
#ROUNDCUBEMAIL_SPELLCHECK_URI

# Roundcube languages
ROUNDCUBEMAIL_ASPELL_DICTS=de,en

# Roundcube max upload file size
ROUNDCUBEMAIL_UPLOAD_MAX_FILESIZE=10M

# Roundcube plugins
#ROUNDCUBEMAIL_INSTALL_PLUGINS=true
#ROUNDCUBEMAIL_PLUGINS=archive,zipdownload,password,emoticons,identicon,markasjunk,vcard_attachments,newmail_notifier,managesieve,enigma
ROUNDCUBEMAIL_PLUGINS=archive,zipdownload,password,emoticons,new_user_dialog,identicon,markasjunk,vcard_attachments,newmail_notifier,managesieve,enigma

#ROUNDCUBEMAIL_DEFAULT_HOST=tls://mail.${DOMAINNAME}
ROUNDCUBEMAIL_DEFAULT_HOST=ssl://mail.${DOMAINNAME}
ROUNDCUBEMAIL_DEFAULT_PORT=993
#ROUNDCUBEMAIL_DEFAULT_PORT=143

ROUNDCUBEMAIL_SMTP_SERVER=tls://mail.${DOMAINNAME}
ROUNDCUBEMAIL_SMTP_PORT=587
#ROUNDCUBEMAIL_SMTP_PORT=25


# Automatically add this domain to user names for login
ROUNDCUBEMAIL_USERNAME_DOMAIN=${DOMAINNAME}

# head /dev/urandom | base64 | head -c 24
ROUNDCUBEMAIL_DES_KEY=cEhkR+vAh4545HsDjh7DyYUGN

#
### === LDAP ===
#
LDAP_BIND_PW=MySuperPW_Bind_User

#
### === MYSQL DB ===
#
# pwgen -1cnsB 30 1
VERSION_DB=10.11
MARIADB_ROOT_PASSWORD=MySuperPW_Root
ROUNDCUBE_DB_HOST=mariadb
ROUNDCUBE_DB_PORT=3306
ROUNDCUBE_DB_NAME=roundcubedb
ROUNDCUBE_DB_USER=roundcube
ROUNDCUBE_DB_PASS=MySuperPW_DB_User
EOL

# create symlink
cd /opt/mailserver
ln -s ./roundcube.env ./.env

# adjust vars
vim /opt/mailserver/roundcube.env

# run docker container
cd /opt/mailserver
docker compose up -d
```
