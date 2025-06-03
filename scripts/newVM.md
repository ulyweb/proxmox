# Steps for new VM inside Proxmox

````
ip a
reboot
ip a
exit
sudo apt update && sudo apt upgrade -y
reboot
exit
sudo su
sudo apt install ca-certificates curl -y # Ensure prereqs
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc
echo   "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
    $(. /etc/os-release && echo "$VERSION_CODENAME") stable" |   sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt update
sudo apt install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin -y
sudo usermod -aG docker $USER
exit
docker run hello-world
docker compose version
poweroff
sudo poweroff
ip a
pwd
mkdir -p ~/nextcloud-aio && cd ~/nextcloud-aio
nano compose.yaml
docker compose up -d
````
