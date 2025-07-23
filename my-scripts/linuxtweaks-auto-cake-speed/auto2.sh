#!/usr/bin/env bash
# Tolga Erok
# 16/5/2025

# LinuxTweaks CAKE Auto Configuration Script using speedtest JSON - Mbit and RTT to auto config CAKE systemD
# Dependencies: speedtest-cli, jq, tc, iproute-tc

GREEN="\033[0;32m"
RED="\033[0;31m"
YELLOW="\033[1;33m"
BLUE="\033[0;34m"
NC="\033[0m"
clear

# --------------------------------------------------------------
# which package manager and set install commands
# --------------------------------------------------------------
if command -v dnf &>/dev/null; then
  INSTALL_CMD="sudo dnf install -y"
  PKG_TC="iproute-tc"
elif command -v pacman &>/dev/null; then
  INSTALL_CMD="sudo pacman -Sy --needed --noconfirm"
  PKG_TC="iproute2"
else
  echo -e "${RED}❌ Unsupported distribution. Exiting...${NC}"
  exit 1
fi

# --------------------------------------------------------------
# array of required commands and packages
# --------------------------------------------------------------
declare -A req_cmds_pkgs=(
  [jq]="jq"
  [speedtest - cli]="speedtest-cli"
  [tc]="$PKG_TC"
)

# --------------------------------------------------------------
# track missing packages
# --------------------------------------------------------------
missing_pkgs=()

# --------------------------------------------------------------
# check add missing packages to list
# --------------------------------------------------------------
for cmd in "${!req_cmds_pkgs[@]}"; do
  if ! command -v "$cmd" &>/dev/null; then
    missing_pkgs+=("${req_cmds_pkgs[$cmd]}")
  fi
done

# ─────────────────────────────────────────────────────────────────────────────
# Show Info and Confirm
# ─────────────────────────────────────────────────────────────────────────────

echo -e "
\033[0;34m╭────────────────────────────────────────────────────────────╮
│          🧠 LinuxTweaks CAKE Auto Configuration            │
╰────────────────────────────────────────────────────────────╯\033[0m

\033[1;33m📡 WHAT THIS SCRIPT DOES:\033[0m

This script automatically sets up \033[0;32mCAKE\033[0m (a smart traffic shaper) for your
upload bandwidth. It's especially useful if your upload slows down
other tasks (video calls, gaming, etc.).

\033[1;33mHOW IT WORKS:\033[0m
  1. Ensures required tools: \033[0;32mspeedtest-cli, jq, tc\033[0m
  2. Detects your active interface: \033[0meth0, wlp2s0, etc
  3. Runs a \033[0;32mspeedtest\033[0m and extracts your upload & ping
  4. Applies \033[1;33m90% upload cap\033[0m to allow headroom
  5. Detects whether you're on \033[0;32mWi-Fi, Ethernet, or LTE\033[0m
  6. Automatically sets overhead based on your connection
  7. Sets up \033[0;32msystemd\033[0m services:
     - At boot to apply CAKE
     - After suspend/resume to re-apply settings

\033[0;32mBENEFITS:\033[0m
  ✅ Upload smoothing at boot & wake
  ✅ Auto detection of interface and overhead
  ✅ Works silently in background after first run
  ✅ Reduced lag, improved real-time performance

\033[1;33mEXAMPLE OUTPUT:\033[0m
  🌐 Interface: wlp2s0
  ⬆️ Upload: 9.21 Mbps → 8.29 Mbps (90%)
  🧮 Overhead: 44 (Wi-Fi)
  🛠️ CAKE applied + systemd services enabled

\033[0;31m💬 Tip:\033[0m You only need to run this ONCE per machine.
"

# need confirmation
read -rp "$(echo -e '\033[0;36m[?] Press ENTER to continue or CTRL+C to cancel...\033[0m')"
clear

# --------------------------------------------------------------
# if missing install them
# --------------------------------------------------------------
if [ ${#missing_pkgs[@]} -gt 0 ]; then
  echo -e "${YELLOW}───────────────────────────────────────────────────────────────${NC}"
  echo -e "${YELLOW}⚠️  Missing dependencies detected: ${missing_pkgs[*]}${NC}"
  echo -e "${YELLOW}Installing missing packages...${NC}"
  echo -e "${YELLOW}───────────────────────────────────────────────────────────────${NC}\n"

  if $INSTALL_CMD "${missing_pkgs[@]}"; then
    echo -e "\n${YELLOW}───────────────────────────────────────────────────────────────${NC}"
    echo -e "${GREEN}✅ Successfully installed missing packages.${NC}"
    echo -e "${YELLOW}───────────────────────────────────────────────────────────────${NC}\n"
    hash -r
  else
    echo -e "${YELLOW}───────────────────────────────────────────────────────────────${NC}"
    echo -e "${RED}❌ Failed to install missing packages. Please install manually.${NC}"
    echo -e "${YELLOW}───────────────────────────────────────────────────────────────${NC}\n"
    exit 1
  fi
else
  echo -e "${GREEN}✅ All dependencies are installed.${NC}"
fi

# --------------------------------------------------------------
# detect tc path
# --------------------------------------------------------------
TC_PATH=$(command -v tc)
if [ -z "$TC_PATH" ]; then
  echo -e "${RED}Failed to find tc after installation. Exiting.${NC}"
  echo -e "${YELLOW}───────────────────────────────────────────────────────────────────────────────────${NC}\n"
  exit 1
fi

# --------------------------------------------------------------
# detect active network interface
# --------------------------------------------------------------
interface=$(ip route get 1.1.1.1 2>/dev/null | awk '{for(i=1;i<=NF;i++) if ($i=="dev") print $(i+1)}')

if [ -z "$interface" ]; then
  echo -e "${YELLOW}───────────────────────────────────────────────────────────────────────────────────${NC}"
  echo -e "${RED}No active network interface found. Exiting.${NC}"
  echo -e "${YELLOW}───────────────────────────────────────────────────────────────────────────────────${NC}\n"
  exit 1
fi

echo ""
echo -e "${YELLOW}──${NC} ${GREEN} Detected active network interface: ${NC}${YELLOW}${interface}${NC}"
echo -e "${YELLOW}──${NC} ${GREEN} Running speedtest package to get data, please WAIT! ... ${NC}\n"

# --------------------------------------------------------------
# Run speedtest and get JSON
# json_output=$(speedtest-cli --json) (BETA)
# --------------------------------------------------------------
json_output=$(timeout 45s speedtest-cli --json 2>/dev/null)
if [[ -z "$json_output" || "$json_output" == "null" ]]; then
  echo -e "${RED}❌ Speedtest failed or timed out. Please check your network.${NC}"
  exit 1
fi

# --------------------------------------------------------------
# Extract download, upload (in bits/s), and ping (in ms) from speedtest
# --------------------------------------------------------------
upload_bps=$(echo "$json_output" | jq '.upload')
download_bps=$(echo "$json_output" | jq '.download')
ping_latency=$(echo "$json_output" | jq '.ping')

# --------------------------------------------------------------
# safety checks
# --------------------------------------------------------------
if [[ -z "$upload_bps" || "$upload_bps" == "null" || -z "$download_bps" || "$download_bps" == "null" ]]; then
  echo "[ERROR] Failed to extract speed values."
  exit 1
fi

# --------------------------------------------------------------
# Convert to Mbit and apply 90% safety margin for UPLOAD
# --------------------------------------------------------------
optimal_upload=$(awk "BEGIN {printf \"%.2f\", $upload_bps * 0.90 / 1000000}")
optimal_download=$(awk "BEGIN {printf \"%.2f\", $download_bps * 0.90 / 1000000}")
ping_latency=$(awk "BEGIN {printf \"%.0f\", $ping_latency}")

echo -e "\n${YELLOW}──${NC} ${GREEN} RAW speedtest results:${NC}"
speedtest-cli --simple

if [[ -z "$interface" ]]; then
  echo "[ERROR] Could not detect active network interface."
  exit 1
fi

# --------------------------------------------------------------
# echo "Active Interface: $interface"
# --------------------------------------------------------------
# Remove existing CAKE qdisc if any
echo -e "${YELLOW}Removing existing qdisc (if any)...${NC}"
sudo tc qdisc del dev "$interface" root 2>/dev/null || echo -e "${BLUE}No previous qdisc found, continuing...${NC}"
# --------------------------------------------------------------

get_overhead() {
  local iface="$1"
  local iface_type

  # --------------------------------------------------------------
  # Check if interface exists
  # --------------------------------------------------------------
  if [[ ! -d /sys/class/net/"$iface" ]]; then
    echo "Error: Interface $iface does not exist."
    exit 1
  fi

  # --------------------------------------------------------------
  # Get interface type
  # --------------------------------------------------------------
  iface_type=$(cat /sys/class/net/"$iface"/type 2>/dev/null)

  # --------------------------------------------------------------
  # Detect WWAN/LTE interfaces by common names or driver presence
  # --------------------------------------------------------------
  if [[ "$iface" =~ ^wwan[0-9]*$ || "$iface" =~ ^wwp[0-9]*$ ]]; then
    echo 94
    return
  fi

  # --------------------------------------------------------------
  # Check if interface is a wireless device (check for wireless directory)
  # --------------------------------------------------------------
  if [[ -d /sys/class/net/"$iface"/wireless ]]; then
    echo 94
    return
  fi

  # --------------------------------------------------------------
  # Ethernet check + PPPoE detection
  # --------------------------------------------------------------
  case "$iface_type" in
  1)
    # --------------------------------------------------------------
    # Check PPPoE (ppp interfaces present)
    # --------------------------------------------------------------
    if ip link show | grep -q ppp; then
      echo 44
    else
      echo 18
    fi
    ;;
  512)
    # loopback, no overhead needed
    echo 0
    ;;
  *)
    # Unknown interface type: default to wifi-like overhead
    echo 94
    ;;
  esac
}

overhead=$(get_overhead "$interface")

# --------------------------------------------------------------
# stats
# --------------------------------------------------------------
if [[ $? -eq 0 ]]; then
  echo -e "\n${YELLOW}──${NC} ${GREEN} CAKE application info calculated at 90% safe buffer rate${NC}"
  echo "  ▪ Interface: $interface"
  # echo "  ▪ Download Bandwidth: ${optimal_download}Mbit"
  echo "  ▪ Upload Bandwidth: ${optimal_upload}Mbit"
  echo "  ▪ RTT: ${ping_latency} ms"
  echo "  ▪ Calculated overhead: ${overhead}bytes"
else
  echo "[ERROR] Failed to apply CAKE."
fi

echo -e "\n${YELLOW}──${NC} ${GREEN} Creating service units, please wait...${NC}\n"

# need confirmation
read -rp "$(echo -e '\033[0;36m[?] Press ENTER to continue or CTRL+C to cancel...\033[0m')"

# --------------------------------------------------------------
# Systemd service names
# --------------------------------------------------------------
service_name="linuxtweaks-cake.service"
service_file="/etc/systemd/system/$service_name"
service_name2="linuxtweaks-cake-resume.service"
service_file2="/etc/systemd/system/$service_name2"

# --------------------------------------------------------------
# saftey check for available varible
# --------------------------------------------------------------
if [[ -z "$optimal_upload" || -z "$ping_latency" || -z "$overhead" ]]; then
  echo -e "${RED}Missing required variables: optimal_upload, ping_latency, or overhead${NC}"
  exit 1
fi

# --------------------------------------------------------------
# Create systemd service for CAKE at boot
# --------------------------------------------------------------
echo -e "${BLUE}Creating systemd service file at ${service_file}...${NC}"
sudo bash -c "cat > \"$service_file\"" <<EOF
[Unit]
Description=Tolga's V10.0 CAKE qdisc for wlp3s0 at boot
After=network-online.target
Wants=network-online.target
ConditionPathExists=/usr/sbin/tc

[Service]
Type=oneshot
RemainAfterExit=yes
Restart=no
StandardOutput=journal
StandardError=journal
Environment=SYSTEMD_SLEEP_FREEZE_USER_SESSIONS=0

# Wait for interface state UP
ExecStartPre=/usr/sbin/modprobe sch_cake
ExecStartPre=/bin/bash -c 'for i in {1..10}; do interface=$(ip -o link show | awk -F": " '"'"'$2 ~ /^(wlp|wlo|wlx|eth|eno)/ && $0 ~ /state UP/ && $0 !~ /NO-CARRIER/ { print $2; exit }'"'"'); [ -n "$interface" ] && break || sleep 1; done'

# Dynamic interface detection and CAKE apply
ExecStart=/bin/bash -c 'for i in {1..5}; do interface=$(ip -o link show | awk -F": " '"'"'$2 ~ /^(wlp|wlo|wlx|eth|eno)/ && $0 ~ /state UP/ && $0 !~ /NO-CARRIER/ { print $2; exit }'"'"'); echo "[$(date +%%T)] Detected interface: $interface"; if [ -n "$interface" ]; then tc qdisc replace dev "$interface" root cake bandwidth ${optimal_upload}Mbit besteffort diffserv4 wash triple-isolate nat ack-filter split-gso rtt ${ping_latency}ms overhead ${overhead} && echo "[$(date +%%T)] CAKE applied successfully." && break; else echo "[$(date +%%T)] No interface up, retrying..."; sleep 2; fi; done'

# Watchdog & safety
TimeoutStartSec=10min
TimeoutStopSec=10s
TimeoutStopFailureMode=kill
SuccessExitStatus=0 3
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

# --------------------------------------------------------------
# Create systemd service for suspend/wake with dynamic interface name
# --------------------------------------------------------------
echo -e "${BLUE}Creating systemd service file at ${service_file2}...${NC}"
sudo bash -c "cat > \"$service_file2\"" <<EOF
[Unit]
Description=Tolga's V10.0 CAKE qdisc after suspend/wake for AUTO-DETECTED interface
After=network-online.target suspend.target sleep.target
Wants=network-online.target
ConditionPathExists=/usr/sbin/tc

[Service]
Type=oneshot
RemainAfterExit=yes
Restart=on-failure
StandardOutput=journal+console
StandardError=journal+console
Environment=SYSTEMD_SLEEP_FREEZE_USER_SESSIONS=0

# Wait for interface state UP
ExecStartPre=/usr/sbin/modprobe sch_cake
ExecStartPre=/bin/bash -c 'for i in {1..10}; do interface=$(ip -o link show | awk -F": " '"'"'$2 ~ /^(wlp|wlo|wlx|eth|eno)/ && $0 ~ /state UP/ && $0 !~ /NO-CARRIER/ { print $2; exit }'"'"'); [ -n "$interface" ] && break || sleep 1; done'

# Dynamic interface detection and CAKE apply
ExecStart=/bin/bash -c 'for i in {1..5}; do interface=$(ip -o link show | awk -F": " '"'"'$2 ~ /^(wlp|wlo|wlx|eth|eno)/ && $0 ~ /state UP/ && $0 !~ /NO-CARRIER/ { print $2; exit }'"'"'); echo "[$(date +%%T)] Detected interface: $interface"; if [ -n "$interface" ]; then tc qdisc replace dev "$interface" root cake bandwidth ${optimal_upload}Mbit besteffort diffserv4 wash triple-isolate nat ack-filter split-gso rtt ${ping_latency}ms overhead ${overhead} && echo "[$(date +%%T)] CAKE applied successfully." && break; else echo "[$(date +%%T)] No interface up, retrying..."; sleep 2; fi; done'

# Watchdog & safety
TimeoutStartSec=10min
TimeoutStopSec=10s
TimeoutStopFailureMode=kill
SuccessExitStatus=0 3

[Install]
WantedBy=suspend.target sleep.target
EOF

# --------------------------------------------------------------
# Reload systemd and enable services
# --------------------------------------------------------------
echo -e "\n${YELLOW}───────────────────────────────────────────────────────────────────────────────────${NC}"
echo -e "${BLUE}Reloading systemd daemon and enabling services...${NC}"
sudo systemctl daemon-reload
sudo systemctl enable --now "$(basename "$service_file")"
sudo systemctl enable --now "$(basename "$service_file2")"

sudo systemctl enable linuxtweaks-cake.service
sudo systemctl enable linuxtweaks-cake-resume.service

# Restart the services
sudo systemctl restart "$(basename "$service_file")"
sudo systemctl restart "$(basename "$service_file2")"

# Detect current interface again for final verification
interface=$(ip -o link show | awk -F": " '$2 ~ /^(wlp|wlo|wlx|eth|eno)/ && $0 ~ /state UP/ && $0 !~ /NO-CARRIER/ { print $2; exit }')
echo -e "${BLUE}Verifying qdisc configuration for ${interface}:${NC}"
echo -e "${GREEN}───────────────────────────────────────────────────────────────────────────────────${NC}\n"
if ! sudo tc -s qdisc show dev "$interface" | grep -A50 -i cake | grep -B2 -A30 -Ei 'cake|bulk|effort|video|voice'; then
  echo -e "${RED}❌ Failed to verify CAKE qdisc. Please check if interface is up or CAKE is supported.${NC}"
fi

echo -e "\n${GREEN}🎉 CAKE configuration applied successfully!${NC}"
echo -e "${YELLOW}──${NC} ${BLUE}Interface :${NC} ${interface}"
echo -e "${YELLOW}──${NC} ${BLUE}Upload    :${NC} ${optimal_upload} Mbit"
echo -e "${YELLOW}──${NC} ${BLUE}RTT       :${NC} ${ping_latency} ms"
echo -e "${YELLOW}──${NC} ${BLUE}Overhead  :${NC} ${overhead} bytes"
echo -e "${YELLOW}──${NC} ${GREEN}✅ Systemd services enabled and running.${NC}\n"

# --------------------------------------------------------------
# List enabled unit files with 'cake' in the name
# --------------------------------------------------------------
echo -e "${YELLOW}───────────────────────────────────────────────────────────────────────────────────${NC}"
systemctl list-unit-files | grep cake
echo ""
echo -e "\n${BLUE}Checking service status:${NC}"
systemctl --no-pager --state=active | grep linuxtweaks-cake

echo -e "${YELLOW}───────────────────────────────────────────────────────────────────────────────────${NC}"
