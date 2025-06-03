# Steps for new VM inside Proxmox
````localadmin@nucaio:~$ history
    1  ip a
    2  reboot
    3  ip a
    4  exit
    5  sudo apt update && sudo apt upgrade -y
    6  reboot
    7  exit
    8  sudo su
    9  sudo apt install ca-certificates curl -y # Ensure prereqs
   10  sudo install -m 0755 -d /etc/apt/keyrings
   11  sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
   12  sudo chmod a+r /etc/apt/keyrings/docker.asc
   13  echo   "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
   14    $(. /etc/os-release && echo "$VERSION_CODENAME") stable" |   sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
   15  sudo apt update
   16  sudo apt install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin -y
   17  sudo usermod -aG docker $USER
   18  exit
   19  docker run hello-world
   20  docker compose version
   21  poweroff
   22  sudo poweroff
   23  ip a
   24  pwd
   25  mkdir -p ~/nextcloud-aio && cd ~/nextcloud-aio
   26  nano compose.yaml
   27  docker compose up -d
````
