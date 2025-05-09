>[!NOTE]After the installation to resize the drive.
> in the shell command : type in:
>
>[!tip]
```
lvremove /dev/pve/data
lvresize -l +100%FREE /dev/pve/root
resize2fs /dev/mapper/pve-root
```
