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
