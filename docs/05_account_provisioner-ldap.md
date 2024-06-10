<h1 align="center">Variable ACCOUNT_PROVISIONER is empty or set to "FILE"</h1>

I will use an OpenLDAp server for the user accounts. The OpenLDAP server will not be accessible from the Internet. The administration is done via Phpldapadmin. How to install and set up an OpenLDAp server is described here. A read-only user is used for the connection.

- Set var `ACCOUNT_PROVISIONER=LDAP`
```bash
# set ACCOUNT_PROVISIONER=LDAP
cd /opt/mailserver/
vim docker-compose.yml
------------------
...
ACCOUNT_PROVISIONER=LDAP
...
------------------
```

OpenLDAP docker container will be run separately.
- Create docker-compose.yml file
```bash
# File docker-compose.yml for OpenLDAP docker container
cd /opt/openldap
vim docker-compose.yml
------------------
#version: "3.2"
networks:
  ldapNet:
    driver: bridge
    driver_opts:
      com.docker.network.enable_ipv6: "false"
      com.docker.network.bridge.name: br-openldap
    ipam:
      driver: default
      config:
        - subnet: ${IPV4_NETWORK:-172.26.5}.0/24
        #- subnet: ${IPV6_NETWORK:-fd4d:6169:6c63:6f80}::/64

services:
  openldap:
    image: johann8/alpine-openldap:${VERSION_OPENLDAP:-latest}
    container_name: openldap
    restart: unless-stopped
    environment:
      SLAPD_ROOTDN:                     ${SLAPD_ROOTDN}
      SLAPD_ROOTPW:                     ${SLAPD_ROOTPW}
      SLAPD_ROOTPW_HASH:                ${SLAPD_ROOTPW_HASH}
      SLAPD_ORGANIZATION:               ${SLAPD_ORGANIZATION}
      SLAPD_FQDN:                       ${SLAPD_FQDN}
      SLAPD_SUFFIX:                     ${SLAPD_SUFFIX}
      SLAPD_PWD_CHECK_QUALITY:          ${SLAPD_PWD_CHECK_QUALITY}
      SLAPD_PWD_MIN_LENGTH:             ${SLAPD_PWD_MIN_LENGTH}
      SLAPD_PWD_MAX_FAILURE:            ${SLAPD_PWD_MAX_FAILURE}
      SLAPD_ROOTPW_SECRET:              ${SLAPD_ROOTPW_SECRET}
      SLAPD_USERPW_SECRET:              ${SLAPD_USERPW_SECRET}
      SLAPD_PASSWORD_HASH:              ${SLAPD_PASSWORD_HASH}
      LDAP_BACKUP_TTL:                  ${LDAP_BACKUP_TTL}
      TZ:                               ${TZ}
      DOCKER_LDAP_HEALTHCHECK_USERNAME: ${DOCKER_LDAP_HEALTHCHECK_USERNAME}
      DOCKER_LDAP_HEALTHCHECK_PASSWORD: ${DOCKER_LDAP_HEALTHCHECK_PASSWORD}

    hostname: ${HOSTNAME0}.${DOMAINNAME}
    volumes:
      - ${DOCKERDIR}/data/backup:/data/backup
      - ${DOCKERDIR}/data/prepopulate:/etc/openldap/prepopulate:ro
      - ${DOCKERDIR}/data/ldapdb:/var/lib/openldap/openldap-data
      - ${DOCKERDIR}/data/ssl:/etc/ssl/openldap
      - ${DOCKERDIR}/data/config/ldap/ldif:/etc/openldap/ldif:ro
      - ${DOCKERDIR}/data/config/ldap/slapd.d:/etc/openldap/slapd.d
      - ${DOCKERDIR}/data/config/ldap/custom-schema:/etc/openldap/custom-schema
      - ${DOCKERDIR}/data/config/ldap/secrets:/run/secrets
#    ports:
#      - ${PORT_LDAP:-389}:389
#      - ${PORT_LDAPS:-636}:636
    healthcheck:
      test: 'ldapwhoami -D "$${DOCKER_LDAP_HEALTHCHECK_USERNAME}" -w "$${DOCKER_LDAP_HEALTHCHECK_PASSWORD}"'
      start_period: 5s
      interval: 30s
      timeout: 15s
      retries: 3
    networks:
      ldapNet:
        ipv4_address: ${IPV4_NETWORK:-172.26.5}.10
        #ipv6_address: ${IPV6_NETWORK:-fd4d:6169:6c63:6f80}::10
    secrets:
      - ${SLAPD_ROOTPW_SECRET}
      - ${SLAPD_USERPW_SECRET}

  phpldapadmin:
    image: johann8/phpldapadmin:${PLA_VERSION}
    container_name: phpldapadmin
    restart: unless-stopped
    environment:
      - TZ=${TZ}
      - PHPLDAPADMIN_LANGUAGE=${PHPLDAPADMIN_LANGUAGE}
      - PHPLDAPADMIN_PASSWORD_HASH=${PHPLDAPADMIN_PASSWORD_HASH}
      - PHPLDAPADMIN_SERVER_NAME=${PHPLDAPADMIN_SERVER_NAME}
      - PHPLDAPADMIN_SERVER_HOST=${PHPLDAPADMIN_SERVER_HOST}
      - PHPLDAPADMIN_BIND_ID=${PHPLDAPADMIN_BIND_ID}
      - PHPLDAPADMIN_SEARCH_BASE=${PHPLDAPADMIN_SEARCH_BASE}
    depends_on:
      openldap:
        condition: service_started
        #condition: service_health
    networks:
      - ldapNet

secrets:
  openldap-root-password:
    file: ${DOCKERDIR}/data/config/ldap/secrets/${SLAPD_ROOTPW_SECRET}
  openldap-user-passwords:
    file: ${DOCKERDIR}/data/config/ldap/secrets/${SLAPD_USERPW_SECRET}
------------------
```

- Create .env file
```bash
# .env file
cd /opt/openldap
vi .env
------------------
#### SYSTEM
TZ=Europe/Berlin
DOCKERDIR=/opt/openldap

### Network
DOMAINNAME=myfirma.de
HOSTNAME0=ldap
PORT_LDAP=389
PORT_LDAPS=636
IPV4_NETWORK=172.26.5
#IPV6_NETWORK=fd4d:6169:6c63:6f80

### === APP OpenLDAP ===
VERSION_OPENLDAP=latest
SLAPD_ORGANIZATION="My Firma"
SLAPD_FQDN=${DOMAINNAME}
SLAPD_SUFFIX="dc=myfirma,dc=de"
SLAPD_ROOTDN="cn=admin,${SLAPD_SUFFIX}"
SLAPD_OU="ou=Users,"
# Plain-text admin password (pwgen -1cnsB 25 3)
SLAPD_ROOTPW=MySuperPassword123456
SLAPD_ROOTPW_HASH=
SLAPD_PASSWORD_HASH=ARGON2
SLAPD_PWD_CHECK_QUALITY=2
SLAPD_PWD_MIN_LENGTH=10
SLAPD_PWD_MAX_FAILURE=5
SLAPD_ROOTPW_SECRET=openldap-root-password
SLAPD_USERPW_SECRET=openldap-user-passwords
LDAP_BACKUP_TTL=5

### === PHPLDAPAdmin Alpine ===
DOMAINNAME_PLA=${DOMAINNAME}
HOSTNAME_PLA=pla
PORT_PLA=8080
PLA_VERSION=latest
PHPLDAPADMIN_LANGUAGE="de_DE"
PHPLDAPADMIN_PASSWORD_HASH="ssha"
PHPLDAPADMIN_SERVER_NAME="${SLAPD_ORGANIZATION} LDAP Server"
PHPLDAPADMIN_SERVER_HOST="ldap://${HOSTNAME0}.${DOMAINNAME}"
PHPLDAPADMIN_BIND_ID="cn=admin,${SLAPD_SUFFIX}"
PHPLDAPADMIN_SEARCH_BASE="ou=Users,${SLAPD_SUFFIX}"
DOCKER_LDAP_HEALTHCHECK_USERNAME="cn=techuser,ou=System,dc=myfirma,dc=de"
DOCKER_LDAP_HEALTHCHECK_PASSWORD=MySuperPassword78910
------------------
```

- Create docker-compose.override.yml file

```bash
# docker-compose.override.yml file
cd /opt/openldap
vim docker-compose.override.yml 
-----------------
services:

  phpldapadmin:
    labels:
      - "traefik.enable=true"
      ### ==== to https ====
      - "traefik.http.routers.phpldapadmin-secure.entrypoints=websecure"
      - "traefik.http.routers.phpldapadmin-secure.rule=Host(`${HOSTNAME_PLA}.${DOMAINNAME_PLA}`)"
      - "traefik.http.routers.phpldapadmin-secure.tls=true"
      - "traefik.http.routers.phpldapadmin-secure.tls.certresolver=production"              # für eigene Zertifikate
      - "traefik.http.routers.phpldapadmin-secure.tls.domains[0].main=ldap.${DOMAINNAME}"   # Für Letsencrypt: Set main domain
      - "traefik.http.routers.phpldapadmin-secure.tls.domains[0].sans=pla.${DOMAINNAME}"    # Add SANs Hosts
      ### ==== to service ====
      - "traefik.http.routers.phpldapadmin-secure.service=phpldapadmin"
      - "traefik.http.services.phpldapadmin.loadbalancer.server.port=${PORT_PLA}"
      - "traefik.docker.network=proxy"
      ### ==== redirect to authelia for secure login ====
      - "traefik.http.routers.phpldapadmin-secure.middlewares=rate-limit@file,secHeaders@file"
      #- "traefik.http.routers.phpldapadmin-secure.middlewares=authelia@docker,rate-limit@file,secHeaders@file"
    networks:
      - proxy

networks:
  proxy:
    external: true
-----------------

```

Templates have been prepared for creating users and groups. The next free UID number must be saved in the file `/opt/openldap/data/config/ldap/ldif/uid_number`. A new user is created with this UID and the number is then increased by 1. In my case, the free UID is 10003.

- Create new user

```bash
### Create user
# Customize vars and enter in bash
TARGET_PATH=/opt/openldap/data/config/ldap/ldif
LDAP_BASE_DN="dc=myfirma,dc=de"
DOMAIN_NAME=myfirma
_UID=backup
GIVEN_NAME=Backup
SN=Company_Name
UID_NUMBER=$(cat ${TARGET_PATH}/uid_number)
TELEPHONE_NUMBER="+49177xxxxxxx"
EMPLOYEE_TYPE="Employee"
DESCRIPTION="Employee Company_Name"

# Add free UID in file uid_number
echo 10003 > ${TARGET_PATH}/uid_number

# download template
cd /tmp
wget https://raw.githubusercontent.com/johann8/docker-mailserver/master/templates/template_create_user

# create ldif from template
cat template_create_user > ${TARGET_PATH}/user_${_UID}.ldif

# modify the created file
sed -i -e "s|{{ LDAP_BASE_DN }}|${LDAP_BASE_DN}|g" \
       -e "s|{{ DOMAIN_NAME }}|${DOMAIN_NAME}|g" \
       -e "s|{{ _UID }}|${_UID}|g" \
       -e "s|{{ SN }}|${SN}|g" \
       -e "s|{{ GIVEN_NAME }}|${GIVEN_NAME}|g" \
       -e "s|{{ UID_NUMBER }}|${UID_NUMBER}|g" \
       -e "s|{{ TELEPHONE_NUMBER }}|${TELEPHONE_NUMBER}|g" \
       -e "s|{{ EMPLOYEE_TYPE }}|${EMPLOYEE_TYPE}|g" \
       -e "s|{{ DESCRIPTION }}|${DESCRIPTION}|g" \
       ${TARGET_PATH}/user_${_UID}.ldif

# add ldif to OpenLDAP Server
cd /opt/openldap
dcexec openldap ldapadd -H ldapi://%2Frun%2Fopenldap%2Fldapi -Y EXTERNAL -f /etc/openldap/ldif/user_${_UID}.ldif

# Increase UID counter
if [[ -f ${TARGET_PATH}/uid_number ]]; then
   echo "INFO: UID Number will be increased by 1..."
   UID_NUMBER=$((UID_NUMBER+1))
   echo ${UID_NUMBER} > ${TARGET_PATH}/uid_number
   # cat ${TARGET_PATH}/uid_number
fi

# Set User password
dcexec openldap ldappasswd -H ldapi://%2Frun%2Fopenldap%2Fldapi -Y EXTERNAL -S "uid=${_UID},ou=Users,${LDAP_BASE_DN}"

# show result
dcexec openldap ldapsearch -H ldapi://%2Frun%2Fopenldap%2Fldapi -Y EXTERNAL -b "${LDAP_BASE_DN}" '(objectclass=*)'
```

```bash
### Create new group
# Customize vars and enter in bash
TARGET_PATH=/opt/openldap/data/config/ldap/ldif
LDAP_BASE_DN="dc=myfirma,dc=de"
DOMAIN_NAME=myfirma.de
_CN=helpdesk
COMPANY="Company_Name"

# download template
cd /tmp
wget https://raw.githubusercontent.com/johann8/docker-mailserver/master/templates/template_create_group

# create ldif from template
cat template_create_group > ${TARGET_PATH}/mailgroup_${_CN}.ldif

# modify the created file
sed -i -e "s|{{ LDAP_BASE_DN }}|${LDAP_BASE_DN}|g" \
       -e "s|{{ DOMAIN_NAME }}|${DOMAIN_NAME}|g" \
       -e "s|{{ _CN }}|${_CN}|g" \
       -e "s|{{ COMPANY }}|${COMPANY}|g" \
       ${TARGET_PATH}/mailgroup_${_CN}.ldif

# add ldif to OpenLDAP Server
cd /opt/openldap
dcexec openldap ldapadd -H ldapi://%2Frun%2Fopenldap%2Fldapi -Y EXTERNAL -f /etc/openldap/ldif/mailgroup_${_CN}.ldif

# show result
dcexec openldap ldapsearch -H ldapi://%2Frun%2Fopenldap%2Fldapi -Y EXTERNAL -b "${LDAP_BASE_DN}" '(objectclass=*)'
```

