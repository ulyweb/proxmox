## Wiping the `/dev/sda` Drive in Proxmox Terminal

To completely wipe the `/dev/sda` drive and prepare it for ZFS, you have several options. The most common and effective methods are:

- **Using `gdisk` to zap the partition table:**
  1. Run:  
     ```
     gdisk /dev/sda
     ```
  2. Enter `x` for extra commands.
  3. Enter `z` to zap (destroy) the GPT and MBR partition tables.
  4. Confirm prompts as needed.  
  This will clear all partition information from the drive[7].

- **Using `dd` to zero out the start of the disk (quick wipe):**
  ```
  dd if=/dev/zero of=/dev/sda bs=512 count=1
  ```
  This command overwrites the first 512 bytes, removing partition tables[11].

- **Using `wipefs` to remove filesystem signatures:**
  ```
  wipefs -a /dev/sda
  ```
  This removes filesystem signatures, making the disk appear blank.

**Note:** If `/dev/sda` is still part of a volume group (LVM), you may need to remove the volume group and logical volumes first[9].

## Creating a ZFS Pool Using Full Disk Capacity

Once the disk is wiped and not in use by any other system, you can create a ZFS pool that uses the entire disk:

1. **Create the ZFS Pool:**
   ```
   zpool create tank /dev/sda
   ```
   - Replace `tank` with your preferred pool name.
   - This command will use the whole disk for the pool[11][10].

2. **Verify the Pool:**
   ```
   zpool status
   zpool list
   ```
   These commands confirm the pool is healthy and using the expected capacity[10].

## Creating ZFS Datasets

Datasets allow you to organize and manage storage within your pool:

- **Create a dataset:**
  ```
  zfs create tank/backups
  zfs create tank/isos
  zfs create tank/vmdrives
  ```
  - Replace `tank` with your pool name and choose dataset names as needed[10].

- **List datasets:**
  ```
  zfs list
  ```
  This will show all datasets and their mount points.

## Making ZFS Storage Available in Proxmox

- Go to the Proxmox web UI:  
  Datacenter > Storage > Add > ZFS  
  Select your pool or dataset to make it available for VM disks, containers, or file storage[8].

## Summary Table

| Step         | Command/Action                                      |
|--------------|-----------------------------------------------------|
| Wipe disk    | `gdisk /dev/sda` → `x` → `z` OR `dd`/`wipefs`       |
| Create pool  | `zpool create tank /dev/sda`                        |
| Create dataset | `zfs create tank/datasetname`                     |
| List datasets | `zfs list`                                         |
| Add to Proxmox | Use Proxmox GUI: Datacenter > Storage > Add > ZFS |

**Caution:** All data on `/dev/sda` will be lost. Double-check the device name before running destructive commands.

These steps will ensure `/dev/sda` is wiped and fully utilized for ZFS storage in your Proxmox home lab[7][10][11].
