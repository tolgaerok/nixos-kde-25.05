#!/bin/bash

SERVICE="linux-power-tweaks.service"
SCRIPT="/usr/local/bin/linux-power-tweaks.sh"
SERVICE_PATH="/etc/systemd/system/$SERVICE"

check_status() {
  systemctl is-enabled "$SERVICE" &>/dev/null && echo "ENABLED" || echo "DISABLED"
}

show_about() {
  yad --center --width=400 --title="About Linux Power Tweaks" --button=OK --text="
<b>Linux Power Tweaks</b> by Tolga Erok (2025)

This tool applies power-saving tweaks:
• Disables NMI Watchdog
• Sets dirty writeback timeout
• Enables PCI/USB runtime power management
• Disables ACPI wakeup devices

Good for desktops & laptops aiming to reduce idle power usage."
}

apply_tweaks() {
  (
    echo 10; echo "# Creating power tweak script..."
    sudo tee "$SCRIPT" > /dev/null << 'EOF'
#!/bin/bash
set -e
echo "[+] Applying Linux Power Tweaks..."
sysctl -w kernel.nmi_watchdog=0
echo "kernel.nmi_watchdog = 0" > /etc/sysctl.d/99-nmi.conf
sysctl -w vm.dirty_writeback_centisecs=1500
echo "vm.dirty_writeback_centisecs = 1500" > /etc/sysctl.d/99-dirty.conf
for dev in /sys/bus/pci/devices/*/power/control; do echo auto > "$dev"; done
for dev in /sys/bus/usb/devices/*/power/control; do echo auto > "$dev"; done
for dev in XHC EHC1 EHC2 LID0; do grep -q "$dev" /proc/acpi/wakeup && echo "$dev" > /proc/acpi/wakeup; done
echo "[✓] Power tweaks applied."
EOF

    echo 40; echo "# Creating systemd service..."
    sudo tee "$SERVICE_PATH" > /dev/null <<EOF
[Unit]
Description=Linux Power Tweaks - Runtime PM, NMI, Writeback, ACPI
After=multi-user.target

[Service]
Type=oneshot
ExecStart=$SCRIPT
RemainAfterExit=true

[Install]
WantedBy=multi-user.target
EOF

    echo 70; echo "# Enabling and starting service..."
    sudo chmod +x "$SCRIPT"
    sudo systemctl daemon-reexec
    sudo systemctl daemon-reload
    sudo systemctl enable --now "$SERVICE"

    echo 100; echo "# Power tweaks applied successfully!"
  ) | yad --progress --title="Applying Tweaks" --width=400 --center \
          --auto-close --auto-kill --pulsate --no-buttons
}

reverse_tweaks() {
  (
    echo 20; echo "# Reversing tweaks..."
    sudo systemctl disable --now "$SERVICE"
    echo 60; echo "# Removing files..."
    sudo rm -f "$SCRIPT" "$SERVICE_PATH"
    sudo rm -f /etc/sysctl.d/99-nmi.conf /etc/sysctl.d/99-dirty.conf
    echo 100; echo "# Power tweaks reversed."
  ) | yad --progress --title="Reversing Tweaks" --width=400 --center \
          --auto-close --auto-kill --pulsate --no-buttons
}

main_menu() {
  STATUS=$(check_status)
  yad --center --width=400 --title="Linux Power Tweaks" --form \
      --text="<b>Current Status:</b> $STATUS" \
      --button="About:1" \
      --button="Apply Tweaks:2" \
      --button="Reverse Tweaks:3" \
      --button="Exit:0"

  case $? in
    1) "$0" --about ;;
    2) "$0" --apply ;;
    3) "$0" --reverse ;;
    0) exit 0 ;;
  esac
}

# Handle CLI args
case "$1" in
  --about) show_about ;;
  --apply) apply_tweaks ;;
  --reverse) reverse_tweaks ;;
  *) main_menu ;;
esac
