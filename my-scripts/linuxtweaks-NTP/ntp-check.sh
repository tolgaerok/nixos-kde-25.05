#!/bin/bash
set -euo pipefail

RED='\033[1;31m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
BLUE='\033[1;34m'
NC='\033[0m'
clear

echo -e "${BLUE}👋 Starting LinuxTweaks NTP Auto-Check Setup...${NC}"

# Create service file
sudo tee /etc/systemd/system/ntp-check.service > /dev/null <<EOF
[Unit]
Description=Auto-enables NTP if disabled
After=network.target

[Service]
Type=oneshot
ExecStart=/usr/bin/timedatectl set-ntp true
RemainAfterExit=true

[Install]
WantedBy=multi-user.target
EOF
echo -e "${GREEN}Created ntp-check.service${NC}"

# Create timer file
sudo tee /etc/systemd/system/ntp-check.timer > /dev/null <<EOF
[Unit]
Description=Periodic NTP check and enable

[Timer]
OnBootSec=10sec
OnUnitActiveSec=15min
Persistent=true

[Install]
WantedBy=timers.target
EOF
echo -e "${GREEN}Created ntp-check.timer${NC}"

# Create restart service for resume
sudo tee /etc/systemd/system/ntp-check-timer-restart.service > /dev/null <<EOF
[Unit]
Description=Restart NTP check timer on resume
After=suspend.target

[Service]
Type=oneshot
ExecStart=/bin/systemctl restart ntp-check.timer

[Install]
WantedBy=multi-user.target
EOF
echo -e "${GREEN}Created ntp-check-timer-restart.service${NC}"

# Create system-sleep hook to restart timer after resume
sudo tee /usr/lib/systemd/system-sleep/ntp-check-timer-restart.sh > /dev/null <<'EOF'
#!/bin/bash
case "$1" in
  post)
    /bin/systemctl restart ntp-check.timer
    ;;
esac
EOF

sudo chmod +x /usr/lib/systemd/system-sleep/ntp-check-timer-restart.sh
echo -e "${GREEN}Created system-sleep hook script${NC}"

# Reload systemd daemon
sudo systemctl daemon-reload
echo -e "${GREEN}Reloaded systemd daemon${NC}"

# Enable & start services/timers
sudo systemctl enable --now ntp-check.service ntp-check.timer ntp-check-timer-restart.service
sudo systemctl start ntp-check.timer ntp-check.service ntp-check.timer ntp-check-timer-restart.service
echo -e "${GREEN}Enabled and started services & timer${NC}"

sleep 2

echo -e "\n${YELLOW}NTP Check Service Status:${NC}"
if ! systemctl is-active --quiet ntp-check.service; then
  echo "ntp-check.service is not active"
else
  echo "ntp-check.service is active"
fi

echo -e "\n${YELLOW}NTP Check Timer Status:${NC}"
if ! systemctl list-timers --no-pager | grep -q ntp-check; then
  echo "ntp-check.timer not found"
else
  systemctl list-timers --no-pager | grep ntp-check
fi

echo -e "\n${YELLOW}NTP Check Timer Restarter Service Status:${NC}"
if ! systemctl is-active --quiet ntp-check-timer-restart.service; then
  echo "ntp-check-timer-restart.service is not active"
else
  echo "ntp-check-timer-restart.service is active"
fi

echo -e "\n${GREEN}Setup complete! Your system will check NTP status every 15 minutes.${NC}"
