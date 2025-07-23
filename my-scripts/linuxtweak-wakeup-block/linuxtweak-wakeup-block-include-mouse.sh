#!/bin/bash

set -e

echo "🔧 Creating wakeup filter script..."

cat << 'EOF' | sudo tee /usr/local/bin/disable-wakeups.sh > /dev/null
#!/bin/bash

# Devices to disable via ACPI
for dev in PEG0 GLAN XHC RP07 RP17; do
    echo "$dev" > /proc/acpi/wakeup 2>/dev/null
done

# Find keyboard and mouse USB device IDs
keyboard_mouse_devs=$(libinput list-devices | awk '
  /Device: / {dev=$2}
  /Keyboard:/ && /yes/ {print dev}
  /Mouse:/ && /yes/ {print dev}
')

# Resolve sysfs device paths for them
keep_paths=()
for input_dev in $keyboard_mouse_devs; do
    sys_path=$(udevadm info -q path -n "$input_dev" 2>/dev/null)
    [ -n "$sys_path" ] && keep_paths+=("/sys$sys_path")
done

# Disable USB device wakeups except for keyboard/mouse
for dev in /sys/bus/usb/devices/*/power/wakeup; do
    skip=false
    for keep in "${keep_paths[@]}"; do
        if [[ "$dev" == "$keep"* ]]; then
            skip=true
            break
        fi
    done
    $skip || echo disabled > "$dev"
done
EOF

sudo chmod +x /usr/local/bin/disable-wakeups.sh

echo "✅ Wakeup filter script created."

echo "🔧 Creating systemd service..."

cat << EOF | sudo tee /etc/systemd/system/disable-wakeups.service > /dev/null
[Unit]
Description=Disable unwanted wakeup sources except keyboard/mouse
After=multi-user.target

[Service]
Type=oneshot
ExecStart=/usr/local/bin/disable-wakeups.sh

[Install]
WantedBy=multi-user.target
EOF

echo "✅ Systemd service created."

echo "🔁 Enabling and starting the service..."

sudo systemctl daemon-reexec
sudo systemctl enable --now disable-wakeups.service

echo "✅ Service enabled and started."
