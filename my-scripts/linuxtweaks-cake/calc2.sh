#!/usr/bin/env bash

# CAKE Bandwidth and Overhead Calculator
# Author: LinuxTweaks
# Purpose: Help you calculate optimal bandwidth and overhead values for CAKE QoS

# ────────────────────────────────────────────────
# Function to convert kbps to CAKE-friendly kbps
adjust_bandwidth() {
  local raw_kbps=$1
  local reduction_pct=$2
  echo $(( raw_kbps * (100 - reduction_pct) / 100 ))
}

# ────────────────────────────────────────────────
# Ask user for connection and interface details
read -rp "Enter your DSL download rate (kbps): " DL_RAW
read -rp "Enter your DSL upload rate (kbps): " UL_RAW
read -rp "Enter reduction % for CAKE (default 5): " REDUCE
read -rp "Enter overhead (default 44 for PPPoE/DSL): " OVERHEAD
read -rp "Enter RTT estimate in ms (default 2): " RTT

# Apply defaults
REDUCE=${REDUCE:-5}
OVERHEAD=${OVERHEAD:-44}
RTT=${RTT:-2}

# Adjust bandwidth
DL_ADJ=$(adjust_bandwidth "$DL_RAW" "$REDUCE")
UL_ADJ=$(adjust_bandwidth "$UL_RAW" "$REDUCE")

# Output results
echo "──────────────────────────────────────────────"
echo "📊 Adjusted CAKE Bandwidth Settings:"
echo "→ Download: $DL_ADJ kbps"
echo "→ Upload: $UL_ADJ kbps"
echo "→ Overhead: ${OVERHEAD} bytes"
echo "→ RTT: ${RTT}ms"
echo "──────────────────────────────────────────────"

# Suggest tc commands
echo "🧠 Suggested 'tc qdisc add' Commands:"
echo "sudo tc qdisc replace dev <your_iface> root cake bandwidth ${UL_ADJ}kbit diffserv4 triple-isolate nat overhead ${OVERHEAD} rtt ${RTT}ms"
echo "sudo tc qdisc replace dev <your_iface> ingress handle ffff:"

echo "✅ Done. Replace <your_iface> with your Wi-Fi or Ethernet interface (e.g., wlp3s0 or eth0)."

