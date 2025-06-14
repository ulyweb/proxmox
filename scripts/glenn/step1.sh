mkdir -p /mnt/ncdata
mkdir -p /home/$USER/nextcloud-aio/
cd /home/$USER/nextcloud-aio/
wget -O .env https://github.com/immich-app/immich/releases/latest/download/example.env
mkdir -p /home/$USER/immich-app/
cd /home/$USER/immich-app/
wget -O docker-compose.yml https://github.com/immich-app/immich/releases/latest/download/docker-compose.yml
wget -O .env https://github.com/immich-app/immich/releases/latest/download/example.env
