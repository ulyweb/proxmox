
>[!NOTE]
>### NUCAiO-VM
>>#### ___***compose.yaml for Nextcloud AIO behind Nginx Proxy Manager.***___

# Glenn
````
services:
  nextcloud-aio-mastercontainer:
    image: ghcr.io/nextcloud-releases/all-in-one:latest
    container_name: nextcloud-aio-mastercontainer
    restart: always
    ports:
      - 8080:8080
    environment:
      APACHE_PORT: 11000
      APACHE_IP_BINDING: 0.0.0.0
      NEXTCLOUD_MEMORY_LIMIT: 4096M # Adjust if needed based on monitoring
      FULLTEXTSEARCH_JAVA_OPTION: "-Xms1024M -Xmx1024M"
      NEXTCLOUD_UPLOAD_LIMIT: 1024G
      # NEXTCLOUD_ENABLE_DRI_DEVICE: TRUE
      NEXTCLOUD_MAX_TIME: 7200
      SKIP_DOMAIN_VALIDATION: false
      TALK_PORT: 3478
      NEXTCLOUD_DATADIR: /mnt/nc_data # Optional
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock:rw
      - nextcloud_aio_mastercontainer:/mnt/docker-aio-config
      - /mnt/nc_data:/mnt/nc_data # Optional

volumes:
  nextcloud_aio_mastercontainer:
    name: nextcloud_aio_mastercontainer
````
#
>[!WARNING]
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
#
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
#
>[!IMPORTANT]
>### *To get your current IP Address.*
````
ip a | grep "scope global" | head -1 | awk '{print $2}' | sed 's|/.*||'
````
#
>[!CAUTION]
>## *Start fresh again by removing all of them!.*
> **Proceed with extreme caution!**
>> ***This action is irreversible.***
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


# Phase 1: Complete Docker Cleanup (Run this in your VM ncaio)

WARNING: This will delete your current Nextcloud AIO Docker setup and any associated Docker volumes that are not already on an external mount. Double-check that any data you care about is either on the NAS already (from previous attempts) or backed up.

## Run your cleanup script inside the VM (ncaio):
````
# Stop all containers with 'nextcloud' in the name
docker stop $(docker ps -a -q -f name=nextcloud)

# List running container names (for your info)
sudo docker ps --format {{.Names}}

# List exited containers (for your info)
sudo docker ps --filter "status=exited"

# Remove all stopped containers
sudo docker container prune -f

# Attempt to remove the nextcloud-aio network (might fail if not exists, that's okay)
sudo docker network rm nextcloud-aio || true # Added '|| true' to prevent script stopping on error

# List dangling volumes (for your info)
sudo docker volume ls --filter "dangling=true"

# Prune all unused (dangling) volumes AND any volume not currently attached to a container (filter all=1)
# This is aggressive. Be sure this is what you want.
sudo docker volume prune -f --filter all=1

# List remaining volumes (for your info)
sudo docker volume ls --format {{.Name}}

# Prune all unused images (not just dangling)
sudo docker image prune -a -f
````

# Phase 2: Prepare and Verify NAS Mount in VM (ncaio)

Stop a Moment - Check /mnt/nc_data contents:
Before re-doing fstab or mounting, if you had previous attempts to move data:

````Bash
ls -lah /mnt/nc_data
````

If this directory contains data from a previous Nextcloud installation that you want to use for this new install, leave it. If you want the NAS share to be completely fresh for Nextcloud (and any data is already backed up elsewhere or truly not needed), you might need to manually clean out the share folder on your NAS itself before proceeding. For a truly "fresh" Nextcloud install, this directory (seen from the VM, pointing to the NAS) should ideally be empty or only contain the structure Nextcloud AIO creates.

Edit /etc/fstab for Correct Permissions and Automount:

Open /etc/fstab in your VM:

````Bash
sudo nano /etc/fstab
````
Ensure you have only one line for your NAS share, and modify it as follows. We'll set uid and gid to 33, which is commonly used by www-data (the user Nextcloud runs as inside its container). This makes the files on the NAS appear to be owned by www-data:www-data from the VM's perspective, which simplifies permissions for the container.

````Code snippet

//192.168.1.223/share /mnt/nc_data cifs username=admin,password=password,uid=33,gid=33,vers=2.0,iocharset=utf8,file_mode=0770,dir_mode=0770,nofail 0 0
````
Key changes/points:

uid=33,gid=33: This is the crucial part for Nextcloud write access.
vers=2.0: The version you found works.
file_mode=0770,dir_mode=0770: Gives read/write/execute to the owner (which we've set to UID 33) and the group (GID 33).
nofail: Good practice for network mounts.
Ensure your NAS username (admin) and password (223NAS6tb) are correct.
Save the file (Ctrl+X, Y, Enter).

Unmount (if already mounted) and Remount with New fstab Settings:

````Bash
sudo umount /mnt/nc_data # Might say 'not mounted', that's fine
sudo systemctl daemon-reload
sudo mount -a
````
Verify the Mount and Permissions:

Check if it's mounted:
````Bash
df -h
````
(You should see //192.168.1.223/share on /mnt/nc_data).
Check ownership and permissions of the mount point itself from within the VM:
````Bash
ls -ld /mnt/nc_data
````
The output should show that /mnt/nc_data is owned by UID 33 and GID 33 (which might display as www-data or just 33 if your VM doesn't have a local user/group named www-data with that ID, but the numeric ID is what matters). The permissions should reflect drwxrwx---.
Test Write Access to /mnt/nc_data (as root, then check as user 33 conceptually):
Since UID/GID 33 now "owns" the mount from the VM's perspective, any process running as UID 33 should be able to write to it. Docker containers launched by the AIO master (which runs as root) should also be able to write and manage permissions within it.

As root (or using sudo), try creating a test file:
````Bash
sudo touch /mnt/nc_data/test_from_root.txt
sudo ls -l /mnt/nc_data/test_from_root.txt
````
This should succeed. The file created should also show as owned by UID/GID 33 because of the mount options.

````Bash
sudo rm /mnt/nc_data/test_from_root.txt
````
This confirms the mount is writable by processes that can assume UID 33 (like Nextcloud's container) or by root (like the Docker daemon and AIO mastercontainer).

# Phase 3: Deploy Fresh Nextcloud AIO (in VM ncaio)

Navigate to your compose.yaml directory:
