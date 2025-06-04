<!--
## ***_<sub>Foot notes here!!</sup>_***
 TO DO: add more details about me later -->


> [!NOTE]
> :pushpin: After the installation to resize the drive.

> [!TIP]
> in the shell command 🖥️ type in ↙️
```
lvremove /dev/pve/data
lvresize -l +100%FREE /dev/pve/root
resize2fs /dev/mapper/pve-root
```


````
pveam update
````

### Optional for Laptop running Proxmox: Close your laptop lid

go to shell in your proxmox:  
````
nano /etc/systemd/logind.conf
````

find under header [Login] in there, remove # to 

#HandleLidSwitch=suspend make sure it says: 

HandleLidSwitch=ignore same with HandleLidSwitchDocked=Ignore


now lets restart that services: type in: 
````
systemctl restart systemd-logind.service
````

okay now lets edit one more for put your screen to sleep.

the command: 
````
nano /etc/default/grub
````

go down and find the line with Grub_cmdline_linux="consoleblank=300"


````
reboot
````
