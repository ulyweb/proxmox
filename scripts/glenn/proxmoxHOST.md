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

Twingate look for your ncaio notepad

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
