#!/bin/bash

# =================================================================================
# Interactive Docker Cleanup Script for Nextcloud AIO
#
# This script automates the process of stopping Nextcloud containers and
# performing an aggressive cleanup of Docker resources, including stopped
# containers, specific networks, unused volumes, and all unused images.
#
# It is designed to be run interactively to prevent accidental data loss.
#
# =================================================================================

# --- Style Definitions ---
BOLD=$(tput bold)
BLUE=$(tput setaf 4)
GREEN=$(tput setaf 2)
RED=$(tput setaf 1)
YELLOW=$(tput setaf 3)
NC=$(tput sgr0) # No Color

# --- Function to check if run as root ---
check_root() {
  if [ "$(id -u)" -ne 0 ]; then
    echo -e "\n${YELLOW}${BOLD}Warning: This script uses 'docker' commands that may require root privileges (or user in 'docker' group).${NC}"
    echo -e "If you encounter permission errors, please run with 'sudo ./your_script_name.sh'\n"
  fi
}

# --- Function to ask for confirmation ---
confirm() {
    read -r -p "${1:-Are you sure? [y/N]} " response
    case "$response" in
        [yY][eE][sS]|[yY])
            true
            ;;
        *)
            false
            ;;
    esac
}

# --- MAIN SCRIPT ---

# --- Initial Check and Master Warning ---
check_root
echo -e "${BLUE}${BOLD}Welcome to the Interactive Docker Cleanup Script for Nextcloud.${NC}"
echo -e "${RED}${BOLD}WARNING: This script will perform DESTRUCTIVE actions that remove Docker containers, volumes, and images. Please read each step carefully.${NC}"
echo

if ! confirm "Do you wish to proceed with the cleanup process? [y/N]"; then
    echo "Cleanup aborted by user."
    exit 0
fi

# --- Step 1: Stop Nextcloud Containers ---
echo -e "\n${BLUE}${BOLD}--- Step 1: Stop Nextcloud Containers ---${NC}"
NEXTCLOUD_CONTAINERS=$(docker ps -a -q -f name=nextcloud)

if [ -z "$NEXTCLOUD_CONTAINERS" ]; then
    echo -e "${GREEN}No containers with 'nextcloud' in the name found.${NC}"
else
    echo "The following containers will be stopped:"
    docker ps -a --format "  - {{.Names}} (ID: {{.ID}}, Status: {{.Status}})" -f name=nextcloud
    echo
    if confirm "Proceed with stopping these containers? [y/N]"; then
        echo "Stopping containers..."
        docker stop $NEXTCLOUD_CONTAINERS
        echo -e "${GREEN}Done.${NC}"
    else
        echo "Skipping container stop. Note that subsequent cleanup steps may be less effective."
    fi
fi

# --- Step 2: Prune Stopped Containers ---
echo -e "\n${BLUE}${BOLD}--- Step 2: Remove All Stopped Containers ---${NC}"
echo "This will remove all containers on your system that are in a 'stopped' state."
echo
if confirm "Proceed with 'docker container prune'? [y/N]"; then
    docker container prune -f
    echo -e "${GREEN}All stopped containers have been removed.${NC}"
else
    echo "Skipping container prune."
fi

# --- Step 3: Remove Nextcloud AIO Network ---
echo -e "\n${BLUE}${BOLD}--- Step 3: Remove 'nextcloud-aio' Network ---${NC}"
echo "This will attempt to remove the Docker network named 'nextcloud-aio'."
echo "It's okay if this step fails; it just means the network doesn't exist."
echo
if confirm "Attempt to remove the 'nextcloud-aio' network? [y/N]"; then
    docker network rm nextcloud-aio > /dev/null 2>&1 || true
    echo -e "${GREEN}Attempted to remove 'nextcloud-aio' network.${NC}"
else
    echo "Skipping network removal."
fi

# --- Step 4: Prune Docker Volumes (Aggressive) ---
echo -e "\n${RED}${BOLD}--- Step 4: AGGRESSIVE Volume Cleanup ---${NC}"
echo -e "${YELLOW}This is the most dangerous step. The command 'docker volume prune --filter all=1'"
echo -e "${YELLOW}will permanently delete ALL Docker volumes that are NOT currently being used"
echo -e "${YELLOW}by a ${BOLD}RUNNING${YELLOW} container. This is more than just 'dangling' volumes."
echo -e "${RED}${BOLD}This can lead to permanent data loss if you have data in volumes for stopped containers that you wish to keep.${NC}"
echo
echo "Here is a list of all volumes currently on your system:"
docker volume ls --format "  - {{.Name}}"
echo
if confirm "${RED}${BOLD}Are you absolutely sure you want to prune all unused volumes? [y/N]${NC}"; then
    docker volume prune -f --filter all=1
    echo -e "${GREEN}All unused volumes have been removed.${NC}"
else
    echo "Skipping volume prune."
fi

# --- Step 5: Prune Docker Images ---
echo -e "\n${BLUE}${BOLD}--- Step 5: Prune All Unused Images ---${NC}"
echo "This step will remove all Docker images that are not associated with an existing container."
echo "This is more aggressive than a standard prune and will remove dangling and unused images."
echo
if confirm "Proceed with 'docker image prune -a'? [y/N]"; then
    docker image prune -a -f
    echo -e "${GREEN}All unused images have been removed.${NC}"
else
    echo "Skipping image prune."
fi

# --- Final Summary ---
echo -e "\n${GREEN}${BOLD}Docker cleanup script has finished.${NC}"
echo "Final status:"
echo -e "\n${BOLD}Running Containers:${NC}"
docker ps --format="table {{.Names}}\t{{.Image}}\t{{.Status}}"
echo -e "\n${BOLD}Remaining Volumes:${NC}"
docker volume ls
echo
echo "Cleanup complete."

