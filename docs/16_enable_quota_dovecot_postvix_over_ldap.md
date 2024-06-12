<h1 align="center">Enable Quota in Postfix and Dovecot over LDAP</h1>

- If variable `ACCOUNT_PROVISIONER=LDAP` is set, then you can set up `guota` in postfix and dovecot via script `user-patches.sh`

```bash
# enable Quota in Postfix und Dovecot 
vim /opt/mailserver/data/dms/config/user-patches.sh
----------------------------
...
#
### === START: Only if LDAP is used ===
#
### === enable quota config in dovecot ===

if [[ ${ACCOUNT_PROVISIONER} == "LDAP" ]]; then

   # copy quota config file 
   if [[ -f /etc/dovecot/conf.d/90-quota.conf.disab ]]; then
      # copy 90-quota.conf
      cp /etc/dovecot/conf.d/90-quota.conf.disab /etc/dovecot/conf.d/90-quota.conf
   fi

   MESSAGE_SIZE_LIMIT_MB=$((POSTFIX_MESSAGE_SIZE_LIMIT / 1000000))
   MAILBOX_LIMIT_MB=$((POSTFIX_MAILBOX_SIZE_LIMIT / 1000000))

   # set var MESSAGE_SIZE_LIMIT_MB in 90-quota.conf
   sed -i "/quota_max_mail_size =/c\    quota_max_mail_size = ${MESSAGE_SIZE_LIMIT_MB}M" /etc/dovecot/conf.d/90-quota.conf

   # set var MAILBOX_LIMIT_MB in 90-quota.conf
   sed -i "/quota_rule =/c\    quota_rule = *:storage=${MAILBOX_LIMIT_MB}M" /etc/dovecot/conf.d/90-quota.conf

   ### === enable quota in postfix ===
   /usr/local/bin/sedfile -i -E \
      "s|(reject_unknown_recipient_domain)|\1, check_policy_service inet:localhost:65265|g" \
      /etc/postfix/main.cf

fi
### === END: Only if LDAP is used ===
...
--------------------------

# restart docker container
cd /opt/mailserver 
docker-compose down && docker-compose up -d
```
