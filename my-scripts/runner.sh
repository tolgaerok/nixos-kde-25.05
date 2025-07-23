#!/run/current-system/sw/bin/bash
SCRIPT_PATH="/etc/nixos/my-scripts/functions.sh"

if [[ -f "$SCRIPT_PATH" ]]; then
    source "$SCRIPT_PATH"
else
    echo "⚠️  Warning: Cannot find $SCRIPT_PATH. Skipping."
fi
