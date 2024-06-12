<h1 align="center">Setup Fail2ban</h1>

```bash
# activate fail2ban
cd /opt/mailserver
vim docker-compose.yml
-----------------
...
      # === Enable fail2ban ===
      - ENABLE_FAIL2BAN=1
...
    # Uncomment if using `ENABLE_FAIL2BAN=1`:
    cap_add:
      - NET_ADMIN
...
----------------

# create bash script user-patches.sh
vim /opt/mailserver/data/dms/config/user-patches.sh
----------------
#!/bin/bash
# This user patches script runs right before starting the daemons.
# That means, all the other configuration is in place, so the script
# can make final adjustments.
# If you modify any supervisord configuration, make sure to run
# "supervisorctl update" or "supervisorctl reload" afterwards.

# Whitelist docker subnetwork
sed -i '/ignoreip = 127.0.0.1/c\ignoreip = 127.0.0.1/8 172.26.10.0/24 fd4d:6169:6c63:6f77::/64' /etc/fail2ban/jail.local
----------------
chmod a+x /opt/mailserver/data/dms/config/user-patches.sh
ls -la /opt/mailserver/data/dms/config/

# check
cd /opt/mailserver
dcexec mailserver bash
cat /etc/fail2ban/jail.local

# some fail2ban commands
docker exec -ti mailserver setup fail2ban status
docker exec -ti mailserver setup fail2ban unban 92.116.223.xxx
docker exec -ti mailserver setup fail2ban ban 92.116.223.xxx

# check logs
tail -f -n2000 /opt/mailserver/data/dms/mail-logs/fail2ban.log
tail -f -n2000 /opt/mailserver/data/dms/mail-logs/mail.warn
tail -f -n2000 /opt/mailserver/data/dms/mail-logs/mail.log
tail -f -n2000 /opt/mailserver/data/dms/mail-logs/mail.info
tail -f -n2000 /opt/mailserver/data/dms/mail-logs/rspamd.log

