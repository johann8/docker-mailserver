<h1 align="center">Set up Dovecot full text search</h1>

To configure `fts-xapian` as a `dovecot` plugin, create a file at data/dms/config/dovecot/fts-xapian-plugin.conf and place the following in it:

```bash
# create config folder
cd /opt/mailserver
mkdir -p ./data/dms/config/dovecot

# create file fts-xapian-plugin.conf
cat > /opt/mailserver/data/dms/config/dovecot/fts-xapian-plugin.conf << 'EOL'
mail_plugins = $mail_plugins fts fts_xapian

plugin {
    fts = xapian
    fts_xapian = partial=3 full=20 verbose=0

    fts_autoindex = yes
    fts_enforced = yes

    # disable indexing of folders
    fts_autoindex_exclude = \Trash

    # Index attachements
    # fts_decoder = decode2text
}

service indexer-worker {
    # limit size of indexer-worker RAM usage, ex: 512MB, 1GB, 2GB
    vsz_limit = 256MB
}

# service decode2text {
#     executable = script /usr/libexec/dovecot/decode2text.sh
#     user = dovecot
#     unix_listener decode2text {
#         mode = 0666
#     }
# }
EOL

# edit docker-compose.yml
vim /opt/mailserver/docker-compose.yml
--------------------
      - ./data/dms/config/dovecot/fts-xapian-plugin.conf:/etc/dovecot/conf.d/10-plugin.conf:ro         # Für Full-Text Search
--------------------
```

-  Initialize indexing on all users for all mail

```bash
docker compose exec mailserver doveadm index -A -q \*

```

- Run the following command in a daily cron job

```bash
docker compose exec mailserver doveadm fts optimize -A

```
