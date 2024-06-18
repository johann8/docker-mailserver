<h1 align="center">Add two additional options to dovecot-ldap.conf.ext</h1>

For the command `doveadm -A` to work, you must add options `iterate_attrs` and `iterate_filter` to the file `dovecot-ldap.conf.ext`.

```bash
vim /opt/mailserver/data/dms/config/user-patches.sh
-------------------------
...
   # Add iterate_attrs and terate_filter
   echo "Add options to dovecot-ldap.conf.ext"
   echo '' >> /etc/dovecot/dovecot-ldap.conf.ext
   echo '# For using doveadm -A:' >> /etc/dovecot/dovecot-ldap.conf.ext

   echo -n "Adding LDAP iterate_attrs...     "
   echo 'iterate_attrs = =user=%{ldap:uid}' >> /etc/dovecot/dovecot-ldap.conf.ext
   print_output

   echo -n "Adding LDAP iterate_filter...    "
   echo 'iterate_filter = (&(objectClass=posixAccount)(mailEnabled=TRUE))' >> /etc/dovecot/dovecot-ldap.conf.ext
   print_output
...
-------------------------

# restart docker container
cd /opt/mailserver 
docker-compose down && docker-compose up -d

# Test command: doveadm -A
docker compose exec mailserver doveadm index -A -q \*
docker compose exec mailserver doveadm mailbox list -A
docker compose exec mailserver doveadm -Dv search -A ALL
docker compose exec mailserver doveadm fts optimize -A
```
