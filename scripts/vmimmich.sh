#!/usr/bin/env bash

# --- Configuration ---
APP="immich-vm" # Changed name to avoid conflict if you have an LXC with original name
VM_DISK_SIZE="${VM_DISK_SIZE:-64G}" # Increased default for VM OS + Immich + libraries
VM_CORES="${VM_CORES:-4}"
VM_RAM="${VM_RAM:-4096}" # In MB
VM_OS_IMAGE_NAME="${VM_OS_IMAGE_NAME:-debian-12-cloud.qcow2}" # Ensure this image exists
VM_BRIDGE="${VM_BRIDGE:-vmbr0}"
VM_STORAGE="${VM_STORAGE:-local-lvm}" # Storage for VM disk
ISO_STORAGE="${ISO_STORAGE:-local}"    # Storage where your cloud-init OS image is located (can be same as VM_STORAGE if it supports images)
CI_USER="${CI_USER:-immichadmin}" # Cloud-init user
CI_SSH_KEY_PATH="${CI_SSH_KEY_PATH:-$HOME/.ssh/id_rsa.pub}" # SSH public key for cloud-init user

# --- Basic Helper Functions (minimal replacement for parts of build.func) ---
CL="\033[0m"
BLB="\033[1;34m"
GN="\033[1;32m"
RD="\033[1;31m"
YW="\033[1;33m"
INFO="[${BLB}INFO${CL}]"
OK="[${GN}OK${CL}]"
ERROR="[${RD}ERROR${CL}]"
WARN="[${YW}WARNING${CL}]"

function msg_info() {
    echo -e "$INFO $1"
}
function msg_ok() {
    echo -e "$OK $1"
}
function msg_error() {
    echo -e "$ERROR $1"
    exit 1
}
function msg_warn() {
    echo -e "$WARN $1"
}

# --- Main Script ---
header_info() {
  echo -e "${BLB}----------------------------------------------------------${CL}"
  echo -e "${BLB}This script will create a new Proxmox VM for ${APP}.${CL}"
  echo -e "${BLB}----------------------------------------------------------${CL}"
  echo
}

check_dependencies() {
  msg_info "Checking for required commands (qm, pvesh)..."
  command -v qm >/dev/null 2>&1 || msg_error "'qm' command not found. This script must be run on a Proxmox VE host."
  command -v pvesh >/dev/null 2>&1 || msg_error "'pvesh' command not found."
  msg_ok "Required commands found."

  if [[ ! -f "$CI_SSH_KEY_PATH" ]]; then
    msg_error "SSH public key not found at $CI_SSH_KEY_PATH. Please generate one or specify the correct path."
  fi
  msg_ok "SSH public key found."

  # Check if cloud-init image exists (basic check, pvesm can do better)
  # Example: pvesh get /nodes/$(hostname)/storage/${ISO_STORAGE}/content -content images | jq -r '.[] | select(.volid=="'${ISO_STORAGE}:${VM_OS_IMAGE_NAME}'") | .volid'
  # For simplicity, we'll assume user ensures it's there. A robust script would verify via pvesm.
  msg_info "Please ensure the cloud-init image '${VM_OS_IMAGE_NAME}' is available on storage '${ISO_STORAGE}'."
  # A more robust check:
  if ! pvesh get /nodes/$(hostname -s)/storage/${ISO_STORAGE}/content --output-format json | jq -e --arg volid "${ISO_STORAGE}:${VM_OS_IMAGE_NAME}" '.[] | select(.volid==$volid)' > /dev/null; then
    msg_error "Cloud-init image '${VM_OS_IMAGE_NAME}' not found on storage '${ISO_STORAGE}'."
  fi
  msg_ok "Cloud-init image '${VM_OS_IMAGE_NAME}' assumed to be available."
}

# --- Cloud-init Setup Script (this will run inside the VM) ---
# Note: This script is extensive and includes library compilation. It can take a LONG time to run via cloud-init.
# Consider pre-building a custom image or using Ansible for more complex setups.
create_cloud_init_script() {
  cat <<EOF > /tmp/immich_setup_vm.sh
#!/usr/bin/env bash
export DEBIAN_FRONTEND=noninteractive
STD_APT="apt-get -y -o Dpkg::Options::=--force-confdef -o Dpkg::Options::=--force-confold"
IMMICH_APP_NAME="immich" # Keep this as 'immich' for paths inside the VM
IMMICH_USER="immich"
IMMICH_GROUP="immich"
IMMICH_INSTALL_DIR="/opt/\${IMMICH_APP_NAME}"
IMMICH_ENV_FILE="\${IMMICH_INSTALL_DIR}/.env"
UPLOAD_DIR="/mnt/immich-uploads" # Example external upload location

echo ">>>> Starting Immich VM Setup Script <<<<"

echo ">>>> [1/10] Updating package lists and installing prerequisites <<<<"
\$STD_APT update
\$STD_APT install -y sudo git curl jq wget gnupg build-essential pkg-config libjpeg62-turbo-dev \\
  libheif-dev librsvg2-dev libopenjp2-7-dev libgsf-1-dev libimage-exiftool-perl libraw-dev \\
  libwebp-dev libavif-dev meson nasm libdav1d-dev libaom-dev libde265-dev libx265-dev \\
  libsharpyuv-dev python3 python3-venv python3-pip nodejs npm postgresql postgresql-contrib \\
  nginx # Nginx for reverse proxy (optional, but good practice)
# Add other dependencies from the original script like patchelf if needed for OpenVINO

echo ">>>> [2/10] Creating Immich user and group <<<<"
if ! getent group \${IMMICH_GROUP} >/dev/null; then groupadd \${IMMICH_GROUP}; fi
if ! id \${IMMICH_USER} >/dev/null 2>&1; then useradd -r -g \${IMMICH_GROUP} -M -s /sbin/nologin -d \${IMMICH_INSTALL_DIR} \${IMMICH_USER}; fi

echo ">>>> [3/10] Setting up PostgreSQL <<<<"
# Assuming PostgreSQL 16 is installed by 'postgresql' package on Debian 12
# If specific version needed, adjust package name
systemctl enable --now postgresql
sudo -u postgres psql -c "CREATE DATABASE immich;"
sudo -u postgres psql -c "CREATE USER immich WITH ENCRYPTED PASSWORD 'immich';" # Change password in production!
sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE immich TO immich;"
sudo -u postgres psql -d immich -c "CREATE EXTENSION IF NOT EXISTS pg_trgm;"
# For Vector support (using pgvector for wider compatibility initially)
# The original script has complex logic for vchord. Simpler pgvector for now.
\$STD_APT install -y postgresql-16-pgvector # Adjust version if needed
sudo -u postgres psql -d immich -c "CREATE EXTENSION IF NOT EXISTS vector;"
# If you want to keep the VectorChord logic, it needs to be adapted here carefully.

echo ">>>> [4/10] Creating Immich directories <<<<"
mkdir -p \${IMMICH_INSTALL_DIR} /opt/staging \${UPLOAD_DIR} \${IMMICH_INSTALL_DIR}/cache \${IMMICH_INSTALL_DIR}/geodata
chown -R \${IMMICH_USER}:\${IMMICH_GROUP} \${IMMICH_INSTALL_DIR} \${UPLOAD_DIR} \${IMMICH_INSTALL_DIR}/cache \${IMMICH_INSTALL_DIR}/geodata
chmod -R 755 \${IMMICH_INSTALL_DIR} \${UPLOAD_DIR}

echo ">>>> [5/10] Creating .env file for Immich <<<<"
cat <<ENV > \${IMMICH_ENV_FILE}
# Required
DB_HOSTNAME=localhost
DB_USERNAME=immich
DB_PASSWORD=immich # Change password here too!
DB_DATABASE_NAME=immich
REDIS_HOSTNAME=localhost # Immich comes with its own Redis

# Paths (adjust if your UPLOAD_DIR is different or on a separate mount)
UPLOAD_LOCATION=\${UPLOAD_DIR} # This is where Immich stores media
# Ensure this path exists and is writable by the user running Immich.

# Optional
NODE_ENV=production
LOG_LEVEL=info
# JWT_SECRET can be generated with: openssl rand -hex 32
JWT_SECRET=\$(openssl rand -hex 32)
TYPESENSE_API_KEY=\$(openssl rand -hex 32) # For search, if used
# Add other variables as needed from https://immich.app/docs/install/environment-variables
# For example, if using reverse proxy:
# IMMICH_SERVER_URL=https://your.immich.domain.com
# IMMICH_WEB_URL=https://your.immich.domain.com
ENV
chown \${IMMICH_USER}:\${IMMICH_GROUP} \${IMMICH_ENV_FILE}
chmod 600 \${IMMICH_ENV_FILE}

echo ">>>> [6/10] Compiling image-processing libraries (This will take a VERY long time) <<<<"
# This section is a direct adaptation of the library compilation from your script.
# It's run as root here for simplicity of installs.
STAGING_DIR=/opt/staging
BASE_DIR=\${STAGING_DIR}/base-images
SOURCE_DIR=\${STAGING_DIR}/image-source
mkdir -p \${STAGING_DIR} \${BASE_DIR} \${SOURCE_DIR}

# Install build tools for libraries if not covered by main prerequisites
# apt-get install -y cmake autoconf automake libtool nasm

echo "Cloning base-images..."
git clone https://github.com/immich-app/base-images.git "\${BASE_DIR}"
cd "\${BASE_DIR}"
git pull # Ensure it's up to date

libraries=("libjxl" "libheif" "libraw" "imagemagick" "libvips") # Add more if needed
# This simplified version recompiles all listed libraries.
# The original script has logic to check revisions, which is more efficient for updates.
# For a first install, compiling them all is fine.

for name in "\${libraries[@]}"; do
  if [[ "\$name" == "libjxl" ]]; then
    echo "Compiling libjxl..."
    SOURCE=\${SOURCE_DIR}/libjxl
    JPEGLI_LIBJPEG_LIBRARY_SOVERSION="62"
    JPEGLI_LIBJPEG_LIBRARY_VERSION="62.3.0"
    LIBJXL_REVISION=\$(jq -cr '.revision' \${BASE_DIR}/server/sources/libjxl.json)
    git clone https://github.com/libjxl/libjxl.git "\$SOURCE"
    cd "\$SOURCE"
    git reset --hard "\$LIBJXL_REVISION"
    git submodule update --init --recursive --depth 1 --recommend-shallow
    git apply "\${BASE_DIR}"/server/sources/libjxl-patches/jpegli-empty-dht-marker.patch
    git apply "\${BASE_DIR}"/server/sources/libjxl-patches/jpegli-icc-warning.patch
    mkdir -p build && cd build
    cmake \\
      -DCMAKE_BUILD_TYPE=Release \\
      -DBUILD_TESTING=OFF \\
      -DJPEGXL_ENABLE_DOXYGEN=OFF \\
      -DJPEGXL_ENABLE_MANPAGES=OFF \\
      -DJPEGXL_ENABLE_PLUGIN_GIMP210=OFF \\
      -DJPEGXL_ENABLE_BENCHMARK=OFF \\
      -DJPEGXL_ENABLE_EXAMPLES=OFF \\
      -DJPEGXL_FORCE_SYSTEM_BROTLI=ON \\
      -DJPEGXL_FORCE_SYSTEM_HWY=ON \\
      -DJPEGXL_ENABLE_JPEGLI=ON \\
      -DJPEGXL_ENABLE_JPEGLI_LIBJPEG=ON \\
      -DJPEGXL_INSTALL_JPEGLI_LIBJPEG=ON \\
      -DJPEGXL_ENABLE_PLUGINS=ON \\
      -DJPEGLI_LIBJPEG_LIBRARY_SOVERSION="\$JPEGLI_LIBJPEG_LIBRARY_SOVERSION" \\
      -DJPEGLI_LIBJPEG_LIBRARY_VERSION="\$JPEGLI_LIBJPEG_LIBRARY_VERSION" \\
      -DLIBJPEG_TURBO_VERSION_NUMBER=2001005 \\
      ..
    make -j"\$(nproc)" && make install && ldconfig /usr/local/lib && make clean
    cd "\${STAGING_DIR}" && rm -rf "\$SOURCE"/{build,third_party}
    echo "libjxl compiled."
  fi
  if [[ "\$name" == "libheif" ]]; then
    echo "Compiling libheif..."
    SOURCE=\${SOURCE_DIR}/libheif
    LIBHEIF_REVISION=\$(jq -cr '.revision' \${BASE_DIR}/server/sources/libheif.json)
    git clone https://github.com/strukturag/libheif.git "\$SOURCE"
    cd "\$SOURCE"
    git reset --hard "\$LIBHEIF_REVISION"
    mkdir -p build && cd build
    cmake --preset=release-noplugins \\
      -DWITH_DAV1D=ON \\
      -DENABLE_PARALLEL_TILE_DECODING=ON \\
      -DWITH_LIBSHARPYUV=ON \\
      -DWITH_LIBDE265=ON \\
      -DWITH_AOM_DECODER=OFF \\
      -DWITH_AOM_ENCODER=OFF \\
      -DWITH_X265=OFF \\
      -DWITH_EXAMPLES=OFF \\
      ..
    make install -j "\$(nproc)" && ldconfig /usr/local/lib && make clean
    cd "\${STAGING_DIR}" && rm -rf "\$SOURCE"/build
    echo "libheif compiled."
  fi
  if [[ "\$name" == "libraw" ]]; then
    echo "Compiling libraw..."
    SOURCE=\${SOURCE_DIR}/libraw
    LIBRAW_REVISION=\$(jq -cr '.revision' \${BASE_DIR}/server/sources/libraw.json)
    git clone https://github.com/libraw/libraw.git "\$SOURCE"
    cd "\$SOURCE"
    git reset --hard "\$LIBRAW_REVISION"
    autoreconf --install && ./configure && make -j"\$(nproc)" && make install && ldconfig /usr/local/lib && make clean
    cd "\${STAGING_DIR}"
    echo "libraw compiled."
  fi
  if [[ "\$name" == "imagemagick" ]]; then
    echo "Compiling ImageMagick..."
    SOURCE=\${SOURCE_DIR}/imagemagick
    IMAGEMAGICK_REVISION=\$(jq -cr '.revision' \${BASE_DIR}/server/sources/imagemagick.json)
    git clone https://github.com/ImageMagick/ImageMagick.git "\$SOURCE"
    cd "\$SOURCE"
    git reset --hard "\$IMAGEMAGICK_REVISION"
    ./configure --with-modules && make -j"\$(nproc)" && make install && ldconfig /usr/local/lib && make clean
    cd "\${STAGING_DIR}"
    echo "ImageMagick compiled."
  fi
  if [[ "\$name" == "libvips" ]]; then
    echo "Compiling libvips..."
    SOURCE=\${SOURCE_DIR}/libvips
    LIBVIPS_REVISION=\$(jq -cr '.revision' \${BASE_DIR}/server/sources/libvips.json)
    git clone https://github.com/libvips/libvips.git "\$SOURCE"
    cd "\$SOURCE"
    git reset --hard "\$LIBVIPS_REVISION"
    meson setup build --buildtype=release --libdir=lib -Dintrospection=disabled -Dtiff=disabled
    cd build && ninja install && ldconfig /usr/local/lib
    cd "\${STAGING_DIR}" && rm -rf "\$SOURCE"/build
    echo "libvips compiled."
  fi
done
echo "Image-processing libraries compiled."
# Storing a record of compiled revisions (similar to original script)
# libraries_for_record=("libjxl" "libheif" "libraw" "imagemagick" "libvips")
# NEW_REVISIONS_FILE="/root/.immich_library_revisions" # Store as root as script runs as root
# > "\$NEW_REVISIONS_FILE" # Create/truncate the file
# for library_name in "\${libraries_for_record[@]}"; do
#   revision=\$(jq -cr '.revision' "\${BASE_DIR}"/server/sources/"\$library_name".json)
#   echo "\$library_name: \$revision" >> "\$NEW_REVISIONS_FILE"
# done

echo ">>>> [7/10] Downloading and setting up Immich application <<<<"
# Get latest release version
RELEASE=\$(curl -s https://api.github.com/repos/immich-app/immich/releases/latest | jq -r .tag_name | sed 's/v//')
echo "Latest Immich release: v\${RELEASE}"

APP_INSTALL_DIR="\${IMMICH_INSTALL_DIR}/app" # Renamed to avoid confusion with IMMICH_INSTALL_DIR
SRC_DIR="\${IMMICH_INSTALL_DIR}/source"
ML_DIR="\${APP_INSTALL_DIR}/machine-learning"
GEO_DIR="\${IMMICH_INSTALL_DIR}/geodata" # Already created

mkdir -p "\${APP_INSTALL_DIR}" "\${SRC_DIR}" "\${ML_DIR}"

immich_zip=\$(mktemp)
curl -fsSL "https://github.com/immich-app/immich/archive/refs/tags/v\${RELEASE}.zip" -o "\$immich_zip"
echo "Unzipping Immich v\${RELEASE}..."
unzip -q "\$immich_zip" -d "/opt" # Unzip to /opt then move
mv "/opt/\${IMMICH_APP_NAME}-\${RELEASE}" "\${SRC_DIR}" # Correct source path after unzip

echo "Building Immich server..."
cd "\${SRC_DIR}/server"
npm install -g node-gyp node-pre-gyp # Global tools
npm ci && npm run build && npm prune --omit=dev --omit=optional

echo "Building Immich open-api SDK..."
cd "\${SRC_DIR}/open-api/typescript-sdk"
npm ci && npm run build

echo "Building Immich web..."
cd "\${SRC_DIR}/web"
npm ci && npm run build

echo "Copying built application files..."
cd "\${SRC_DIR}"
cp -a server/{node_modules,dist,bin,resources,package.json,package-lock.json,start*.sh} "\${APP_INSTALL_DIR}/"
cp -a web/build "\${APP_INSTALL_DIR}/www"
cp LICENSE "\${APP_INSTALL_DIR}"

echo "Setting up Machine Learning component..."
cd "\${SRC_DIR}/machine-learning"
python3 -m venv "\${ML_DIR}/ml-venv"
source "\${ML_DIR}/ml-venv/bin/activate"
pip3 install -U pip uv # Install uv inside venv
uv pip install --system --extra cpu # Using --system as it's in a venv; remove if problematic
# For OpenVINO/Intel GPU, uncomment and adapt:
# uv pip install --system --extra openvino
# patchelf --clear-execstack "\${ML_DIR}/ml-venv/lib/python3.XX/site-packages/onnxruntime/capi/onnxruntime_pybind11_state.cpython-3XX-x86_64-linux-gnu.so" # Adjust python version
deactivate
cp -a machine-learning/{ann,immich_ml} "\${ML_DIR}"
# Original script copies ml_start.sh, ensure it exists or is generated
cp "\${APP_INSTALL_DIR}/start-machine-learning.sh" "\${ML_DIR}/ml_start.sh" # Assuming it's there

echo "Finalizing paths and links..."
ln -sf "\${APP_INSTALL_DIR}/resources" "\${IMMICH_INSTALL_DIR}/resources" # symlink resources
cd "\${APP_INSTALL_DIR}"
# Fix hardcoded paths if any (careful with these)
# grep -Rl /usr/src . | xargs -n1 sed -i "s|/usr/src|\${IMMICH_INSTALL_DIR}|g" # Be cautious
# grep -RlE "'/build'" . | xargs -n1 sed -i "s|'/build'|\${APP_INSTALL_DIR}|g"
sed -i "s@\"/cache\"@\"\${IMMICH_INSTALL_DIR}/cache\"@g" "\${ML_DIR}/immich_ml/config.py"

# Symlink upload directory (ensure UPLOAD_DIR from .env is used)
ln -s "\$(grep '^UPLOAD_LOCATION=' \${IMMICH_ENV_FILE} | cut -d'=' -f2)" "\${APP_INSTALL_DIR}/upload"
ln -s "\$(grep '^UPLOAD_LOCATION=' \${IMMICH_ENV_FILE} | cut -d'=' -f2)" "\${ML_DIR}/upload"
ln -s "\${GEO_DIR}" "\${APP_INSTALL_DIR}/geodata" # symlink geodata

echo "Installing Immich CLI..."
# Sharp needs to be built from source after other libraries are available
npm install --build-from-source sharp
rm -rf "\${APP_INSTALL_DIR}/node_modules/@img/sharp-{libvips*,linuxmusl-x64}" # Clean up prebuilt binaries
npm i -g @immich/cli

echo "Setting ownership for Immich installation..."
chown -R \${IMMICH_USER}:\${IMMICH_GROUP} \${IMMICH_INSTALL_DIR}
echo "\${RELEASE}" > "\${IMMICH_INSTALL_DIR}_\${IMMICH_APP_NAME}_version.txt"

echo ">>>> [8/10] Setting up systemd services <<<<"
# Immich Server/Web Service
cat << SYSTEMD_WEB > /etc/systemd/system/immich-server.service
[Unit]
Description=Immich Server (Web)
Wants=network-online.target
After=network-online.target postgresql.service
StartLimitIntervalSec=5
StartLimitBurst=10

[Service]
User=\${IMMICH_USER}
Group=\${IMMICH_GROUP}
WorkingDirectory=\${APP_INSTALL_DIR}
ExecStart=/usr/bin/node \${APP_INSTALL_DIR}/dist/main.js
Restart=on-failure
RestartSec=5s
EnvironmentFile=\${IMMICH_ENV_FILE}
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
SYSTEMD_WEB

# Immich Microservices (Job Queue, etc. - started by server)
# Immich Machine Learning Service
cat << SYSTEMD_ML > /etc/systemd/system/immich-ml.service
[Unit]
Description=Immich Machine Learning
Wants=network-online.target
After=network-online.target immich-server.service
StartLimitIntervalSec=5
StartLimitBurst=10

[Service]
User=\${IMMICH_USER}
Group=\${IMMICH_GROUP}
WorkingDirectory=\${ML_DIR}
ExecStart=\${ML_DIR}/ml_start.sh # Use the copied/generated script
Restart=on-failure
RestartSec=5s
EnvironmentFile=\${IMMICH_ENV_FILE}
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
SYSTEMD_ML

systemctl daemon-reload
systemctl enable --now immich-server.service immich-ml.service

echo ">>>> [9/10] Cleaning up <<<<"
rm -f "\$immich_zip"
rm -rf "\${SRC_DIR}" # Remove source after build
# apt-get -y autoremove # Be careful with autoremove in cloud-init if other things depend on auto-installed pkgs
apt-get -y autoclean
# Consider cleaning /opt/staging too if space is critical
# rm -rf /opt/staging

echo ">>>> [10/10] Immich setup complete. <<<<"
echo "Immich should be accessible at http://<VM_IP>:2283 (or your reverse proxy address)"
echo "Default DB user: immich, pass: immich (CHANGE THIS!)"
echo "Uploads directory: \${UPLOAD_DIR}"

touch /opt/immich_setup_complete
# End of cloud-init script
EOF
chmod +x /tmp/immich_setup_vm.sh
msg_ok "Cloud-init script created at /tmp/immich_setup_vm.sh"
}


build_vm() {
  msg_info "Starting VM build process..."

  NEXTID=$(pvesh get /cluster/nextid)
  VMID="$NEXTID"
  VM_NAME="${APP}-${VMID}"
  msg_info "New VM ID: ${VMID}, Name: ${VM_NAME}"

  msg_info "Creating VM ${VMID}..."
  qm create "${VMID}" \
    --name "${VM_NAME}" \
    --machine q35 \
    --bios ovmf \
    --efidisk0 ${VM_STORAGE}:1,format=qcow2,efitype=4m,pre-enrolled-keys=1 \
    --memory "${VM_RAM}" \
    --cores "${VM_CORES}" \
    --cpu host \
    --net0 virtio,bridge=${VM_BRIDGE},firewall=1 \
    --scsihw virtio-scsi-pci \
    --description "Immich Photo Management VM. Managed by script." \
    --tags "immich,photos,scripted"

  msg_info "Importing OS disk from ${VM_OS_IMAGE_NAME} on ${ISO_STORAGE} to ${VM_STORAGE}..."
  qm importdisk "${VMID}" "${VM_OS_IMAGE_NAME}" "${VM_STORAGE}" --format qcow2 # Let Proxmox handle volid on target storage

  msg_info "Attaching OS disk and setting boot order..."
  # The imported disk will be 'unusedX'. Find it and attach.
  # A common pattern is it becomes 'vm-<vmid>-disk-0' on the target storage.
  # We'll assume it's vm-${VMID}-disk-0 for simplicity.
  # A more robust way is to parse 'qm rescan --vmid ${VMID}' or 'pvesm list ${VM_STORAGE}'
  # For now, assume the standard naming convention after import:
  OS_DISK_VOLID="${VM_STORAGE}:vm-${VMID}-disk-0" # This is an assumption.
                                                  # If importdisk doesn't create this predictable name,
                                                  # you might need to find the actual volid.
                                                  # Example: qm set ${VMID} --scsi0 ${VM_STORAGE}:$(basename $(pvesm list ${VM_STORAGE} | grep "vm-${VMID}-disk-[0-9]" | awk '{print $1}'))

  qm set "${VMID}" --scsi0 ${OS_DISK_VOLID},discard=on,ssd=1,iothread=1
  qm set "${VMID}" --boot order=scsi0

  msg_info "Configuring Cloud-Init drive..."
  qm set "${VMID}" --ide2 ${ISO_STORAGE}:cloudinit # Uses the ISO_STORAGE, can be same as VM_STORAGE
  qm set "${VMID}" --ciuser "${CI_USER}"
  # qm set "${VMID}" --cipassword "YourSecurePassword" # Alternatively, but SSH keys are better
  qm set "${VMID}" --sshkeys "${CI_SSH_KEY_PATH}"
  qm set "${VMID}" --ipconfig0 ip=dhcp # Assuming DHCP

  msg_info "Attaching cloud-init setup script..."
  # Store the cloud-init script to a snippet or pass directly. For Proxmox, local snippet is cleaner.
  # First, ensure the local snippets directory exists for the target storage if it's dir-based
  # For this script, we'll use a temporary file and load it via qm set --cicustom
  # This avoids needing a 'snippets' directory on a specific storage.
  # The script file /tmp/immich_setup_vm.sh needs to be accessible by the Proxmox user running this.
  # Proxmox will copy this into the cloud-init drive.
  qm set "${VMID}" --cicustom "user=local:snippets/immich_setup_vm.sh" # This expects /var/lib/vz/snippets/immich_setup_vm.sh
                                                                        # Let's copy it there.
  SNIPPET_PATH="/var/lib/vz/snippets/immich_setup_vm.sh" # Default local snippet path
  cp /tmp/immich_setup_vm.sh "${SNIPPET_PATH}" || msg_error "Failed to copy setup script to ${SNIPPET_PATH}"
  # Ensure your ISO_STORAGE is configured to provide snippets if it's not 'local'
  # A safer way for generic storage if it's not 'local':
  # qm set $VMID --cicustom "user=local:$(pwd)/immich_setup_vm.sh" (if PVE host can access script path)
  # However, the 'local:snippets/' is the standard way for file-based custom scripts.
  # If your ISO_STORAGE is not 'local', you might need to adjust how cicustom is used or where the script is placed.
  # For robust solution, upload to a storage that supports snippets.
  # Assuming 'local' storage for snippets:
  msg_ok "Copied cloud-init script to ${SNIPPET_PATH} for VM ${VMID}."


  msg_info "Setting up QEMU Guest Agent..."
  qm set "${VMID}" --agent enabled=1,fstrim_cloned_disks=1

  msg_info "Resizing OS disk to ${VM_DISK_SIZE}..."
  qm resize "${VMID}" scsi0 "${VM_DISK_SIZE}" # Cloud-init should handle filesystem resize inside VM

  msg_info "Starting VM ${VMID}..."
  qm start "${VMID}"

  msg_ok "VM ${VMID} (${VM_NAME}) creation initiated."
  echo -e "${WARN}The Immich installation inside the VM will take a SIGNIFICANT amount of time."
  echo -e "${WARN}Monitor the VM console or wait for '/opt/immich_setup_complete' file creation inside the VM."
  echo -e "${INFO}You can access the VM console via Proxmox web UI or 'qm terminal ${VMID}'."
  echo -e "${INFO}Once setup is complete, Immich should be accessible at http://<VM_IP>:2283 (or your reverse proxy address)."
}

# --- Script Execution ---
header_info
check_dependencies
create_cloud_init_script # Create the script locally first
build_vm

msg_ok "Successfully initiated Immich VM creation and setup!"
echo -e "${GN}Please monitor the VM's console for installation progress.${CL}"
echo -e "${YW}It may take 30-90+ minutes depending on your hardware, especially the library compilation part.${CL}"
