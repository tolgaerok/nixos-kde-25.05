#!/usr/bin/env bash
# Tolga erok
# 18/5/2025
# BETA
# my flatpak manager/installer

# VERSION 6
# CHANGELOG: 13/6/2025    massive overhaul

done="✅"
error="⚠️"

# Relaunch script with sudo if not root
if [[ $EUID -ne 0 ]]; then
  echo "Elevating privileges with sudo..."
  exec sudo "$0" "$@"
fi

#------------------------------------#
# check for YAD; install if missing  #
#------------------------------------#
#if ! command -v yad &>/dev/null; then
#  echo "Installing yad..."
#  sudo dnf5 install -y yad &>/dev/null || {
#    zenity --error --text="Failed to install 'yad'. Exiting."
#    exit 1
#  }
#fi

detect_distro() {
  if [ -f /etc/arch-release ]; then
    echo "arch"
  elif [ -f /etc/fedora-release ]; then
    echo "fedora"
  elif [ -f /etc/debian_version ]; then
    echo "debian"
  else
    echo "unknown"
  fi
}

case "$(detect_distro)" in
arch) sudo pacman -Sy --noconfirm yad ;;
fedora) sudo dnf5 install -y yad ;;
debian) sudo apt update && sudo apt install -y yad ;;
*)
  zenity --error --text="Unsupported distro."
  exit 1
  ;;
esac

# ─── Ensure my Icon is Present ───────────────────────────────────────────────────
DESKTOP_FILE="$HOME/.local/share/applications/flatpak-manager.desktop"
LOCAL_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/flatpak-manager"
REAL_USER="${SUDO_USER:-$(logname)}"
SCRIPT_VER=3
USER_HOME=$(eval echo "~$REAL_USER")
VER_FILE="$LOCAL_DIR/version"
flatpak_list="$HOME/flatpaks-installed.txt"
icon_URL="https://raw.githubusercontent.com/tolgaerok/linuxtweaks/main/MY_PYTHON_APP/images/LinuxTweak.png
"
icon_dir="$USER_HOME/.config"
icon_path="$icon_dir/LinuxTweak.png"
mkdir -p "$LOCAL_DIR"
mkdir -p "$icon_dir"
wget -q -O "$icon_path" "$icon_URL"
chmod 644 "$icon_path"
clear

#-----------------------------#
# YAD progress bar wrapper    #
#-----------------------------#
fancy() {
  local width=40
  local line1="📡 Downloading & Installing:"
  local line2="$1"
  local padded1 padded2

  line1=${line1//&/&amp;}
  line2=${line2//&/&amp;}

  padded1=$(printf "%*s" $(((${#line1} + width) / 2)) "$line1")
  padded2=$(printf "%*s" $(((${#line2} + width) / 3)) "$line2")

  log_file="$HOME/linuxtweaks.log"
  touch "$log_file"
  status_file=$(mktemp)

  (
    echo "10"
    echo "# Starting: $1"
    sleep 0.3

    eval "$2" 2>&1 | tee -a "$log_file" | while IFS= read -r line; do
      if [[ "$line" == "Downloading" ]]; then
        echo "40"
      elif [[ "$line" == "Installing" ]]; then
        echo "70"
      elif [[ "$line" == "Done" ]]; then
        echo "100"
      fi
    done

    echo $? >"$status_file"
    sleep 0.3
  ) | yad --progress \
    --title="LinuxTweaks Flatpak-Setup" \
    --image="$icon_path" \
    --text="<tt>$padded1\n$padded2</tt>" \
    --percentage=0 \
    --width=500 \
    --center \
    --auto-close

  cmd_exit_code=$(cat "$status_file")
  rm -f "$status_file"

  if [[ $cmd_exit_code -ne 0 ]]; then
    echo "⚠️  An error occurred during '$1'. Check log: $log_file"
    yad --error \
      --title="Error during $1" \
      --image="$icon_path" \
      --text="An error occurred while executing:\n\n$1\n\nCheck the log at:\n$log_file" \
      --width=400 \
      --center
  fi
}

reboot_func() {
  yad --question \
    --title="Reboot Required" \
    --image="$icon_path" \
    --text="Reboot now to apply changes?" \
    --width=350 --center \
    --button="No":1 --button="Yes":0

  if [[ $? -eq 0 ]]; then
    sudo reboot
  else
    yad --info \
      --title="Reboot Later" \
      --image="$icon_path" \
      --text="You can reboot manually later to apply changes." \
      --width=350 --center
  fi
}

#----------------------------------#
# 👋 confirmation prompt to start  #
#----------------------------------#
prompt_text=$(
  cat <<'EOF'
👋 Welcome to the LinuxTweaks Flatpak Setup

This tool will perform the following Flatpak-related actions:

    🟢  Check and install missing dependencies (e.g., yad)
    🟢  Automatically configure Flathub and environment overrides
    🟢  Install a curated list of essential Flatpak apps
    🟢  Generate or import Flatpak app lists for backup/restore
    🟢  Reinstall apps from saved Flatpak list
    🟢  Create a handy desktop launcher for this tool
    🟢  Display progress using a graphical progress bar
    🟢  Log all actions to ~/linuxtweaks.log for review

⚙️  This tool is still in BETA – feedback is welcome!

🚀   Do you want to proceed?
EOF
)

prompt_text_2=$(
  cat <<'EOF'
👋 Welcome to the LinuxTweaks Flatpak Setup

This section will perform the following Flatpak-related actions:

    🟢  Install custom selection of Flatpaks
    🟢  Export installed SYSTEM wide flatpaks
    🟢  Import your list of flatpaks
    🟢  Reinstall apps from saved Flatpak list
    🟢  Remove ALL installled SYSTEM wide flatpaks
    🟢  Remove ALL installled USER wide flatpaks
    🟢  List all installled USER flatpaks
    🟢  List all installled SYSTEM wide flatpaks

⚙️  This tool is still in BETA – feedback is welcome!


EOF
)

yad --question \
  --title="Confirm LinuxTweaks Flatpak-Setup" \
  --image="$icon_path" \
  --no-markup \
  --text="$prompt_text" \
  --width=550 \
  --center \
  --button="No:1" \
  --button="Yes:0"

if [[ $? -ne 0 ]]; then
  yad --info \
    --title="Cancelled" \
    --image="$icon_path" \
    --no-markup \
    --text="Flatpak-setup aborted by user.\n\nYou can run this script later when ready." \
    --width=400 \
    --center
  exit 1
fi

#-----------------------------#
# ⚠️ System Update
#-----------------------------#

# suppress stupid GTK warnings from yad
yad_suppress() {
  yad "$@" 2>/dev/null
}

first_run_setup() {
  fancy " 🛠️ Running initial Flatpak Manager setup.., please WAIT ..." 'bash -c "
  # Add Flathub if missing
  flatpak remote-add --if-not-exists --system flathub https://flathub.org/repo/flathub.flatpakrepo

  # Theme tweaks only works in USER space
  # flatpak override --user --filesystem=xdg-config/gtk-4.0:ro
  # flatpak override --user --unset-env=QT_QPA_PLATFORMTHEME"
'

  declare -a default_flatpaks=(
    app/com.dec05eba.gpu_screen_recorder/x86_64/stable
    app/com.heroicgameslauncher.hgl/x86_64/stable
    app/com.valvesoftware.Steam/x86_64/stable
    app/io.github.ilya_zlobintsev.LACT/x86_64/stable
    app/net.davidotek.pupgui2/x86_64/stable
    app/net.lutris.Lutris/x86_64/stable
    com.github.tchx84.Flatseal
    com.obsproject.Studio
    com.obsproject.Studio.Plugin.{OBSVkCapture,GStreamerVaapi}
    com.wps.Office
    io.github.aandrew_me.ytdn
    io.github.flattool.Warehouse
    io.missioncenter.MissionCenter
    org.gnome.Connections
    org.gnome.DejaDup
    org.gnome.World.PikaBackup
    org.gnome.baobab
    org.gtk.Gtk3theme.Arc-Dark
    org.gtk.Gtk3theme.Yaru-Blue
    org.gtk.Gtk3theme.Yaru-Deepblue
    org.mozilla.firefox
    org.virt_manager.virt-manager
    runtime/com.obsproject.Studio.Plugin.OBSVkCapture/x86_64/stable
    runtime/org.freedesktop.Platform.VulkanLayer.MangoHud/x86_64/23.08
    runtime/org.freedesktop.Platform.VulkanLayer.MangoHud/x86_64/24.08
    runtime/org.freedesktop.Platform.VulkanLayer.OBSVkCapture/x86_64/24.08
    runtime/org.freedesktop.Platform.VulkanLayer.gamescope/x86_64/23.08
    runtime/org.freedesktop.Platform.VulkanLayer.gamescope/x86_64/24.08
  )

  for app in "${default_flatpaks[@]}"; do
    # Install system-wide
    fancy " 📦 Installing $app..., please WAIT ..." "flatpak install -y --noninteractive --system flathub \"$app\" || echo '⚠️ Failed to install: $app'"
  done

  # Theme override for rhythm box
  sudo flatpak override --reset org.gnome.Rhythmbox3
  flatpak override --user --reset org.gnome.Rhythmbox3
  sudo flatpak override org.gnome.Rhythmbox3 --env=GTK_THEME=Arc-Dark --filesystem=host

  echo "$SCRIPT_VER" >"$VER_FILE"

  mkdir -p "$(dirname "$DESKTOP_FILE")"
  cat >"$DESKTOP_FILE" <<EOF
[Desktop Entry]
Name=LinuxTweaks Flatpak Manager
Comment=Manage and reinstall Flatpaks
Exec=$HOME/flatpak-manager.sh
Icon=system-software-install
Terminal=false
Type=Application
Categories=Utility;System;
EOF

  # Fucking Notify-send still needs to be run as the actual user
  sudo -u "$REAL_USER" DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$(id -u "$REAL_USER")/bus" \
    DISPLAY=:0 notify-send "Flatpak Manager" "✅ Setup complete. Launcher created!"

}

export_flatpak_list() {
  flatpak list --app --columns=application >"$flatpak_list"
  yad_suppress --info --width=300 --text="✅ Flatpak list exported to:\n<b>$flatpak_list</b>"
}

import_flatpak_list() {
  file=$(yad_suppress --file --title="Import Flatpak List" --file-filter="*.txt")
  [[ -z "$file" ]] && return
  while read -r app; do
    flatpak install -y --noninteractive flathub "$app"
  done <"$file"
  yad_suppress --info --width=300 --text="📥 Imported and installed Flatpaks from:\n<b>$file</b>"
}

reinstall_flatpaks() {
  if [[ -f "$flatpak_list" ]]; then
    while read -r app; do
      flatpak install -y --noninteractive flathub "$app"
    done <"$flatpak_list"
    yad_suppress --info --width=300 --text="🔁 Reinstalled all Flatpaks from list."
  else
    yad_suppress --error --width=300 --text="❌ List not found:\n<b>$flatpak_list</b>"
  fi
}

# remove system-wide Flatpaks
remove_all_flatpaks() {
  yad --question \
    --title="Confirm Removal" \
    --image="$icon_path" \
    --text="⚠️ Are you sure you want to remove ALL System Flatpak applications?\n\nThis action cannot be undone." \
    --width=450 \
    --center \
    --button="No":1 --button="Yes":0

  if [[ $? -eq 0 ]]; then # you clicked 'Yes'
    # Get list of system Flatpaks into an ARRAY
    local -a system_flatpaks_array=()
    mapfile -t system_flatpaks_array < <(flatpak list --system --app --columns=application)

    if [[ ${#system_flatpaks_array[@]} -eq 0 ]]; then
      yad_suppress --info --width=300 --text="ℹ️ No System Flatpak applications found."
      return
    fi

    local uninstall_cmd="flatpak uninstall --system -y --delete-data"
    for app_id in "${system_flatpaks_array[@]}"; do
      uninstall_cmd+=" \"$app_id\""
    done

    fancy "🗑️ Removing all System Flatpaks..." "$uninstall_cmd"

    if [[ $? -eq 0 ]]; then
      yad_suppress --info --width=300 --text="🗑️ All System Flatpaks have been removed successfully."
    else
      yad_suppress --error --width=300 --text="❌ An error occurred during System Flatpak removal. Check log."
    fi
  else
    yad_suppress --info --width=300 --text="🚫 System Flatpak removal cancelled."
  fi
}

# remove USER Flatpaks
remove_all_user_flatpaks() {
  yad --question \
    --title="Confirm Removal" \
    --image="$icon_path" \
    --text="⚠️ Are you sure you want to remove ALL User Flatpak applications?\n\nThis action cannot be undone." \
    --width=450 \
    --center \
    --button="No":1 --button="Yes":0

  if [[ $? -eq 0 ]]; then # User clicked 'Yes'
    # Get list of User Flatpaks into an ARRAY
    local -a user_flatpaks_array=()
    # FIX: Changed system_flatpaks_array to user_flatpaks_array was too stonned to see the error
    mapfile -t user_flatpaks_array < <(flatpak list --user --app --columns=application)

    if [[ ${#user_flatpaks_array[@]} -eq 0 ]]; then
      yad_suppress --info --width=300 --text="ℹ️ No USER Flatpak applications found."
      return
    fi

    local uninstall_cmd="flatpak uninstall --user -y --delete-data"
    for app_id in "${user_flatpaks_array[@]}"; do
      uninstall_cmd+=" \"$app_id\""
    done

    fancy "🗑️ Removing all USER Flatpaks..." "$uninstall_cmd"

    if [[ $? -eq 0 ]]; then
      yad_suppress --info --width=300 --text="🗑️ All USER Flatpaks have been removed successfully."
    else
      yad_suppress --error --width=300 --text="❌ An error occurred during USER Flatpak removal. Check log."
    fi
  else
    yad_suppress --info --width=300 --text="🚫 USER Flatpak removal cancelled."
  fi
}

# Only list system-wide Flatpaks
show_flatpak_list() {
  local entries=()
  while IFS=$'\t' read -r app name; do
    entries+=("$app" "$name" "System")
  done < <(flatpak list --system --app --columns=application,name)

  yad --center --width=850 --height=800 \
    --title="Installed System Flatpaks" \
    --list \
    --column="Flatpak ID" \
    --column="App Name" \
    --column="Install Scope" \
    "${entries[@]}"
}

# Only list user Flatpaks
show_flatpak_user_list() {
  local entries=()
  while IFS=$'\t' read -r app name; do
    entries+=("$app" "$name" "User")
  done < <(flatpak list --user --app --columns=application,name)

  yad --center --width=850 --height=800 \
    --title="Installed USER Flatpaks" \
    --list \
    --column="Flatpak ID" \
    --column="App Name" \
    --column="Install Scope" \
    "${entries[@]}"
}

#-----------------------------------------#
#  Main Menu GUI                          #
#-----------------------------------------#
main_menu() {
  yad --center --width=600 --height=650 --title="LinuxTweaks Flatpak Manager" --image="$icon_path" --text="$prompt_text_2" --list --print-column=1 --column="Option" --column="Description" \
    "run_setup" "Initial install and setup" \
    "export_list" "Export installed Flatpak apps list" \
    "import_list" "Import and install from saved list" \
    "reinstall_list" "Reinstall all apps from list" \
    "remove_all" "Remove all installed System Flatpaks" \
    "remove_all_user_flatpaks" "Remove all installed USER Flatpaks" \
    "show_flatpak_user_list" "Show currently installed USER Flatpaks" \
    "show_installed" "Show currently installed SYSTEM Flatpaks"
}

while true; do
  set +o pipefail
  menu_output=$(main_menu)
  yad_exit_code=$?
  set -o pipefail

  choice=$(echo "$menu_output" | awk -F'|' '{print $1}' | xargs echo -n)

  if [[ $yad_exit_code -ne 0 ]]; then
    break
  fi

  echo "DEBUG: Captured choice: \"$choice\""

  case "$choice" in
  run_setup)
    first_run_setup
    ;;
  export_list)
    export_flatpak_list
    ;;
  import_list)
    import_flatpak_list
    ;;
  reinstall_list)
    reinstall_flatpaks
    ;;
  remove_all)
    remove_all_flatpaks
    ;;
  remove_all_user_flatpaks)
    remove_all_user_flatpaks
    ;;
  show_installed)
    show_flatpak_list
    ;;
  show_flatpak_user_list)
    show_flatpak_user_list
    ;;
  *)
    yad --info --text="Unknown option: \"$choice\" (length: ${#choice})"
    ;;
  esac
done

reboot_func
exit 0
