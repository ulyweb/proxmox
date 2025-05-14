# After creating the VM

````
sudo apt update && sudo apt upgrade -y
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker $USER
newgrp docker
sudo apt install -y cifs-utils p7zip nano qemu-guest-agent nfs-kernel-server
sudo systemctl enable qemu-guest-agent
sudo mkdir /mnt/nc_data
````

````
sudo mount 10.17.76.70:/data /mnt/nc_data
sudo nano /etc/fstab
sudo umount /mnt/nc_data
sudo mount -a
sudo systemctl daemon-reload
sudo mount -a
df -hT /mnt/nc_data
mount | grep /mnt/nc_data
````
