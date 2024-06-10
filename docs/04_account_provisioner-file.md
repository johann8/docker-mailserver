<h1 align="center">Variable ACCOUNT_PROVISIONER is empty or set to "FILE"</h1>

If you do not want to provide an `LDAP` server, you can create the users in a `file`. Here you have to comment out the `LDAP` and `Dovecot` sections in docker-compose.yml file. The users are created with the help of a script on the command line.
 

```bash
# set ACCOUNT_PROVISIONER=FILE
cd /opt/mailserver/
vim docker-compose.yml
------------------
...
ACCOUNT_PROVISIONER=FILE
...
------------------

# Comment OpenLDAP and Dovecot section
vim docker-compose.yml
-----------------  
...
      # >>> Postfix LDAP Integration
      - ACCOUNT_PROVISIONER=FILE                                # Achtung: SPOOF_PROTECTION=1 - muss unbedingt eingeschaltet werden
#      - LDAP_START_TLS=yes                                      # Don't use both tls=yes and ldaps URI
#      - LDAP_SERVER_HOST=ldap://ldap.myfirma.de
#      - LDAP_SEARCH_BASE=ou=Users,dc=rohrkabel,dc=eu
#      - LDAP_BIND_DN=cn=techuser,ou=System,dc=rohrkabel,dc=eu
#      - LDAP_BIND_PW=MRYayXrX77wiwkvdVkeWRzYpbtKiWp             # cat /opt/openldap/data/config/ldap/ldif/bind_DN_user_techuser.ldif
#      - LDAP_QUERY_FILTER_USER=(&(objectClass=inetOrgPerson)(|(uid=%u)(mail=%u))(mailEnabled=TRUE))
#      - LDAP_QUERY_FILTER_GROUP=(&(mailGroupMember=%s)(mailEnabled=TRUE))
#      - LDAP_QUERY_FILTER_ALIAS=(&(mailAlias=%s)(mailEnabled=TRUE))
#      - LDAP_QUERY_FILTER_DOMAIN=(&(|(mail=*@%s)(mailalias=*@%s)(mailGroupMember=*@%s))(mailEnabled=TRUE))
      # <<< Postfix LDAP Integration

      # >>> Dovecot LDAP Integration
#      - DOVECOT_TLS=yes
#      - DOVECOT_PASS_ATTRS=mail=user,userPassword=password
#      - DOVECOT_USER_ATTRS=homeDirectory=home,=uid=5000,=gid=5000
#      - DOVECOT_USER_ATTRS==uid=5000,=gid=5000,=home=/var/mail/%d/%Ln,=mail=maildir:~/,=quota_rule=*:storage=%{ldap:mailQuota}
#      - DOVECOT_USER_FILTER=(&(objectClass=inetOrgPerson)(|(uid=%u)(mail=%u))(mailEnabled=TRUE))
#      - DOVECOT_PASS_FILTER=(&(objectClass=inetOrgPerson)(|(uid=%u)(mail=%u))(mailEnabled=TRUE))
#      - DOVECOT_MAILBOX_FORMAT=maildir
#      - DOVECOT_AUTH_BIND=yes
      # <<< Dovecot LDAP Integration
...
-----------------

# Create user and aliases
# Not all at once but one after the other

DOMAINNAME=myfirma.de
docker exec -ti mailserver setup email add jhahn@${DOMAINNAME} MySuperPassword33

docker exec -ti mailserver setup email add info@${DOMAINNAME} MySuperPassword33

docker exec -ti mailserver setup email add backup@${DOMAINNAME} MySuperPassword33

docker exec -ti mailserver setup email add service@${DOMAINNAME} MySuperPassword33

docker exec -ti mailserver setup email add helpdesk@${DOMAINNAME} MySuperPassword33

# Check the result
docker exec -ti mailserver setup email list


# 2.0 You should add at least one alias, the postmaster alias. This is a common convention, but not strictly required.
DOMAINNAME=myfirma.de
docker exec -ti mailserver setup alias add postmaster@${DOMAINNAME} jhahn@${DOMAINNAME}

# Check the result
docker exec -ti mailserver setup alias list

### Attention!!!
# Create catchall address
DOMAINNAME=myfirma.de
docker-compose exec mailserver setup alias add @myfirma.de catchall@myfirma.de
```
