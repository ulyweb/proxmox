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

