<h1 align="center">Setup RSPAMD Web Interface</h1>

[Rspamd](https://rspamd.com/) provides a web interface, which contains statistics and data Rspamd collects. The interface is enabled by default and reachable on port 11334.

```bash
# create DNS Record
rspamd.myfirma.de 	86400 	CNAME 	0 	mail.myfirma.de

# edit docker-compose.override.yml file
cd /opt/mailserver
vim docker-compose.override.yml
----------------------
...
  mailserver:
    labels:
      - "traefik.enable=true"
      ### ==== to https ====
      - "traefik.http.routers.rspamd-secure.rule=Host(`${HOSTNAME1}.${DOMAINNAME}`) "
      - "traefik.http.routers.rspamd-secure.entrypoints=websecure"
      - "traefik.http.routers.rspamd-secure.tls=true"
      - "traefik.http.routers.rspamd-secure.tls.certresolver=production"  # für eigene Zertifikate
      ### ==== to service ====
      - "traefik.http.routers.rspamd-secure.service=rspamd"
      - "traefik.http.services.rspamd.loadbalancer.server.port=${PORT1}"
      - "traefik.http.services.rspamd.loadbalancer.passhostheader=true"
      - "traefik.docker.network=proxy"
      ### ==== redirect to authelia for secure login ====
      - "traefik.http.routers.rspamd-secure.middlewares=rate-limit@file,secHeaders@file"
    networks:
      - proxy
...
----------------------

# create rspamd config folder
cd /opt/mailserver
mkdir -p ./data/dms/config/rspamd
tree /opt/mailserver -L 4 -d

# copy file worker-controller.inc from docker container
docker cp mailserver:/etc/rspamd/local.d/worker-controller.inc ./data/dms/config/rspamd/worker-controller.inc

# edit docker-compose.yml file
cd /opt/mailserver
vim docker-compose.yml
-----------------------------
...
  mailserver:
...
    volumes:
...
      - ./data/dms/config/rspamd/worker-controller.inc:/etc/rspamd/local.d/worker-controller.inc:ro  # For assess to rspamd Web UI
...
-----------------------------

# edit .env file
cd /opt/mailserver
vim .env
-----------------
...
### === Network ===
...
HOSTNAME1=rspamd
PORT1=11334
IPV4_NETWORK=172.26.10
...
-----------------

# create and set rspamd Web UI password
# pwgen -1ycnsB --remove-chars=". ^ $ * ; ~ ' _ ? @ : , & |" 15 10
# PW: )U+he\k9pzo#7jb
cd /opt/mailserver
dcexec mailserver bash
rspamadm pw
---------------
Enter passphrase:
$2$6jc6exry58i7fjnwoqj1wtqmqgp6mn1k$ofborypjdbmennip3cs1ra3zuikdz3b6cso6tdgibzx9bpof37wb
-----------------

# Edit worker-controller.inc file
vim /opt/mailserver/data/dms/config/rspamd/worker-controller.inc
-----------------------
# documentation: https://rspamd.com/doc/workers/controller.html

bind_socket = "0.0.0.0:11334";

password = "$2$6jc6exry58i7fjnwoqj1wtqmqgp6mn1k$ofborypjdbmennip3cs1ra3zuikdz3b6cso6tdgibzx9bpof37wb";
----------------------

# enable rspamd module
vim /opt/mailserver/data/dms/config/rspamd/custom-commands.conf
---------------------------
# https://docker-mailserver.github.io/docker-mailserver/edge/config/security/rspamd/
set-option-for-module classifier-bayes autolearn true

# disable-module chartable
---------------------------

# restart docker container
cd /opt/mailserver 
docker-compose down && docker-compose up -d


# Login to Rspamd Web UI
https://rspamd.myfirma.de
```
