>[!NOTE]
>Nextcloud All-in-One yaml file without reverse proxy.

### Make compose.yaml file
```bash
nano ~/compose.yaml
```

```bash
services:
  nextcloud-aio-mastercontainer:
    image: ghcr.io/nextcloud-releases/all-in-one:latest
    init: true
    restart: always
    container_name: nextcloud-aio-mastercontainer
    volumes:
      - nextcloud_aio_mastercontainer:/mnt/docker-aio-config
      - /var/run/docker.sock:/var/run/docker.sock:ro
    network_mode: bridge
    ports:
      - 80:80
      - 8080:8080
      - 8443:8443
    environment: 
      # APACHE_PORT: 11000 # Is needed when running behind a web server or reverse proxy (like Apache, Nginx, Caddy, Cloudflare Tunnel and else). See https://github.com/nextcloud/all-in-one/blob/main/reverse-proxy.md
      # APACHE_IP_BINDING: 127.0.0.1 # Should be set when running behind a web server or reverse proxy (like Apache, Nginx, Caddy, Cloudflare Tunnel and else) that is running on the same host. See https://github.com/nextcloud/all-in-one/blob/main/reverse-proxy.md
      FULLTEXTSEARCH_JAVA_OPTIONS: "-Xms1024M -Xmx1024M" # Allows to adjust the fulltextsearch java options. See https://github.com/nextcloud/all-in-one#how-to-adjust-the-fulltextsearch-java-options
      NEXTCLOUD_DATADIR: /mnt/ncdata # Allows to set the host directory for Nextcloud's datadir. ⚠️⚠️⚠️ Warning: do not set or adjust this value after the initial Nextcloud installation is done! See https://github.com/nextcloud/all-in-one#how-to-change-the-default-location-of-nextclouds-datadir
      # NEXTCLOUD_MOUNT: /mnt/ # Allows the Nextcloud container to access the chosen directory on the host. See https://github.com/nextcloud/all-in-one#how-to-allow-the-nextcloud-container-to-access-directories-on-the-host
      NEXTCLOUD_UPLOAD_LIMIT: 16G # Can be adjusted if you need more. See https://github.com/nextcloud/all-in-one#how-to-adjust-the-upload-limit-for-nextcloud
      NEXTCLOUD_MAX_TIME: 3600 # Can be adjusted if you need more. See https://github.com/nextcloud/all-in-one#how-to-adjust-the-max-execution-time-for-nextcloud
      NEXTCLOUD_MEMORY_LIMIT: 4096M # Can be adjusted if you need more. See https://github.com/nextcloud/all-in-one#how-to-adjust-the-php-memory-limit-for-nextcloud
      # NEXTCLOUD_TRUSTED_CACERTS_DIR: /path/to/my/cacerts # CA certificates in this directory will be trusted by the OS of the nextcloud container (Useful e.g. for LDAPS) See https://github.com/nextcloud/all-in-one#how-to-trust-user-defined-certification-authorities-ca
      # NEXTCLOUD_STARTUP_APPS: deck twofactor_totp tasks calendar contacts notes # Allows to modify the Nextcloud apps that are installed on starting AIO the first time. See https://github.com/nextcloud/all-in-one#how-to-change-the-nextcloud-apps-that-are-installed-on-the-first-startup
      # NEXTCLOUD_ADDITIONAL_APKS: imagemagick # This allows to add additional packages to the Nextcloud container permanently. Default is imagemagick but can be overwritten by modifying this value. See https://github.com/nextcloud/all-in-one#how-to-add-os-packages-permanently-to-the-nextcloud-container
      NEXTCLOUD_ADDITIONAL_PHP_EXTENSIONS: imagick # This allows to add additional php extensions to the Nextcloud container permanently. Default is imagick but can be overwritten by modifying this value. See https://github.com/nextcloud/all-in-one#how-to-add-php-extensions-permanently-to-the-nextcloud-container
      # NEXTCLOUD_ENABLE_DRI_DEVICE: true # This allows to enable the /dev/dri device for containers that profit from it. ⚠️⚠️⚠️ Warning: this only works if the '/dev/dri' device is present on the host! If it should not exist on your host, don't set this to true as otherwise the Nextcloud container will fail to start! See https://github.com/nextcloud/all-in-one#how-to-enable-hardware-acceleration-for-nextcloud
      # NEXTCLOUD_ENABLE_NVIDIA_GPU: true # This allows to enable the NVIDIA runtime and GPU access for containers that profit from it. ⚠️⚠️⚠️ Warning: this only works if an NVIDIA gpu is installed on the server. See https://github.com/nextcloud/all-in-one#how-to-enable-hardware-acceleration-for-nextcloud.
      # NEXTCLOUD_KEEP_DISABLED_APPS: false # Setting this to true will keep Nextcloud apps that are disabled in the AIO interface and not uninstall them if they should be installed. See https://github.com/nextcloud/all-in-one#how-to-keep-disabled-apps
      SKIP_DOMAIN_VALIDATION: true 
      # TALK_PORT: 3478 # This allows to adjust the port that the talk container is using which is exposed on the host. See https://github.com/nextcloud/all-in-one#how-to-adjust-the-talk-port

#   # Optional: Caddy reverse proxy. See https://github.com/nextcloud/all-in-one/discussions/575
#   # Alternatively, use Tailscale if you don't have a domain yet. See https://github.com/nextcloud/all-in-one/discussions/5439
#   # Hint: You need to uncomment APACHE_PORT: 11000 above, adjust cloud.example.com to your domain and uncomment the necessary docker volumes at the bottom of this file in order to make it work
#   # You can find further examples here: https://github.com/nextcloud/all-in-one/discussions/588
#   caddy:
#     image: caddy:alpine
#     restart: always
#     container_name: caddy
#     volumes:
#       - caddy_certs:/certs
#       - caddy_config:/config
#       - caddy_data:/data
#       - caddy_sites:/srv
#     network_mode: "host"
#     configs:
#       - source: Caddyfile
#         target: /etc/caddy/Caddyfile
# configs:
#   Caddyfile:
#     content: |
#       # Adjust cloud.example.com to your domain below
#       https://cloud.example.com:443 {
#         reverse_proxy localhost:11000
#       }

volumes: # If you want to store the data on a different drive, see https://github.com/nextcloud/all-in-one#how-to-store-the-filesinstallation-on-a-separate-drive
  nextcloud_aio_mastercontainer:
    name: nextcloud_aio_mastercontainer # This line is not allowed to be changed as otherwise the built-in backup solution will not work
  # caddy_certs:
  # caddy_config:
  # caddy_data:
  # caddy_sites:
```

### or direct setup without Proxy

>[!NOTE]
>To set up port forwarding on your AT&T BGW320-505 router for Nextcloud AIO with DuckDNS, follow these steps:

---

## **Step 1: Configure Port Forwarding on AT&T Router**
1. **Log into your router**:
   - Go to `http://192.168.1.254` in your browser.
   - Enter the **Device Access Code** (found on the router’s label).

2. **Create custom port forwarding rules**:
   - Navigate to **Firewall > NAT/Gaming**.
   - For each port below, create a **Custom Service**:
     | Service Name      | Global Port Range | Protocol | Host Port | Host IP Address    |
     |-------------------|-------------------|----------|-----------|--------------------|
     | Nextcloud_HTTP    | 80-80             | TCP      | 80        | 192.168.1.60      |
     | Nextcloud_HTTPS   | 443-443           | TCP      | 443       | 192.168.1.60      |
     | Nextcloud_Stun    | 3478-3478         | TCP/UDP  | 3478      | 192.168.1.60      |
     | Nextcloud_AIO     | 8443-8443         | TCP      | 8443      | 192.168.1.60      |

   - Save each rule and ensure they appear in the "Active NAT/Gaming Rules" list.

---

## **Step 2: Verify DuckDNS Configuration**
1. **Update DuckDNS record**:
   - Ensure `nasmj.duckdns.org` points to your public IP (check via `curl -4 icanhazip.com`).
   - Use DuckDNS’s update script or web interface to refresh the IP if needed.

---

## **Step 3: Run Nextcloud AIO Docker Command**
Use this command for Linux (adjust for ARM64 if using Raspberry Pi):
```bash
sudo docker run \
--sig-proxy=false \
--name nextcloud-aio-mastercontainer \
--restart always \
--publish 80:80 \
--publish 8080:8080 \
--publish 8443:8443 \
--volume nextcloud_aio_mastercontainer:/mnt/docker-aio-config \
--volume /var/run/docker.sock:/var/run/docker.sock:ro \
ghcr.io/nextcloud-releases/all-in-one:latest
```

---

## **Step 4: Complete Nextcloud Setup**
1. **Access the AIO interface**:
   - Open `https://192.168.1.60:8443` (local) or `https://nasmj.duckdns.org:8443` (external).
   - Follow the prompts to configure your domain and SSL certificate.

2. **Verify port accessibility**:
   - Use ````https://portchecker.co```` to confirm ports 80, 443, 3478, and 8443 are open.
   - Use ````https://www.yougetsignal.com/tools/open-ports/```` to confirm ports 80, 443, 3478, and 8443 are open.
---

## **Troubleshooting Tips**
- **Firewall**: Ensure Windows Defender/other firewalls allow inbound traffic for the ports listed above.
- **Router Reboot**: Restart the AT&T router after configuring port forwarding.
- **SSL Errors**: If certificates fail, manually renew via `sudo docker exec -it nextcloud-aio-mastercontainer /bin/bash -c "apk add curl && certbot renew"`.

Once complete, your Nextcloud AIO instance will be accessible at `https://nasmj.duckdns.org`!
