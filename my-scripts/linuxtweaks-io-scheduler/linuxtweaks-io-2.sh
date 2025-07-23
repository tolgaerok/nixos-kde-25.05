#!/usr/bin/env bash
set -euo pipefail

GRUB_FILE="/etc/default/grub"

# Show scheduler choices
SCHEDULER=$(yad \
    --title="LinuxTweaks - I/O Scheduler Selector" \
    --width=400 --height=200 \
    --center \
    --list \
    --radiolist \
    --column="Select" --column="Scheduler" TRUE mq-deadline FALSE kyber FALSE bfq FALSE none \
    --text="Select your preferred I/O scheduler for the kernel." \
    --button=gtk-ok:0 --button=gtk-cancel:1)

[ $? -ne 0 ] && echo "Cancelled by user." && exit 1

NEW_SCHED=$(echo "$SCHEDULER" | awk '{print $2}')
[ -z "$NEW_SCHED" ] && echo "No scheduler selected." && exit 1

# Backup
cp -f "$GRUB_FILE" "$GRUB_FILE.bak.$(date +%s)"
echo "Backed up $GRUB_FILE"

# Clean out any existing elevator= from GRUB_CMDLINE_LINUX
LINE=$(grep '^GRUB_CMDLINE_LINUX=' "$GRUB_FILE")
CLEANED=$(echo "$LINE" | sed -E 's/elevator=[^" ]+//g' | sed -E 's/\s+/ /g')

# Add new elevator
UPDATED=$(echo "$CLEANED" | sed -E "s|\"$| elevator=$NEW_SCHED\"|")

# Apply to grub file
sed -i "s|^GRUB_CMDLINE_LINUX=.*|$UPDATED|" "$GRUB_FILE"
echo "Updated GRUB_CMDLINE_LINUX to: $UPDATED"

# Regenerate GRUB config
grub2-mkconfig -o /boot/grub2/grub.cfg
echo "Regenerated GRUB config."

# Done
yad --info --center --width=300 --text="I/O scheduler set to: $NEW_SCHED\nReboot required to apply changes."
