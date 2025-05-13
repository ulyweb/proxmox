## 🚀 Nextcloud AIO with Nginx Proxy Manager: Docker Compose Setup

This guide provides the `compose.yaml` configuration for deploying Nextcloud All-in-One (AIO) behind Nginx Proxy Manager (NPM).

> [!NOTE]
> ### Project: NUCAiO-VM
> This `compose.yaml` is tailored for the "NUCAiO-VM" setup, demonstrating how to run Nextcloud AIO when NPM handles SSL termination and reverse proxying.

```yaml
# compose.yaml for Nextcloud AIO behind Nginx Proxy Manager

services:
  nextcloud-aio-mastercontainer:
    image: ghcr.io/nextcloud-releases/all-in-one:latest
    container_name: nextcloud-aio-mastercontainer
    restart: always
    ports:
      # Expose AIO interface on host port 8080.
      # Access it via http://<server-ip>:8080
      - 8080:8080
    environment:
      # Port for Nextcloud AIO's internal Apache server.
      # Nginx Proxy Manager will forward requests to this port.
      - APACHE_PORT=11000
      # Bind Apache to all interfaces within the container.
      - APACHE_IP_BINDING=0.0.0.0
      # Adjust memory limit for Nextcloud. Monitor usage and change if necessary.
      # Examples: 2G, 4096M
      - NEXTCLOUD_MEMORY_LIMIT=4096M
      # Optional: Define a custom host path for Nextcloud data.
      # Ensure this path exists and has correct permissions.
      - NEXTCLOUD_DATADIR=/mnt/nc_data
    volumes:
      # Required for AIO to manage other Docker containers.
      - /var/run/docker.sock:/var/run/docker.sock:rw
      # Persistent storage for AIO mastercontainer configuration.
      - nextcloud_aio_mastercontainer:/mnt/docker-aio-config
      # Optional: Mount Nextcloud data directory from the host.
      # This MUST match NEXTCLOUD_DATADIR if defined above.
      - /mnt/nc_data:/mnt/nc_data

volumes:
  nextcloud_aio_mastercontainer:
    name: nextcloud_aio_mastercontainer
```

---

## 🛠️ Post-Installation Configuration & Troubleshooting

> [!WARNING]
> ### Address Potential Setup Errors
> After the Nextcloud AIO installation completes via the web interface (`http://<server-ip>:8080`), you might encounter some common errors in the Nextcloud admin overview. These usually relate to trusted proxies, phone region, or database issues.
>
> **Execute the following commands on your Docker host to resolve them.**

### Common Fixes using `occ` commands:

Run these commands *after* the AIO setup has fully provisioned the Nextcloud container.

```bash
# Set the default phone region (e.g., US, GB, DE)
docker exec --user www-data nextcloud-aio-nextcloud php occ config:system:set default_phone_region --value=US

# Run a maintenance repair (can fix various issues)
docker exec --user www-data nextcloud-aio-nextcloud php occ maintenance:repair --include-expensive

# --- Trusted Proxies Configuration ---
# Check current overwrite.cli.url (should be your domain)
docker exec --user www-data nextcloud-aio-nextcloud php occ config:system:get overwrite.cli.url

# Check current trusted_proxies
docker exec --user www-data nextcloud-aio-nextcloud php occ config:system:get trusted_proxies

# Set your Nginx Proxy Manager's Docker IP address as a trusted proxy.
# Replace 10.17.76.78 with the actual IP of your NPM container or network gateway.
# The '2' might vary if you have other trusted proxies; it's the array index.
docker exec --user www-data nextcloud-aio-nextcloud php occ config:system:set trusted_proxies 2 --value=10.17.76.78

# Verify trusted_proxies again
docker exec --user www-data nextcloud-aio-nextcloud php occ config:system:get trusted_proxies
```

### Additional Repair and Configuration Commands:

These commands can help with database indexing, app installations, or managing security features.

```bash
# Add missing database indices
docker exec nextcloud-aio-nextcloud php occ db:add-missing-indices

# Install Nextcloud Office (Collabora RichDocuments) - increase memory limit if needed for this command
docker exec --user www-data nextcloud-aio-nextcloud php -d memory_limit=1024M occ app:install richdocumentscode

# Disable Brute-Force Protection (useful during setup or if locked out, re-enable later)
docker exec --user www-data nextcloud-aio-nextcloud php occ config:system:set auth.bruteforce.protection.enabled --type=boolean --value=false

# Re-enable Brute-Force Protection (Recommended for security)
docker exec --user www-data nextcloud-aio-nextcloud php occ config:system:set auth.bruteforce.protection.enabled --type=boolean --value=true

# Restart the Nextcloud container if changes require it
docker restart nextcloud-aio-nextcloud
```

---

## 💡 Manual Configuration & Verification Tips

> [!TIP]
> ### Fine-Tuning and Verification
> Sometimes, a deeper dive or manual check is necessary. These commands allow for direct repair, container access, and configuration file inspection.

**Force a comprehensive repair:**
This can resolve lingering issues.
```bash
docker exec --user www-data -it nextcloud-aio-nextcloud php occ maintenance:repair --include-expensive
```

**Access the Nextcloud container's shell:**
For direct troubleshooting or file system exploration.
```bash
docker exec -it nextcloud-aio-nextcloud bash
```

**Manually edit `config.php` (use with caution):**
This is useful if `occ` commands are insufficient or for specific low-level changes.
```bash
# From within the container shell (after running the command above):
cd /var/www/html/config/
vi config.php # Or use nano if installed: nano config.php
```

**Verify `trusted_proxies` and `overwriteprotocol` in `config.php`:**
This command displays the relevant lines directly from the configuration file. `overwriteprotocol` should typically be set to `https` when behind a reverse proxy handling SSL.
```bash
docker exec nextcloud-aio-nextcloud cat /var/www/html/config/config.php | grep -E "trusted_proxies|overwriteprotocol"
```

---

## 🌐 Network Information

> [!IMPORTANT]
> ### Identify Your Server's IP Address
> You'll often need your Docker host's primary IP address for accessing Nextcloud AIO's interface, configuring Nginx Proxy Manager, or setting trusted proxies if NPM is on a different host.

**Get your host's primary global IP address (Linux):**
```bash
ip a | grep "scope global" | head -1 | awk '{print $2}' | sed 's|/.*||'
```

---

## ⚠️ Reset and Clean Up Nextcloud AIO Environment

> [!CAUTION]
> ### **Start Fresh: Complete Removal of Nextcloud AIO**
> **Proceed with extreme caution!** The following commands will stop and permanently remove all Nextcloud AIO Docker containers, volumes (including potentially your data if not stored on a separate host path and backed up), and networks associated with this setup.
>
> ***This action is irreversible. Ensure you have backed up any critical data.***

**Step-by-step removal process:**

1.  **Stop all Nextcloud-related containers:**
    ```bash
    docker stop $(docker ps -a -q -f name=nextcloud)
    ```

2.  **(Optional) List all Docker containers to verify:**
    ```bash
    sudo docker ps --format "{{.Names}}"
    ```

3.  **(Optional) List exited containers:**
    ```bash
    sudo docker ps --filter "status=exited"
    ```

4.  **Remove all stopped Docker containers:**
    ```bash
    sudo docker container prune -f
    ```

5.  **Remove the Nextcloud AIO Docker network:**
    ```bash
    sudo docker network rm nextcloud-aio
    ```

6.  **(Optional) List dangling Docker volumes (unused):**
    ```bash
    sudo docker volume ls --filter "dangling=true"
    ```

7.  **Remove all Docker volumes associated with Nextcloud AIO and any other dangling volumes.**
    * **To remove ONLY Nextcloud AIO specific volumes (safer if you know their exact names):**
        First, identify them: `sudo docker volume ls`
        Then remove them: `sudo docker volume rm nextcloud_aio_mastercontainer nextcloud_aio_nextcloud ... (and other related volumes)`
    * **To remove all dangling (unused) volumes (more aggressive):**
        ```bash
        sudo docker volume prune -f
        ```
    * **To remove ALL volumes, including those in use if you filter for `all=1` (EXTREMELY DANGEROUS - ensure you understand this):**
        The original command `sudo docker volume prune -f --filter all=1` would attempt to remove *all* volumes, not just dangling ones or specific ones. This is generally not what you want unless you intend to wipe all Docker volumes on your system.
        A safer approach to remove specific named volumes after stopping containers is:
        `sudo docker volume rm nextcloud_aio_mastercontainer <any_other_nextcloud_aio_volume_names>`

8.  **(Optional) List all Docker volumes to verify:**
    ```bash
    sudo docker volume ls --format "{{.Name}}"
    ```

9.  **Remove all unused Docker images:**
    ```bash
    sudo docker image prune -a -f
    ```

---
