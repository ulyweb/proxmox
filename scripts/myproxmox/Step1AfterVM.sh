#!/bin/bash

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Post-VM Setup Script for Docker, Nextcloud & Immich                 #
#                                                                     #
# A menu-driven script to automate common application setups          #
# on a fresh Proxmox VM (Debian/Ubuntu-based).                        #
#                                                                     #
# Inspired by the Proxmox VE Helper-Scripts TUI.                        #
#                                                                     #
# Version: 1.0                                                        #
# Date: 2025-06-08                                                    #
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

# --- Color Definitions for a nicer UI ---
NC='\033[0m' # No Color
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'

# --- Function to check if running as root ---
# Certain commands, like installing software, require root privileges.
# This function ensures the script is run with 'sudo' or as the 'root' user.
check_root() {
    if [ "$(id -u)" -ne 0 ]; then
        echo -e "${RED}Error: This script must be run with root privileges. Please use 'sudo ./your_script_name.sh'.${NC}"
        exit 1
    fi
}

# --- Function to get the correct non-root username ---
# When you run a script with `sudo`, the `$USER` variable becomes `root`.
# We need the original user's name (e.g., 'pveuser') to add them to the docker group.
# `$SUDO_USER` holds the name of the user who invoked `sudo`.
get_user() {
  if [ -n "$SUDO_USER" ]; then
    TARGET_USER=$SUDO_USER
  else
    # Fallback in case the script is run directly as root
    TARGET_USER=$(logname)
  fi
  # Final check to ensure we have a user
  if [ -z "$TARGET_USER" ]; then
    echo -e "${RED}Could not determine the non-root user. Please run with 'sudo'.${NC}"
    exit 1
  fi
}


# --- Function to display the main menu ---
show_menu() {
    clear
    echo -e "${BLUE}=============================================${NC}"
    echo -e "${CYAN}        Post-VM Application Setup Script     ${NC}"
    echo -e "${BLUE}=============================================${NC}"
    echo -e "This script should be run inside your new VM."
    echo -e "---------------------------------------------"
    echo -e " ${YELLOW}1)${NC} Install Docker & Configure User"
    echo -e " ${YELLOW}2)${NC} Prepare Directories for Nextcloud AIO"
    echo -e " ${YELLOW}3)${NC} Download & Prepare Immich Docker Compose"
    echo -e "---------------------------------------------"
    echo -e " ${YELLOW}4)${NC} Run ALL Setup Steps (1, 2, and 3)"
    echo -e "---------------------------------------------"
    echo -e " ${YELLOW}5)${NC} Exit"
    echo -e "${BLUE}=============================================${NC}"
}

# --- Function to Install Docker ---
# This function automates the installation of Docker Engine.
# 1. Downloads the official `get-docker.sh` script. This is the recommended
#    method to ensure you get the latest version of Docker.
# 2. Executes the script to install Docker.
# 3. Creates a 'docker' user group if it doesn't already exist.
# 4. Adds your user account to this group. This is a crucial security and
#    convenience step that allows you to run docker commands without `sudo`.
# 5. Displays the status of the Docker service to confirm it's running.
install_docker() {
    clear
    echo -e "${CYAN}--- 1. Installing Docker & Configuring User ---${NC}"
    echo -e "This will download and run the official Docker installation script."
    echo -e "It will also add the user '${YELLOW}${TARGET_USER}${NC}' to the 'docker' group."
    echo -e "--------------------------------------------------------------------"
    read -p "Press Enter to continue..."

    echo -e "\n${BLUE}Downloading the Docker installation script...${NC}"
    curl -fsSL https://get.docker.com -o get-docker.sh

    echo -e "${BLUE}Running the Docker installation script...${NC}"
    sh get-docker.sh

    echo -e "${BLUE}Creating 'docker' group (if it doesn't exist)...${NC}"
    groupadd -f docker

    echo -e "${BLUE}Adding user '${TARGET_USER}' to the 'docker' group...${NC}"
    usermod -aG docker "$TARGET_USER"

    echo -e "${GREEN}Docker installed successfully!${NC}"
    echo -e "\n${BLUE}Checking Docker service status:${NC}"
    systemctl status docker --no-pager

    echo -e "\n${YELLOW}IMPORTANT: For group changes to take effect, you must log out and log back in, or start a new SSH session.${NC}"
    read -p "Press Enter to return to the menu..."
}

# --- Function to Prepare for Nextcloud AIO ---
# This function creates the directory structure required for a Nextcloud setup.
# 1. Creates `/mnt/ncdata`, a common location for persistent container data
#    to live outside the main OS partition.
# 2. Creates a `nextcloud-aio` directory in the user's home folder, which is
#    the standard place to manage Nextcloud AIO files.
# 3. Sets the correct ownership for the directory in the user's home.
prepare_nextcloud() {
    clear
    echo -e "${CYAN}--- 2. Preparing Directories for Nextcloud AIO ---${NC}"
    echo -e "This will create the following directories:"
    echo -e "  - /mnt/ncdata (for persistent data)"
    echo -e "  - /home/${TARGET_USER}/nextcloud-aio (for management)"
    echo -e "---------------------------------------------------------"
    read -p "Press Enter to continue..."

    echo -e "\n${BLUE}Creating /mnt/ncdata...${NC}"
    mkdir -p /mnt/ncdata

    echo -e "${BLUE}Creating /home/${TARGET_USER}/nextcloud-aio/...${NC}"
    mkdir -p "/home/${TARGET_USER}/nextcloud-aio/"
    chown -R "${TARGET_USER}:${TARGET_USER}" "/home/${TARGET_USER}/nextcloud-aio/"


    echo -e "\n${GREEN}Success! Nextcloud directories created.${NC}"
    echo -e "\n${YELLOW}Next Step: Please run the official Nextcloud AIO 'docker run' command."
    echo -e "You can find the latest command here:"
    echo -e "${CYAN}https://github.com/nextcloud/all-in-one#how-to-use-it${NC}"
    read -p "Press Enter to return to the menu..."
}

# --- Function to Prepare for Immich ---
# This function prepares the environment for the Immich Photo Manager.
# 1. Creates an `immich-app` directory in the user's home folder.
# 2. Navigates into that directory.
# 3. Downloads the latest `docker-compose.yml` and `example.env` files from
#    the official Immich GitHub repository releases. Using the '/latest/' URL
#    ensures you always get the most recent stable configuration.
prepare_immich() {
    clear
    echo -e "${CYAN}--- 3. Downloading & Preparing Immich ---${NC}"
    echo -e "This will create '/home/${TARGET_USER}/immich-app/' and download the"
    echo -e "latest 'docker-compose.yml' and '.env' files into it."
    echo -e "------------------------------------------------------------------"
    read -p "Press Enter to continue..."

    IMMICH_DIR="/home/${TARGET_USER}/immich-app"
    echo -e "\n${BLUE}Creating directory ${IMMICH_DIR}...${NC}"
    mkdir -p "${IMMICH_DIR}"
    
    cd "${IMMICH_DIR}"

    echo -e "${BLUE}Downloading latest docker-compose.yml for Immich...${NC}"
    wget -O docker-compose.yml https://github.com/immich-app/immich/releases/latest/download/docker-compose.yml

    echo -e "${BLUE}Downloading latest example .env file for Immich...${NC}"
    wget -O .env https://github.com/immich-app/immich/releases/latest/download/example.env

    echo -e "${BLUE}Setting ownership of Immich files to user '${TARGET_USER}'...${NC}"
    chown -R "${TARGET_USER}:${TARGET_USER}" "${IMMICH_DIR}"


    echo -e "\n${GREEN}Success! Immich files downloaded to ${IMMICH_DIR}.${NC}"
    echo -e "${YELLOW}Next Step: Edit the '.env' file with your custom settings before running 'docker-compose up -d'.${NC}"
    read -p "Press Enter to return to the menu..."
}

# --- Main Script Logic ---
check_root
get_user

while true; do
    show_menu
    read -p "Enter your choice [1-5]: " choice
    case $choice in
        1)
            install_docker
            ;;
        2)
            prepare_nextcloud
            ;;
        3)
            prepare_immich
            ;;
        4)
            echo -e "${CYAN}--- Running ALL Setup Steps ---${NC}"
            install_docker
            prepare_nextcloud
            prepare_immich
            echo -e "\n${GREEN}All setup steps completed!${NC}"
            read -p "Press Enter to return to the menu..."
            ;;
        5)
            echo -e "${CYAN}Exiting script. Goodbye!${NC}"
            exit 0
            ;;
        *)
            echo -e "${RED}Invalid option. Please try again.${NC}"
            read -p "Press Enter to continue..."
            ;;
    esac
done
