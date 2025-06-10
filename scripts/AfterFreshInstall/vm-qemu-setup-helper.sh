#!/bin/bash

# TUI script for Proxmox VM setup helper
# Inspired by Proxmox VE Helper-Scripts style
# Author: Uly

clear
header() {
  echo -e "\e[1;32m=============================="
  echo " Proxmox VM QEMU Setup Helper "
  echo -e "==============================\e[0m"
}

menu() {
  echo ""
  echo "1) Add Serial Port 0 to VM"
  echo "2) Enable QEMU Guest Agent in VM"
  echo "3) Install QEMU Agent inside Linux VM (via SSH)"
  echo "4) Enable serial console in VM (Ubuntu/Debian)"
  echo "0) Exit"
  echo ""
}

add_serial_port() {
  read -p "Enter VM ID: " VMID
  qm set $VMID -serial0 socket
  echo "✅ Serial Port 0 added to VM $VMID"
}

enable_qemu_agent() {
  read -p "Enter VM ID: " VMID
  qm set $VMID -agent enabled=1
  echo "✅ QEMU Guest Agent enabled on VM $VMID"
}

install_qemu_agent_vm() {
  read -p "Enter IP of the Linux VM: " VMIP
  read -p "Enter SSH username (e.g., root): " USER
  echo "🔐 You will be prompted for SSH password"
  ssh $USER@$VMIP 'bash -s' << 'EOF'
echo "🛠️ Installing QEMU Guest Agent..."
sudo apt update
sudo apt install qemu-guest-agent -y
sudo systemctl enable --now qemu-guest-agent
echo "✅ QEMU Guest Agent installed and running!"
EOF
}

enable_serial_console_vm() {
  read -p "Enter IP of the Linux VM: " VMIP
  read -p "Enter SSH username (e.g., root): " USER
  echo "🔐 You will be prompted for SSH password"
  ssh $USER@$VMIP 'bash -s' << 'EOF'
echo "🛠️ Configuring serial console..."
sudo sed -i 's/GRUB_CMDLINE_LINUX="/GRUB_CMDLINE_LINUX="console=tty0 console=ttyS0,115200n8 /' /etc/default/grub
sudo update-grub
sudo systemctl enable serial-getty@ttyS0.service
echo "✅ Serial console configured!"
EOF
}

while true; do
  clear
  header
  menu
  read -p "Choose an option [0-4]: " CHOICE
  case $CHOICE in
    1) add_serial_port ;;
    2) enable_qemu_agent ;;
    3) install_qemu_agent_vm ;;
    4) enable_serial_console_vm ;;
    0) echo "👋 Exiting..."; exit 0 ;;
    *) echo "❌ Invalid option. Try again."; sleep 1 ;;
  esac
  read -p "Press [Enter] to return to menu..."
done
