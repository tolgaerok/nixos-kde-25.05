#!/bin/bash
# Tolga Erok
# 21/5/2025

# ────────────────────────────────────────────────
# LinuxTweaks custom my-preload script setup
# ────────────────────────────────────────────────

clear

# Variables
LOCAL_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/flatpak-manager"
REAL_USER="${SUDO_USER:-$(logname)}"
USER_HOME=$(eval echo "~$REAL_USER")

# Safety check: Ensure a real, non-root user is detected
if [[ -z "$REAL_USER" || "$REAL_USER" == "root" || ! -d "$USER_HOME" ]]; then
    echo -e "${RED}❌ Could not detect a valid non-root user home directory. Exiting.${NC}"
    exit 1
fi

icon_URL="https://raw.githubusercontent.com/tolgaerok/linuxtweaks/main/MY_PYTHON_APP/images/LinuxTweak.png"
icon_dir="$USER_HOME/.config"
icon_path="$icon_dir/LinuxTweak.png"

mkdir -p "$LOCAL_DIR" "$icon_dir"
wget -O "$icon_path" "$icon_URL"
chmod 644 "$icon_path"

# Log file for all actions
log_file="$USER_HOME/linuxtweaks-my-preload.log"
touch "$log_file"

# Ensure YAD is installed
if ! command -v yad &>/dev/null; then
    echo "Installing yad..."
    sudo dnf install -y yad &>>"$log_file" || {
        zenity --error --text="Failed to install 'yad'. Exiting."
        exit 1
    }
fi

# Ensure vmtouch is installed
if ! command -v vmtouch &>/dev/null; then
    echo "Installing vmtouch..."
    sudo dnf install -y vmtouch &>>"$log_file" || {
        zenity --error --text="Failed to install 'vmtouch'. Exiting."
        exit 1
    }
fi

# Paths for script and service
PRELOAD_SCRIPT="/usr/local/bin/my-preload.sh"
SERVICE_FILE="/etc/systemd/system/my-preload.service"
SLEEP_HOOK="/usr/lib/systemd/system-sleep/my-preload-resume.sh"

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

log_event() {
    echo "[$(date '+%d %B %Y %-I:%M%P')] $1" >>"$log_file"
}

function check_vmtouch() {
    VMT_PATH=$(command -v vmtouch || true)
    if [[ -z "$VMT_PATH" ]]; then
        echo -e "${RED}Error: vmtouch is not installed or not in PATH.${NC}"
        echo "Please install vmtouch before continuing."
        return 1
    fi
    return 0
}

function install_preload() {
    if ! check_vmtouch; then
        return 1
    fi
    log_event "Installing preload service"

    VMT_PATH=$(command -v vmtouch)

    echo -e "${GREEN}Installing preload script and service...${NC}"

    # Write the preload script
    cat >"$PRELOAD_SCRIPT" <<'EOF'
#!/bin/bash

VMT=$(command -v vmtouch)
YELLOW='\033[1;33m'
GREEN='\033[1;32m'
NC='\033[0m' # No color

if [[ -z "$VMT" ]]; then
  echo "vmtouch not installed. Please install it first."
  exit 1
fi

# Common applications to preload
files=(
  /usr/bin/bash
  /usr/bin/ssh
  /usr/lib64/libc.so.6
  /usr/bin/firefox
  /usr/bin/kate
  /usr/bin/korganizer
  /usr/bin/dolphin
  /usr/bin/code
  /usr/bin/gimp
)

for file in "${files[@]}"; do
  if [[ -f "$file" ]]; then
    "$VMT" -tf "$file" &
  else
    echo -e "${YELLOW}Warning: $file not found, skipping.${NC}"
  fi
done

wait

echo -e "${GREEN}Simulating preload for Flatpaks (user + system)...${NC}"

# Universal Flatpak preload (user)
flatpak list --app --user --columns=application | while read -r app; do
  dir="$HOME/.var/app/$app"
  if [ -d "$dir" ]; then
    echo "User Flatpak: $app"
    find "$dir" -type f \( -iname "*.so" -o -iname "*.bin" -o -iname "*.exe" \) 2>/dev/null | while read -r file; do
      "$VMT" -q -t "$file"
    done
  fi
done

# Universal Flatpak preload (system - only accessible if app has user data)
flatpak list --app --system --columns=application | while read -r app; do
  dir="$HOME/.var/app/$app"
  if [ -d "$dir" ]; then
    echo "System Flatpak (user overlay): $app"
    find "$dir" -type f \( -iname "*.so" -o -iname "*.bin" -o -iname "*.exe" \) 2>/dev/null | while read -r file; do
      "$VMT" -q -t "$file"
    done
  fi
done

# Explicit WPS preload (optional fallback)
WPS_DIR="$HOME/.var/app/com.wps.Office"
if flatpak info com.wps.Office &>/dev/null; then
  echo "🔹 Warming up WPS Office Flatpak files..."
  find "$WPS_DIR" -type f \( -iname "*.so" -o -iname "*.bin" -o -iname "*.exe" \) 2>/dev/null | while read -r file; do
    "$VMT" -q -t "$file"
  done
  echo "✅ WPS Office preload complete."
else
  echo "⚠️ WPS Office Flatpak not installed or inaccessible."
fi

echo -e "${GREEN}✅ Preload completed.${NC}"
EOF

    chmod +x "$PRELOAD_SCRIPT"

    # Write the systemd service file
    cat >"$SERVICE_FILE" <<EOF
[Unit]
Description=Preload important files into memory using vmtouch
After=local-fs.target
ConditionPathExists=$PRELOAD_SCRIPT

[Service]
Type=oneshot
RemainAfterExit=yes
ExecStart=$PRELOAD_SCRIPT
Nice=19
IOSchedulingClass=idle
IOSchedulingPriority=7
CPUSchedulingPolicy=idle
TimeoutStartSec=30s
SyslogIdentifier=my-preload

[Install]
WantedBy=multi-user.target
EOF

    # Reload systemd and enable/start the service
    systemctl daemon-reload
    systemctl enable --now my-preload.service

    # Write the sleep hook for systemd to restart on resume
    cat >"$SLEEP_HOOK" <<'EOF'
#!/bin/bash
logger "my-preload-resume.sh called with argument: $1"
case "$1" in
  post)
    logger "Restarting my-preload.service on resume"
    systemctl restart my-preload.service
    ;;
esac
EOF

    chmod +x "$SLEEP_HOOK"

    echo -e "${GREEN}Installation complete.${NC}"
    log_event "Installation complete"
    notify
}

function uninstall_preload() {
    echo -e "${YELLOW}Stopping and disabling my-preload.service...${NC}"
    log_event "Uninstalling preload service"
    systemctl stop my-preload.service
    systemctl disable my-preload.service

    echo -e "${YELLOW}Removing preload script, service file, and sleep hook...${NC}"
    rm -f "$PRELOAD_SCRIPT" "$SERVICE_FILE" "$SLEEP_HOOK"

    systemctl daemon-reload

    echo -e "${GREEN}Uninstallation complete.${NC}"
    log_event "Uninstallation complete"
}

function start_service() {
    log_event "Starting preload service"
    clear
    systemctl daemon-reload
    systemctl enable --now my-preload.service
    systemctl start my-preload.service
    echo -e "${GREEN}Service started.${NC}"
    log_event "Preload service started"
}

function stop_service() {
    clear
    systemctl stop my-preload.service
    echo -e "${YELLOW}Service stopped.${NC}"
}

function restart_service() {
    log_event "Restarting preload service"
    clear
    systemctl restart my-preload.service
    echo -e "${GREEN}Service restarted.${NC}"
    log_event "Preload service restarted"
}

function status_service() {
    log_event "Checking preload service status"
    clear
    systemctl status my-preload.service --no-pager
    log_event "Displayed preload service status"
}

function notify() {
    log_event "Preload Service Setup installed"
    sudo -u "$REAL_USER" \
        DISPLAY=:0 \
        DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$(id -u "$REAL_USER")/bus" \
        notify-send "Preload Service Setup installed" "✅  Your computer is ready!" \
        --app-name="💻  Preload Service Setup Installer" \
        -i "$icon_path" -u NORMAL
    log_event "Displayed preload service setup complete"
}

function notifyX() {
    log_event "Preload Service Setup EXITED"
    sudo -u "$REAL_USER" \
        DISPLAY=:0 \
        DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$(id -u "$REAL_USER")/bus" \
        notify-send "Preload Service Setup Exit" "✅  Thankyou for trying linuxtweaks my-preload tweak!" \
        --app-name="💻  Preload Service" \
        -i "$icon_path" -u NORMAL
    log_event "Displayed preload service setup EXITED"
}

# Simple menu for managing the service
while true; do

    echo
    echo "Preload Service Setup Menu"
    echo "--------------------------"
    echo "1) Install preload service"
    echo "2) Uninstall preload service"
    echo "3) Start preload service"
    echo "4) Stop preload service"
    echo "5) Restart preload service"
    echo "6) Show service status"
    echo "7) Exit"
    echo
    read -rp "Select an option [1-7]: " choice
    log_event "User selected menu option: $choice"

    case "$choice" in
    1) install_preload ;;
    2) uninstall_preload ;;
    3) start_service ;;
    4) stop_service ;;
    5) restart_service ;;
    6) status_service ;;
    7)
        echo "Exiting."
        notifyX
        exit 0
        ;;
    *) echo -e "${RED}Invalid option. Please choose 1-7.${NC}" ;;
    esac
done
