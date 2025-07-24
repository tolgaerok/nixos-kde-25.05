#!/run/current-system/sw/bin/bash
export PATH=/run/current-system/sw/bin:$PATH
sleep 10

ICON="/etc/nixos/flatpaks/LinuxTweak.png"
TITLE="🔧 Flatpak Maintenance"
LOGFILE="$(mktemp)"
: > "$LOGFILE"

cleanup() {
    rm -f "$LOGFILE"
}
trap cleanup EXIT

tail -F "$LOGFILE" | yad --width=800 --height=500 --center \
--window-icon="$ICON" --image="$ICON" \
--title="$TITLE" \
--text="Running Flatpak Maintenance tasks..." \
--button=gtk-close:0 \
--text-info --fontname="monospace" \
--margins=10 &

YAD_PID=$!

log() {
    echo -e "\n$1" >> "$LOGFILE"
}

run_step() {
    log "🔷 $1"
    stdbuf -oL bash -c "$2" >> "$LOGFILE" 2>&1
    log "✅ Done: $1"
    sleep 2
}

sleep 2
log "🚀 Starting Flatpak maintenance..."
run_step "🌐 Removing unused Flatpaks..." "flatpak --system uninstall --unused -y --noninteractive"
run_step "📡 Updating system Flatpaks..." "flatpak update -y --noninteractive --system"
run_step "🧰 Repairing Flatpaks..." "flatpak repair --system"
log "🎉 All maintenance tasks complete."
wait $YAD_PID
