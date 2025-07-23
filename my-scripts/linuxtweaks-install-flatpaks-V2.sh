#!/usr/bin/env bash
# Tolga Erok
# 9/7/25
# Personal flatpak installer VERSION: 2

set -euo pipefail
clear

# my default file for the list of Flatpaks to install
my_nixos_flatpak_file="${TARGET_FLATPAK_FILE:-/etc/nixos/flatpaks/system-flatpaks.list}"

echo "─────────────── LINUXTWEAKS FLATPAK INSTALLER ───────────────"
echo ""

# Check if flatpak is installed
if ! command -v flatpak &>/dev/null; then
    echo "Flatpak not found. Installing..."

    if command -v dnf5 &>/dev/null || command -v dnf &>/dev/null; then
        sudo dnf install -y flatpak
    elif command -v pacman &>/dev/null; then
        sudo pacman -Sy --noconfirm flatpak
    elif command -v apt &>/dev/null; then
        sudo apt update && sudo apt install -y flatpak
    elif command -v nix-env &>/dev/null; then
        nix-env -iA nixpkgs.flatpak
    else
        echo "Unsupported distro. Install flatpak manually."
        exit 1
    fi
fi

# Add Flathub remote if missing
flatpak remote-add --if-not-exists --system flathub https://flathub.org/repo/flathub.flatpakrepo

# process my Flatpak list
if [[ -s "$my_nixos_flatpak_file" ]]; then
    echo "Installing/Updating Flatpaks from $my_nixos_flatpak_file..."

    while IFS= read -r app || [[ -n "$app" ]]; do
        [[ -z "$app" || "$app" =~ ^# ]] && continue

        # Trim whitespace from the app line
        app=$(echo "$app" | xargs)

        echo "→ Installing or updating: $app"

        if [[ "$app" == *"/"* ]]; then
            flatpak install --system --noninteractive --or-update -y "$app" ||
                echo "⚠️ Failed to install $app"
        else
            flatpak install --system --noninteractive --or-update -y "$app" ||
                echo "⚠️ Failed to install $app"
        fi
    done <"$my_nixos_flatpak_file"

else
    echo "No Flatpaks to install. File missing or empty: $my_nixos_flatpak_file"
fi

# VSCode Extensions
if command -v code &>/dev/null; then
    echo "Installing VSCode extensions..."
    extensions=(
        ms-azuretools.vscode-containers
        ms-vscode-remote.remote-containers
        ms-vscode-remote.remote-ssh
    )
    for ext in "${extensions[@]}"; do
        echo "→ Installing: $ext"
        code --install-extension "$ext" --force ||
            echo "⚠️ Failed to install $ext"
    done
else
    echo "VSCode not found. Skipping extension installation."
fi

echo ""
echo "─────────────── INSTALLATION COMPLETE ───────────────"
echo ""
echo "─────────────── Flatpak SYSTEM level list ───────────────"
echo ""
flatpak list --system
echo ""
echo "─────────────── Vscode Extention list ───────────────"
echo ""
code --list-extensions
echo ""