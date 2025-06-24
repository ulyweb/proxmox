>[!NOTE]
> Install AIO
>Now, open the Terminal and start AIO with this command:

# For Linux and without a web server or reverse proxy (like Apache, Nginx and else) already in place:

```bash
sudo docker run \
--sig-proxy=false \
--name nextcloud-aio-mastercontainer \
--restart always \
--publish 80:80 \
--publish 8080:8080 \
--publish 8443:8443 \
-e SKIP_DOMAIN_VALIDATION=true \
--volume nextcloud_aio_mastercontainer:/mnt/docker-aio-config \
--volume /var/run/docker.sock:/var/run/docker.sock:ro \
ghcr.io/nextcloud-releases/all-in-one:latest
```


>[!TIP]
> ## Here’s how your `docker run` command translates into a `compose.yaml` (or `docker-compose.yml`) file for use with Docker Compose:

---

## **1. Create a compose.yaml File**

Paste the following into a file named `compose.yaml`:

```yaml
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

---

## **2. How to Use This File**

1. **Save the file as `compose.yaml` in your project directory.**
2. **Start the services with:**
   ```bash
   sudo docker compose up -d
   ```
   (Note: If you are using an older version of Docker, you may need to use `docker-compose up -d` instead.)

---

## **Notes**

- **The `--sig-proxy=false` option is not available in Docker Compose by default.**  
  - This option is used for signal handling in `docker run`. Most users do not need to worry about this in Compose.
  - If you specifically need this behavior, you may need to use a custom entrypoint or script, but it is rarely required for Nextcloud AIO.
- **Everything else in your command is mapped directly to the Compose file.**
- **The `volumes:` section at the bottom ensures the named volume is created.**

---

**You’re all set!**  
This `compose.yaml` will give you the same setup as your original Docker command.
