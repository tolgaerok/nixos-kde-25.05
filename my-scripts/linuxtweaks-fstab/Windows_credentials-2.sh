#!/bin/bash

# Variables — change as needed
CRED_FILE="/etc/samba/Windows_credentials2.conf"
MOUNT_POINT="/mnt/DADS-W11"
SHARE="//192.168.0.20/tolga"
USERNAME="Tuncay"
PASSWORD="Tarkan23"
UID=1000
GID=1000

# Create credentials file with username and password
echo -e "username=$USERNAME\npassword=$PASSWORD" | sudo tee "$CRED_FILE" > /dev/null

# Secure the credentials file permissions
sudo chmod 600 "$CRED_FILE"
sudo chown root:root "$CRED_FILE"

# Create mount point if missing
sudo mkdir -p "$MOUNT_POINT"

# Backup existing fstab
sudo cp /etc/fstab /etc/fstab.bak

# Prepare fstab entry (escape slashes for sed)
FSTAB_ENTRY="$SHARE  $MOUNT_POINT  cifs  credentials=$CRED_FILE,vers=3.0,uid=$UID,gid=$GID,file_mode=0777,dir_mode=0777,iocharset=utf8,cache=loose,noserverino,actimeo=60,nofail,x-systemd.automount,_netdev  0 0"

# Escape slashes in $SHARE for sed pattern
ESCAPED_SHARE=$(echo "$SHARE" | sed 's/[\/&]/\\&/g')

# Check if entry exists
if grep -qsF "$SHARE" /etc/fstab; then
  # Replace existing entry
  sudo sed -i.bak "/$ESCAPED_SHARE/c\\
$FSTAB_ENTRY
" /etc/fstab
  echo "Updated existing mount entry in /etc/fstab"
else
  # Append new entry
  echo "$FSTAB_ENTRY" | sudo tee -a /etc/fstab
  echo "Added mount entry to /etc/fstab"
fi

echo "Done. You can now mount with: sudo mount $MOUNT_POINT"

