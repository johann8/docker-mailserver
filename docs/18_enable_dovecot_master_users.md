<h1 align="center">Enable Quota in Postfix and Dovecot over LDAP</h1>

If you use the OpenLDAp backend, the project `docker-mailserver` does not support the setup of `dovecot master users`. You can still set them up with the help of `user-patches.sh` bash script.

```bash
### create dovecot master user with bash script setup.sh
# show help
dcexec -ti mailserver setup help

# create master user
dcexec -ti mailserver setup dovecot-master add masteruser

# list master user
dcexec -ti mailserver setup dovecot-master list

# add to user-patches.sh
vim /opt/mailserver/data/dms/config/user-patches.sh
----------------------------
...
### === Enable dovecot master users ==

if [[ ${ACCOUNT_PROVISIONER} == "LDAP" ]]; then
   # file exists and is not empty
   if [[ -s /tmp/docker-mailserver/dovecot-masters.cf ]]; then
      echo "=== Configure dovecot master user ==="

      echo -n "Editing 10-auth.conf...          "
      sed -i '/\!include auth-master\.inc/s/^#//' /etc/dovecot/conf.d/10-auth.conf
      print_output

      echo -n "Coping file masterdb...          "
      cp /tmp/docker-mailserver/dovecot-masters.cf /etc/dovecot/masterdb
      print_output

      # replace "|" => ":"
      echo -n "Editing file masterdb...         "
      sed -i 's/|/:/' /etc/dovecot/masterdb
      print_output

      echo -n "Setting masterdb owner rights... "
      chown root:dovecot /etc/dovecot/masterdb
      print_output

      echo -n "Setting masterdb permission...   "
      chmod 640 /etc/dovecot/masterdb
      print_output

#      # For debug only
#      echo -n "Enabling auth_debug...           "
#      sed -i '/#auth_debug_passwords = no/c\auth_debug_passwords = yes' -e '/#auth_debug = no/c\auth_debug = yes' /etc/dovecot/conf.d/10-logging.conf
#      print_output
   fi
fi
...

# restart docker container
cd /opt/mailserver 
docker-compose down && docker-compose up -d

# test auth
docker compose exec mailserver doveadm auth test info@myfirma.de*masteruser

# Test login via IMAP
openssl s_client -connect myil.myfirma.de:993
a1 login info@myfirma.de*masteruser MyMasterUserPassword
a2 list "" *
a3 GETQUOTA ""
a4 logout
```
