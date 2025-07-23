#!/bin/bash
# tolga erok
# https://www.opencode.net/tamascsabi/varied-icon-theme

ICON_SRC_DIR="$(pwd)"
ICON_DST_DIR="/usr/share/icons"

# Check for root
if [[ $EUID -ne 0 ]]; then
  echo "Run this script as root: sudo $0"
  exit 1
fi

echo "🔍 Searching for *.tar.xz icon themes in: $ICON_SRC_DIR"

for icon_tar in "$ICON_SRC_DIR"/Varied-*.tar.xz; do
  [[ -f "$icon_tar" ]] || continue

  folder_name=$(basename "$icon_tar" .tar.xz)

  echo "📦 Installing: $folder_name"
  tar -xf "$icon_tar" -C "$ICON_DST_DIR"

  # update icon cache
  echo "🔄 Updating icon cache for: $folder_name"
  gtk-update-icon-cache -f "$ICON_DST_DIR/$folder_name"
done

echo "✅ All Varied icon themes installed and caches updated."

