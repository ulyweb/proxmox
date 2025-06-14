curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

sudo groupadd docker
sudo usermod -aG docker $USER
newgrp docker

sudo systemctl status docker

# --- Function to check if running as root ---
# Certain commands, like installing software, require root privileges.
# This function ensures the script is run with 'sudo' or as the 'root' user.


mkdir -p /mnt/ncdata
mkdir -p /home/$USER/nextcloud-aio/
cd /home/$USER/nextcloud-aio/
wget -O compose.yaml https://github.com/ulyweb/proxmox/releases/download/glenn-v1.0.0/compose.yaml
mkdir -p /home/$USER/immich-app/
cd /home/$USER/immich-app/
wget -O docker-compose.yml https://github.com/immich-app/immich/releases/latest/download/docker-compose.yml
wget -O .env https://github.com/immich-app/immich/releases/latest/download/example.env


#  Make the Script Executable:  
#  This command gives your user permission to run the script.  
#  Bash
    echo -e "\n${YELLOW}IMPORTANT: chmod \+x vm\_setup.sh.${NC}"
    read -p "Press Enter to return to the prompt..."
