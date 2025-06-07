>[!NOTE]
>Bash script that automates the process of changing your Proxmox server's IP address.

This script will:
* Prompt you for the new IP address (with CIDR) and the new gateway.
* Automatically detect the old IP address and network configuration file.
* Show you the proposed changes before making them.
* Ask for your confirmation before writing the changes to the system files.
* Modify both `/etc/network/interfaces` and `/etc/hosts`.
* Offer to reboot the server to apply the changes.

***

### The Bash Script: `change-proxmox-ip.sh`

You can create a file named `change-proxmox-ip.sh` on your Proxmox server and paste the code below into it.

```bash
#!/bin/bash

# =================================================================================
# Proxmox IP Change Script
#
# This script automates changing the static IP address, gateway, and /etc/hosts
# file on a Proxmox VE server. It must be run with root privileges.
#
# WARNING: An incorrect IP configuration can make your server inaccessible
# over the network. Double-check all inputs before confirming.
# =================================================================================

# --- Ensure the script is run as root ---
if [ "$(id -u)" -ne 0 ]; then
  echo "This script must be run as root. Please use 'sudo ./change-proxmox-ip.sh'" >&2
  exit 1
fi

# --- Configuration File Paths ---
INTERFACES_FILE="/etc/network/interfaces"
HOSTS_FILE="/etc/hosts"

# --- Function to validate IP address format (basic check) ---
validate_ip() {
  local ip=$1
  if [[ $ip =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
    return 0
  else
    return 1
  fi
}

# --- Find the current static IP and Gateway ---
echo "🔎 Detecting current network configuration..."
CURRENT_IP_CIDR=$(grep -E '^\s*address\s' $INTERFACES_FILE | awk '{print $2}')
CURRENT_GATEWAY=$(grep -E '^\s*gateway\s' $INTERFACES_FILE | awk '{print $2}')
CURRENT_IP=$(echo $CURRENT_IP_CIDR | cut -d'/' -f1)

if [ -z "$CURRENT_IP_CIDR" ] || [ -z "$CURRENT_GATEWAY" ]; then
  echo "❌ Error: Could not automatically detect the current IP address or gateway from $INTERFACES_FILE."
  echo "Please ensure the file is correctly formatted."
  exit 1
fi

echo "    Current IP/CIDR: $CURRENT_IP_CIDR"
echo "    Current Gateway:   $CURRENT_GATEWAY"
echo ""

# --- Prompt user for new IP information ---
echo "📝 Please provide the new network details."

while true; do
  read -p "Enter the new IP address with CIDR (e.g., 192.168.1.10/24): " NEW_IP_CIDR
  NEW_IP=$(echo $NEW_IP_CIDR | cut -d'/' -f1)
  if validate_ip $NEW_IP; then
    break
  else
    echo "Invalid IP address format. Please try again."
  fi
done

while true; do
  read -p "Enter the new gateway address (e.g., 192.168.1.1): " NEW_GATEWAY
  if validate_ip $NEW_GATEWAY; then
    break
  else
    echo "Invalid gateway address format. Please try again."
  fi
done

echo ""
echo "==================== Configuration Summary ===================="
echo "The script will make the following changes:"
echo ""
echo "Configuration File: $INTERFACES_FILE"
echo "  - OLD address: $CURRENT_IP_CIDR"
echo "  + NEW address: $NEW_IP_CIDR"
echo "  - OLD gateway: $CURRENT_GATEWAY"
echo "  + NEW gateway: $NEW_GATEWAY"
echo ""
echo "Configuration File: $HOSTS_FILE"
echo "  - OLD IP mapping: $CURRENT_IP"
echo "  + NEW IP mapping: $NEW_IP"
echo "==============================================================="
echo ""

# --- Confirmation Prompt ---
read -p "Are you sure you want to apply these changes? (yes/no): " CONFIRMATION
if [[ ${CONFIRMATION,,} != "yes" ]]; then
    echo "Aborted. No changes have been made."
    exit 0
fi

# --- Perform the replacement ---
echo "🚀 Applying changes..."

# Backup files before editing
cp $INTERFACES_FILE "${INTERFACES_FILE}.bak_$(date +%F_%T)"
cp $HOSTS_FILE "${HOSTS_FILE}.bak_$(date +%F_%T)"

# Use sed to replace the lines
sed -i "s|^\(\s*address\s\)$CURRENT_IP_CIDR|\1$NEW_IP_CIDR|" $INTERFACES_FILE
sed -i "s|^\(\s*gateway\s\)$CURRENT_GATEWAY|\1$NEW_GATEWAY|" $INTERFACES_FILE
sed -i "s|^\($CURRENT_IP\s\)|$NEW_IP |" $HOSTS_FILE

echo "✅ Network configuration files have been updated successfully."
echo ""

# --- Reboot Prompt ---
read -p "A reboot is required to apply the network changes. Reboot now? (yes/no): " REBOOT_CONFIRM
if [[ ${REBOOT_CONFIRM,,} == "yes" ]]; then
    echo "Rebooting server now..."
    reboot
else
    echo "Changes have been saved but a reboot is required for them to take effect."
    echo "You can reboot manually by running the 'reboot' command."
fi

exit 0
```

***

### Step-by-Step Instructions

#### Step 1: Create the Script File

1.  Log in to your Proxmox server's console (either physically or via SSH if you still have access).
2.  Use the `nano` text editor to create a new file.

    ```bash
    nano change-proxmox-ip.sh
    ```

3.  Copy the entire bash script from the section above and paste it into the `nano` editor.
4.  Save the file and exit by pressing `Ctrl + X`, then `Y`, and finally `Enter`.

#### Step 2: Make the Script Executable

You need to give the script permission to be executed.

```bash
chmod +x change-proxmox-ip.sh
```

#### Step 3: Run the Script

Execute the script with `sudo` to ensure it has the necessary root permissions to modify system files.

```bash
sudo ./change-proxmox-ip.sh
```

The script will then guide you through the rest of the process:

1.  It will first show you the IP address and gateway it detected.
2.  It will then prompt you to enter the new IP address with CIDR (e.g., `192.168.1.10/24`).
3.  Next, it will ask for the new gateway (e.g., `192.168.1.1`).
4.  A summary of the intended changes will be displayed for your review.
5.  You must type `yes` to confirm and apply the changes.
6.  Finally, it will ask if you want to reboot. Type `yes` to restart the server with the new IP address.

After the reboot, your Proxmox server will be accessible on the new IP address you configured. Make sure your computer is connected to the same `192.168.1.0/24` network to access the web interface at `https://your-new-ip:8006`.
