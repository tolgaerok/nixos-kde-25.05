#!/bin/bash
# Tolga Erok
# 20/5/2025

# ────────────────────────────────────────────────
# LinuxTweaks Flatpak Auto-Updater
# ────────────────────────────────────────────────

# Colors
NC='\033[0m'
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[1;34m'
WHITE='\033[1;37m'

SERVICE=linuxtweaks-flatpak.service
TIMER=linuxtweaks-flatpak.timer
USER_DIR="$HOME/.config/systemd/user"
icon_URL="https://raw.githubusercontent.com/tolgaerok/linuxtweaks/main/MY_PYTHON_APP/images/LinuxTweak.png"
icon_dir="/usr/local/bin/LinuxTweaks/images"
icon_path="$icon_dir/LinuxTweak.png"
unit_dir="$USER_DIR"

# NEW: Sleep hook script and service names
SLEEP_HOOK_SCRIPT="sleep-resume-restart.sh"
SLEEP_HOOK_SERVICE="sleep-resume-restart.service"

# ---- Flatpak Theming Tweaks - LinuxTweaks (Tolga)  ----
flatpak override --user --env=USE_POINTER_VIEWPORT=1
flatpak override --user --filesystem=xdg-config/gtk-4.0:ro
flatpak override --user --unset-env=QT_QPA_PLATFORMTHEME
sudo timedatectl set-ntp true

install_units() {
    mkdir -p "$USER_DIR"
    mkdir -p "$icon_dir"

    echo -e "${GREEN}[+] Downloading icon...\n${NC}"
    tmp_icon="/tmp/LinuxTweak.png"
    wget -O "$tmp_icon" "$icon_URL"
    sudo mv "$tmp_icon" "$icon_path"
    sudo chmod 644 "$icon_path"
    sudo chown root:root "$icon_path"

    # Service unit
    cat >"$USER_DIR/$SERVICE" <<EOF
[Unit]
Description=LinuxTweaks Flatpak Automatic Update and Notification VER: 5.0
Documentation=man:flatpak(1)
Wants=network-online.target
After=network-online.target

[Service]
Type=oneshot
ExecCondition=/bin/bash -c '[[ "\$(busctl get-property org.freedesktop.NetworkManager /org/freedesktop/NetworkManager org.freedesktop.NetworkManager Metered | cut -d\" \" -f3)" =~ ^(2|4)$ ]] && exit 1 || exit 0'

ExecStart=/bin/bash -c '/usr/bin/notify-send "" "🌐  Checking for flatpak cruft" --app-name="🔧  Flatpak Maintenance" -i /usr/local/bin/LinuxTweaks/images/LinuxTweak.png -u NORMAL && /usr/bin/flatpak --system uninstall --unused -y --noninteractive && /usr/bin/flatpak --user uninstall --unused -y --noninteractive && sleep 5 && /usr/bin/notify-send "" "📡  Checking for flatpak UPDATES" --app-name="📡  Flatpak Updater" -i /usr/local/bin/LinuxTweaks/images/LinuxTweak.png -u NORMAL && /usr/bin/flatpak --system update -y --noninteractive && /usr/bin/flatpak --user update -y --noninteractive && sleep 5 && /usr/bin/notify-send "" "💻  Checking and repairing Flatpaks" --app-name="🔧  Flatpak Repair Service" -i /usr/local/bin/LinuxTweaks/images/LinuxTweak.png -u NORMAL && /usr/bin/flatpak --system repair && /usr/bin/flatpak --user repair && sleep 5 && /usr/bin/notify-send "Flatpaks checked, fixed and updated" "✅  Your computer is ready!" --app-name="💻  Flatpak Update Service" -i /usr/local/bin/LinuxTweaks/images/LinuxTweak.png -u NORMAL'

TimeoutStopFailureMode=abort
Environment=SYSTEMD_SLEEP_FREEZE_USER_SESSIONS=0

[Install]
WantedBy=default.target
EOF

    # Write timer unit with corrected Unit= and no duplicate [Timer]
    cat >"$USER_DIR/$TIMER" <<EOF
[Unit]
Description=Run LinuxTweaks Flatpak Update Script every 6 hours, after boot, suspend, and on activity VER: 5.0

[Timer]
OnBootSec=1min
OnUnitActiveSec=6h
OnResumeSec=1min
Unit=$SERVICE
Persistent=true

[Install]
WantedBy=default.target
EOF

    ### NEW: Create systemd sleep hook script to restart timer on resume
    cat >"$USER_DIR/$SLEEP_HOOK_SCRIPT" <<'EOF'
#!/bin/bash
case "$1" in
    pre) ;;
    post)
        systemctl --user restart linuxtweaks-flatpak.timer
        ;;
esac
EOF

    chmod +x "$USER_DIR/$SLEEP_HOOK_SCRIPT"

    ### NEW: Create systemd service that calls above script on suspend resume
    # cat >"$USER_DIR/$SLEEP_HOOK_SERVICE" <<EOF
    sudo tee /etc/systemd/system/sleep-resume-restart.service >/dev/null <<EOF
[Unit]
Description=Restart user Flatpak Updater Timer after resume
After=suspend.target hibernate.target sleep.target
PartOf=suspend.target

[Service]
Type=oneshot
ExecStart=/usr/local/bin/restart-flatpak-timers.sh
RemainAfterExit=true

[Install]
WantedBy=suspend.target hibernate.target sleep.target
EOF

    echo -e "\n${BLUE}📄 Reloading systemd daemon...${NC}"
    systemctl --user daemon-reexec
    systemctl --user daemon-reload

    echo -e "${GREEN}✅ Enabling and starting timer and service...${NC}"
    systemctl --user enable --now "$SERVICE"
    systemctl --user enable --now "$TIMER"
    # systemctl --user enable --now "$SLEEP_HOOK_SERVICE"
    systemctl enable --now sleep-resume-restart.service

    echo -e "${YELLOW}▶ Starting services manually now...${NC}"
    #systemctl --user start "$SERVICE"
    #systemctl --user start "$TIMER"

    echo -e "${GREEN}✅ Installation and activation complete.${NC}\n"
}

remove_units() {
    echo -e "\n${YELLOW}⛔ Stopping and disabling timer, service and sleep hook...${NC}"
    systemctl --user stop $TIMER $SERVICE $SLEEP_HOOK_SERVICE 2>/dev/null || true
    systemctl --user disable $TIMER $SERVICE $SLEEP_HOOK_SERVICE 2>/dev/null || true

    echo -e "${RED}🧹 Removing unit files and sleep hook script...${NC}"
    rm -f "$USER_DIR/$SERVICE" "$USER_DIR/$TIMER" "$USER_DIR/$SLEEP_HOOK_SCRIPT" "$USER_DIR/$SLEEP_HOOK_SERVICE"

    echo -e "${BLUE}📄 Reloading systemd daemon...${NC}"
    systemctl --user daemon-reload

    echo -e "${WHITE}🔁 Resetting failed service states...${NC}"
    systemctl --user reset-failed $SERVICE || true

    echo -e "${GREEN}✅ Removal complete.${NC}\n"
}

check_status() {
    echo -e "\n${BLUE}📋 Timer Status:${NC}"
    if systemctl --user is-active --quiet "$TIMER"; then
        echo -e "${GREEN}🟢 ACTIVE:${NC} $TIMER is running"
    else
        echo -e "${RED}🔴 INACTIVE or not found:${NC} $TIMER"
    fi

    echo -e "\n${BLUE}📋 Service Status:${NC}"

    if [[ ! -f "$USER_DIR/$SERVICE" ]]; then
        echo -e "${RED}🔴 NOT FOUND:${NC} $SERVICE"
    else
        SERVICE_STATE=$(systemctl --user show -p ActiveState --value "$SERVICE" 2>/dev/null)

        if [[ "$SERVICE_STATE" == "active" ]] || [[ "$SERVICE_STATE" == "activating" ]]; then
            echo "🟢 ACTIVE: $SERVICE is running"
        elif [[ "$SERVICE_STATE" == "inactive" ]]; then
            echo "🟢 COMPLETED: $SERVICE ran and exited successfully"
        else
            echo "🟡 NOT FOUND or failed: $SERVICE"
        fi

        # show detailed info
        LAST_RUN_INFO=$(systemctl --user show -p ExecMainStatus,ExecMainExitTimestamp "$SERVICE" 2>/dev/null)
        echo -e "\n📆 Last Run Info:\n$LAST_RUN_INFO"
    fi

    echo
}

# ────────────────────────────────────────────────
# Main Menu
# ────────────────────────────────────────────────

while true; do
    echo -e "\n${BLUE}📦 LinuxTweaks Flatpak Auto-Updater${NC}\n"
    echo -e "${BLUE}🔹 1)${NC} 📥 Install & Enable"
    echo -e "${BLUE}🔹 2)${NC} ❌ Remove"
    echo -e "${BLUE}🔹 3)${NC} 📊 Status"
    echo -e "${BLUE}🔹 0)${NC} 🚪 Exit"
    echo -n -e "${YELLOW}Select: ${NC}"
    read -r choice
    case $choice in
    1) install_units ;;
    2) remove_units ;;
    3) check_status ;;
    0) exit 0 ;;
    *) echo -e "${RED}Invalid choice. Try again.${NC}" ;;
    esac
done
