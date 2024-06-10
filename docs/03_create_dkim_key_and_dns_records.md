<h1 align="center">Create DKIM key and DNS Records</h1>

- Create DKIM key

```bash
#
# Set ENABLE_RSPAMD=1 and  ENABLE_OPENDKIM=0 in docker-compose.yml
# docker exec -ti mailserver setup config dkim help
DOMAINNAME=myfirma.de
docker exec -ti mailserver setup config dkim keysize 2048 selector dkim domain ${DOMAINNAME} -vv

# show created keys
ls -la /opt/mailserver/data/dms/config/rspamd/dkim/

# show DKIM DNS Record
cat /opt/mailserver/data/dms/config/rspamd/dkim/rsa-2048-dkim-myfirma.de.public.dns.txt
```
- Create DNS Records

| DNS Record | TTL | Typ | Priority | Data |
| :--------------------------------- | :----------------------------------: | :--------------------------------: | :--------------------------------:|:-------------------------------- |
|myfirma.de                    | 86400 | A     | 0   |109.123.xxx.xxx |
|myfirma.de                    | 86400 | AAAA  | 0   |2a02:c206:xxxx:xxxx::2 |
|myfirma.de                    | 86400 | MX    | 10  |mail.myfirma.de |
|mail.myfirma.de               | 86400 | A     | 0   |109.123.xxx.xxx |
|imap.myfirma.de               | 86400 | CNAME | 0   |mail.myfirma.de |
|smtp.myfirma.de               | 86400 | CNAME | 0   |mail.myfirma.de |
|rsapmd.myfirma.de             | 86400 | CNAME | 0   |mail.myfirma.de |
|ldap.myfirma.de               | 86400 | CNAME | 0   |mail.myfirma.de |
|pla.myfirma.de                | 86400 | CNAME | 0   |mail.myfirma.de |
|rc.myfirma.de                 | 86400 | CNAME | 0   |mail.myfirma.de |
|rsapmd.myfirma.de             | 86400 | CNAME | 0   |mail.myfirma.de |
|autoconfig.myfirma.de         | 86400 | A     | 0   |109.123.xxx.xxx |
|autodiscover.myfirma.de       | 86400 | A     | 0   |109.123.xxx.xxx |
|_autodiscover._tcp.myfirma.de | 86400 | SRV   | 0   |1 443 mail.myfirma.de |
|_pop3s._tcp._tcp.myfirma.de   | 86400 | SRV   | 0   |1 995 mail.myfirma.de |
|_imaps._tcp.myfirma.de        | 86400 | SRV   | 0   |1 993 mail.myfirma.de |
|_sieve._tcp.myfirma.de        | 86400 | SRV   | 0   |1 4190 mail.myfirma.de |
|_smtps._tcp.myfirma.de        | 86400 | SRV   | 0   |1 465 mail.myfirma.de |
|_submission._tcp.myfirma.de   | 86400 | SRV   | 0   |1 587 mail.myfirma.de |
|dkim._domainkey.myfirma.de    | 86400 | TXT   | 0   |v=DKIM1; k=rsa; p=StRinG123 |
|_dmarc.myfirma.de             | 86400 | TXT   | 0   |v=DMARC1; p=quarantine; adkim=r; aspf=r; pct=100; rua=mailto:postmaster@myfirma.de; |
|myfirma.de                    | 86400 | TXT   | 0   |mailconf=https://autoconfig.myfirma.de/mail/config-v1.1.xml |
|myfirma.de                    | 86400 | TXT   | 0   |v=spf1 a mx ip4:109.123.xxx.xxx -all |
|mail.myfirma.de               | ---   | PTR   | -   |109.123.xxx.xxx |
|mail.myfirma.de               | ---   | PTR   | -   |2a02:c206:xxxx:xxxx::2 |

- Verify DNS recods

```bash
### === Some Examples === 
# NS record over 8.8.8.8 NS Server
dig @8.8.8.8 +short chip.de NS

# A record over 8.8.8.8 NS Server
dig @8.8.8.8 +short chip.de A

# A record
dig +short chip.de A
dig +short chip.de AAAA

# PTR Record IPV4
dig -x 109.123.246.64
dig +short -x 109.123.246.64

# PTR Record IPV6
dig -x 2a02:c206:3010:2208::1
dig +short -x 2a02:c206:3010:2208::1

# DNS trace
dig +trace chip.de
dig +trace mail.chip.de

# A record 
dig +nocmd +noall +answer +ttlid A mail.chip.de

# show ultiple records
dig +multiline +noall +answer +nocmd chip.de ANY

# CNAME record
dig  +short pla.chip.de CNAME
dig  +short ldap.chip.de CNAME

# SRV record
dig +short _imaps._tcp.chip.de SRV
dig +short _smtps._tcp.chip.de SRV

# DKIM
dig +short dkim._domainkey.chip.de TXT

# DMARC
dig +short  _dmarc.chip.de TXT

# SPF
dig +multiline +noall +answer +nocmd chip.de ANY

```
