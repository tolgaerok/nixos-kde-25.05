#!/bin/bash
# Tolga Erok
# 14/5/2025

# systemd to enable all my services

# ------------------------------------
# Colours
# ------------------------------------
RED='\e[1;31m'
GREEN='\e[1;32m'
YELLOW='\e[1;33m'
BLUE='\e[1;34m'
CYAN='\e[1;34m'
NC='\e[0m'
RESET="\033[0m"

# ------------------------------------
# Icons (using Unicode symbols)
# ------------------------------------
icon_FIREWALL="🛡️"
icon_SERVICE="⚙️"
icon_PORT="🌐"
icon_MULTICAST="🔊"
icon_FORWARD="🔁"
icon_STATUS="✅"
icon_WARNING="⚠️"
clear

check_service_status() {
    local service="$1"
    local label="${2:-$service}"  # optional custom label

    if [[ "$service" == "wsdd-sleep.service" ]]; then
        if systemctl is-enabled --quiet "$service"; then
            echo -e "${GREEN}    ✔ ${NC} ${YELLOW}${label} is ${NC}${GREEN}enabled (oneshot service)${NC}"
        else
            echo -e "${RED}✖ ${label} is not enabled${NC}"
        fi
    else
        if systemctl is-active --quiet "$service"; then
            echo -e "${GREEN}    ✔ ${NC} ${YELLOW}${label} is ${NC}${GREEN}running${NC}"
        else
            echo -e "${RED}✖ ${label} failed to start${NC}"
        fi
    fi
}

# -------------------------------------------------------------------
# systemd service file
# -------------------------------------------------------------------
service_dir="/etc/systemd/system/linuxTweaks-autostart.service"

# -------------------------------------------------------------------
# clean up the logs
# -------------------------------------------------------------------
echo -e "${YELLOW}\n ─── Clean Up Logs  ────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────${NC}"
journalctl --rotate
journalctl --vacuum-time=1s
echo -e "${YELLOW} ───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────${NC}\n"

# -------------------------------------------------------------------
# systemd service file
# -------------------------------------------------------------------
cat << EOF > $service_dir
[Service]
Type=oneshot
RemainAfterExit=true
Restart=on-failure
RestartSec=5

# Enable LinuxTweaks services
ExecStartPre=/bin/sh -c '/bin/systemctl enable linuxtweaks-cake-resume.service || true'
ExecStartPre=/bin/sh -c '/bin/systemctl enable linuxtweaks-cake.service || true'
ExecStartPre=/bin/sh -c '/bin/systemctl enable nmb.service || true'
ExecStartPre=/bin/sh -c '/bin/systemctl enable ntp-check.service || true'
ExecStartPre=/bin/sh -c '/bin/systemctl enable ntp-check.timer || true'
ExecStartPre=/bin/sh -c '/bin/systemctl enable preload.service || true'
ExecStartPre=/bin/sh -c '/bin/systemctl enable smb.service || true'
ExecStartPre=/bin/sh -c '/bin/systemctl enable wsdd-sleep.service || true'
ExecStartPre=/bin/sh -c '/bin/systemctl enable wsdd-starter.service || true'
ExecStartPre=/bin/sh -c '/bin/systemctl enable wsdd.service || true'

# Start LinuxTweaks services
ExecStart=/bin/systemctl start smb.service nmb.service linuxtweaks-cake.service linuxtweaks-cake-resume.service ntp-check.service ntp-check.timer preload.service wsdd.service wsdd-sleep.service wsdd-starter.service

[Install]
WantedBy=multi-user.target
EOF

# -------------------------------------------------------------------
# success message
# -------------------------------------------------------------------
echo -e "${BLUE}\n ─── Systemd Creeation  ─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────${NC}"
echo "Systemd service file created at $service_dir"

# -------------------------------------------------------------------
# Reload systemd
# -------------------------------------------------------------------
echo "Reloading systemd daemon..."
sudo systemctl daemon-reexec
sudo systemctl daemon-reload

# -------------------------------------------------------------------
# Enable and start the service
# -------------------------------------------------------------------
echo "Enabling and starting the service..."
sudo systemctl enable linuxTweaks-autostart.service
sudo systemctl start linuxTweaks-autostart.service

# -------------------------------------------------------------------
# Check the service status
# -------------------------------------------------------------------
echo -e "${BLUE}\n ─── Checking the status of linuxTweaks-autostart.service  ─────────────────────────────────────────────────────────────────────────────────────────────────────────────${NC}"
sudo systemctl status linuxTweaks-autostart.service
echo -e "${BLUE} ───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────${NC}\n"

echo -e "${BLUE}\n Service Status Check:${NC}"
echo -e "${YELLOW} ────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────${NC}"
check_service_status linuxTweaks-autostart.service "LinuxTweaks Autostart service"
check_service_status linuxtweaks-cake-resume.service "LinuxTweaks CAKE Resume service"
check_service_status linuxtweaks-cake.service "LinuxTweaks CAKE service"
check_service_status nmb.service "NMB service"
check_service_status ntp-check.service "NTP Check service"
check_service_status ntp-check.timer "NTP Check timer (triggers ntp-check.service)"
check_service_status preload.service "Preload service"
check_service_status smb.service "SMB service"
check_service_status wsdd-sleep.service "WSDD-Sleep service"
check_service_status wsdd-starter.service "WSDD-restarter service"
check_service_status wsdd.service "WSDD service"
echo -e "${YELLOW} ───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────${NC}\n"

# -------------------------------------------------------------------
# View logs
# -------------------------------------------------------------------
echo "View logs for any issues with the service:"
journalctl -u linuxTweaks-autostart.service
