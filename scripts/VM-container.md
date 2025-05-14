# After creating the VM

````
sudo apt update && sudo apt upgrade -y
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh 
sudo apt install -y cifs-utils p7zip nano qemu-guest-agent
sudo systemctl enable qemu-guest-agent
````
