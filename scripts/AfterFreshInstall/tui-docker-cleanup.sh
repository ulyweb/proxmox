
#!/bin/bash

# =================================================================================
# TUI Menu-Driven Docker Cleanup Script
#
# A user-friendly, menu-driven script to clean up Docker resources.
# Inspired by the Proxmox VE Helper-Scripts TUI.
#
# =================================================================================

# --- Style Definitions ---
BOLD=$(tput bold)
BLUE=$(tput setaf 4)
GREEN=$(tput setaf 2)
RED=$(tput setaf 1)
YELLOW=$(tput setaf 3)
NC=$(tput sgr0) # No Color

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

# --- Header for TUI ---
header_info() {
    clear
    echo -e "${BLUE}${BOLD}"
    echo "  ╔══════════════════════════════════════════════════════════════╗"
    echo "  ║             Interactive Docker Cleanup Utility             ║"
    echo "  ╚══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

# --- Action Functions ---

# 1. Stop Containers
stop_containers() {
    header_info
    echo -e "${BLUE}${BOLD}--- Stop Containers ---${NC}"
    read -p "Enter a container keyword, 'all' to stop everything, or press Enter to cancel: " CONTAINER_KEYWORD

    if [ -n "$CONTAINER_KEYWORD" ]; then
        DISPLAY_NAME="matching '$CONTAINER_KEYWORD'"
        if [[ "${CONTAINER_KEYWORD,,}" == "all" ]]; then
            TARGET_CONTAINERS=$(docker ps -a -q)
            DISPLAY_NAME="ALL"
        else
            TARGET_CONTAINERS=$(docker ps -a -q -f name="$CONTAINER_KEYWORD")
        fi

        if [ -z "$TARGET_CONTAINERS" ]; then
            echo -e "\n${GREEN}No containers $DISPLAY_NAME found.${NC}"
        else
            echo -e "\nThe following $DISPLAY_NAME containers will be stopped:"
            docker ps -a --filter "id=$(echo $TARGET_CONTAINERS | sed 's/ / --filter id=/g')" --format "  - {{.Names}} (ID: {{.ID}}, Status: {{.Status}})"
            echo
            if confirm "Proceed with stopping these containers? [y/N]"; then
                echo "Stopping containers..."
                docker stop $TARGET_CONTAINERS >/dev/null 2>&1
                echo -e "${GREEN}Done.${NC}"
            else
                echo "Action canceled."
            fi
        fi
    fi
    read -p "Press [Enter] to return to the menu."
}

# 2. Prune Stopped Containers
prune_stopped_containers() {
    header_info
    echo -e "${BLUE}${BOLD}--- Remove All Stopped Containers ---${NC}"
    echo "This will remove all containers on your system that are in a 'stopped' or 'exited' state."
    echo
    if confirm "Proceed with 'docker container prune'? [y/N]"; then
        docker container prune -f
        echo -e "${GREEN}All stopped containers have been removed.${NC}"
    else
        echo "Action canceled."
    fi
    read -p "Press [Enter] to return to the menu."
}

# 3. Remove Networks
remove_networks() {
    header_info
    echo -e "${BLUE}${BOLD}--- Remove Networks ---${NC}"
    read -p "Enter a network name, 'all' for custom networks, or press Enter to cancel: " NETWORK_NAME

    if [ -n "$NETWORK_NAME" ]; then
        if [[ "${NETWORK_NAME,,}" == "all" ]]; then
            CUSTOM_NETWORKS=$(docker network ls --filter "driver!=bridge" --filter "driver!=host" --filter "driver!=none" --format "{{.Name}}")
            if [ -z "$CUSTOM_NETWORKS" ]; then
                echo -e "\n${GREEN}No custom networks found to remove.${NC}"
            else
                echo -e "\nThe following custom networks will be removed:"
                echo "$CUSTOM_NETWORKS" | sed 's/^/  - /'
                echo
                if confirm "Proceed with removing ALL custom networks? [y/N]"; then
                    docker network rm $CUSTOM_NETWORKS >/dev/null 2>&1 || true
                    echo -e "${GREEN}All custom networks have been removed.${NC}"
                else
                    echo "Action canceled."
                fi
            fi
        else
            echo -e "\nThis will attempt to remove the Docker network named '$NETWORK_NAME'."
            if confirm "Attempt to remove the '$NETWORK_NAME' network? [y/N]"; then
                docker network rm "$NETWORK_NAME" >/dev/null 2>&1 || true
                echo -e "${GREEN}Attempted to remove '$NETWORK_NAME' network.${NC}"
            else
                echo "Action canceled."
            fi
        fi
    fi
    read -p "Press [Enter] to return to the menu."
}

# 4. Prune Volumes
prune_volumes() {
    header_info
    echo -e "${RED}${BOLD}--- AGGRESSIVE Volume Cleanup ---${NC}"
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
        echo "Action canceled."
    fi
    read -p "Press [Enter] to return to the menu."
}

# 5. Prune Images
prune_images() {
    header_info
    echo -e "${BLUE}${BOLD}--- Prune All Unused Images ---${NC}"
    echo "This step will remove all Docker images that are not associated with an existing container."
    echo "This is more aggressive than a standard prune and will remove dangling and unused images."
    echo
    if confirm "Proceed with 'docker image prune -a'? [y/N]"; then
        docker image prune -a -f
        echo -e "${GREEN}All unused images have been removed.${NC}"
    else
        echo "Action canceled."
    fi
    read -p "Press [Enter] to return to the menu."
}

# 6. Full System Prune (Docker's built-in command)
system_prune() {
    header_info
    echo -e "${YELLOW}${BOLD}--- Docker System Prune ---${NC}"
    echo "This runs the built-in 'docker system prune -a' command."
    echo "It will remove:"
    echo "  - All stopped containers"
    echo "  - All networks not used by at least one container"
    echo "  - All images without at least one container associated to them"
    echo "  - All build cache"
    echo
    if confirm "Do you want to run a full system prune? [y/N]"; then
        docker system prune -a -f
        echo -e "${GREEN}Docker system prune completed.${NC}"
    else
        echo "Action canceled."
    fi
    read -p "Press [Enter] to return to the menu."
}

# --- Main Menu ---
while true; do
    header_info
    echo -e "Please select an option:\n"
    echo -e "  ${GREEN}1)${NC} Stop Containers (by keyword or 'all')"
    echo -e "  ${GREEN}2)${NC} Remove All Stopped Containers"
    echo -e "  ${GREEN}3)${NC} Remove Networks (by name or 'all' custom)"
    echo
    echo -e "  ${YELLOW}4)${NC} Prune Unused Volumes ${RED}(Potentially Destructive)${NC}"
    echo -e "  ${YELLOW}5)${NC} Prune Unused Images (Aggressive)${NC}"
    echo -e "  ${YELLOW}6)${NC} Run Full Docker System Prune ${RED}(Potentially Destructive)${NC}"
    echo
    echo -e "  ${RED}q)${NC} Quit"
    echo
    read -p "Enter your choice: " choice
    case $choice in
        1) stop_containers ;;
        2) prune_stopped_containers ;;
        3) remove_networks ;;
        4) prune_volumes ;;
        5) prune_images ;;
        6) system_prune ;;
        q|Q) echo -e "\nExiting. Goodbye!\n" ; exit ;;
        *) echo -e "${RED}Invalid option. Please try again.${NC}" ; sleep 2 ;;
    esac
done
