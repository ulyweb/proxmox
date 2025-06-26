
Nginx Proxy Manager
the file is under /opt/npm/compose.yaml

```bash
sudo mkdir -p /opt/npm
sudo mkdir -p /mnt/ncdata
sudo cd /opt/npm
cd /opt/npm
sudo nano compose.yaml
```


compose.yaml config file:
```bash
services:
  app:
    image: 'jc21/nginx-proxy-manager:latest'
    restart: unless-stopped
    ports:
      - '80:80'    # HTTP
      - '443:443'  # HTTPS
      - '81:81'    # Admin Panel
    volumes:
      - ./data:/data
      - ./letsencrypt:/etc/letsencrypt
```

Nextcloud All in One:
the file is under /home/localadmin/nextcloud-aio/compose.yaml

```bash
mkdir -p /home/$USER/nextcloud-aio
cd /home/$USER/nextcloud-aio
nano compose.yaml
```

compose.yaml config file:

```bash
services:
  nextcloud-aio-mastercontainer:
    image: ghcr.io/nextcloud-releases/all-in-one:latest
    container_name: nextcloud-aio-mastercontainer
    restart: always
    environment:
      # - SKIP_DOMAIN_VALIDATION=true
    ports:
      - "80:80"
      - "8080:8080"
      - "8443:8443"
    volumes:
      - nextcloud_aio_mastercontainer:/mnt/docker-aio-config
      - /var/run/docker.sock:/var/run/docker.sock:ro
      - /mnt/ncdata:/mnt/ncdata   # Mounts host's /mnt/ncdata to /mnt/ncdata in container

volumes:
  nextcloud_aio_mastercontainer:
```

```bash
sudo nano /etc/hosts
```

add 
192.168.1.60 nasmj.duckdns.org


