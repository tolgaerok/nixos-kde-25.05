#!/usr/bin/env bash
# Tolga Erok
# 9/7/25
# MNT checker

RESET="\e[0m"
BOLD="\e[1m"
GREEN="\e[38;5;82m"
YELLOW="\e[38;5;220m"
RED="\e[38;5;196m"
GREY="\e[38;5;245m"
WHITE="\e[97m"

SYMBOL_ACTIVE="🟢"
SYMBOL_INACTIVE="🟡"
SYMBOL_FAILED="🔴"

clear

echo -e "${BOLD}${WHITE}"
echo "┌───────────────────────────────────────────────┐"
echo "│      Linuxtweaks SYSTEMD MNT status checker   │"
echo "└───────────────────────────────────────────────┘"
echo -e "${RESET}"

echo -e "Checking individual unit statuses...\n"

# what i want checked
units=(
    mnt-TEMU_STICK.mount
    mnt-Relationships.mount
    mnt-Relationships.automount
    mnt-QNAP_Public.mount
    mnt-QNAP_Public.automount
)

# go over each unit
for unit in "${units[@]}"; do
    active_state=$(systemctl show -p ActiveState --value "$unit" 2>/dev/null)

    case "$active_state" in
    active)
        printf "${GREEN}%-30s %-10s %s${RESET}\n" "$unit" "[ACTIVE]" "$SYMBOL_ACTIVE"
        ;;
    inactive)
        printf "${YELLOW}%-30s %-10s %s${RESET}\n" "$unit" "[INACTIVE]" "$SYMBOL_INACTIVE"
        ;;
    failed)
        printf "${RED}%-30s %-10s %s${RESET}\n" "$unit" "[FAILED]" "$SYMBOL_FAILED"
        ;;
    *)
        printf "${YELLOW}%-30s %-10s %s${RESET}\n" "$unit" "[UNKNOWN]" "$SYMBOL_INACTIVE"
        ;;
    esac
done

echo ""

# show list-units output just for the mnt lines
echo -e "My full list of systemd units matching 'mnt':"
echo -e "${GREY}─────────────────────────────────────────────────────${RESET}"

systemctl list-units | grep mnt | awk '
{
    unit = $1
    load = $2
    active = $3
    substate = $4

    desc=""
    for (i=5; i<=NF; i++) {
        desc = desc $i " "
    }
    printf "%-40s %-8s %-8s %-10s %s\n", unit, load, active, substate, desc
}' | while read -r line; do
    echo -e "${WHITE}${line}${RESET}"
done

echo -e "${GREY}─────────────────────────────────────────────────────${RESET}"
