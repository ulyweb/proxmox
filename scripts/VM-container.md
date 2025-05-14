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
````

Edit `/etc/fstab` in the VM:

Open the `/etc/fstab` file with nano as root:
````
sudo nano /etc/fstab
````

Add the NFS entry:
````
PROXMOX_HOST_IP:/data  /mnt/nc_data  nfs  defaults,_netdev,bg  0  0
````

````
sudo umount /mnt/nc_data
sudo mount -a
sudo systemctl daemon-reload
sudo mount -a
df -hT /mnt/nc_data
mount | grep /mnt/nc_data
````
