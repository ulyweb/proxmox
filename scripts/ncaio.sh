#!/bin/bash

# Script to deploy Nextcloud All-in-One in a Proxmox LXC container
# and configure it to work with an external Nginx Proxy Manager

# Function to check if a command exists
command_exists() {
  command -v "$1" >/dev/null 2>&1
}

# Function to exit with an error message
die() {
  echo "ERROR: $1" >&2
  exit 1
}

# Check if running as root
if [[ $EUID -ne 0 ]]; then
  die "This script must be run as root"
fi

# Check if pct command exists
if ! command_exists pct; then
  die "Proxmox VE tools not found. Please install them."
fi

# Prompt for LXC ID
read -p "Enter the desired LXC ID: " LXC_ID

# Prompt for LXC name
read -p "Enter the desired LXC name: " LXC_NAME

# Prompt for host domain
read -p "Enter your domain name (e.g., example.com): " HOST_DOMAIN

# Prompt for timezone
read -p "Enter your desired timezone (e.g., America/Los_Angeles): " TZ

# Prompt for gateway IP with default value
read -p "Enter your gateway IP address (leave blank for default): " GATEWAY_IP
if [ -z "$GATEWAY_IP" ]; then
  GATEWAY_IP=$(ip route show default | awk '/default/ {print $3}')
fi

# Prompt for MAC address with default value
read -p "Enter the desired MAC address for the container (leave blank for default): " MAC_ADDRESS
if [ -z "$MAC_ADDRESS" ]; then
  MAC_ADDRESS=$(openssl rand -hex 6 | sed 's/\(..\)/\1:/g; s/.$//')
fi

# Install jq if not already installed
if ! command_exists jq; then
  apt update
  apt install -y jq
fi

# Get available storage list
STORAGE_LIST=$(pvesh get /nodes/$(hostname)/storage --output-format json | jq -r '.data | keys[]')

# Prompt for storage selection
echo "Available storage options:"
select STORAGE in $STORAGE_LIST; do
  if [[ -n "$STORAGE" ]]; then
    break
  fi
  echo "Invalid selection. Please try again."
done

# Create LXC container with selected storage
pct create $LXC_ID $LXC_NAME \
  -hostname $LXC_NAME \
  -ostype ubuntu \
  -storage "$STORAGE" \
  -net0 name=eth0,bridge=vmbr0,gw=$GATEWAY_IP,hwaddr=$MAC_ADDRESS,ip=dhcp \
  -onboot 1 \
  -unprivileged 0

# ... (rest of the script remains the same)
