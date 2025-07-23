#!/usr/bin/env bash
set -euo pipefail

USB_DEV="/dev/sdc"     # Your USB device
MAIN_DEV="/dev/sda"
MOUNT_POINT="/mnt/temu"
FSTAB="/etc/fstab"
FIO_BIN="/usr/local/bin/fio"

echo "Reloading systemd and fstab..."
sudo systemctl daemon-reload || true
sudo systemctl reset-failed || true
sudo umount -l /mnt/DADS-W11 || true
sudo mount "$MOUNT_POINT" || true

lsblk -f
blkid /dev/$USB_DEV
file -s /dev/$USB_DEV

echo "Running ntfsfix on $USB_DEV..."
sudo ntfsfix "$USB_DEV"

PKG_MGR="dnf"
if command -v dnf5 &>/dev/null; then
  PKG_MGR="dnf5"
fi

echo "Using package manager: $PKG_MGR"

if ! command -v fio &>/dev/null || ! [[ -x "$FIO_BIN" ]]; then
  echo "Installing required build tools and libraries..."
  sudo $PKG_MGR install -y libaio libaio-devel wget make gcc automake autoconf libtool pkgconf ntfs-3g
  cd /tmp
  wget -c https://github.com/axboe/fio/archive/refs/tags/fio-3.37.tar.gz -O fio-3.37.tar.gz
  rm -rf fio-3.37
  tar -xzf fio-3.37.tar.gz
  cd fio-3.37
  ./configure
  make
  sudo make install
else
  echo "fio already installed."
fi

USB_PART="${USB_DEV}1"
UUID=$(blkid -s UUID -o value "$USB_PART" || true)
if [[ -z "$UUID" ]]; then
  echo "Could not find UUID for $USB_PART"
  exit 1
fi
echo "UUID for $USB_PART: $UUID"

sudo mkdir -p "$MOUNT_POINT"

# Clean previous entries for this mountpoint in fstab
sudo sed -i "\|$MOUNT_POINT|d" "$FSTAB"

# Try ntfs3 first
FSTAB_LINE="UUID=$UUID $MOUNT_POINT ntfs3 rw,async,uid=1000,gid=1000,umask=0022,noatime 0 0"
echo "$FSTAB_LINE" | sudo tee -a "$FSTAB"
sudo systemctl daemon-reload

if mountpoint -q "$MOUNT_POINT"; then
  echo "Unmounting $MOUNT_POINT"
  sudo umount "$MOUNT_POINT"
fi

echo "Trying to mount $MOUNT_POINT with ntfs3..."
if sudo mount "$MOUNT_POINT"; then
  echo "Mounted successfully with ntfs3."
else
  echo "ntfs3 mount failed, falling back to ntfs-3g..."
  sudo sed -i "\|$MOUNT_POINT|d" "$FSTAB"
  FSTAB_LINE="UUID=$UUID $MOUNT_POINT ntfs-3g rw,async,uid=1000,gid=1000,umask=0022,noatime 0 0"
  echo "$FSTAB_LINE" | sudo tee -a "$FSTAB"
  sudo systemctl daemon-reload
  echo "Mounting $MOUNT_POINT with ntfs-3g..."
  if ! sudo mount "$MOUNT_POINT"; then
    echo "ntfs-3g mount also failed. Skipping speed tests and IO scheduler."
    exit 1
  fi
fi

echo "Setting IO scheduler for $MAIN_DEV to mq-deadline"
echo mq-deadline | sudo tee /sys/block/$(basename "$MAIN_DEV")/queue/scheduler > /dev/null

echo "Setting IO scheduler for $USB_DEV to none"
echo none | sudo tee /sys/block/$(basename "$USB_DEV")/queue/scheduler > /dev/null

TEST_FILE="$MOUNT_POINT/fio-testfile"

echo "Running write test (1G)..."
sudo "$FIO_BIN" --name=usbwrite --filename="$TEST_FILE" --rw=write --bs=4M --size=1G --ioengine=libaio --iodepth=16 --direct=1 --numjobs=1 --runtime=30 --group_reporting

echo "Running read test (1G)..."
sudo "$FIO_BIN" --name=usbread --filename="$TEST_FILE" --rw=read --bs=4M --size=1G --ioengine=libaio --iodepth=16 --direct=1 --numjobs=1 --runtime=30 --group_reporting

sudo rm -f "$TEST_FILE"

echo "Done."
