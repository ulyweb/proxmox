
#!/bin/bash

# =================================================================================
# TUI Menu-Driven Proxmox Post-Installation Script
#
# A user-friendly, menu-driven script to automate common tasks after a
# fresh Proxmox VE installation. Inspired by the Proxmox VE Helper-Scripts TUI.
#
# WARNING: This script performs IRREVERSIBLE actions, including DISK
# PARTITION MODIFICATIONS. It should only be run on a fresh install.
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
    echo -e "\n${RED}${BOLD}Error: This script must be run as root.${NC}"
    echo "Please run it with 'sudo ./your_script_name.sh'"
    exit 1
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

# --- Header for TUI ---
header_info() {
    clear
    echo -e "${BLUE}${BOLD}"
    echo "  ╔══════════════════════════════════════════════════════════════╗"
    echo "  ║          Proxmox VE Post-Installation Utility              ║"
    echo "  ╚══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

# --- Action Functions ---

# 1. Configure LVM Storage
configure_lvm() {
    header_info
    echo -e "${RED}${BOLD}--- Configure LVM Storage ---${NC}"
    echo "This step removes 'pve/data' and extends 'pve/root' to use all free space."
    echo -e "${RED}${BOLD}WARNING: This action is IRREVERSIBLE and DESTROYS data on 'pve/data'.${NC}"
    echo "Only run this on a fresh, single-disk installation."
    echo

    if confirm "Are you absolutely sure you want to reconfigure LVM storage? [y/N]"; then
        echo "Executing: lvremove /dev/pve/data"
        lvremove /dev/pve/data -y || { echo -e "${RED}Failed to remove LV. Aborting.${NC}"; read -p "Press [Enter] to continue."; return; }
        
        echo "Executing: lvresize -l +100%FREE /dev/pve/root"
        lvresize -l +100%FREE /dev/pve/root || { echo -e "${RED}Failed to resize LV. Aborting.${NC}"; read -p "Press [Enter] to continue."; return; }
        
        echo "Executing: resize2fs /dev/mapper/pve-root"
        resize2fs /dev/mapper/pve-root || { echo -e "${RED}Failed to resize filesystem. Aborting.${NC}"; read -p "Press [Enter] to continue."; return; }
        
        echo -e "${GREEN}LVM configuration completed successfully.${NC}"
    else
        echo "Action canceled."
    fi
    read -p "Press [Enter] to return to the menu."
}

# 2. Update Appliance Templates
update_templates() {
    header_info
    echo -e "${BLUE}${BOLD}--- Update Appliance Templates ---${NC}"
    echo "Updating the list of available TurnKey Linux container templates..."
    echo
    pveam update
    echo -e "\n${GREEN}Appliance templates updated.${NC}"
    read -p "Press [Enter] to return to the menu."
}

# 3. Configure Laptop Lid Behavior
configure_laptop_lid() {
    header_info
    echo -e "${BLUE}${BOLD}--- Configure Laptop Lid Behavior ---${NC}"
    echo "This will modify '/etc/systemd/logind.conf' to prevent the"
    echo "server from suspending when the laptop lid is closed."
    echo

    if confirm "Do you want to configure the server to ignore the lid switch? [y/N]"; then
        sed -i -E 's/^#?HandleLidSwitch=.*/HandleLidSwitch=ignore/' /etc/systemd/logind.conf
        sed -i -E 's/^#?HandleLidSwitchDocked=.*/HandleLidSwitchDocked=ignore/' /etc/systemd/logind.conf

        echo "Restarting systemd-logind service to apply changes..."
        systemctl restart systemd-logind.service
        echo -e "${GREEN}Laptop lid behavior configured successfully.${NC}"
    else
        echo "Action canceled."
    fi
    read -p "Press [Enter] to return to the menu."
}

# 4. Configure Console Blanking
configure_grub() {
    header_info
    echo -e "${BLUE}${BOLD}--- Configure Console Screen Blanking ---${NC}"
    echo "This will modify GRUB to make the console screen go blank after 5 minutes."
    echo

    if confirm "Do you want to add console blanking to GRUB? [y/N]"; then
        if grep -q "consoleblank=" /etc/default/grub; then
            echo "Console blanking setting already appears to exist. Skipping modification."
        else
            sed -i 's/^\(GRUB_CMDLINE_LINUX=".*\)"/\1 consoleblank=300"/' /etc/default/grub
            echo "GRUB configuration updated. Running update-grub..."
            update-grub
            echo -e "${GREEN}GRUB configured successfully. A reboot is required.${NC}"
        fi
    else
        echo "Action canceled."
    fi
    read -p "Press [Enter] to return to the menu."
}

# 5. Run All Steps
run_all_steps() {
    header_info
    echo -e "${YELLOW}${BOLD}--- Run All Post-Install Steps ---${NC}"
    echo "This will run all setup tasks in sequence."
    if confirm "Do you want to begin? [y/N]"; then
        configure_lvm
        update_templates
        configure_laptop_lid
        configure_grub
        echo -e "\n${GREEN}${BOLD}All setup tasks have been processed.${NC}"
        echo "A reboot is highly recommended to apply all changes."
        if confirm "Reboot now? [y/N]"; then
            echo "Rebooting..."
            reboot
        fi
    else
        echo "Action canceled."
    fi
    read -p "Press [Enter] to return to the menu."
}

# --- Main Script Execution ---
check_root
while true; do
    header_info
    echo -e "Please select a Proxmox post-installation task:\n"
    echo -e "  ${GREEN}1)${NC} Configure LVM Storage ${RED}(Destructive! Run on fresh install only)${NC}"
    echo -e "  ${GREEN}2)${NC} Update Appliance Templates"
    echo -e "  ${GREEN}3)${NC} Configure Laptop Lid to be Ignored"
    echo -e "  ${GREEN}4)${NC} Configure Console Blanking (for physical screen)"
    echo
    echo -e "  ${YELLOW}5)${NC} Run All Steps Sequentially"
    echo
    echo -e "  ${RED}q)${NC} Quit"
    echo
    read -p "Enter your choice: " choice
    case $choice in
        1) configure_lvm ;;
        2) update_templates ;;
        3) configure_laptop_lid ;;
        4) configure_grub ;;
        5) run_all_steps ;;
        q|Q) echo -e "\nExiting. Goodbye!\n" ; exit ;;
        *) echo -e "${RED}Invalid option. Please try again.${NC}" ; sleep 2 ;;
    esac
done
