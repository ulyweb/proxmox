# History command from proxmox host:

```bash
history > history-glenn-pve
cat history-glenn-pve 

hostnamectl
bash -c "$(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/tools/pve/post-pve-install.sh)"
grub-efi-amd64
lvremove /dev/pve/data
lvresize -l +100%FREE /dev/pve/root
resize2fs /dev/mapper/pve-root
pveam update
nano /etc/systemd/logind.conf
systemctl restart systemd-logind.service 
nano /etc/default/grub
reboot

curl "https://binaries.twingate.com/connector/setup.sh" | TWINGATE_ACCESS_TOKEN="eyJhbGciOiJFUzI1NiIsImtpZCI6InJjU1JQQVpEUG8wM3A4SlVqV0kyeGY1Sk81NFhVU0RsMHdvQzdnUnFyZTgiLCJ0eXAiOiJEQVQifQ.eyJudCI6IkFOIiwiYWlkIjoiNTMxMTcxIiwiZGlkIjoiMjI1Nzk5MCIsInJudyI6MTc0ODU3NjQ4OCwianRpIjoiYTNlNjFiNDYtMjVhYy00ZGU3LTgxOTMtNmZiODhkYWQ5YmVlIiwiaXNzIjoidHdpbmdhdGUiLCJhdWQiOiJ1bHlob21lIiwiZXhwIjoxNzQ4NTc5ODAwLCJpYXQiOjE3NDg1NzYyMDAsInZlciI6IjQiLCJ0aWQiOiIxNTU3MjUiLCJybmV0aWQiOiIyMDQ0NTQifQ.rSGbyTFCPSe23W9VPuyoe3o6ot5uUeM0QvG-Yct9giJGdxELUp1dM8iBeznB5dQABsUoRrzCWLQi--0ek7IL4g" TWINGATE_REFRESH_TOKEN="y2SbMszexanpT6tMn1FVeDumdWaESnHvUDaPP5n06grHGnYQlkyaDG9ojIEfSO_ko-RGrJr6lt5mijF7wBpY0oC18H8RIwpDyModKXlAfXrIdJFBd0fbQDbCOwgPF295IEtqXw" TWINGATE_NETWORK="ulyhome" TWINGATE_LABEL_DEPLOYED_BY="linux" bash

apt upgrade -y
whoami
poweroff

ps -ef | grep cr[o]n

mkdir duckdns
cd duckdns

nano duck.sh

chmod 700 duck.sh

crontab -e

./duck.sh

cat duck.log

ps -ef | grep cr[o]n

hostname -I

mkdir -p /mnt/nas_linkstation
apt update 
apt install cifs-utils -y
apt upgrade -y

nano /etc/fstab

mount -a
systemctl daemon-reload
mount -a
df -h
ls -l /mnt/nas_linkstation/
id
exit
reboot
```
