#!/run/current-system/sw/bin/sh
# Tolga Erok

# ────────── ENVIRONMENT SETUP ──────────
export PATH="/run/current-system/sw/bin:$PATH"

# ────────── RAM + ZRAM + TMPFS INFO ──────────
RAM_INSTALLED=$(free -h | awk '/^Mem/ {print $2}')
RAM_USED=$(free -h | awk '/^Mem/ {print $3}')
TMPFS_USED=$(df -h)
# ZRAMSWAP_USED=$(zramctl | grep /dev/zram0 | awk '{print $4}')
ZRAM_DEVICE=$(find /sys/block/ -maxdepth 1 -name "zram*" | head -n1)

if [[ -n "$ZRAM_DEVICE" && -f "$ZRAM_DEVICE/mm_stat" ]]; then
    ZRAM_USED=$(awk '{printf "%.1f MB", $3/1024/1024}' "$ZRAM_DEVICE/mm_stat")
    ZRAMSWAP_USED="$ZRAM_USED"
else
    ZRAMSWAP_USED="Not Configured"
fi

# ────────── EARLYOOM STATUS DETECTION ──────────
earlyoom_units=(
    earlyoom.service
    nixos-earlyoom.service
    system-earlyoom.service
)

EARLYOOM_USED="Not Running"
for unit in "${earlyoom_units[@]}"; do
    if systemctl list-units --all --full | grep -q "^$unit"; then
        if systemctl is-active --quiet "$unit"; then
            EARLYOOM_USED="Running ($unit)"
        else
            EARLYOOM_USED="Installed but not active ($unit)"
        fi
        break
    fi
done

# Fallback
if [ "$EARLYOOM_USED" = "Not Running" ] && pgrep -x earlyoom >/dev/null; then
    EARLYOOM_USED="Running (process only)"
fi

# ────────── FLATHUB STATUS DETECTION ──────────
if systemctl is-enabled flatpak-repo.service >/dev/null 2>&1; then
    FLATHUB_LOADED="\e[32mLoaded\e[0m"
else
    FLATHUB_LOADED="\e[33mNot Loaded\e[0m"
fi

if systemctl is-active --quiet flatpak-repo.service; then
    FLATHUB_ACTIVE="\e[32mActive\e[0m"
else
    FLATHUB_ACTIVE="\e[33mInactive\e[0m"
fi

# ────────── SYSCTL TWEAKS ──────────
stdbuf -o0 printf ""
echo -e "\e[1;32m[✔]\e[0m Restarting kernel tweaks...\n"
sudo sysctl --system

# ────────── SYSTEM OUTPUT ──────────
printf "\n\e[33mRAM Installed:         \e[0m\e[34m%s\e[0m\n" "$RAM_INSTALLED"
printf "\e[33mRAM Used:              \e[0m\e[34m%s\e[0m\n" "$RAM_USED"
printf "\n\e[33mDisk + TMPFS Usage:    \e[0m\n\e[34m%s\e[0m\n\n" "$TMPFS_USED"
printf "\e[33mZRAMSWAP Used:         \e[0m\e[34m%s\e[0m\n" " $ZRAMSWAP_USED"
printf "\e[33mEarlyOOM Status:       \e[0m\e[34m%s\e[0m\n" " $EARLYOOM_USED"

# EarlyOOM service
earlyoom_unit="earlyoom.service"
if systemctl is-active --quiet "$earlyoom_unit"; then
    echo -e "\e[33mEarlyOOM Service:       \e[0m\e[32mRunning ($earlyoom_unit)\e[0m"
    elif systemctl list-unit-files | grep -q "^$earlyoom_unit"; then
    echo -e "\e[33mEarlyOOM Service:       \e[0m\e[33mInstalled but not active ($earlyoom_unit)\e[0m"
else
    echo -e "\e[33mEarlyOOM Service:       \e[0m\e[31mNot Installed\e[0m"
fi

printf "\e[33mFlathub Service Status:\e[0m %b / %b\n" "$FLATHUB_ACTIVE" "$FLATHUB_LOADED"
printf "\e[33mFlathub Repo Status:   \e[0m%b\n" " $FLATHUB_LOADED"


# ────────── FILESYSTEM OVERVIEW ──────────
# echo -e "\n\e[33mFilesystem Overview:\e[0m"
# duf

# ────────── UDEV RULES ──────────
echo -e "\n\e[33m────────── Reloading udev rules ──────────\e[0m"
udevadm control --reload-rules
udevadm trigger --action=add
udevadm trigger --subsystem-match=usb --verbose
udevadm trigger

# ────────── I/O SCHEDULER ──────────
echo -e "\n\e[33mCurrent I/O Scheduler for sda:\e[0m"
scheds=$(cat /sys/block/sda/queue/scheduler)
green=$'\e[32m'
reset=$'\e[0m'
echo "$scheds" | sed -E "s/\[([^]]+)\]/[$green\1$reset]/"

echo -e "\n\e[33mAll Block Devices - Rotation + Scheduler:\e[0m"
lsblk -d -o NAME,ROTA,SCHED

# ────────── FINAL MESSAGE ──────────
figlet system updated

LAST_REBUILD=$(stat -c %y /nix/var/nix/profiles/system | cut -d'.' -f1)
echo -e "\n\e[33m─────── Last nixos-rebuild switch: $LAST_REBUILD ───────\e[0m"


