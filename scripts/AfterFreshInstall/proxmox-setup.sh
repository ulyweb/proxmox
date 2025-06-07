#!/bin/bash

# =================================================================================
# Proxmox VE Post-Installation Script (Safer Version)
#
# This script automates common setup tasks after a fresh Proxmox installation:
# 1. Reallocates disk space from 'pve/data' to 'pve/root'.
# 2. Updates the PVE appliance templates.
# 3. Configures system to ignore laptop lid closing.
# 4. Sets the console to blank after 5 minutes of inactivity.
#
# WARNING: This script performs IRREVERSIBLE actions, including DISK
# PARTITION MODIFICATIONS. It should only be run on a fresh install.
# Back up any important data before proceeding.
#
# =================================================================================

# --- Style Definitions ---
BOLD=$(tput bold)
BLUE=$(tput setaf 4)
GREEN=$(tput setaf 2)
RED=$(tput setaf 1)
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
    # call with a prompt string or use a default
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

# --- MASTER WARNING - Must be accepted to proceed ---
show_master_warning() {
    clear
    echo -e "${RED}${BOLD}******************************************************************${NC}"
    echo -e "${RED}${BOLD}* !! WARNING !!                           *${NC}"
    echo -e "${RED}${BOLD}******************************************************************${NC}"
    echo
    echo -e "${BOLD}This script is designed for FRESH Proxmox installations and will"
    echo -e "${BOLD}make significant and IRREVERSIBLE changes to your system, including:${NC}"
    echo
    echo -e "  1. ${RED}DELETING the '/dev/pve/data' logical volume.${NC}"
    echo "  2. Resizing your root partition to use all available space."
    echo "  3. Modifying system configuration files."
    echo
    echo -e "${BOLD}DO NOT run this on a production system or a system with data you"
    echo -e "${BOLD}wish to keep on the 'data' volume.${NC}"
    echo
    read -r -p "Type 'yes' to acknowledge this warning and proceed: " confirmation
    if [[ "${confirmation,,}" != "yes" ]]; then
        echo "Aborted. No changes have been made."
        exit 0
    fi
    echo
}


# --- STEP 1: Configure LVM Storage ---
configure_lvm() {
  echo -e "\n${BLUE}${BOLD}--- Step 1: Configure LVM Storage ---${NC}"
  echo "This step will remove the 'pve/data' logical volume and extend"
  echo "'pve/root' to use all available free space. This is a common"
  echo "procedure for single-disk Proxmox setups."
  echo -e "${RED}${BOLD}WARNING: This action is IRREVERSIBLE and will destroy all data on 'pve/data'.${NC}"
  echo

  if confirm "Are you absolutely sure you want to reconfigure LVM storage? [y/N]"; then
    echo "Executing: lvremove /dev/pve/data"
    lvremove /dev/pve/data -y || { echo -e "${RED}Failed to remove LV. Aborting.${NC}"; return; }
    
    echo "Executing: lvresize -l +100%FREE /dev/pve/root"
    lvresize -l +100%FREE /dev/pve/root || { echo -e "${RED}Failed to resize LV. Aborting.${NC}"; return; }
    
    echo "Executing: resize2fs /dev/mapper/pve-root"
    resize2fs /dev/mapper/pve-root || { echo -e "${RED}Failed to resize filesystem. Aborting.${NC}"; return; }
    
    echo -e "${GREEN}LVM configuration completed successfully.${NC}"
  else
    echo "Skipping LVM configuration."
  fi
}

# --- STEP 2: Update Appliance Templates ---
update_templates() {
  echo -e "\n${BLUE}${BOLD}--- Step 2: Update Appliance Templates ---${NC}"
  echo "Updating the list of available TurnKey Linux container templates..."
  echo "Executing: pveam update"
  pveam update
  echo -e "${GREEN}Appliance templates updated.${NC}"
}

# --- STEP 3: Configure Laptop Lid Behavior ---
configure_laptop_lid() {
  echo -e "\n${BLUE}${BOLD}--- Step 3: Configure Laptop Lid Behavior ---${NC}"
  echo "This step will modify '/etc/systemd/logind.conf' to prevent the"
  echo "server from suspending when the laptop lid is closed."
  echo

  if confirm "Do you want to configure the server to ignore the lid switch? [y/N]"; then
    echo "Modifying /etc/systemd/logind.conf..."
    sed -i -E 's/^#?HandleLidSwitch=.*/HandleLidSwitch=ignore/' /etc/systemd/logind.conf
    sed -i -E 's/^#?HandleLidSwitchDocked=.*/HandleLidSwitchDocked=ignore/' /etc/systemd/logind.conf

    echo "Restarting systemd-logind service to apply changes..."
    echo "Executing: systemctl restart systemd-logind.service"
    systemctl restart systemd-logind.service
    echo -e "${GREEN}Laptop lid behavior configured successfully.${NC}"
  else
    echo "Skipping laptop lid configuration."
  fi
}

# --- STEP 4: Configure Console Blanking ---
configure_grub() {
  echo -e "\n${BLUE}${BOLD}--- Step 4: Configure Console Screen Blanking ---${NC}"
  echo "This step will modify the GRUB bootloader configuration to make the"
  echo "console screen go blank after 5 minutes (300 seconds) of inactivity."
  echo

  if confirm "Do you want to add console blanking to GRUB? [y/N]"; then
    # Check if the setting already exists to avoid duplicates
    if grep -q "consoleblank=" /etc/default/grub; then
      echo "Console blanking setting already appears to exist. Skipping modification."
    else
      echo "Modifying /etc/default/grub..."
      sed -i 's/^\(GRUB_CMDLINE_LINUX=".*\)"/\1 consoleblank=300"/' /etc/default/grub
      echo "GRUB configuration file updated."
      
      echo "Updating GRUB bootloader..."
      echo "Executing: update-grub"
      update-grub
      echo -e "${GREEN}GRUB configured successfully.${NC}"
    fi
  else
    echo "Skipping GRUB configuration."
  fi
}

# --- MAIN SCRIPT EXECUTION ---
main() {
  check_root
  show_master_warning
  
  echo -e "${BLUE}${BOLD}Starting Proxmox Post-Install Configuration...${NC}"
  
  configure_lvm
  update_templates
  configure_laptop_lid
  configure_grub

  echo -e "\n${GREEN}${BOLD}All selected tasks are complete.${NC}"
  echo "A reboot is recommended for all changes (especially LVM and GRUB) to take full effect."

  if confirm "Do you want to reboot the server now? [y/N]"; then
    echo "Rebooting now..."
    reboot
  else
    echo "Please reboot the server manually by running the 'reboot' command."
  fi
}

# --- Run the main function ---
main
