#!/bin/bash

# --- Nextcloud AIO Stack Reset and Deploy Script ---
# This script will perform a full cleanup of your Docker environment
# and deploy a fresh, robust stack for Nextcloud AIO and Nginx Proxy Manager.
# It is designed to be run from your home directory or any parent of 'nextcloud-aio'.
#
# IMPORTANT: This script will permanently delete all Docker containers,
# networks (including default ones if possible), and images. This is intended
# to fix deep-seated issues by providing a completely fresh Docker environment.

# Exit immediately if a command exits with a non-zero status.
set -e

# --- Configuration ---
# The directory where your compose.yaml and other data will live.
PROJECT_DIR="/home/localadmin/nextcloud-aio"
# The directory where Nextcloud data will be stored on the host.
NEXTCLOUD_DATA_DIR="/mnt/ncdata"

# --- Style Definitions ---
BOLD=$(tput bold)
BLUE=$(tput setaf 4)
GREEN=$(tput setaf 2)
RED=$(tput setaf 1)
YELLOW=$(tput setaf 3)
NC=$(tput sgr0) # No Color

# --- Main Script ---

echo -e "${BLUE}${BOLD}### STEP 1: Preparing Project Directory ###${NC}"
# Create the project directory if it doesn't exist.
mkdir -p "$PROJECT_DIR"
# Navigate into the project directory.
cd "$PROJECT_DIR"
echo -e "==> ${GREEN}Changed directory to $(pwd)${NC}"
echo ""

echo -e "${BLUE}${BOLD}### STEP 2: Full Docker System Cleanup ###${NC}"

echo "==> Stopping and removing old containers defined in compose.yaml..."
# The '|| true' prevents the script from exiting if there are no containers to stop.
sudo docker compose down -v --remove-orphans || true
echo -e "==> ${GREEN}Old containers stopped and removed.${NC}"

echo "==> Attempting to remove ALL Docker networks (user-defined and default)..."
NETWORKS_TO_REMOVE=$(sudo docker network ls -q)
if [ -n "$NETWORKS_TO_REMOVE" ]; then
    echo "    Removing networks: $(echo "$NETWORKS_TO_REMOVE" | tr '\n' ' ')"
    sudo docker network rm $NETWORKS_TO_REMOVE || true
    echo -e "==> ${GREEN}Attempted to remove all Docker networks. Some default networks may persist or be recreated.${NC}"
else
    echo -e "==> ${GREEN}No Docker networks found to remove.${NC}"
fi


echo "==> Pruning all unused Docker data (containers, networks, images, build cache)..."
# The -af flag forces the removal without prompting for confirmation.
sudo docker system prune -af
echo -e "==> ${GREEN}Unused Docker data pruned.${NC}"

echo "==> Restarting the Docker service to ensure a clean slate and network re-initialization..."
# This re-initializes Docker's networking.
sudo systemctl restart docker
echo -e "==g> ${GREEN}Docker has been restarted.${NC}"
echo ""

# --- Create NEXTCLOUD_DATADIR if it doesn't exist ---
echo -e "${BLUE}${BOLD}### STEP 3: Ensuring Nextcloud Data Directory Exists ###${NC}"
if [ ! -d "$NEXTCLOUD_DATA_DIR" ]; then
    echo "==> Nextcloud data directory '$NEXTCLOUD_DATA_DIR' does not exist. Creating it..."
    sudo mkdir -p "$NEXTCLOUD_DATA_DIR"
    echo -e "==> ${GREEN}Directory '$NEXTCLOUD_DATA_DIR' created successfully.${NC}"
else
    echo -e "==> ${GREEN}Nextcloud data directory '$NEXTCLOUD_DATA_DIR' already exists.${NC}"
fi
echo ""

# --- Prompt Section for Compose File Creation and Startup ---
echo -e "${BLUE}${BOLD}### STEP 4: Action Required - Compose File Creation and Startup ###${NC}"
echo "Docker environment cleanup is complete and essential directories are prepared."
echo ""
echo -e "Do you want to ${GREEN}re-create compose.yaml and start the Docker stack${NC}?"
echo -e "  ${GREEN}1) Re-create compose.yaml and start Docker stack${NC}"
echo -e "  ${RED}q) Quit and exit the script${NC}"
echo
read -p "Enter your choice (1 or q): " choice_final

case "$choice_final" in
    1)
        echo -e "\n${BLUE}${BOLD}--- Proceeding with compose.yaml creation and Docker stack startup ---${NC}"
        ;;
    q|Q)
        echo -e "\n${YELLOW}Quitting. No new compose.yaml will be created, and no Docker stack will be started.${NC}"
        echo -e "${RED}Reminder: Your Docker environment has been aggressively pruned. You may need to manually bring up other services if they existed.${NC}"
        exit 0
        ;;
    *)
        echo -e "\n${RED}Invalid choice. Exiting script. No new compose.yaml will be created, and no Docker stack will be started.${NC}"
        exit 1
        ;;
esac

echo ""
echo -e "${BLUE}${BOLD}### STEP 5: Creating the Final 'compose.yaml' File ###${NC}"
# This uses a 'here document' (cat << EOF) to write the file.
# It's a reliable way to create a config file from a script.
cat << EOF > compose.yaml
services:

  # Remove the nginx-proxy-manager service if running elsewhere
  nginx-proxy-manager:
    image: 'docker.io/jc21/nginx-proxy-manager:latest'
    restart: unless-stopped
    container_name: nginx-proxy-manager
    network_mode: host
    environment: # Uncomment this if IPv6 is not enabled on your host
      - DISABLE_IPV6=true # Uncomment this if IPv6 is not enabled on your host
    volumes:
      - ./npm/data:/data
      - ./npm/letsencrypt:/etc/letsencrypt

  nextcloud-aio-mastercontainer:
    image: ghcr.io/nextcloud-releases/all-in-one:latest
    init: true
    restart: always
    container_name: nextcloud-aio-mastercontainer # This line is not allowed to be changed.
    network_mode: bridge
    volumes:
      - nextcloud_aio_mastercontainer:/mnt/docker-aio-config # This line is not allowed to be changed.
      - /var/run/docker.sock:/var/run/docker.sock:ro
    ports:
      - 8080:8080
    environment:
      # AIO_COMMUNITY_CONTAINERS: "local-ai memories" # Community containers https://github.com/nextcloud/all-in-one/tree/main/community-containers
      APACHE_PORT: 11000 # Use this port in Nginx Proxy Manager
      # NC_TRUSTED_PROXIES: 172.18.0.3 # this is the NPM proxy ip address in the docker network !
      # FULLTEXTSEARCH_JAVA_OPTIONS: "-Xms1024M -Xmx1024M"
      NEXTCLOUD_DATADIR: /mnt/ncdata # ⚠️ Warning: do not set or adjust this value after the initial Nextcloud installation is done!
      # NEXTCLOUD_MOUNT: /mnt/ # Allows the Nextcloud container to access the chosen directory on the host.
      NEXTCLOUD_UPLOAD_LIMIT: 1028G
      NEXTCLOUD_MAX_TIME: 7200
      NEXTCLOUD_MEMORY_LIMIT: 4096M
      # NEXTCLOUD_ENABLE_DRI_DEVICE: true # Intel QuickSync
      SKIP_DOMAIN_VALIDATION: True # This should only be set to true if things are correctly configured.
      TALK_PORT: 3478 # This allows to adjust the port that the talk container is using which is exposed on the host. See https://github.com/nextcloud/all-in-one#how-to-adjust-the-talk-port

volumes:
  nextcloud_aio_mastercontainer:
    name: nextcloud_aio_mastercontainer # This line is not allowed to be changed.
EOF

echo -e "==> '${GREEN}compose.yaml' has been created successfully.${NC}"
echo ""

echo -e "${BLUE}${BOLD}### STEP 6: Starting the New Docker Stack ###${NC}"
sudo docker compose up -d
echo -e "==> ${GREEN}All containers have been started.${NC}"
echo ""

echo -e "${GREEN}${BOLD}#####################################################################${NC}"
echo -e "${GREEN}${BOLD}### SCRIPT COMPLETE - MANUAL ACTION REQUIRED ###${NC}"
echo -e "${GREEN}${BOLD}#####################################################################${NC}"
echo ""
echo "The automated script has finished. You must now configure Nginx Proxy Manager."
echo ""
echo "1. Wait about 60 seconds for the containers to fully initialize."
echo "2. Open your web browser and go to: ${YELLOW}http://192.168.1.60:81${NC}"
echo "3. Log in to Nginx Proxy Manager."
echo "4. Go to 'Hosts' -> 'Proxy Hosts' and edit your 'nasmj.duckdns.org' entry."
echo "5. On the 'Details' tab, set the forwarding details to EXACTLY this:"
echo "    - Forward Hostname / IP:   ${YELLOW}nextcloud-aio-mastercontainer${NC}"
echo "    - Forward Port:            ${YELLOW}11000${NC}"
echo "6. Make sure 'Websockets Support' is enabled."
echo "7. Click 'Save'."
echo ""
echo "After saving the changes in Nginx Proxy Manager, your Nextcloud instance"
echo "and the Admin Overview page should load quickly and without errors."
echo -e "${GREEN}${BOLD}#####################################################################${NC}"
