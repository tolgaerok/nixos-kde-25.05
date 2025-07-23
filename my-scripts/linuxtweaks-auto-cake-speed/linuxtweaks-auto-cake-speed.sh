#!/bin/bash
# tolga erok
# 14/5/2025

# ref:  https://www.bufferbloat.net/projects/codel/wiki/Cake/
# ref:  https://openwrt.org/docs/guide-user/network/traffic-shaping/sqm
# ref:  https://man7.org/linux/man-pages/man8/tc-cake.8.html

# Color
YELLOW="\033[1;33m"
BLUE="\033[0;34m"
RED="\033[0;31m"
GREEN="\033[1;32m"
NC="\033[0m"
clear

# check if speedtest-cli is installed
echo -e "${BLUE} Checking for speedtest-cli...${NC}"
echo -e "${YELLOW} ──────────────────────────────────${NC}"
if ! command -v speedtest-cli &> /dev/null; then
    echo -e "${YELLOW} Installing speedtest-cli...${NC}"
    yes | sudo dnf install -y speedtest-cli
else
    echo -e "${GREEN} speedtest-cli is already installed.${NC}"
fi

# retrieve speedtest results
get_speedtest_results() {
    echo -e "\n${BLUE} Running speed test...${NC}"
    result=$(speedtest-cli --simple)

    if [ $? -ne 0 ]; then
        echo -e "${RED} Failed to retrieve speedtest results.${NC}"
        exit 1
    fi

    # get values
    download_speed=$(echo "$result" | grep "Download" | awk '{print $2}')
    upload_speed=$(echo "$result" | grep "Upload" | awk '{print $2}')
    ping_latency=$(echo "$result" | grep "Ping" | awk '{print $2}')

    echo -e "\n${YELLOW} Speedtest Results (RAW with no 5% buffer):${NC}"
    echo -e "${YELLOW} ─────────────────────────────────────────────${NC}"
    echo -e "${GREEN} Download Speed:${NC} ${download_speed} Mbit/s"
    echo -e "${GREEN} Upload Speed:  ${NC} ${upload_speed} Mbit/s"
    echo -e "${GREEN} Ping Latency:  ${NC} ${ping_latency} ms"
}

# Run speedtest and get the values
get_speedtest_results

# Calculate CAKE target bandwidths (5% buffer)
optimal_download=$(echo "$download_speed * 0.95" | bc)
optimal_upload=$(echo "$upload_speed * 0.95" | bc)

# see if CAKE is supported
echo -e "\n${BLUE} Checking CAKE availability in kernel...${NC}"
echo -e "${YELLOW} ───────────────────────────────────────${NC}"
if ! modinfo sch_cake &> /dev/null; then
    echo -e "${RED} Error: CAKE is not available in your kernel.${NC}"
    exit 1
else
    echo -e "${GREEN} CAKE is supported.${NC}"
fi

# detect primary network interface
echo -e "\n${BLUE} Detecting network interface...${NC}"
# echo -e "${YELLOW} ────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────${NC}"
interface=$(ip link | awk -F': ' '/^[0-9]+: (eth|wlp|enp)/ { print $2; exit }')

if [ -z "$interface" ]; then
    echo -e "${RED} Error: No suitable network interface found.${NC}"
    exit 1
fi

echo -e "${GREEN} Using interface:${NC} ${interface}"
echo -e "${YELLOW} ───────────────────────────────${NC}"

# Summary
echo -e "\n${GREEN} Optimal CAKE Settings with 5% buffer:${NC}"
echo -e "${YELLOW} ─────────────────────────────────────────────${NC}"
echo -e "${GREEN} Download:${NC} ${optimal_download} Mbps"
echo -e "${GREEN} Upload:  ${NC} ${optimal_upload} Mbps"
echo -e "${GREEN} RTT:     ${NC} ${ping_latency} ms"
#echo -e "${YELLOW} ────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────${NC}\n"
# Apply CAKE settings (echoed, not run)
echo -e "\n${BLUE} Applying optimal CAKE settings (simulated)...with 5% buffer:${NC}"
echo -e "${YELLOW} ───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────${NC}"
echo -e "${YELLOW} Tweaked cmd:${NC} sudo tc qdisc replace dev $interface root cake bandwidth ${optimal_download}Mbit diffserv4 triple-isolate nat nowash ack-filter split-gso rtt ${ping_latency}ms overhead 44"
echo ""
