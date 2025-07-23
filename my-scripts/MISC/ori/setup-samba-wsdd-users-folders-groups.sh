#!/bin/bash

# Tolga Erok - Fedora 39 KDE Samba + WSDD Tweaker
# Updated: 08/05/2025

set -euo pipefail

# ------------------------------------
# Colours
# ------------------------------------
RED='\e[1;31m'
GREEN='\e[1;32m'
YELLOW='\e[1;33m'
BLUE='\e[1;34m'
CYAN='\e[1;34m'
NC='\e[0m'

clear

if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}Please run this script as root or with sudo.${NC}"
    exit 1
fi

# ------------------------------------
# Create sambashare group if needed
# ------------------------------------
getent group sambashare >/dev/null || groupadd sambashare

read -rp "Username for this script: " user
export user

# ------------------------------------
# Add Charm repo and install gum
# ------------------------------------
cat <<EOF > /etc/yum.repos.d/charm.repo
[charm]
name=Charm
baseurl=https://repo.charm.sh/yum/
enabled=1
gpgcheck=1
gpgkey=https://repo.charm.sh/yum/gpg.key
EOF

dnf install -y gum

# ------------------------------------
# Functions
# ------------------------------------
display_message() {
    clear
    echo -e "\n                  ${CYAN}Tolga's SAMBA & WSDD setup script${NC}\n"
    echo -e "${BLUE}|--------------------${YELLOW} Currently configuring:${BLUE}-------------------|"
    echo -e "|${YELLOW}==>${NC}  $1"
    echo -e "${BLUE}|--------------------------------------------------------------|${NC}"
    gum spin --spinner dot --title "Stand-by..." -- sleep 1
}

check_service_status() {
    local service="$1"
    local label="${2:-$service}"  # optional custom label

    if [[ "$service" == "wsdd-sleep.service" ]]; then
        if systemctl is-enabled --quiet "$service"; then
            echo -e "${GREEN}    ✔ ${NC} ${YELLOW}${label} is ${NC}${GREEN}enabled (oneshot service)${NC}"
        else
            echo -e "${RED}✖ ${label} is not enabled${NC}"
        fi
    else
        if systemctl is-active --quiet "$service"; then
            echo -e "${GREEN}    ✔ ${NC} ${YELLOW}${label} is ${NC}${GREEN}running${NC}"
        else
            echo -e "${RED}✖ ${label} failed to start${NC}"
        fi
    fi
}

# ------------------------------------
# List of packages needed
# ------------------------------------
packages=(
  avahi
  bash-completion
  busybox
  ca-certificates
  cifs-utils
  crontabs
  curl
  dnf-plugins-core
  dnf-utils
  duf
  gnupg2
  iptables-nft
  iptables-services
  nano
  nftables
  policycoreutils-python-utils
  samba
  samba-client
  samba-common
  samba-usershares
  screen
  ufw
  unzip
  vim-enhanced
  wget2
  wsdd
  zip
)

# ------------------------------------
# Install base packages
# ------------------------------------
display_message "Installing core networking and system packages"

missing=()

# ------------------------------------
# Check each package
# ------------------------------------
for pkg in "${packages[@]}"; do
  echo -en "${YELLOW}Checking for package: ${NC}$pkg... "

  # Use rpm to check if the package is installed
  if rpm -q "$pkg" &>/dev/null; then
    echo -e "${GREEN}✔ Installed${NC}"
  else
    echo -e "${RED}✖ Not installed${NC}"
    missing+=("$pkg")
  fi
done

# ------------------------------------
# Now install missing packages
# ------------------------------------
if [ ${#missing[@]} -gt 0 ]; then
  echo -e "\nInstalling missing packages: ${missing[@]}"
  dnf install -y "${missing[@]}" || { echo -e "${RED}Failed to install some packages${NC}"; exit 1; }
else
  echo -e "${GREEN}\nAll packages are already installed.\n${NC}"
fi

sleep 2

# ------------------------------------
# Recheck
# ------------------------------------
display_message "Rechecking core networking and system packages"
for pkg in "${packages[@]}"; do
  echo -en "${YELLOW}Checking for package: ${NC}$pkg... "

  # Use rpm to check if the package is installed
  if rpm -q "$pkg" &>/dev/null; then
    echo -e "${GREEN}✔ Installed${NC}"
  else
    echo -e "${RED}✖ Not installed${NC}"
    missing+=("$pkg")
  fi
done

sleep 2

# ------------------------------------
# Enable services
# ------------------------------------
display_message "Enabling and starting SMB/NMB services"
systemctl enable --now smb.service nmb.service

# ------------------------------------
# Set SELinux booleans
# ------------------------------------
display_message "Setting SELinux Samba permissions"
setsebool -P samba_enable_home_dirs on
setsebool -P samba_export_all_rw on
setsebool -P smbd_anon_write on

# ------------------------------------
# User and group setup
# ------------------------------------
display_message "Creating Samba user and group"
read -rp "Enter the USERNAME to add to Samba: " sambausername
read -rp "Enter the GROUP name to add the user to: " sambagroup
groupadd -f "$sambagroup"

if ! id "$sambausername" &>/dev/null; then
    useradd -m "$sambausername"
fi

smbpasswd -a "$sambausername"
smbpasswd -e "$sambausername"
usermod -aG "$sambagroup" "$sambausername"

# ------------------------------------
# Create hostname-based shared folder
# ------------------------------------
shared_folder="/home/$(hostname)_Share"
display_message "Creating shared folder at $shared_folder"

# ------------------------------------
# Ensure that $sambagroup and $sambausername are set
# ------------------------------------
if [ -z "$sambagroup" ]; then
    echo "Error: sambagroup is not set!"
    exit 1
fi

if [ -z "$sambausername" ]; then
    echo "Error: sambausername is not set!"
    exit 1
fi

# ------------------------------------
# Create the shared folder
# ------------------------------------
mkdir -p "$shared_folder"
chgrp "$sambagroup" "$shared_folder"
chmod 1770 "$shared_folder"
chmod g+w "$shared_folder"

# ------------------------------------
# Set the appropriate SELinux context for Samba share
# ------------------------------------
semanage fcontext -a -t samba_share_t "${shared_folder}(/.*)?"
restorecon -Rv "$shared_folder"

# ------------------------------------
# Usershares setup
# ------------------------------------
mkdir -p /var/lib/samba/usershares
chown root:sambashare /var/lib/samba/usershares
chmod 1770 /var/lib/samba/usershares
chmod g+w /var/lib/samba/usershares

# ------------------------------------
# Ensure correct SELinux context for the usershares folder
# ------------------------------------
restorecon -Rv /var/lib/samba/usershares

# ------------------------------------
# Add the user to the sambashare group
# ------------------------------------
gpasswd -a "$sambausername" sambashare

# ------------------------------------
# Configure smb.conf for usershare if not already
# ------------------------------------
smb_conf="/etc/samba/smb.conf"
if [ ! -f "$smb_conf" ]; then
    cp /usr/share/samba/smb.conf.default "$smb_conf"
fi

if ! grep -q "usershare path" "$smb_conf"; then
    sed -i '/^\[global\]/a \
    usershare path = /var/lib/samba/usershares\
    usershare max shares = 100\
    usershare allow guests = no\
    usershare owner only = yes' "$smb_conf"
fi

# ------------------------------------
# Custom shared directory
# ------------------------------------
share_dir="/srv/samba/share"
mkdir -p "$share_dir"
chown "$sambausername:$sambausername" "$share_dir"
chmod 1770 "$share_dir"
chgrp sambashare "$share_dir"
semanage fcontext -a -t samba_share_t "${share_dir}(/.*)?"
restorecon -Rv "$share_dir"

# ------------------------------------
# Add share to smb.conf if not present
# ------------------------------------
if ! grep -q "^\[My-Share\]" "$smb_conf"; then
    tee -a "$smb_conf" > /dev/null <<EOF

# - SIMPLE SHARE ---------------------------------- #
[My-Share]
   path = $share_dir
   browseable = yes
   writable = yes
   valid users = $sambausername
   create mask = 0660
   directory mask = 0770
   guest ok = no
EOF
fi

# ------------------------------------
# Restart services
# ------------------------------------
display_message "Restarting SMB/NMB services"
systemctl restart smb.service nmb.service

# ------------------------------------
# SSH setup
# ------------------------------------
display_message "Setting up SSH service"
systemctl enable --now sshd

# ------------------------------------
# WSDD firewall rules and setup
# ------------------------------------
display_message "Setting up WSDD and configuring firewall"
firewall-cmd --add-rich-rule='rule family="ipv4" source address="239.255.255.250" port protocol="udp" port="3702" accept' --permanent
firewall-cmd --add-rich-rule='rule family="ipv6" source address="ff02::c" port protocol="udp" port="3702" accept' --permanent
firewall-cmd --add-rich-rule='rule family="ipv4" port protocol="udp" port="3702" accept'
firewall-cmd --add-rich-rule='rule family="ipv6" port protocol="udp" port="3702" accept'
firewall-cmd --add-rich-rule='rule family="ipv4" port protocol="tcp" port="5357" accept'
firewall-cmd --add-rich-rule='rule family="ipv6" port protocol="tcp" port="5357" accept'
firewall-cmd --add-port=3702/udp --permanent
firewall-cmd --add-port=5357/tcp --permanent

# ------------------------------------
# Configure firewall for Samba
# ------------------------------------
display_message "Configuring Firewall for Samba"

# ------------------------------------
# Allow Samba service through the firewall
# ------------------------------------
firewall-cmd --add-service=samba --permanent
firewall-cmd --reload

# ------------------------------------
# Make runtime changes permanent
# ------------------------------------
firewall-cmd --runtime-to-permanent

# ------------------------------------
# Old NixOS TCP & UDP port settings
# ------------------------------------
allowedTCPPorts=(
    21    # FTP
    53    # DNS
    80    # HTTP
    443   # HTTPS
    143   # IMAP
    389   # LDAP
    139   # Samba
    445   # Samba
    25    # SMTP
    22    # SSH
    5432  # PostgreSQL
    3306  # MySQL/MariaDB
    3307  # MySQL/MariaDB
    111   # NFS
    2049  # NFS
    2375  # Docker
    22000 # Syncthing
    9091  # Transmission
    60450 # Transmission
    80    # Gnomecast server
    8010  # Gnomecast server
    8888  # Gnomecast server
    5357  # wsdd: Samba
    1714  # Open KDE Connect
    1764  # Open KDE Connect
    8200  # Teamviewer
)

allowedUDPPorts=(
    53    # DNS
    137   # NetBIOS Name Service
    138   # NetBIOS Datagram Service
    3702  # wsdd: Samba
    5353  # Device discovery
    21027 # Syncthing
    22000 # Syncthing
    8200  # Teamviewer
    1714  # Open KDE Connect
    1764  # Open KDE Connect
)

for port in "${allowedTCPPorts[@]}"; do
    echo "Setting up TCPorts: $port"
    firewall-cmd --permanent --add-port=$port/tcp
done

for port in "${allowedUDPPorts[@]}"; do
    echo "Setting up UDPPorts: $port"
    firewall-cmd --permanent --add-port=$port/udp
done

echo "[${GREEN}✔${NC}] Adding NetBIOS name resolution traffic on UDP port 137"
iptables -t raw -A OUTPUT -p udp -m udp --dport 137 -j CT --helper netbios-ns

# ------------------------------------
# Reload the firewall for changes to take effect
# ------------------------------------
firewall-cmd --reload
gum spin --spinner dot --title "Reloading firewall" -- sleep 1.5

display_message "[${GREEN}✔${NC}] Firewall rules applied successfully, reloading system services."
gum spin --spinner dot --title "Reloading all services" -- sleep 1.5

# ------------------------------------
# Create wsdd systemd unit file
# ------------------------------------
display_message "Creating custom WSDD service"

# ------------------------------------
# create wsdd user and group
# ------------------------------------
if ! id -u wsdd &>/dev/null; then
    sudo useradd -r -s /usr/sbin/nologin wsdd
fi

if ! getent group wsdd &>/dev/null; then
    sudo groupadd wsdd
fi

# ------------------------------------
# Adding the user to the group
# ------------------------------------
sudo usermod -aG wsdd wsdd
interface=$(ip -o link show | awk -F': ' '!/lo/ {print $2; exit}')

cat <<EOF > /etc/systemd/system/wsdd.service
[Unit]
Description=Tolga Custom (WSDD) - Web Services Dynamic Discovery host daemon
Documentation=man:wsdd(8)
After=network-online.target
Wants=network-online.target
BindsTo=smb.service

[Service]
Type=simple
ExecStart=/bin/bash -c 'interface=\$(ip link show | awk -F: "/^[2-9]:|^[1-9][0-9]: / && /UP/ && !/LOOPBACK|NO-CARRIER/ {gsub(/^[[:space:]]+|[[:space:]]+$/, \\"\\" ,\\\$2); print \\\$2; exit}"); [ -n "\$interface" ] && exec /usr/bin/wsdd --interface "\$interface" || exit 1'
ExecStop=/bin/kill -SIGTERM \$MAINPID

User=wsdd
Group=wsdd
RuntimeDirectory=wsdd
AmbientCapabilities=CAP_SYS_CHROOT CAP_NET_ADMIN
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

# ------------------------------------
# SystemD to auto-restart wsdd after suspend using systemd
# ------------------------------------
SERVICE_PATH="/etc/systemd/system/wsdd-sleep.service"
display_message "Creating systemd service to restart wsdd after suspend..."
sleep 1

cat <<EOF | sudo tee "$SERVICE_PATH" > /dev/null
[Unit]
Description=Restart WSDD after suspend/resume
After=sleep.target

[Service]
Type=oneshot
ExecStart=/usr/bin/systemctl restart wsdd.service

[Install]
WantedBy=sleep.target
EOF

display_message "Done! wsdd will now restart after suspend/resume."
sleep 1

# ------------------------------------
# SERVICE SETUP AND VERIFICATION
# ------------------------------------
display_message "Enabling and starting Samba & WSDD services"
sleep 1

# ------------------------------------
# Enable and start Samba (smb/nmb) and WSDD services
# ------------------------------------
systemctl daemon-reload
systemctl enable --now smb.service nmb.service wsdd.service wsdd-sleep.service

# ------------------------------------
# Restart to apply any changes
# ------------------------------------
systemctl restart smb.service nmb.service wsdd.service wsdd-sleep.service

# ------------------------------------
# Reload systemd for any unit overrides
# ------------------------------------
systemctl daemon-reexec
systemctl daemon-reload

# ------------------------------------
# Apply kernel and device rule changes
# ------------------------------------
udevadm control --reload-rules
udevadm trigger
sysctl --system
sysctl -p

# ------------------------------------
# Final verification and status output
# ------------------------------------
display_message "All done! Samba & WSDD setup is complete."
sleep 2

echo -e "${BLUE}\nService Status Check:${NC}"
check_service_status smb.service "SMB service"
check_service_status nmb.service "NMB service"
check_service_status wsdd.service "WSDD service"
check_service_status wsdd-sleep.service "WSDD-Sleep service"
echo " "

# ------------------------------------
# Recheck WSDD
# ------------------------------------
systemctl restart wsdd.service wsdd-sleep.service
systemctl status wsdd.service --no-pager
systemctl status wsdd-sleep.service --no-pager

sleep 1
exit 0

