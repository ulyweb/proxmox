## This will fixed the error messages
````
docker exec --user www-data -it nextcloud-aio-nextcloud php occ maintenance:repair --include-expensive
````
````
docker exec -it nextcloud-aio-nextcloud bash
````
````
cd /var/www/html/config/
vi config.php
````
````
cat /var/www/html/config/config.php | grep -E "trusted_proxies|overwriteprotocol"
````
### To get your current IP Address
````
ip a | grep "scope global" | head -1 | awk '{print $2}' | sed 's|/.*||'
````
### Removing all again!
````
docker stop $(docker ps -a -q -f name=nextcloud)
sudo docker ps --format {{.Names}}
sudo docker ps --filter "status=exited"
sudo docker container prune -f 
sudo docker network rm nextcloud-aio
sudo docker volume ls --filter "dangling=true"
sudo docker volume prune -f --filter all=1 
sudo docker volume ls --format {{.Name}}
sudo docker image prune -a -f
````


## NUCAiO-VM
````
# compose.yaml for Nextcloud AIO behind Nginx Proxy Manager
# Running inside Proxmox VM

services:
  nextcloud-aio-mastercontainer:
    image: ghcr.io/nextcloud-releases/all-in-one:latest
    container_name: nextcloud-aio-mastercontainer
    restart: always
    ports:
      - 8080:8080
    environment:
      - APACHE_PORT=11000
      - APACHE_IP_BINDING=0.0.0.0
      - NEXTCLOUD_MEMORY_LIMIT=4096M # Adjust if needed based on monitoring
      - NEXTCLOUD_DATADIR=/mnt/nextcloud # Optional
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock:rw
      - nextcloud_aio_mastercontainer:/mnt/docker-aio-config
      - /mnt/nextcloud:/mnt/ncdata # Optional

volumes:
  nextcloud_aio_mastercontainer:
    name: nextcloud_aio_mastercontainer
````
