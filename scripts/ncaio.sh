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

# Prompt for gateway IP
read -p "Enter your gateway IP address: " GATEWAY_IP

# Prompt for MAC address
read -p "Enter the desired MAC address for the container: " MAC_ADDRESS

# Create LXC container
pct create $LXC_ID $LXC_NAME \
  -hostname $LXC_NAME \
  -ostype ubuntu \
  -storage local-lvm \
  -net0 name=eth0,bridge=vmbr0,gw=$GATEWAY_IP,hwaddr=$MAC_ADDRESS,ip=dhcp \
  -onboot 1 \
  -unprivileged 0

# Start the container
pct start $LXC_ID

# Wait for the container to start
sleep 10

# Update and upgrade packages within the container
pct exec $LXC_ID -- bash -c "apt update && apt upgrade -y"

# Install Docker and Docker Compose
pct exec $LXC_ID -- bash -c "apt install -y apt-transport-https ca-certificates curl gnupg lsb-release"
pct exec $LXC_ID -- bash -c "curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg"
pct exec $LXC_ID -- bash -c "echo \"deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable\" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null"
pct exec $LXC_ID -- bash -c "apt update"
pct exec $LXC_ID -- bash -c "apt install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin"

# Set timezone
pct exec $LXC_ID -- bash -c "ln -sf /usr/share/zoneinfo/$TZ /etc/localtime"
pct exec $LXC_ID -- bash -c "dpkg-reconfigure -f noninteractive tzdata"

# Create directories for Nextcloud data and Docker Compose files
pct exec $LXC_ID -- bash -c "mkdir -p /mnt/data/nextcloud"
pct exec $LXC_ID -- bash -c "mkdir -p /opt/nextcloud-aio"

# Create docker-compose.yml for Nextcloud All-in-One with correct configuration
cat << EOF > /tmp/docker-compose.yml
version: "3.8"

volumes:
  nextcloud_aio_mastercontainer:
    name: nextcloud_aio_mastercontainer

services:
  nextcloud:
    image: nextcloud/all-in-one:latest
    restart: unless-stopped
    container_name: nextcloud-aio-mastercontainer
    volumes:
      - nextcloud_aio_mastercontainer:/mnt/docker-aio-config
      - /var/run/docker.sock:/var/run/docker.sock:ro
    ports:
      - 8080:8080
    environment:
      - APACHE_PORT=11000
      - APACHE_IP_BINDING=0.0.0.0
      - OVERWRITEHOST=$HOST_DOMAIN
      - OVERWRITEPROTOCOL=https
      - NEXTCLOUD_UPLOAD_LIMIT=10G
      - NEXTCLOUD_MEMORY_LIMIT=2048M
      - TRUSTED_PROXIES=10.17.76.78 # Add your Nginx Proxy Manager IP here

EOF


# Copy docker-compose.yml to the container
pct push $LXC_ID /tmp/docker-compose.yml /opt/nextcloud-aio/

# Start Nextcloud All-in-One
pct exec $LXC_ID -- bash -c "cd /opt/nextcloud-aio && docker-compose up -d"

echo "Nextcloud All-in-One deployed successfully!"
echo "Access Nextcloud at https://$HOST_DOMAIN"
echo "Remember to configure your Nginx Proxy Manager at 10.17.76.78 to complete the setup."
