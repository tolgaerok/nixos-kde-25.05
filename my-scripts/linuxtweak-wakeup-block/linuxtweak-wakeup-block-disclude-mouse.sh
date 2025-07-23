#!/bin/bash
set -e

echo "Creating wakeup filter script..."

sudo tee /usr/local/bin/disable-unwanted-wakeups.sh > /dev/null << 'EOF'
#!/bin/bash

# Enable/disable ACPI devices — toggle them to disable wakeup by default
for dev in PEG0 GLAN XHC RP07 RP17; do
    echo "$dev" > /proc/acpi/wakeup 2>/dev/null
done

# Get sysfs paths for keyboard and mouse devices only
keyboard_mouse_sysfs=()

# Get event devices for keyboard and mouse via libinput
keyboard_devices=$(libinput list-devices | awk '/Device:/ {dev=$2} /Keyboard:/ && /yes/ {print dev}')
mouse_devices=$(libinput list-devices | awk '/Device:/ {dev=$2} /Mouse:/ && /yes/ {print dev}')

for dev in $keyboard_devices $mouse_devices; do
    sys_path=$(udevadm info -q path -n "$dev" 2>/dev/null)
    if [[ -n "$sys_path" ]]; then
        keyboard_mouse_sysfs+=("/sys$sys_path")
    fi
done

# Disable wakeup on all USB devices except keyboard/mouse
for wakeup_file in /sys/bus/usb/devices/*/power/wakeup; do
    enabled=false
    for allowed in "${keyboard_mouse_sysfs[@]}"; do
        if [[ "$wakeup_file" == "$allowed"* ]]; then
            enabled=true
            break
        fi
    done
    if $enabled; then
        echo enabled > "$wakeup_file"
    else
        echo disabled > "$wakeup_file"
    fi
done
EOF

sudo chmod +x /usr/local/bin/disable-unwanted-wakeups.sh

echo "Creating systemd service..."

sudo tee /etc/systemd/system/disable-unwanted-wakeups.service > /dev/null << EOF
[Unit]
Description=Disable unwanted wakeup sources except keyboard/mouse
After=multi-user.target

[Service]
Type=oneshot
ExecStart=/usr/local/bin/disable-unwanted-wakeups.sh

[Install]
WantedBy=multi-user.target
EOF

echo "Enabling and starting service..."

sudo systemctl daemon-reexec
sudo systemctl enable --now disable-unwanted-wakeups.service

echo "Done. Keyboard and mouse will wake the PC, other devices will not."
