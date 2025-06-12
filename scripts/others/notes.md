#### https://github.com/TechHutTV/homelab/blob/main/cloud/README.md?plain=1

#### https://techhut.tv/7-docker-basics-for-beginners/

## Nextcloud Notes

### NGINX Proxy Manager
Under details set the scheme to http, your local IP for the server, and the port 11000 then enable Block Common Exploits and Websocket Support under details. Under SSL enable Force SSL and HTTP/2 support. Under advanced add the following lines.
```
client_body_buffer_size 512k;
proxy_read_timeout 86400s;
client_max_body_size 0;
```

### Use a Network Share for Data Directory
[source](https://github.com/nextcloud/all-in-one?tab=readme-ov-file#can-i-use-a-cifssmb-share-as-nextclouds-datadir)
```
sudo nano /etc/fstab
//10.0.0.100/nextcloud /nextcloud cifs rw,mfsymlinks,seal,username=user,password=password,uid=33,gid=0,file_mode=0770,dir_mode=0770 0 0
```
### Add Files to Data Directory Manually
Nextcloud steps to add files manually to data directory. 
#### Fix permissions 
```
chown -R www-data:www-data ./directory
```
#### Scan for new files
```
sudo docker exec --user www-data -it nextcloud-aio-nextcloud php occ files:scan --all
```
### Find lost AIO Passphrase
```
docker exec nextcloud-aio-mastercontainer grep password /mnt/docker-aio-config/data/configuration.json
```

### Manage Docker as a non-root user

One step in the Linux post-installation steps is to manage Docker as a non-root user. To do this, you can add your user account to the docker group. This allows you to run Docker commands without using sudo them every time. However, it is important to note that adding a user to the docker group grants them significant privileges, as Docker allows direct access to the host system. Therefore, exercise caution when granting Docker access to non-root users, as it can potentially lead to security vulnerabilities if not properly managed and monitored.

If you want to do this, run the following commands:
```bash
sudo groupadd docker
sudo usermod -aG docker $USER
newgrp docker
```

You can check out the “convenience script” for one of the easiest ways to install it on your system. Once that’s done, any future updates will also be available through apt. Here are the commands to install using the script:
```bash
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
```
Regardless of how you install Docker on Ubuntu, the Docker systemd service will automatically start and enable. So, Docker will start automatically if the system is ever rebooted. You can check to see if it is running with the following command:
```bash
sudo systemctl status docker
```
