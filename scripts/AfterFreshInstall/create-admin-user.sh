> [!NOTE]
> TUI-style Bash script** inspired by the Proxmox VE Helper-Scripts format. It will:

✅ Create a PAM user
✅ Set the user’s password
✅ Add the user to `sudo` (optional)
✅ Assign `Administrator` permissions in Proxmox
✅ Optionally enable SSH access

This is a fully self-contained script you can run directly on your Proxmox VE host (as `root`):

---

### ✅ Script: `create-admin-user.sh`

```bash
#!/bin/bash

# ─────────────────────────────────────────────────────────────
# Proxmox Admin User Creator - TUI Inspired Script
# Inspired by Proxmox VE Helper-Scripts
# ─────────────────────────────────────────────────────────────

PVE_REALM="pam"
ROLE="Administrator"

# Colors
GREEN='\033[1;32m'
RED='\033[1;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

function pause() {
  read -rp "Press [Enter] to continue..."
}

function header() {
  clear
  echo -e "${GREEN}"
  echo "┌────────────────────────────────────────────┐"
  echo "│      Proxmox Admin User Creation Tool      │"
  echo "└────────────────────────────────────────────┘"
  echo -e "${NC}"
}

function create_user() {
  header
  read -rp "Enter new admin username: " NEWUSER

  if id "$NEWUSER" &>/dev/null; then
    echo -e "${YELLOW}User '$NEWUSER' already exists.${NC}"
  else
    adduser "$NEWUSER"
  fi
  pause
}

function set_password() {
  header
  read -rp "Enter username to set password for: " USERNAME

  if id "$USERNAME" &>/dev/null; then
    passwd "$USERNAME"
  else
    echo -e "${RED}User does not exist.${NC}"
  fi
  pause
}

function assign_admin_role() {
  header
  read -rp "Enter username to assign Proxmox Administrator role: " USERNAME

  if id "$USERNAME" &>/dev/null; then
    pveum user add "${USERNAME}@${PVE_REALM}" 2>/dev/null || echo "User already exists in Proxmox realm."
    pveum aclmod / -user "${USERNAME}@${PVE_REALM}" -role "$ROLE"
    echo -e "${GREEN}Administrator role assigned to ${USERNAME}@${PVE_REALM}.${NC}"
  else
    echo -e "${RED}User does not exist.${NC}"
  fi
  pause
}

function add_to_sudo() {
  header
  read -rp "Enter username to add to sudo group: " USERNAME

  if id "$USERNAME" &>/dev/null; then
    usermod -aG sudo "$USERNAME"
    echo -e "${GREEN}User $USERNAME added to sudo group.${NC}"
  else
    echo -e "${RED}User does not exist.${NC}"
  fi
  pause
}

function enable_ssh_access() {
  header
  echo "SSH is already enabled system-wide for PAM users in most cases."
  echo "Ensure the user is in /etc/ssh/sshd_config AllowUsers or that the setting is not restrictive."
  echo
  systemctl status ssh
  pause
}

function menu() {
  while true; do
    header
    echo "1) Create new admin user"
    echo "2) Set user password"
    echo "3) Assign Proxmox Administrator role"
    echo "4) Add user to sudo group"
    echo "5) SSH Access Notes"
    echo "6) Exit"
    echo
    read -rp "Choose an option [1-6]: " OPTION
    case $OPTION in
      1) create_user ;;
      2) set_password ;;
      3) assign_admin_role ;;
      4) add_to_sudo ;;
      5) enable_ssh_access ;;
      6) echo "Exiting..."; exit 0 ;;
      *) echo -e "${RED}Invalid option.${NC}"; pause ;;
    esac
  done
}

menu
```

---

### ✅ How to Use

1. Save the script:

   ```bash
   nano create-admin-user.sh
   ```

   Paste the code, then save with `Ctrl+O`, `Enter`, and exit with `Ctrl+X`.

2. Make it executable:

   ```bash
   chmod +x create-admin-user.sh
   ```

3. Run it as root:

   ```bash
   ./create-admin-user.sh
   ```

---

### 🔐 Security Tip

Once the user is created and tested, consider **disabling root login via SSH** (edit `/etc/ssh/sshd_config` → `PermitRootLogin no`) for better security.

---

Would you like to turn this into a reusable `.deb` installer package or a Proxmox addon later?
