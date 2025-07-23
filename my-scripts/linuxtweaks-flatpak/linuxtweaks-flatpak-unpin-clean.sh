#!/bin/bash

PINNED_DIR="/var/lib/flatpak/pinned"
TMPFILE=$(mktemp)

if [ ! -d "$PINNED_DIR" ]; then
    yad --info --title="Flatpak Unpin" --text="No pinned Flatpak runtimes found."
    exit 0
fi

# Gather pinned runtimes files
mapfile -t pinned_files < <(sudo find "$PINNED_DIR" -type f)

if [ ${#pinned_files[@]} -eq 0 ]; then
    yad --info --title="Flatpak Unpin" --text="No pinned Flatpak runtimes found."
    exit 0
fi

# Prepare YAD checklist input: each line is "<tag> <status> <label>"
# Use basename as tag and label
> "$TMPFILE"
for file in "${pinned_files[@]}"; do
    name=$(basename "$file")
    echo -e "$name\tFALSE\t$file" >> "$TMPFILE"
done

# Show checklist dialog for pinned runtimes
selected=$(yad --width=600 --height=400 --list --checklist \
    --title="Flatpak Runtime Unpin" \
    --text="Select runtimes to unpin:" \
    --column="Unpin" --column="Name" --column="Path" \
    --separator=":" \
    --file="$TMPFILE")

if [ -z "$selected" ]; then
    yad --info --title="Flatpak Unpin" --text="No runtimes selected. Exiting."
    rm -f "$TMPFILE"
    exit 0
fi

# Confirm unpin
if ! yad --question --title="Confirm Unpin" --text="Are you sure you want to unpin the selected runtimes?"; then
    yad --info --title="Flatpak Unpin" --text="Cancelled by user."
    rm -f "$TMPFILE"
    exit 0
fi

# Unpin the selected runtimes
IFS=":" read -r -a to_unpin <<< "$selected"
for name in "${to_unpin[@]}"; do
    for file in "${pinned_files[@]}"; do
        if [[ $(basename "$file") == "$name" ]]; then
            sudo rm -v "$file"
        fi
    done
done

rm -f "$TMPFILE"

# Run flatpak uninstall --unused
yad --info --title="Flatpak Cleanup" --text="Running 'flatpak uninstall --unused' to clean up..."

sudo flatpak uninstall --unused --noninteractive | yad --progress --title="Cleaning Flatpak" --pulsate --auto-close --no-buttons

yad --info --title="Flatpak Cleanup" --text="Cleanup completed!"

exit 0
