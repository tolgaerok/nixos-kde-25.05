#!/usr/bin/env bash
# Tolga Erok
# Personal flatpak installer VERSION: 2

# ─── BETA: Install Flatpaks for Debian, NixOS, Fedora, and Arch ─────────────────────────────────────
set -euo pipefail
# my default file for the list of Flatpaks to install
my_nixos_flatpak_file="${TARGET_FLATPAK_FILE:-/etc/nixos/flatpaks/system-flatpaks.list}"

# is flatpak installed, install if not
if ! command -v flatpak &>/dev/null; then
    echo "Flatpak not found. Attempting to install Flatpak..."

    # which package manager and install flatpak
    if command -v dnf5 &>/dev/null || command -v dnf &>/dev/null; then
        sudo dnf install -y flatpak || { echo "Failed to install flatpak on Fedora. Exiting."; exit 1; }
    elif command -v pacman &>/dev/null; then
        sudo pacman -Sy --noconfirm flatpak || { echo "Failed to install flatpak on Arch. Exiting."; exit 1; }
    elif command -v apt &>/dev/null; then
        sudo apt update && sudo apt install -y flatpak || { echo "Failed to install flatpak on Debian. Exiting."; exit 1; }
    elif command -v nix-env &>/dev/null; then
        nix-env -iA nixpkgs.flatpak || { echo "Failed to install flatpak on NixOS. Exiting."; exit 1; }
    else
        echo "Unsupported distribution. Please install Flatpak manually."
        exit 1
    fi
fi

# Add Flathub remote if not already added
flatpak remote-add --if-not-exists --system flathub https://flathub.org/repo/flathub.flatpakrepo


# Check if my Flatpak file exists and is not empty: /etc/nixos/flatpaks/system-flatpaks.list
if [[ -s "$my_nixos_flatpak_file" ]]; then
    echo "Installing/Updating Flatpaks from $my_nixos_flatpak_file..."

    # Install or update Flatpaks listed in my file
    xargs -a "$my_nixos_flatpak_file" flatpak install --system -y --or-update
else
    echo "No Flatpaks to install. The file is missing or empty: $my_nixos_flatpak_file"

fi
