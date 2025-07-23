#!/usr/bin/env bash

# Metadata
# ----------------------------------------------------------------------------
# AUTHOR="Tolga Erok"
# VERSION="V10"
# DATE_CREATED="18/3/2025"

# ----------------------------------------------------------------------------
# BUG_FIX="15/4/2025" : Typo error on creating wake service
# BUG_FIX="16/4/2025" : fixed detecting package manager more rebust
# BUG_FIX="13/5/2025" : fixed detecting dev, interface and code enchancement
# ----------------------------------------------------------------------------

# Description: Systemd script to force CAKE onto any active network interface.
# REF: https://www.bufferbloat.net/projects/codel/wiki/Cake/


YELLOW="\033[1;33m"
GREEN='\e[1;32m'
BLUE="\033[0;34m"
RED="\033[0;31m"
NC="\033[0m"
clear

# which package manager and set install command for `tc`
if command -v dnf &>/dev/null; then
    INSTALL_CMD="sudo dnf install -y iproute-tc"
elif command -v pacman &>/dev/null; then
    INSTALL_CMD="sudo pacman -Sy --needed iproute2"
else
    echo -e "${RED}❌ Unsupported distribution. Exiting...${NC}"
    exit 1
fi

# check for `tc` command - install if itsmissing
if ! command -v tc &>/dev/null; then
    echo -e "${YELLOW}───────────────────────────────────────────────────────────────${NC}"
    echo -e "${YELLOW}⚠️  'tc' command not found. Installing required package...${NC}"
    echo -e "${YELLOW}───────────────────────────────────────────────────────────────${NC}\n"
    if $INSTALL_CMD; then
        echo -e "${YELLOW}───────────────────────────────────────────────────────────────${NC}"
        echo -e "${GREEN}✅ 'tc' installed successfully.${NC}"
        echo -e "${YELLOW}───────────────────────────────────────────────────────────────${NC}\n"
        hash -r
    else
        echo -e "${YELLOW}───────────────────────────────────────────────────────────────${NC}"
        echo -e "${RED}❌ Failed to install 'tc'. Please install it manually.${NC}"
        echo -e "${YELLOW}───────────────────────────────────────────────────────────────${NC}\n"
        exit 1
    fi
else
    echo -e "${YELLOW}───────────────────────────────────────────────────────────────${NC}"
    echo -e "${GREEN}✅ 'tc' is already installed.${NC}"
    echo -e "${YELLOW}───────────────────────────────────────────────────────────────${NC}"
fi

# detect tc path
TC_PATH=$(command -v tc)
if [ -z "$TC_PATH" ]; then
    echo -e "${RED}Failed to find tc after installation. Exiting.${NC}"
    echo -e "${YELLOW}───────────────────────────────────────────────────────────────────────────────────${NC}\n"
    exit 1
fi

# detect active network interface
interface=$(ip -o link show | awk -F': ' '
$2 ~ /wlp|wlo|wlx|eth|eno/ && /UP/ && !/NO-CARRIER/ {print $2; exit}')

if [ -z "$interface" ]; then
    echo -e "${YELLOW}───────────────────────────────────────────────────────────────────────────────────${NC}"
    echo -e "${RED}No active network interface found. Exiting.${NC}"
    echo -e "${YELLOW}───────────────────────────────────────────────────────────────────────────────────${NC}\n"
    exit 1
fi

echo -e "\n${YELLOW}───────────────────────────────────────────────────────────────────────────────────${NC}"
echo -e "${BLUE}Detected active network interface: ${interface}${NC}"

# Systemd service names
service_name="linuxtweaks-cake.service"
service_file="/etc/systemd/system/$service_name"
service_name2="linuxtweaks-cake-resume.service"
service_file2="/etc/systemd/system/$service_name2"

# Create systemd service for CAKE at boot
echo -e "${BLUE}Creating systemd service file at ${service_file}...${NC}"
sudo bash -c "cat > $service_file" <<EOF
[Unit]
Description=Tolga's V10.0 CAKE qdisc for $interface at boot
After=network-online.target
Wants=network-online.target

[Service]
Type=oneshot
ExecStart=/bin/bash -c 'interface=\$(ip link show | awk -F: '\''\$0 ~ \"wlp|wlo|wlx\" && \$0 !~ \"NO-CARRIER\" {gsub(/^[ \t]+|[ \t]+$/, \"\", \$2); print \$2; exit}'\''); if [ -n \"\$interface\" ]; then sudo tc qdisc replace dev \$interface root cake bandwidth 21Mbit diffserv4 triple-isolate nat nowash ack-filter split-gso rtt 25ms overhead 44; fi'
RemainAfterExit=yes

Environment=SYSTEMD_SLEEP_FREEZE_USER_SESSIONS=0

# Watchdog & safety
TimeoutStartSec=10min
TimeoutStopSec=10s
TimeoutStopFailureMode=kill

StandardError=journal
StandardOutput=journal
SuccessExitStatus=0 3
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

# Create systemd service for suspend/wake with dynamic interface name
echo -e "${BLUE}Creating systemd service file at ${service_file2}...${NC}"
sudo bash -c "cat > $service_file2" <<EOF
[Unit]
Description=Tolga's V10.0 CAKE qdisc after suspend/wake for $interface
After=network-online.target suspend.target
Wants=network-online.target

[Service]
Type=oneshot
ExecStart=/bin/bash -c 'iface=\$(ip -o link show | awk -F: '\''/wlp|wlo|wlx/ && \$2 !~ /NO-CARRIER/ {gsub(/^[ \t]+|[ \t]+$/, "", \$2); print \$2; exit}'\''); \
if [ -n "\$iface" ]; then \
  /usr/sbin/tc qdisc replace dev "\$iface" root cake bandwidth 21Mbit diffserv4 triple-isolate nat nowash ack-filter split-gso rtt 25ms overhead 44; \
fi'

RemainAfterExit=yes
Environment=SYSTEMD_SLEEP_FREEZE_USER_SESSIONS=0

# Watchdog & safety
TimeoutStartSec=10min
TimeoutStopSec=10s
TimeoutStopFailureMode=kill

StandardError=journal
StandardOutput=journal
SuccessExitStatus=0 3
Restart=on-failure

[Install]
WantedBy=suspend.target
EOF

# Systemd service names
service_name="linuxtweaks-cake.service"
service_name2="linuxtweaks-cake-resume.service"

# Reload systemd and enable services
echo -e "\n${YELLOW}───────────────────────────────────────────────────────────────────────────────────${NC}"
echo -e "${BLUE}Reloading systemd daemon and enabling services...${NC}"
sudo systemctl daemon-reload
sudo systemctl enable --now "$service_name"
sudo systemctl enable --now "$service_name2"

# Restart the services, adding restart on failure logic
sudo systemctl restart "$service_name"
sudo systemctl restart "$service_name2"

sudo systemctl daemon-reexec && sudo systemctl daemon-reload && sudo systemctl reenable linuxtweaks-cake.service && sudo systemctl restart linuxtweaks-cake.service && systemctl status linuxtweaks-cake.service


echo -e "${BLUE}Verifying qdisc configuration for ${interface}:${NC}"
echo -e "${GREEN}───────────────────────────────────────────────────────────────────────────────────${NC}\n"
sudo tc -s qdisc show dev "$interface" | grep -A50 -i cake | grep -B2 -A30 -Ei 'cake|bulk|effort|video|voice'

# List enabled unit files with 'cake' in the name
echo -e "${YELLOW}───────────────────────────────────────────────────────────────────────────────────${NC}"
systemctl list-unit-files | grep cake
echo -e "${YELLOW}───────────────────────────────────────────────────────────────────────────────────${NC}"
