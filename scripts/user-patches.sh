#!/bin/bash
# This user patches script runs right before starting the daemons.
# That means, all the other configuration is in place, so the script
# can make final adjustments.
# If you modify any supervisord configuration, make sure to run
# "supervisorctl update" or "supervisorctl reload" afterwards.

# Function: print output
print_output() {
   if [[ $? -ne 0 ]]; then
      RES1=1
      echo "[ ERROR ]"
   else
      RES1=0
      echo "[ DONE ]"
   fi
}

# Whitelist docker network
echo -n "Whitelisting docker network...   "
sed -i '/ignoreip = 127.0.0.1/c\ignoreip = 127.0.0.1/8 172.26.10.0/24 fd4d:6169:6c63:6f77::/64' /etc/fail2ban/jail.local
print_output

#
### === START: Only if LDAP is used ===
#
### === enable quota config in dovecot ===

if [[ ${ACCOUNT_PROVISIONER} == "LDAP" ]]; then

   # copy quota config file
   if [[ -f /etc/dovecot/conf.d/90-quota.conf.disab ]]; then
      # copy 90-quota.conf
      echo -n "Enabling file 90-quota.conf...   "
      cp /etc/dovecot/conf.d/90-quota.conf.disab /etc/dovecot/conf.d/90-quota.conf
      print_output
   fi

   MESSAGE_SIZE_LIMIT_MB=$((POSTFIX_MESSAGE_SIZE_LIMIT / 1000000))
   MAILBOX_LIMIT_MB=$((POSTFIX_MAILBOX_SIZE_LIMIT / 1000000))

   # set var MESSAGE_SIZE_LIMIT_MB in 90-quota.conf
   echo -n "Setting message size limit...    "
   sed -i "/quota_max_mail_size =/c\    quota_max_mail_size = ${MESSAGE_SIZE_LIMIT_MB}M" /etc/dovecot/conf.d/90-quota.conf
   print_output

   # set var MAILBOX_LIMIT_MB in 90-quota.conf
   echo -n "Setting mailbox limit...         "
   sed -i "/quota_rule =/c\    quota_rule = *:storage=${MAILBOX_LIMIT_MB}M" /etc/dovecot/conf.d/90-quota.conf
   print_output

   # comment quota_rule
   echo -n "Commenting quota_rule...         "
   sed -i '/quota_rule =/s/^/#/' /etc/dovecot/conf.d/90-quota.conf
   print_output

   # Enable quota plugin
   echo -n "Enabling quota plugin...         "
   sed -i '/mail_plugins =/s/$/ quota/' /etc/dovecot/conf.d/10-mail.conf
   print_output

   # Enable quota plugin imap protocol
   echo -n "Enabling quota plugin IMAP...    "
   sed -i '/mail_plugins =/s/$/ imap_quota/' /etc/dovecot/conf.d/20-imap.conf
   print_output

   ### === enable quota in postfix ===
   echo -n "Enabling quota in postfix...     "
   /usr/local/bin/sedfile -i -E \
      "s|(reject_unknown_recipient_domain)|\1, check_policy_service inet:localhost:65265|g" /etc/postfix/main.cf
   print_output

   # Add iterate_attrs and terate_filter
   echo "=== Add options to dovecot-ldap.conf.ext ==="
   echo '' >> /etc/dovecot/dovecot-ldap.conf.ext
   echo '# For using doveadm -A:' >>/etc/dovecot/dovecot-ldap.conf.ext

   echo -n "Adding LDAP iterate_attrs...     "
   echo 'iterate_attrs = =user=%{ldap:uid}' >> /etc/dovecot/dovecot-ldap.conf.ext
   print_output

   echo -n "Adding LDAP iterate_filter...    "
   echo 'iterate_filter = (&(objectClass=posixAccount)(mailEnabled=TRUE))' >> /etc/dovecot/dovecot-ldap.conf.ext
   print_output
fi

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

#       # is not necessary
#      echo -n "Creating userdb for master users..."
#      echo -e "" "\nuserdb {\n  # Create userdb for dovecot master users\n  args = username_format=%u /etc/dovecot/masterdb\n  driver = passwd-file\n}" >> /etc/dovecot/conf.d/auth-master.inc
#      print_output

#      # For debug only
#      echo -n "Enabling auth_debug...           "
#      sed -i '/#auth_debug_passwords = no/c\auth_debug_passwords = yes' -e '/#auth_debug = no/c\auth_debug = yes' /etc/dovecot/conf.d/10-logging.conf
#      print_output
   fi
fi

#echo 'user-patches.sh successfully executed'

