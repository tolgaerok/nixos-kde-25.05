#!/usr/bin/env bash
# Tolga Erok
# 18/5/2025
# BETA
# LinuxTweaks Flatpak installer including flatpak gamescope

set -euo pipefail

# uncomment to see verbose on screen (debug purposes)
#set -x

done="✅"
error="⚠️"

# log for all actions
log_file="$HOME/linuxtweaks.log"
touch "$log_file"

# is YAD installed
if ! command -v yad &>/dev/null; then
    echo "Installing yad..."
    sudo dnf install -y yad &>>"$log_file" || {
        zenity --error --text="Failed to install 'yad'. Exiting."
        exit 1
    }
fi

# Variables
DESKTOP_FILE="$HOME/.local/share/applications/flatpak-manager.desktop"
LOCAL_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/flatpak-manager"
REAL_USER="${SUDO_USER:-$(logname)}"
USER_HOME=$(eval echo "~$REAL_USER")
VER_FILE="$LOCAL_DIR/version"
flatpak_list="$HOME/flatpaks-installed.txt"
SCRIPT_VER=3
icon_URL="https://raw.githubusercontent.com/tolgaerok/linuxtweaks/main/MY_PYTHON_APP/images/LinuxTweak.png"
icon_dir="$USER_HOME/.config"
icon_path="$icon_dir/LinuxTweak.png"

mkdir -p "$LOCAL_DIR" "$icon_dir"
wget -q -O "$icon_path" "$icon_URL" || echo "⚠️ Warning: Failed to download icon"
chmod 644 "$icon_path"
clear

# YAD progress bar wrapper
fancy() {
    local title="$1"
    local cmd="$2"
    local status_file=$(mktemp)

    (
        echo "10"
        echo "# Starting: $title"
        sleep 0.5

        eval "$cmd" 2>&1 | tee -a "$log_file" | while read -r line; do
            echo "# $line"
            sleep 0.1
        done
        echo "${PIPESTATUS[0]}" >"$status_file"
        echo "100"
        # echo $? >"$status_file"
        sleep 0.3
    ) | yad --progress \
        --title="LinuxTweaks Flatpaks-Setup" \
        --image="$icon_path" \
        --text="<tt>$title</tt>" \
        --percentage=0 \
        --width=500 \
        --center \
        --auto-close

    local exit_code=$(cat "$status_file")
    rm -f "$status_file"

    if [[ $exit_code -ne 0 ]]; then
        yad --error --title="Error during $title" --image="$icon_path" \
            --text="An error occurred while executing: $title\nCheck the log at: $log_file" \
            --width=400 --center
    fi
}

# Reboot confirmation
declare -f reboot_func >/dev/null 2>&1 || reboot_func() {
    yad --question --title="Reboot Required" --image="$icon_path" \
        --text="Reboot now to apply changes?" --width=350 --center \
        --button="No":1 --button="Yes":0

    if [[ $? -eq 0 ]]; then
        sudo reboot
    else
        yad --info --title="Reboot Later" --image="$icon_path" \
            --text="You can reboot manually later to apply changes." --width=350 --center
    fi
}

# Welcome prompt
prompt_text="\
👋 Welcome to the LinuxTweaks Flatpak Manager\n\nThis tool will:\n• Install yad if needed\n• Configure Flathub\n• Install essential Flatpaks\n• Export/import Flatpak lists\n• Create a launcher\n\n🚀 Proceed?"

yad --question --title="Confirm LinuxTweaks Flatpak-Setup" --image="$icon_path" \
    --no-markup --text="$prompt_text" --width=550 --center \
    --button="No":1 --button="Yes":0 || {
    yad --info --title="Cancelled" --image="$icon_path" \
        --no-markup --text="Post-setup aborted. You can run this later." --width=400 --center
    exit 1
}

# System Update
# fancy "System Update" "sudo dnf install -y dnf dnf-plugins-core && sudo dnf upgrade --refresh -y"

# Flatpak setup
first_run_setup() {
    fancy "Setting up Flatpak and Flathub" 'bash -c "
        flatpak remote-add --if-not-exists --user flathub https://flathub.org/repo/flathub.flatpakrepo
        flatpak override --user --filesystem=xdg-config/gtk-4.0:ro
        flatpak override --user --unset-env=QT_QPA_PLATFORMTHEME
    "'

    # Add Flathub remote if not already present (user)
    fancy "Adding Flathub remote (user)" "flatpak remote-add --if-not-exists --user flathub https://flathub.org/repo/flathub.flatpakrepo"

    # Update all Flatpak apps (user and system)
    fancy "Updating Flatpak apps (user)" "flatpak update --user --noninteractive -y"
    fancy "Updating Flatpak apps (system)" "flatpak update --system --noninteractive -y"

    fancy "Adding Flathub remote" "flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo"

    declare -a default_flatpaks=(
        com.github.tchx84.Flatseal
        com.rtosta.zapzap
        com.wps.Office
        io.github.aandrew_me.ytdn
        io.github.flattool.Warehouse
        io.missioncenter.MissionCenter
        org.gnome.Connections
        org.gnome.DejaDup
        org.gnome.World.PikaBackup
        org.gnome.baobab
        org.mozilla.firefox
    )

    for app in "${default_flatpaks[@]}"; do
        fancy "Installing or updating $app" "flatpak install --user --noninteractive -y --or-update flathub '$app'"
    done


    declare -a gaming_flatpaks=(
        org.virt_manager.virt-manager
        app/com.valvesoftware.Steam/x86_64/stable
        app/com.heroicgameslauncher.hgl/x86_64/stable
        app/net.lutris.Lutris/x86_64/stable
        app/net.davidotek.pupgui2/x86_64/stable
        app/com.dec05eba.gpu_screen_recorder/x86_64/stable
        app/io.github.ilya_zlobintsev.LACT/x86_64/stable
        runtime/org.freedesktop.Platform.VulkanLayer.gamescope/x86_64/24.08
        runtime/org.freedesktop.Platform.VulkanLayer.gamescope/x86_64/23.08
        runtime/org.freedesktop.Platform.VulkanLayer.OBSVkCapture/x86_64/24.08
        runtime/com.obsproject.Studio.Plugin.OBSVkCapture/x86_64/stable
        runtime/org.freedesktop.Platform.VulkanLayer.MangoHud/x86_64/24.08
        runtime/org.freedesktop.Platform.VulkanLayer.MangoHud/x86_64/23.08
    )

    for app in "${gaming_flatpaks[@]}"; do
        fancy "Installing $app" "sudo flatpak --system install --noninteractive -y --or-update flathub '$app'"
    done


    echo "$SCRIPT_VER" > "$VER_FILE"

    mkdir -p "$(dirname "$DESKTOP_FILE")"
    cat > "$DESKTOP_FILE" <<EOF
[Desktop Entry]
Name=LinuxTweaks Flatpak Manager
Comment=Manage and reinstall Flatpaks
Exec=$HOME/flatpak-manager.sh
Icon=$icon_path
Terminal=false
Type=Application
Categories=Utility;System;
EOF

    update-desktop-database ~/.local/share/applications &>/dev/null
    sudo -u "$REAL_USER" \
    DISPLAY=:0 \
    DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$(id -u "$REAL_USER")/bus" \
    notify-send "Flatpaks installed" "✅  Your computer is ready!" \
        --app-name="💻  LinuxTweaks Flatpak Installer" \
        -i "$icon_path" -u NORMAL
}

# Run setup
first_run_setup
