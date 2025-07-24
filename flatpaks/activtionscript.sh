system.activationScripts.flatpak-maintenance = {
  text = ''
    echo -e "\e[32m[Flatpak Maintenance] Starting...\e[0m"

    ${pkgs.bash}/bin/bash <<'EOF'
    export PATH=/run/current-system/sw/bin:$PATH
    icon="/etc/nixos/flatpaks/LinuxTweak.png"
    logdir="/var/log/flatpak-maintenance"
    mkdir -p "$logdir" || exit 1
    chmod 755 "$logdir"
    DISPLAY=:0
    DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/1000/bus
    XDG_RUNTIME_DIR=/run/user/1000
    real_user=${username}

    log() {
        printf "\e[34m[INFO] %s\e[0m\n" "$1"
    }

    notify() {
        su -l "$real_user" -c "DISPLAY=:0 DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/1000/bus notify-send '$1' '$2' --app-name='$3' -i '$icon' -u NORMAL"
    }


    sleep 2

    log "🌐 Checking for unused flatpaks..."
    notify "" "🌐 ☀️ Checking for flatpak cruft" "🔧  Flatpak Maintenance"
    flatpak --system uninstall --unused -y --noninteractive | tee "$logdir/flatpak-unused.log"

    sleep 2

    log "📡 Running flatpak system update..."
    notify "" "📡  Checking for flatpak UPDATES" "📡  Flatpak Updater"
    flatpak update -y --noninteractive --system | tee "$logdir/flatpak-update.log"

    sleep 2

    log "💻 Running flatpak system repair..."
    notify "" "💻  Checking and repairing Flatpaks" "🔧  Flatpak Repair Service"
    flatpak repair --system | tee "$logdir/flatpak-repair.log"

    sleep 2

    log "✅ All Flatpak maintenance tasks completed."
    notify "Flatpaks checked, fixed and updated" "✅  Your computer is ready!" "💻  Flatpak Update Service"
    EOF
  '';
};