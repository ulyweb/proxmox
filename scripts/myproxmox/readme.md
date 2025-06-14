>[!NOTE] Automating those post-creation VM tasks menu-driven script to handle the installation and setup of Docker, Nextcloud, and Immich.



One important note: I noticed the Nextcloud setup step in your manual list was using a configuration file from Immich. 
This was likely a copy-paste error. To prevent a broken installation, my script will correctly create the directories for Nextcloud, 
and then I'll guide you on where to find the official, correct command from the Nextcloud AIO team.

### ---

**The Post-VM Setup Script**

Here is the complete script. You can run this inside your newly created Debian or Ubuntu-based VM to perform the setup.

Post-VM Setup Script  
Jun 14, 12:57 PM  
Open  
Try again without Canvas

### **How to Use the Script**

Follow these steps **inside your new VM**, not on the Proxmox host itself.

1. Connect to Your VM:  
   Log in to your new VM's terminal via SSH or using the console in the Proxmox web interface.  
2. Become Root or Use sudo:  
   You will need root privileges. You can either log in as root or, more commonly, use a standard user account that has sudo privileges.  
3. Create the Script File:  
   Use a text editor like nano to create the script file.  
   Bash  
   nano vm\_setup.sh

4. Paste the Script Code:  
   Copy the entire script from the code block above and paste it into the nano editor.  
5. **Save and Exit the Editor:**  
   * Press Ctrl \+ X.  
   * Press Y to confirm you want to save.  
   * Press Enter to accept the filename.  
6. Make the Script Executable:  
   This command gives your user permission to run the script.  
   Bash  
   chmod \+x vm\_setup.sh

7. Run the Script:  
   Execute the script using sudo to ensure it has the necessary permissions to install software and create directories.  
   Bash  
   sudo ./vm\_setup.sh

The script will launch its menu. You can choose to run each step individually or select option 4 to run them all at once. Just follow the on-screen prompts.
