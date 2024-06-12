<h1 align="center">Setup autodiscover mail settings</h1>

- DNS records must be available

```bash
# edit docker-compose.yml file
cd /opt/mailserver
vim docker-compose.yml
----------------------------
...
  autodiscover:
    image: monogramm/autodiscover-email-settings:latest
    container_name: autodiscover
    restart: unless-stopped
    environment:
      - COMPANY_NAME=HITC
      - SUPPORT_URL=https://autodiscover.${DOMAINNAME}
      - DOMAIN=${DOMAINNAME}
      # IMAP configuration (host mandatory to enable)
      - IMAP_HOST=imap.${DOMAINNAME}
      - IMAP_PORT=993
      - IMAP_SOCKET=SSL
      # POP configuration (host mandatory to enable)
      #- POP_HOST=pop3.${DOMAINNAME}
      #- POP_PORT=995
      #- POP_SOCKET=SSL
      # SMTP configuration (host mandatory to enable)
      - SMTP_HOST=smtp.${DOMAINNAME}
      - SMTP_PORT=587
      - SMTP_SOCKET=STARTTLS
    networks:
      - mailserverNet
----------------------------

# edit docker-compose.override.yml file
cd /opt/mailserver
vim docker-compose.override.yml
---------------------------
...
  autodiscover:
    labels:
      - "traefik.enable=true"
      ### ==== to https ====
      - "traefik.http.routers.autodiscover-secure.rule=Host(`autoconfig.${DOMAINNAME}`) || Host(`autodiscover.$DOMAINNAME`)"
      - "traefik.http.routers.autodiscover-secure.entrypoints=websecure"
      - "traefik.http.routers.autodiscover-secure.tls=true"
      - "traefik.http.routers.autodiscover-secure.tls.certresolver=production"  # für eigene Zertifikate
      ### ==== to service ====
      - "traefik.http.routers.autodiscover-secure.service=autodiscover"
      - "traefik.http.services.autodiscover.loadbalancer.server.port=8000"
      - "traefik.http.services.autodiscover.loadbalancer.passhostheader=true"
      - "traefik.docker.network=proxy"
      ### ==== redirect to authelia for secure login ====
      - "traefik.http.routers.autodiscover-secure.middlewares=rate-limit@file,secHeaders@file"
    networks:
      - proxy
--------------------------

# restart docker container
cd /opt/mailserver 
docker-compose down && docker-compose up -d


# homepage for autodiscover
https://autodiscover.myfirma.de

```
