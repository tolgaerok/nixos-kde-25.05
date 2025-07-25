#!/run/current-system/sw/bin/bash
export PATH=/run/current-system/sw/bin:$PATH

DISPLAY=:0
DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/1000/bus
XDG_RUNTIME_DIR=/run/user/1000
real_user=${username}
sleep 10

icon="/etc/nixos/flatpaks/LinuxTweak.png"

log() {
    printf "\e[34m[INFO] %s\e[0m\n" "$1"
}

#notify() {
#    /run/current-system/sw/bin/notify-send "$1" "$2" --app-name="$3" -i "$icon" -u NORMAL
#}

notify() {
    /run/current-system/sw/bin/notify-send \
      "$1" "$2" \
      --app-name="$3" \
      --icon="$icon" \
      --urgency=normal \
      --expire-time=5000
}

sleep 5

log "🌐 Checking for unused flatpaks..."
notify "" "🌐 ☀️ Checking for flatpak cruft" "🔧  Flatpak Maintenance"
flatpak --system uninstall --unused -y --noninteractive | tee /tmp/flatpak-unused.log

sleep 3

log "📡 Running flatpak system update..."
notify "" "📡  Checking for flatpak UPDATES" "📡  Flatpak Updater"
flatpak update -y --noninteractive --system | tee /tmp/flatpak-update.log

sleep 3

#log "💻 Running flatpak system repair..."
#notify "" "💻  Checking and repairing Flatpaks" "🔧  Flatpak Repair Service"
#flatpak repair --system | tee /tmp/flatpak-repair.log

sleep 3

log "✅ All Flatpak maintenance tasks completed."
notify "Flatpaks checked, fixed and updated" "✅  Your computer is ready!" "💻  Flatpak Update Service"
