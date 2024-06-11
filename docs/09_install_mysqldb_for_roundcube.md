<h1 align="center">Install MySQL DB for Roundcube</h1>

If no database is specified, Roundcube automatically creates a `SQLite ` database. However, we want to use Mariadb.

```bash
# add to docker-compose.yml
cd /opt/mailserver
vim /opt/mailserver/docker-compose.yml
---------------
...
#
### === MariaDB Container ===
#
  mariadb:
    image: mariadb:${VERSION_DB}
    container_name: mariadb
    stop_grace_period: 45s
    restart: on-failure:10
    #mem_limit: 4G
    #mem_reservation: 2G
    healthcheck:
      test: "mysqladmin ping -h localhost -u$${UBOUND_DB_USER} --password=$${UBOUND_DB_PASS}"
      interval: 45s
      timeout: 10s
      retries: 5
    volumes:
      - "${DOCKERDIR}/data/mariadb/dbdata:/var/lib/mysql:rw"
      - "${DOCKERDIR}/data/mariadb/config:/etc/mysql/conf.d:ro"
      #- "${DOCKERDIR}/data/mariadb/socket:/var/run/mysqld"
    environment:
      - MARIADB_ROOT_PASSWORD=${MARIADB_ROOT_PASSWORD}
      - MARIADB_DATABASE=${ROUNDCUBE_DB_NAME}     # Roundcube Database - created automatically
      - MARIADB_USER=${ROUNDCUBE_DB_USER}
      - MARIADB_PASSWORD=${ROUNDCUBE_DB_PASS}
#    ports:
#      - "3306:3306"
    security_opt:
      - no-new-privileges:true
    networks:
      mailserverNet:
        ipv4_address: ${IPV4_NETWORK:-172.26.10}.15
        #ipv6_address: ${IPV6_NETWORK:-fd4d:6169:6c63:6f77}::15
---------------

# # adjust env vars (DB is created automatically)
cd /opt/mailserver
vim .env

# create folders for database
mkdir -p /opt/mailserver/data/mariadb/{config,dbdata,socket}
tree -L 3 -d /opt/mailserver/

# create config datei for mariadb
cat > /opt/mailserver/data/mariadb/config/my.cnf << 'EOL'
[mysqld]
default-time-zone              = 'Europe/Berlin'
character-set-client-handshake = FALSE
character-set-server           = utf8mb4
collation-server               = utf8mb4_unicode_ci
max_allowed_packet             = 192M
max-connections                = 350
key_buffer_size                = 0
read_buffer_size               = 192K
sort_buffer_size               = 2M
innodb_buffer_pool_size        = 24M
read_rnd_buffer_size           = 256K
tmp_table_size                 = 24M
performance_schema             = 0
innodb-strict-mode             = 0
thread_cache_size              = 8
query_cache_type               = 0
query_cache_size               = 0
max_heap_table_size            = 48M
thread_stack                   = 256K
skip-host-cache
#skip-name-resolve
log-warnings                   = 0
event_scheduler                = 1

[client]
default-character-set          = utf8mb4

[mysql]
default-character-set          = utf8mb4
EOL

# if docker container is running, you can check DB
cd /opt/mailserver
docker-compose exec mariadb bash
env
mysql -uroot -p
MariaDB [(none)]> show databases;
MariaDB [(none)]> use mysql;
MariaDB [mysql]> select HOST,USER,PASSWORD from user;
MariaDB [mysql]> use roundcubedb;
MariaDB [roundcubedb]> show tables;
```
