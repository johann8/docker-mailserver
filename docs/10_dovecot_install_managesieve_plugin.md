<h1 align="center">Dovecot install Managesieve plugin</h1>

- Create `Dovecot` `Managesieve` config file 20-managesieve.conf

```bash
# create dovecot folder
cd /opt/mailserver
mkdir -p ./data/dms/config/dovecot

# copy file 20-managesieve.conf from docker
cd /opt/mailserver
docker cp mailserver:/etc/dovecot/conf.d/20-managesieve.conf ./data/dms/config/dovecot/20-managesieve.conf

# edit 20-managesieve.conf
cat > /opt/mailserver/data/dms/config/dovecot/20-managesieve.conf << 'EOL'
##
## ManageSieve specific settings
##

# Uncomment to enable managesieve protocol:
protocols = $protocols sieve

# Service definitions

service managesieve-login {
  inet_listener sieve {
    port = 4190
  }

  #inet_listener sieve_deprecated {
  #  port = 2000
  #}

  # Number of connections to handle before starting a new process. Typically
  # the only useful values are 0 (unlimited) or 1. 1 is more secure, but 0
  # is faster. <doc/wiki/LoginProcess.txt>
  service_count = 1

  # Number of processes to always keep waiting for more connections.
  process_min_avail = 2

  # If you set service_count=0, you probably need to grow this.
  vsz_limit = 64M
}

service managesieve {
  # Max. number of ManageSieve processes (connections)
  process_limit = 64
}

# Service configuration

protocol sieve {
  # Maximum ManageSieve command line length in bytes. ManageSieve usually does
  # not involve overly long command lines, so this setting will not normally
  # need adjustment
  #managesieve_max_line_length = 65536

  # Maximum number of ManageSieve connections allowed for a user from each IP
  # address.
  # NOTE: The username is compared case-sensitively.
  #mail_max_userip_connections = 10

  # Space separated list of plugins to load (none known to be useful so far).
  # Do NOT try to load IMAP plugins here.
  #mail_plugins =

  # MANAGESIEVE logout format string:
  #  %i - total number of bytes read from client
  #  %o - total number of bytes sent to client
  #  %{put_bytes} - Number of bytes saved using PUTSCRIPT command
  #  %{put_count} - Number of scripts saved using PUTSCRIPT command
  #  %{get_bytes} - Number of bytes read using GETCRIPT command
  #  %{get_count} - Number of scripts read using GETSCRIPT command
  #  %{get_bytes} - Number of bytes processed using CHECKSCRIPT command
  #  %{get_count} - Number of scripts checked using CHECKSCRIPT command
  #  %{deleted_count} - Number of scripts deleted using DELETESCRIPT command
  #  %{renamed_count} - Number of scripts renamed using RENAMESCRIPT command
  managesieve_logout_format = bytes=%i/%o

  # To fool ManageSieve clients that are focused on CMU's timesieved you can
  # specify the IMPLEMENTATION capability that Dovecot reports to clients.
  # For example: 'Cyrus timsieved v2.2.13'
  #managesieve_implementation_string = Dovecot Pigeonhole

  # Explicitly specify the SIEVE and NOTIFY capability reported by the server
  # before login. If left unassigned these will be reported dynamically
  # according to what the Sieve interpreter supports by default (after login
  # this may differ depending on the user).
  #managesieve_sieve_capability =
  #managesieve_notify_capability =

  # The maximum number of compile errors that are returned to the client upon
  # script upload or script verification.
  #managesieve_max_compile_errors = 5

  # Refer to 90-sieve.conf for script quota configuration and configuration of
  # Sieve execution limits.
}
EOL

# edit docker-compose.yml
cd /opt/mailserver
vim docker-compose.yml
--------------------
...
    volumes:
...
      - ./data/dms/config/dovecot/20-managesieve.conf:/etc/dovecot/conf.d/20-managesieve.conf:ro # For managesieve
...
--------------------

# edit .env file
cd /opt/mailserver
vim .env
--------------------
...
# Roundcube plugins
ROUNDCUBEMAIL_PLUGINS=archive,zipdownload,password,emoticons,identicon,markasjunk,vcard_attachments,managesieve
...
--------------------

# rename managesieve plugin config file
mv /opt/mailserver/data/roundcube/appdata/plugins/managesieve/config.inc.php.dist /opt/mailserver/data/roundcube/appdata/plugins/managesieve/config.inc.php

# Set access to tls://mail.myfirma.de:4190
sed -i "/managesieve_host/c\$config['managesieve_host'] = 'tls://mail.myfirma.de:4190';" /opt/mailserver/data/roundcube/appdata/plugins/managesieve/config.inc.php

# Activate vacation
sed -i "/managesieve_vacation']/c\$config['managesieve_vacation'] = 1;" /opt/mailserver/data/roundcube/appdata/plugins/managesieve/config.inc.php
sed -i "/managesieve_forward']/c\$config['managesieve_forward'] = 1;" /opt/mailserver/data/roundcube/appdata/plugins/managesieve/config.inc.php
sed -i "/managesieve_vacation_from_init']/c\$config['managesieve_vacation_from_init'] = true;" /opt/mailserver/data/roundcube/appdata/plugins/managesieve/config.inc.php

# check file config.inc.php
vim /opt/mailserver/data/roundcube/appdata/plugins/managesieve/config.inc.php

#  create file  managesieve.inc.php
vim ./data/roundcube/config/managesieve.inc.php
----------------------------------------
<?php
$config['managesieve_host'] = 'tls://mail.myfirma.de:4190';
?>
-----------------------------------

# restart docker container
cd /opt/mailserver 
docker-compose down && docker-compose up -d
```
