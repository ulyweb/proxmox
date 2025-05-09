## After the installation we need to resize the drive.

## in the shell command : type in: lvremove /dev/pve/data

## now we going to resize: type in: lvresize -l +100%FREE /dev/pve/root

## last command to confirm: type in: resize2fs /dev/mapper/pve-root
