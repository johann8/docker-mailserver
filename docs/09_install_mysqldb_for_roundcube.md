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

```
