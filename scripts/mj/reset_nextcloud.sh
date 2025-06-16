#!/bin/bash

# --- Nextcloud AIO Stack Reset and Deploy Script ---
# This script will perform a full cleanup of your Docker environment
# and deploy a fresh, robust stack for Nextcloud AIO and Nginx Proxy Manager.
# It is designed to be run from your home directory or any parent of 'nextcloud-aio'.
#
# IMPORTANT: This script will permanently delete all unused Docker containers,
# networks, and images. This is intended to fix deep-seated issues but
# will affect other Docker projects if they are not currently running.

# Exit immediately if a command exits with a non-zero status.
set -e

# --- Configuration ---
# The directory where your compose.yaml and other data will live.
# Updated to use the explicit path you provided.
PROJECT_DIR="/home/localadmin/nextcloud-aio"

# --- Main Script ---

echo "### STEP 1: Preparing Project Directory ###"
# Create the project directory if it doesn't exist.
mkdir -p "$PROJECT_DIR"
# Navigate into the project directory.
cd "$PROJECT_DIR"
echo "==> Changed directory to $(pwd)"
echo ""

echo "### STEP 2: Full Docker System Cleanup ###"

echo "==> Stopping and removing old containers defined in compose.yaml..."
# The '|| true' prevents the script from exiting if there are no containers to stop.
sudo docker compose down -v --remove-orphans || true

echo "==> Pruning all unused Docker data (containers, networks, images)..."
# The -af flag forces the removal without prompting for confirmation.
sudo docker system prune -af

echo "==> Restarting the Docker service to ensure a clean slate..."
# This re-initializes Docker's networking.
sudo systemctl restart docker
echo "==> Docker has been restarted."
echo ""

echo "### STEP 3: Creating the Final 'compose.yaml' File ###"
# This uses a 'here document' (cat << EOF) to write the file.
# It's a reliable way to create a config file from a script.
cat << EOF > compose.yaml
version: "3.8"

# This creates a dedicated network for our containers to communicate on.
networks:
  nextcloud-network:
    name: nextcloud-network

services:
  # Nginx Proxy Manager (NPM) will handle all web traffic and SSL.
  nginx-proxy-manager:
    image: 'docker.io/jc21/nginx-proxy-manager:latest'
    restart: unless-stopped
    container_name: nginx-proxy-manager
    ports:
      # Exposes web ports to your host machine.
      - "80:80"
      - "443:443"
      # Exposes the NPM admin UI port.
      - "81:81"
    volumes:
      - ./npm/data:/data
      - ./npm/letsencrypt:/etc/letsencrypt
    # Attaches NPM to our dedicated network.
    networks:
      nextcloud-network:
        # This is the key: it makes NPM respond to your domain name inside Docker.
        aliases:
          - nasmj.duckdns.org

  # Nextcloud All-in-One (AIO) master container.
  nextcloud-aio-mastercontainer:
    image: ghcr.io/nextcloud-releases/all-in-one:latest
    init: true
    restart: always
    container_name: nextcloud-aio-mastercontainer
    # This ensures NPM starts before AIO.
    depends_on:
      - nginx-proxy-manager
    volumes:
      - nextcloud_aio_mastercontainer:/mnt/docker-aio-config
      - /var/run/docker.sock:/var/run/docker.sock:ro
    ports:
      # Only the AIO interface port needs to be exposed for initial setup.
      - "8080:8080"
    environment:
      # The internal port that AIO will run the Nextcloud apache service on.
      APACHE_PORT: 11000
      # Trusts requests coming from any container on the Docker network.
      NC_TRUSTED_PROXIES: 172.16.0.0/12
      # Below are your custom settings from before.
      NEXTCLOUD_DATADIR: /mnt/ncdata
      NEXTCLOUD_UPLOAD_LIMIT: 1028G
      NEXTCLOUD_MAX_TIME: 7200
      NEXTCLOUD_MEMORY_LIMIT: 4096M
      TALK_PORT: 3478
    # Attaches AIO to the same dedicated network as NPM.
    networks:
      - nextcloud-network

volumes:
  nextcloud_aio_mastercontainer:
    name: nextcloud_aio_mastercontainer
EOF

echo "==> 'compose.yaml' has been created successfully."
echo ""

echo "### STEP 4: Starting the New Docker Stack ###"
sudo docker compose up -d
echo ""
echo "==> All containers have been started."
echo ""

echo "#####################################################################"
echo "### SCRIPT COMPLETE - MANUAL ACTION REQUIRED ###"
echo "#####################################################################"
echo ""
echo "The automated script has finished. You must now configure Nginx Proxy Manager."
echo ""
echo "1. Wait about 60 seconds for the containers to fully initialize."
echo "2. Open your web browser and go to: http://192.168.1.60:81"
echo "3. Log in to Nginx Proxy Manager."
echo "4. Go to 'Hosts' -> 'Proxy Hosts' and edit your 'nasmj.duckdns.org' entry."
echo "5. On the 'Details' tab, set the forwarding details to EXACTLY this:"
echo "   - Forward Hostname / IP:  nextcloud-aio-mastercontainer"
echo "   - Forward Port:           11000"
echo "6. Make sure 'Websockets Support' is enabled."
echo "7. Click 'Save'."
echo ""
echo "After saving the changes in Nginx Proxy Manager, your Nextcloud instance"
echo "and the Admin Overview page should load quickly and without errors."
echo "#####################################################################"

