#!/bin/bash
# kingtolga flatpak theme setup - clean, precise, no fluff

GREEN="🟢"
YELLOW="🟡"
RED="🔴"
RESET="\e[0m"
BOLD="\e[1m"

info() { echo -e "${GREEN}${BOLD}ℹ $1${RESET}"; }
warn() { echo -e "${YELLOW}${BOLD}⚠ $1${RESET}"; }
error() { echo -e "${RED}${BOLD}✖ $1${RESET}"; }

# Clear QT_QPA_PLATFORMTHEME override (avoid empty/unset clash)
info "Clearing QT_QPA_PLATFORMTHEME override..."
flatpak override --user --unset-env=QT_QPA_PLATFORMTHEME

# Set your environment variables
info "Setting GTK theme to Breeze..."
flatpak override --user --env=GTK_THEME=Breeze

info "Setting QT style override to Breeze..."
flatpak override --user --env=QT_STYLE_OVERRIDE=Breeze

# Optional: set QT_QPA_PLATFORMTHEME to KDE or qt6ct for Qt apps
# Uncomment one if you want it
# info "Setting QT_QPA_PLATFORMTHEME to KDE..."
# flatpak override --user --env=QT_QPA_PLATFORMTHEME=KDE

# info "Setting QT_QPA_PLATFORMTHEME to qt6ct..."
flatpak override --user --env=QT_QPA_PLATFORMTHEME=qt6ct

# Optional: suppress GTK theme size warnings
info "Suppressing GTK theme warnings (optional)..."
flatpak override --user --env=GDK_CORE_DEVICE_EVENTS=1

# Show current overrides for confirmation
info "Current flatpak overrides for user:"
flatpak override --user --show

info "Done. Restart your Flatpak apps to apply changes."
