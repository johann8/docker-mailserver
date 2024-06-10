<h1 align="center">Prepare VPS</h1>

```bash
# set hostname
hostnamectl set-hostname mail.myfirma.eu --static

# show IPV6 address
ip -6 addr show

# add ipv6 addr device ens18
nmcli connection modify ens18 ipv6.addresses '2a02:c206:xxxxx:xxxx::1/64' ipv6.method "manual"

# add ipv6 gateway
nmcli connection modify ens18 ipv6.gateway 'fe80::1'

# restart NetworkManager Service
nmcli con down ens18 && nmcli con up ens18

# Show the result
nmcli device show ens18

# Enable IPV6 support in docker
vim /etc/docker/daemon.json
-------------------
{
  "ip6tables": true,
  "experimental" : true,
  "userland-proxy": true
}
------------------
systemctl restart docker.service
systemctl status docker.service

# add firewall rules
firewall-cmd --permanent --zone=public --add-port=587/tcp
firewall-cmd --permanent --zone=public --add-port=4190/tcp
firewall-cmd --add-service={smtp,smtps,imaps} --permanent --zone=public
firewall-cmd --reload
firewall-cmd --list-all
```
