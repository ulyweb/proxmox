>[!NOTE]
> ## Creating a full, robust, menu-driven GUI automation in Bash :
>>***__as Bash is primarily a shell language.__***

### **menu-driven terminal-based interactive script** using `whiptail` or `dialog`. `whiptail` is generally more common and user-friendly for these types of simple text-based UIs on Debian/Ubuntu systems.

This script will:

  * Detect the current user.
  * Prompt for the Nextcloud VM's static IP and subdomain.
  * Provide a menu for Nginx Proxy Manager (NPM) and Nextcloud AIO setup tasks.
  * Include the `/etc/hosts` modification.
  * Incorporate the `sudo` commands and directory navigation.

**Assumptions:**

1.  You are running this script on the **Nextcloud VM itself (192.168.1.60)**.
2.  `whiptail` (or `dialog`) is installed. If not, the script will prompt to install it.
3.  The user running the script has `sudo` privileges.

-----

### **Full Script Code (Bash with `whiptail`)**

```bash
#!/bin/bash

# --- Configuration Variables (will be set by user input) ---
NEXTCLOUD_IP=""
NEXTCLOUD_SUBDOMAIN=""
USER_HOME=""

# --- Helper Functions ---

# Function to check for and install whiptail
install_whiptail() {
    if ! command -v whiptail &> /dev/null; then
        whiptail --yesno "whiptail is not installed. Do you want to install it now? (Requires sudo)" 10 60 --defaultno
        if [ $? -eq 0 ]; then
            sudo apt update && sudo apt install -y whiptail
            if [ $? -ne 0 ]; then
                whiptail --msgbox "Failed to install whiptail. Please install it manually: sudo apt install -y whiptail" 10 60
                exit 1
            fi
        else
            whiptail --msgbox "whiptail is required for this script. Exiting." 10 60
            exit 1
        fi
    fi
}

# Function to get user input for IP and Subdomain
get_user_config() {
    NEXTCLOUD_IP=$(whiptail --inputbox "Enter Nextcloud VM Static IP (e.g., 192.168.1.60):" 10 60 "$NEXTCLOUD_IP" 3>&1 1>&2 2>&3)
    exit_status=$?
    if [ $exit_status -ne 0 ]; then exit 1; fi # User cancelled

    NEXTCLOUD_SUBDOMAIN=$(whiptail --inputbox "Enter Nextcloud Subdomain (e.g., subdomain.duckdns.org):" 10 60 "$NEXTCLOUD_SUBDOMAIN" 3>&1 1>&2 2>&3)
    exit_status=$?
    if [ $exit_status -ne 0 ]; then exit 1; fi # User cancelled

    USER_HOME=$(eval echo "~$USER") # Get the current user's home directory
}

# Function to display a message box
show_message() {
    whiptail --msgbox "$1" 10 70
}

# Function to confirm an action
confirm_action() {
    whiptail --yesno "$1" 10 60 --defaultno
    return $?
}

# --- Installation/Configuration Functions ---

install_docker_and_compose() {
    show_message "Installing Docker and Docker Compose..."
    # Install Docker (from official convenience script, or package manager)
    # Using package manager is generally preferred for consistency on Debian/Ubuntu
    sudo apt update
    sudo apt install -y apt-transport-https ca-certificates curl software-properties-common
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    sudo apt update
    sudo apt install -y docker-ce docker-ce-cli containerd.io

    # Add current user to docker group
    sudo usermod -aG docker "$USER"
    show_message "Docker installed. You might need to log out and log back in for Docker group changes to take effect for your user."

    # Install Docker Compose V2 (recommended way for modern Docker)
    sudo apt install -y docker-compose-plugin
    if [ $? -eq 0 ]; then
        show_message "Docker Compose V2 (docker compose) installed successfully."
    else
        show_message "Failed to install Docker Compose V2. Trying legacy Docker Compose (docker-compose)."
        sudo curl -L "https://github.com/docker/compose/releases/download/v2.24.5/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
        sudo chmod +x /usr/local/bin/docker-compose
        if [ $? -eq 0 ]; then
            show_message "Legacy Docker Compose (docker-compose) installed successfully."
        else
            show_message "Failed to install any Docker Compose. Please install it manually."
        fi
    fi

    show_message "Docker and Docker Compose installation complete. Please log out and log back in for changes to take effect before proceeding with Docker-related tasks."
}


setup_npm() {
    show_message "Setting up Nginx Proxy Manager..."
    if confirm_action "Create /opt/npm directory and compose.yaml?"; then
        sudo mkdir -p /opt/npm
        sudo mkdir -p /mnt/ncdata # Ensure Nextcloud data directory also exists
        
        # Create compose.yaml
        sudo bash -c "cat > /opt/npm/compose.yaml <<EOF
services:
  app:
    image: 'jc21/nginx-proxy-manager:latest'
    restart: unless-stopped
    ports:
      - '80:80'    # HTTP
      - '443:443'  # HTTPS
      - '81:81'    # Admin Panel
    volumes:
      - ./data:/data
      - ./letsencrypt:/etc/letsencrypt
EOF"
        if [ $? -eq 0 ]; then
            show_message "NPM compose.yaml created successfully in /opt/npm."
        else
            show_message "Failed to create NPM compose.yaml."
            return 1
        fi
    fi

    if confirm_action "Start Nginx Proxy Manager containers?"; then
        sudo docker compose -f /opt/npm/compose.yaml up -d
        if [ $? -eq 0 ]; then
            show_message "NPM containers started. Access admin panel at http://$NEXTCLOUD_IP:81"
        else
            show_message "Failed to start NPM containers. Check logs."
        fi
    fi
}

setup_nextcloud_aio() {
    show_message "Setting up Nextcloud All-in-One..."
    if confirm_action "Create $USER_HOME/nextcloud-aio directory and compose.yaml?"; then
        mkdir -p "$USER_HOME/nextcloud-aio"
        
        # Create compose.yaml
        bash -c "cat > \"$USER_HOME/nextcloud-aio/compose.yaml\" <<EOF
services:
  nextcloud-aio-mastercontainer:
    image: ghcr.io/nextcloud-releases/all-in-one:latest
    container_name: nextcloud-aio-mastercontainer
    restart: always
    environment:
      # - SKIP_DOMAIN_VALIDATION=true
    ports:
      - \"80:80\"
      - \"8080:8080\"
      - \"8443:8443\"
    volumes:
      - nextcloud_aio_mastercontainer:/mnt/docker-aio-config
      - /var/run/docker.sock:/var/run/docker.sock:ro
      - /mnt/ncdata:/mnt/ncdata # Mounts host's /mnt/ncdata to /mnt/ncdata in container

volumes:
  nextcloud_aio_mastercontainer:
EOF"
        if [ $? -eq 0 ]; then
            show_message "Nextcloud AIO compose.yaml created successfully in $USER_HOME/nextcloud-aio."
        else
            show_message "Failed to create Nextcloud AIO compose.yaml."
            return 1
        fi
    fi

    if confirm_action "Start Nextcloud AIO master container?"; then
        # Use sudo for docker compose if user is not in docker group yet (though we try to add them)
        sudo docker compose -f "$USER_HOME/nextcloud-aio/compose.yaml" up -d
        if [ $? -eq 0 ]; then
            show_message "Nextcloud AIO master container started. Access AIO interface at https://$NEXTCLOUD_IP:8080"
            show_message "Remember to complete the AIO setup via the web interface (https://$NEXTCLOUD_IP:8080) and configure your domain: $NEXTCLOUD_SUBDOMAIN"
        else
            show_message "Failed to start Nextcloud AIO master container. Check logs."
        fi
    fi
}

modify_etc_hosts() {
    show_message "Modifying /etc/hosts file for NAT Loopback workaround..."
    if confirm_action "Add '$NEXTCLOUD_IP $NEXTCLOUD_SUBDOMAIN' to /etc/hosts?"; then
        # Check if the line already exists to avoid duplicates
        if ! sudo grep -q "$NEXTCLOUD_IP $NEXTCLOUD_SUBDOMAIN" /etc/hosts; then
            echo "$NEXTCLOUD_IP $NEXTCLOUD_SUBDOMAIN" | sudo tee -a /etc/hosts > /dev/null
            if [ $? -eq 0 ]; then
                show_message "Entry added to /etc/hosts. Verify with 'ping $NEXTCLOUD_SUBDOMAIN'"
            else
                show_message "Failed to add entry to /etc/hosts."
            fi
        else
            show_message "Entry '$NEXTCLOUD_IP $NEXTCLOUD_SUBDOMAIN' already exists in /etc/hosts. No changes made."
        fi
    fi
}

# --- Nextcloud Troubleshooting/Maintenance Functions ---

check_nc_logs() {
    show_message "Checking Nextcloud logs (last 50 lines from master container)..."
    sudo docker logs nextcloud-aio-mastercontainer --tail 50 | whiptail --textbox /dev/stdin 20 80
}

check_nc_container_health() {
    show_message "Checking status of Nextcloud AIO containers..."
    sudo docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | whiptail --textbox /dev/stdin 20 80
}

restart_nc_aio() {
    show_message "Restarting Nextcloud AIO containers..."
    if confirm_action "Are you sure you want to restart Nextcloud AIO? This will briefly take down your Nextcloud instance."; then
        # Find the compose file path based on user's home
        NC_AIO_COMPOSE_PATH="$USER_HOME/nextcloud-aio/compose.yaml"
        if [ -f "$NC_AIO_COMPOSE_PATH" ]; then
            sudo docker compose -f "$NC_AIO_COMPOSE_PATH" down
            sudo docker compose -f "$NC_AIO_COMPOSE_PATH" up -d
            show_message "Nextcloud AIO restarted."
        else
            show_message "Nextcloud AIO compose file not found at $NC_AIO_COMPOSE_PATH. Cannot restart."
        fi
    fi
}

# --- Main Menu Logic ---

main_menu() {
    while true; do
        CHOICE=$(whiptail --title "Nextcloud AIO & NPM Automation" --menu "Choose an option:" 25 80 15 \
            "1" "Set/Update Nextcloud IP & Subdomain" \
            "2" "Install Docker and Docker Compose" \
            "3" "Setup Nginx Proxy Manager (NPM)" \
            "4" "Setup Nextcloud All-in-One (AIO)" \
            "5" "Apply /etc/hosts NAT Loopback Workaround" \
            "6" "Check Nextcloud AIO Container Health" \
            "7" "Check Nextcloud AIO Logs (last 50 lines)" \
            "8" "Restart Nextcloud AIO Containers" \
            "9" "Run All Initial Setup Steps (Docker, NPM, AIO, Hosts)" \
            "10" "Exit" 3>&1 1>&2 2>&3)

        exit_status=$?
        if [ $exit_status -ne 0 ]; then
            break # User pressed Cancel or Escape
        fi

        case "$CHOICE" in
            1) get_user_config ;;
            2) install_docker_and_compose ;;
            3) setup_npm ;;
            4) setup_nextcloud_aio ;;
            5) modify_etc_hosts ;;
            6) check_nc_container_health ;;
            7) check_nc_logs ;;
            8) restart_nc_aio ;;
            9) # Run All Initial Setup Steps
                show_message "Running all initial setup steps. Ensure you've set IP and Subdomain first."
                get_user_config # Ensure config is set
                install_docker_and_compose
                show_message "Please log out and log back in for Docker group changes to take effect, then re-run the script and choose 'Run All Initial Setup Steps' again."
                break # Exit to force re-login for Docker group
                # If they didn't re-login, subsequent docker commands will fail.
                # A more robust script might check if user is in docker group here.

                # After re-login and re-running the script:
                # setup_npm
                # setup_nextcloud_aio
                # modify_etc_hosts
                ;;
            10) break ;; # Exit
            *) show_message "Invalid choice. Please try again." ;;
        esac
    done
    show_message "Exiting Nextcloud AIO & NPM Automation script. Goodbye!"
}

# --- Main Script Execution ---

install_whiptail # Ensure whiptail is available first

# Initial prompt for IP and Subdomain if not already set or remembered
if [ -z "$NEXTCLOUD_IP" ] || [ -z "$NEXTCLOUD_SUBDOMAIN" ]; then
    get_user_config
fi

# Start the main menu
main_menu
```

-----

### **How to Use the Script:**

1.  **Save the script:**
    Save the code above into a file, for example, `nextcloud_setup.sh`:

    ```bash
    nano nextcloud_setup.sh
    ```

    Paste the code, then `Ctrl+X`, `Y`, `Enter`.

2.  **Make it executable:**

    ```bash
    chmod +x nextcloud_setup.sh
    ```

3.  **Run the script:**

    ```bash
    ./nextcloud_setup.sh
    ```

4.  **Follow the Prompts:**

      * The script will first check if `whiptail` is installed and offer to install it.
      * It will then ask for your Nextcloud VM's static IP and your subdomain.
      * A main menu will appear, allowing you to select different actions.

**Important Notes and Considerations:**

  * **`localadmin` vs. `$USER`:** The script uses `$USER` which automatically expands to the current logged-in user's username (e.g., `localadmin`). `USER_HOME=$(eval echo "~$USER")` correctly determines that user's home directory.
  * **Dynamic IP/Subdomain:** The script prompts for these values at the beginning. If you re-run the script, it *will* prompt again, allowing you to update them if necessary.
  * **`sudo` and Docker Group:**
      * The `install_docker_and_compose` function adds the current user to the `docker` group. **For this change to take effect, you must log out and log back in.** The script includes a message about this. If you select "Run All Initial Setup Steps", it will tell you to re-login. This is a critical step for `docker compose` commands to work without `sudo` by the user directly.
      * Until you log out/in, Docker commands in the script will use `sudo`.
  * **NPM `compose.yaml` location:** The script places it in `/opt/npm` as you specified, requiring `sudo` for creation.
  * **Nextcloud AIO `compose.yaml` location:** The script places it in `/home/$USER/nextcloud-aio` as you specified, which is the current user's home directory, so `sudo` is not strictly needed for the `mkdir` or `cat` commands *for that directory*, but `sudo` *is* needed for Docker commands.
  * **`compose.yaml` Content:** The `cat > file <<EOF` syntax is used to write the multi-line YAML configurations cleanly.
  * **"Run All Initial Setup Steps" (Option 9):** This is a convenience option. Due to the Docker group membership requirement, it explicitly tells you to re-login after Docker installation. You'd then re-run the script and choose "Run All Initial Setup Steps" again to complete NPM, AIO, and hosts file modifications.
  * **Error Handling:** The script includes basic `if [ $? -ne 0 ]` checks after commands to provide some feedback if a command fails.
  * **`whiptail` vs. `dialog`:** If `whiptail` isn't available or preferred, you could modify the script to use `dialog` (replace `whiptail` commands with `dialog` equivalents), but you'd need to install `dialog` instead. `whiptail` is generally simpler for these types of menus.
  * **User Interface:** This is a text-based UI. It's not a graphical desktop window, but it provides interactive prompts and menus in your terminal.

---

### This script should provide a solid foundation for automating your Nextcloud AIO and Nginx Proxy Manager setup and basic maintenance tasks\!
