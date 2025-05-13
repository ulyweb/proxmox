
>[!NOTE]
>### NUCAiO-VM
>>#### ___***compose.yaml for Nextcloud AIO behind Nginx Proxy Manager.***___

````
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
      - NEXTCLOUD_DATADIR=/mnt/nc_data # Optional
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock:rw
      - nextcloud_aio_mastercontainer:/mnt/docker-aio-config
      - /mnt/nc_data:/mnt/nc_data # Optional

volumes:
  nextcloud_aio_mastercontainer:
    name: nextcloud_aio_mastercontainer
````
>[!TIP]
>### Wait until installation is finished, because you'll get some errors.
>>#### ___***To fix them, use the command below what will apply to the error.***___


````
docker exec --user www-data nextcloud-aio-nextcloud php occ config:system:set default_phone_region --value=US
docker exec --user www-data nextcloud-aio-nextcloud php occ maintenance:repair --include-expensive
docker exec --user www-data nextcloud-aio-nextcloud php occ config:system:get overwrite.cli.url
docker exec --user www-data nextcloud-aio-nextcloud php occ config:system:get trusted_proxies
docker exec --user www-data nextcloud-aio-nextcloud php occ config:system:set trusted_proxies 2 --value=10.17.76.78
docker exec --user www-data nextcloud-aio-nextcloud php occ config:system:get trusted_proxies
````
Other repair command
````
docker exec nextcloud-aio-nextcloud php occ db:add-missing-indices
docker exec --user www-data nextcloud-aio-nextcloud php -d memory_limit=1024M occ app:install richdocumentscode
docker exec --user www-data nextcloud-aio-nextcloud php occ db:add-missing-indices
docker exec --user www-data nextcloud-aio-nextcloud php occ config:system:set auth.bruteforce.protection.enabled --type=boolean --value=false #To disabling Brute-Force Protection (Recommended):
docker exec --user www-data nextcloud-aio-nextcloud php occ config:system:set auth.bruteforce.protection.enabled --type=boolean --value=true #To Re-enable Brute-Force Protection (Recommended):
docker restart nextcloud-aio-nextcloud
````

>[!TIP]
>### *This will fixed the error messages.*

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
>[!TIP]
>### *To get your current IP Address.*

````
ip a | grep "scope global" | head -1 | awk '{print $2}' | sed 's|/.*||'
````

>[!TIP]
>### *Start fresh again by removing all of them!.*

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
