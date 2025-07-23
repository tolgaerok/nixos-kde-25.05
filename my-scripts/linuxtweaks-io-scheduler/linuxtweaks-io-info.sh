#!/usr/bin/env bash
# chmod +x disk-io-check.sh
# ./disk-io-check.sh sda1

DEVICE="${1:-sda1}"
BLOCK_DEV="/dev/${DEVICE}"
BASE_DEV="$(echo "$DEVICE" | sed 's/[0-9]*$//')"

echo "🔍 Disk I/O Status for: $BLOCK_DEV"
echo "-----------------------------------------"

# Install sysstat if not present (for iostat)
if ! command -v iostat &>/dev/null; then
    echo "⚙️  Installing 'sysstat' (required for iostat)..."
    if command -v dnf &>/dev/null; then
        sudo dnf install -y sysstat
    elif command -v pacman &>/dev/null; then
        sudo pacman -Sy --noconfirm sysstat
    else
        echo "❌ Unsupported package manager. Install 'sysstat' manually."
        exit 1
    fi
fi

# 1. Scheduler
echo -e "\n📦 I/O Scheduler for /dev/${BASE_DEV}:"
cat /sys/block/${BASE_DEV}/queue/scheduler

# 2. Queue Depth
echo -e "\n🌀 Queue Requests:"
cat /sys/block/${BASE_DEV}/queue/nr_requests

# 3. SSD or HDD?
echo -e "\n⚙️  Rotational (0=SSD, 1=HDD):"
cat /sys/block/${BASE_DEV}/queue/rotational

# 4. Filesystem Info
echo -e "\n🗂️  Filesystem Mount Info:"
df -hT | grep "${DEVICE}"

# 5. Live I/O Stats (brief snapshot)
echo -e "\n📊 Live I/O Activity Snapshot (1s):"
iostat -xz 1 2 | grep "${BASE_DEV}"

# 6. Deep Device Metadata
echo -e "\n🧬 udevadm Info:"
udevadm info --query=all --name="$BLOCK_DEV" | grep -E 'DEVNAME=|ID_MODEL=|ID_SERIAL=|ID_FS_TYPE=|ID_FS_USAGE=|ID_PART_ENTRY_NAME=|ID_PATH=|ID_ATA_FEATURE_SET_SMART|ID_ATA_ROTATION_RATE_RPM'

echo -e "\n✅ Done."
