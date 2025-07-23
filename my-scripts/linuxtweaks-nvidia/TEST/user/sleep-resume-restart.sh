#!/bin/bash
exec >>"$HOME/.local/share/linuxtweaks-flatpak.log" 2>&1
echo "[INFO] Running Flatpak Auto-Updater at $(date)"
case "$1" in
    pre) ;;
    post)
        systemctl --user restart linuxtweaks-flatpak.timer
        ;;
esac
