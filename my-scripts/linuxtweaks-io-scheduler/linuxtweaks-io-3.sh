#!/usr/bin/env bash
# tolga erok
# 23/5/25

# ────────────────────────────────────────────────
# LinuxTweaks custom io-scheduler script setup
# ────────────────────────────────────────────────
set -euo pipefail
IFS=$'\n\t'

clear

# check for user's home directory safely
if [ -n "${SUDO_USER:-}" ]; then
    user_home=$(eval echo "~$SUDO_USER")
else
    user_home="$HOME"
fi

# log file
log_file="$user_home/yad_install.log"
#mkdir "$log_file"

# log for permission error
if ! touch "$log_file" &>/dev/null; then
    zenity --error --text="Cannot create log file at $log_file. Exiting."
    exit 1
fi

# check for YAD if not install
if ! command -v yad &>/dev/null; then
    echo "Installing yad..." | tee -a "$log_file"

    if command -v dnf &>/dev/null; then
        sudo dnf install -y yad &>>"$log_file" || {
            zenity --error --text="Failed to install yad with dnf. Exiting."
            exit 1
        }
    elif command -v pacman &>/dev/null; then
        sudo pacman -Sy --noconfirm yad &>>"$log_file" || {
            zenity --error --text="Failed to install yad with pacman. Exiting."
            exit 1
        }
    elif command -v apt &>/dev/null; then
        sudo apt update &>>"$log_file"
        sudo apt install -y yad &>>"$log_file" || {
            zenity --error --text="Failed to install yad with apt. Exiting."
            exit 1
        }
    else
        zenity --error --text="Unsupported package manager. Please install yad manually."
        exit 1
    fi
fi

# catch error
error_exit() {
    yad --title="Error" --width=300 --height=100 --text="$1" --button=OK
    exit 1
}

# whats your device (e.g. sda)
DEVICE=$(yad --title="Select Device" --width=400 --height=150 \
    --entry --entry-label="Enter disk device (e.g. sda):" 2>/dev/null)

if [[ -z "$DEVICE" ]]; then
    error_exit "No device entered, exiting."
fi

# does device exists
if [ ! -b "/dev/$DEVICE" ]; then
    error_exit "Device /dev/$DEVICE does not exist, exiting."
fi

# Choose a scheduler
SCHEDULER=$(yad --title="Choose I/O Scheduler" --width=400 --height=200 \
    --list --radiolist --column "Select" --column "Scheduler" \
    TRUE mq-deadline FALSE none FALSE kyber FALSE bfq 2>/dev/null)

if [[ -z "$SCHEDULER" ]]; then
    error_exit "No scheduler selected, exiting."
fi

# BETA--  format: TRUE|mq-deadline or similar - extract scheduler name
SCHEDULER=$(echo "$SCHEDULER" | awk -F'|' '{print $2}')
if [[ -z "$SCHEDULER" ]]; then
    error_exit "Could not parse scheduler selection, exiting."
fi

# Choose
METHOD=$(yad --title="Choose Setup Method" --width=400 --height=150 \
    --list --radiolist --column "Select" --column "Method" \
    TRUE "systemd service" FALSE "udev rule" 2>/dev/null)

if [[ -z "$METHOD" ]]; then
    error_exit "No method selected, exiting."
fi

METHOD=$(echo "$METHOD" | awk -F'|' '{print $2}')
if [[ -z "$METHOD" ]]; then
    error_exit "Could not parse method selection, exiting."
fi

FEEDBACK=""

if [[ "$METHOD" == "systemd service" ]]; then
    # create or overwrite my systemd service file
    SERVICE_FILE="/etc/systemd/system/io-scheduler.service"
    sudo tee "$SERVICE_FILE" >/dev/null <<EOF
[Unit]
Description=LinuxTweaks set I/O Scheduler on boot for /dev/$DEVICE
After=local-fs.target

[Service]
Type=oneshot
ExecStart=/bin/sh -c "echo $SCHEDULER | sudo tee /sys/block/$DEVICE/queue/scheduler"

[Install]
WantedBy=multi-user.target
EOF

    # reload systemd daemon and enable service
    sudo systemctl daemon-reload
    sudo systemctl enable io-scheduler.service
    sudo systemctl start io-scheduler.service

    FEEDBACK="Created systemd service to set scheduler '$SCHEDULER' on /dev/$DEVICE\n
Service file: $SERVICE_FILE\n
Enabled and started io-scheduler.service"

elif [[ "$METHOD" == "udev rule" ]]; then
    # Create udev rule
    RULE_FILE="/etc/udev/rules.d/60-ioscheduler.rules"
    sudo tee "$RULE_FILE" >/dev/null <<EOF
ACTION=="add|change", KERNEL=="$DEVICE", ATTR{queue/scheduler}="$SCHEDULER"
EOF

    # Reload udev rules and trigger for device
    sudo udevadm control --reload-rules
    sudo udevadm trigger --action=add --attr-match=devname="/dev/$DEVICE"
    sudo udevadm trigger

    FEEDBACK="Created udev rule to set scheduler '$SCHEDULER' on /dev/$DEVICE\n
Rule file: $RULE_FILE\n
Reloaded udev rules and triggered device"
else
    error_exit "Unknown method: $METHOD"
fi

# feedback
yad --title="I/O Scheduler Setup Complete" --width=500 --height=250 --text="$FEEDBACK" --button=OK
