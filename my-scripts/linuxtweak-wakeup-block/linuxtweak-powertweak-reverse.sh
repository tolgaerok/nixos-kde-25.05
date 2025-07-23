#!/bin/bash
set -e

echo "🧹 Reverting Linux Power Tweaks..."

# 1. Stop and disable the systemd service
SERVICE_FILE="/etc/systemd/system/linux-power-tweaks.service"
if systemctl is-enabled --quiet linux-power-tweaks.service; then
    echo " - Disabling and stopping systemd service..."
    sudo systemctl disable --now linux-power-tweaks.service
fi

# 2. Remove systemd service and power script
echo " - Removing service and power script..."
sudo rm -f "$SERVICE_FILE"
sudo rm -f /usr/local/bin/linux-power-tweaks.sh

# 3. Remove sysctl tweak files
echo " - Removing sysctl configuration files..."
sudo rm -f /etc/sysctl.d/99-nmi.conf
sudo rm -f /etc/sysctl.d/99-dirty.conf

# 4. Reset runtime PM settings (if needed)
echo " - Resetting Runtime PM settings for PCI devices..."
for dev in /sys/bus/pci/devices/*/power/control; do
    echo "on" | sudo tee "$dev" > /dev/null
done

echo " - Resetting autosuspend for USB devices..."
for dev in /sys/bus/usb/devices/*/power/control; do
    echo "on" | sudo tee "$dev" > /dev/null
done

# 5. Re-enable ACPI wake devices (best-effort)
echo " - Re-enabling common ACPI wake devices..."
WAKE_DEVICES=(XHC EHC1 EHC2 LID0)
for dev in "${WAKE_DEVICES[@]}"; do
    grep -q "$dev" /proc/acpi/wakeup && echo "$dev" | sudo tee /proc/acpi/wakeup > /dev/null
done

# 6. Reload systemd and apply default sysctl settings
echo " - Reloading systemd and applying default sysctl..."
sudo systemctl daemon-reload
sudo sysctl --system

echo "✅ Linux Power Tweaks fully reverted."
