#!/bin/bash
# CAKE Bandwidth Calculator Script by LinuxTweaks

# Set default values
RTT_MS=25
OVERHEAD=44
UP_MBIT=19
DOWN_MBIT=60

echo "=== LinuxTweaks CAKE Calculator ==="
echo "Detected/Assumed values:"
echo "  Upstream: ${UP_MBIT} Mbit"
echo "  Downstream: ${DOWN_MBIT} Mbit"
echo "  Overhead: ${OVERHEAD} bytes"
echo "  RTT: ${RTT_MS} ms"

# Calculate qdisc rate settings
UP_BITS=$(echo "$UP_MBIT * 1000000" | bc)
DOWN_BITS=$(echo "$DOWN_MBIT * 1000000" | bc)

# Calculate thresholds
BULK_THRESH=$(echo "$UP_BITS * 0.625 / 1000" | bc)
VIDEO_THRESH=$(echo "$UP_BITS * 0.5 / 1000" | bc)
VOICE_THRESH=$(echo "$UP_BITS * 0.25 / 1000" | bc)

echo
echo "Recommended CAKE qdisc settings:"
echo "  tc qdisc add dev <interface> root cake bandwidth ${UP_MBIT}Mbit diffserv4 triple-isolate ack-filter rtt ${RTT_MS}ms raw overhead ${OVERHEAD}"
echo
echo "Thresholds for Diffserv (approx):"
echo "  Bulk: ${BULK_THRESH} Kbit"
echo "  Video: ${VIDEO_THRESH} Kbit"
echo "  Voice: ${VOICE_THRESH} Kbit"
