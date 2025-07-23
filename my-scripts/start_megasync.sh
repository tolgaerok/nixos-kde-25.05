#!/bin/bash
# Start MEGAsync inside Distrobox container 'f41' using X11
# Tolga Erok - 2025

LOGFILE="$HOME/megasync.log"

{
  echo "─── Starting MEGAsync at $(date) ───"

  # Fucking X11 environment variables
  export GDK_BACKEND=x11
  export QT_QPA_PLATFORM=xcb
  export DISPLAY="${DISPLAY:-:0}"
  export XAUTHORITY="${XAUTHORITY:-$HOME/.Xauthority}"
  export XDG_RUNTIME_DIR="/run/user/$(id -u)"

  echo "DISPLAY=$DISPLAY"
  echo "XAUTHORITY=$XAUTHORITY"
  echo "XDG_RUNTIME_DIR=$XDG_RUNTIME_DIR"

  echo "Granting X access to user, fucking bastard..."
  xhost +SI:localuser:$(whoami)

  echo "Launching MEGAsync inside Distrobox container '41'..."
} >>"$LOGFILE" 2>&1

# Execute MEGAsync inside the Distrobox container named 'f41'
distrobox enter --name f41 -- bash -c '
  export GDK_BACKEND=x11
  export QT_QPA_PLATFORM=xcb
  export DISPLAY=:0
  export XAUTHORITY=/home/tolga/.Xauthority
  megasync
' >>"$LOGFILE" 2>&1 &
