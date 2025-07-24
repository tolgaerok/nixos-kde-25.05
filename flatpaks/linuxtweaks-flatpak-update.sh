#!/run/current-system/sw/bin/bash
export PATH=/run/current-system/sw/bin:$PATH

icon="/etc/nixos/flatpaks/LinuxTweak.png"

log() {
    printf "\e[34m[INFO] %s\e[0m\n" "$1"
}

notify() {
    /run/current-system/sw/bin/notify-send "$1" "$2" --app-name="$3" -i "$icon" -u NORMAL
}

sleep 5
log "✅ All Flatpak maintenance tasks completed."
notify "I love pussy" "✅  My cock is pussy ready!" "💻  COCK Update Service"
