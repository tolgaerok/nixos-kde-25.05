#!/bin/bash

set -e

echo "🔧 Setting up Linux Power Tweaks (fully automated)..."

# 1. Write the power tweaks script
POWER_SCRIPT="/usr/local/bin/linux-power-tweaks.sh"

cat << 'EOF' | sudo tee "$POWER_SCRIPT" > /dev/null
#!/bin/bash
set -e

echo "[+] Applying Linux Power Tweaks..."

# Disable NMI Watchdog
echo " - Disabling NMI Watchdog..."
sysctl -w kernel.nmi_watchdog=0
echo "kernel.nmi_watchdog = 0" > /etc/sysctl.d/99-nmi.conf

# Set dirty writeback timeout
echo " - Setting dirty writeback timeout to 1500 centisecs..."
sysctl -w vm.dirty_writeback_centisecs=1500
echo "vm.dirty_writeback_centisecs = 1500" > /etc/sysctl.d/99-dirty.conf

# Enable Runtime PM for PCI Devices
echo " - Enabling Runtime PM for PCI devices..."
for dev in /sys/bus/pci/devices/*/power/control; do
    echo auto > "$dev"
done

# Enable autosuspend for USB Devices
echo " - Enabling autosuspend for USB devices..."
for dev in /sys/bus/usb/devices/*/power/control; do
    echo auto > "$dev"
done

# Disable Unwanted ACPI Wakeup Devices
WAKE_DEVICES=(XHC EHC1 EHC2 LID0)
echo " - Disabling unwanted ACPI wakeup devices..."
for dev in "${WAKE_DEVICES[@]}"; do
    grep -q "$dev" /proc/acpi/wakeup && echo "$dev" > /proc/acpi/wakeup
done

echo "[✓] Power tweaks applied."
EOF

sudo chmod +x "$POWER_SCRIPT"

# 2. Create the systemd service unit
SERVICE_FILE="/etc/systemd/system/linux-power-tweaks.service"

cat << EOF | sudo tee "$SERVICE_FILE" > /dev/null
[Unit]
Description=Linux Power Tweaks - Runtime PM, NMI, Writeback, ACPI
After=multi-user.target

[Service]
Type=oneshot
ExecStart=$POWER_SCRIPT
RemainAfterExit=true

[Install]
WantedBy=multi-user.target
EOF

# 3. Reload systemd, enable and start the service
echo "🔁 Enabling and starting service..."
sudo systemctl daemon-reexec
sudo systemctl daemon-reload
sudo systemctl enable --now linux-power-tweaks.service

echo "✅ Linux Power Tweaks installed and activated!"
