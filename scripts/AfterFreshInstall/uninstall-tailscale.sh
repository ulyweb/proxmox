#!/usr/bin/env bash

#
# Title: Tailscale Uninstaller Script
# Description: A menu-driven Bash script to safely and completely remove Tailscale from a Proxmox/Debian-based system.
# Author: Gemini
#

# --- Color Definitions ---
YW=$(echo -e "\033[33m")
RD=$(echo -e "\033[01;31m")
BL=$(echo -e "\033[36m")
GN=$(echo -e "\033[1;92m")
CL=$(echo -e "\033[m")

# --- Helper Functions ---
function msg_info() {
  echo -e "${BL}[INFO]${CL} $1"
}

function msg_ok() {
  echo -e "${GN}[OK]${CL} $1"
}

function msg_warn() {
  echo -e "${YW}[WARN]${CL} $1"
}

function msg_error() {
  echo -e "${RD}[ERROR]${CL} $1"
}

# --- Pause and Clear ---
function press_enter() {
  read -p "Press [Enter] to continue..."
}

# --- Header ---
function header() {
  clear
  cat <<"EOF"
   ______     _ __  _           _
  /_  __/____(_) /_(_)___ ___  (_)___
   / / / ___/ / __/ / __ `__ \/ / __ \
  / / / /__/ / /_/ / / / / / / / / / /
 /_/  \___/_/\__/_/_/ /_/ /_/_/_/ /_/
    Tailscale Uninstaller
EOF
  echo -e "${BL}----------------------------------------------------------${CL}"
}

# --- Action Functions ---

function check_tailscale_installed() {
  if ! command -v tailscale >/dev/null 2>&1; then
    header
    msg_warn "Tailscale does not appear to be installed."
    msg_info "Exiting script."
    press_enter
    exit
  fi
}

function disconnect_tailscale() {
  header
  msg_info "Attempting to disconnect from the Tailscale network..."
  if sudo tailscale down; then
    msg_ok "Successfully disconnected from Tailnet."
  else
    msg_warn "Could not disconnect. Maybe already down or service is not running."
  fi
  press_enter
}

function stop_service() {
  header
  msg_info "Stopping and disabling the Tailscale service..."
  if sudo systemctl stop tailscaled; then
    msg_ok "Tailscale service (tailscaled) stopped."
  else
    msg_error "Failed to stop the Tailscale service."
  fi

  if sudo systemctl disable tailscaled; then
    msg_ok "Tailscale service (tailscaled) disabled from starting on boot."
  else
    msg_error "Failed to disable the Tailscale service."
  fi
  press_enter
}

function uninstall_package() {
  header
  msg_info "Uninstalling the Tailscale package..."
  if sudo apt-get remove -y tailscale; then
    msg_ok "Tailscale package has been uninstalled."
  else
    msg_error "Failed to uninstall the Tailscale package."
  fi
  press_enter
}

function purge_package() {
  header
  msg_warn "You are about to PURGE Tailscale."
  msg_warn "This will remove the package AND all configuration files,"
  msg_warn "including your machine's identity key. This is irreversible."
  read -p "Are you sure you want to continue? [y/N] " -n 1 -r
  echo
  if [[ $REPLY =~ ^[Yy]$ ]]; then
    msg_info "Purging the Tailscale package and its configurations..."
    if sudo apt-get purge -y tailscale; then
      msg_ok "Tailscale package and its configurations have been purged."
    else
      msg_error "Failed to purge the Tailscale package."
    fi
  else
    msg_info "Purge operation cancelled."
  fi
  press_enter
}

function cleanup_dependencies() {
  header
  msg_info "Cleaning up unused dependencies..."
  if sudo apt-get autoremove -y; then
    msg_ok "Unused dependencies have been removed."
  else
    msg_error "Failed to clean up dependencies."
  fi
  press_enter
}

function run_all() {
    header
    msg_info "Starting the complete removal process..."
    press_enter
    disconnect_tailscale
    stop_service
    purge_package # Using purge for a complete cleanup
    cleanup_dependencies
    header
    msg_ok "All removal steps have been completed."
    msg_info "The final recommended step is to remove this machine from your"
    msg_info "Tailscale Admin Console: https://login.tailscale.com/admin/machines"
    press_enter
}

# --- Main Menu ---
function show_menu() {
  header
  echo -e "${YW}Please select an option:${CL}"
  echo -e " 1) Disconnect from Tailscale Network ('tailscale down')"
  echo -e " 2) Stop & Disable Tailscale Service"
  echo -e " 3) Uninstall Tailscale Package (Keeps Configs)"
  echo -e " 4) ${RD}Purge Tailscale Package (Deletes All Configs)${CL}"
  echo -e " 5) Clean Up Unused Dependencies"
  echo -e ""
  echo -e " 6) ${GN}Run All Recommended Removal Steps (Purge)${CL}"
  echo -e ""
  echo -e " q) Quit"
  echo -e "${BL}----------------------------------------------------------${CL}"
}

# --- Script Entry Point ---
check_tailscale_installed

while true; do
  show_menu
  read -p "Enter your choice: " choice
  case $choice in
    1) disconnect_tailscale ;;
    2) stop_service ;;
    3) uninstall_package ;;
    4) purge_package ;;
    5) cleanup_dependencies ;;
    6) run_all ; exit ;;
    [qQ]) msg_info "Exiting script."; exit ;;
    *) msg_error "Invalid option. Please try again." ; press_enter ;;
  esac
done
