#!/bin/bash
# tolga erok - 25/5/2025
# NVIDIA systemd service & modeset checker with power state and driver param insights

GREEN="🟢"
YELLOW="🟡"
RED="🔴"
BOLD="\e[1m"
RESET="\e[0m"

SERVICE_NAME="nvidia-persistenced"

print_header() {
  echo -e "\n${BOLD}\033[1;36m🔍 Checking NVIDIA-related systemd services...${RESET}\n"
  printf "%-30s %-15s %-20s\n" "Service" "Enabled" "Active State"
  printf "%-30s %-15s %-20s\n" "-------" "-------" "-------------"
}

nv_status() {
  print_header
  for svc in nvidia-persistenced nvidia-suspend nvidia-resume nvidia-hibernate; do
    # Enabled
    if systemctl is-enabled --quiet "$svc"; then
      enabled="${GREEN}enabled 🟢${RESET}"
    else
      enabled="${YELLOW}disabled 🟡${RESET}"
    fi

    # Active or oneshot idle
    if systemctl is-active --quiet "$svc"; then
      active="${GREEN}active 🟢${RESET}"
    else
      type=$(systemctl show -p Type --value "$svc" 2>/dev/null)
      if [[ $type == "oneshot" ]]; then
        active="\e[1;34moneshot (idle) 📌${RESET}"
      else
        active="${RED}inactive ❌${RESET}"
      fi
    fi

    printf "%-30s %-15b %-20b\n" "$svc" "$enabled" "$active"
  done

  echo -e "\n\033[0;36m📌 'oneshot (idle)' means service runs only during suspend/resume/hibernate events.${RESET}\n"
}

echo -e "${BOLD}📦 NVIDIA Service: ${SERVICE_NAME}${RESET}"

# Detect NVIDIA GPU
if ! lspci | grep -qi nvidia; then
  echo -e "${RED}No NVIDIA GPU detected. Exiting.${RESET}"
  exit 1
else
  echo -e "${GREEN}NVIDIA GPU Detected ✔${RESET}"
fi

# Install service if missing
if ! systemctl list-unit-files | grep -qw "$SERVICE_NAME"; then
  echo -e "${YELLOW}Service not found. Installing...${RESET}"
  sudo dnf install -y nvidia-persistenced
fi

# Enable & start service
sudo systemctl enable --now "$SERVICE_NAME"

# Service status
STATUS=$(systemctl is-active "$SERVICE_NAME")
ENABLED=$(systemctl is-enabled "$SERVICE_NAME" 2>/dev/null)

case $STATUS in
active) echo -e "${GREEN}Service is running${RESET}" ;;
inactive | deactivating) echo -e "${YELLOW}Service is not running${RESET}" ;;
failed) echo -e "${RED}Service failed to start${RESET}" ;;
*) echo -e "${YELLOW}Unknown service state: $STATUS${RESET}" ;;
esac

echo -e "🚦 Startup Status: $ENABLED"

MODSET=$(sudo cat /sys/module/nvidia_drm/parameters/modeset 2>/dev/null || echo "N")

if [[ "$MODSET" =~ [Yy] ]]; then
  echo -e "${GREEN}DRM Modeset: Enabled${RESET}"
else
  echo -e "${YELLOW}DRM Modeset: Disabled or Missing${RESET}"

  if ! grep -q "options nvidia_drm modeset=1" /etc/modprobe.d/nvidia-drm.conf 2>/dev/null; then
    echo -e "${YELLOW}Applying modeset fix...${RESET}"
    echo "options nvidia_drm modeset=1" | sudo tee /etc/modprobe.d/nvidia-drm.conf >/dev/null
    echo -e "${YELLOW}Regenerating initramfs...${RESET}"
    # sudo dracut -f
    sudo dracut -f --kver $(uname -r)
    echo -e "${GREEN}DRM Modeset fix applied. Reboot required.${RESET}"
  else
    echo -e "${YELLOW}Modeset config present. Please reboot.${RESET}"
  fi
fi

# Power states check
echo -e "\n${BOLD}🛌 Power States:${RESET}"
for state in suspend hibernate hybrid-sleep; do
  if systemctl list-units --type=target --all | grep -q "${state}.target"; then
    echo -e "${GREEN}${state^}: Available${RESET}"
  else
    echo -e "${YELLOW}${state^}: Not Supported${RESET}"
  fi
done

# Check suspend/resume errors in logs
if journalctl -k -b | grep -iqE 'nvidia.*(fail|error|resume)'; then
  echo -e "${YELLOW}Check journal logs for NVIDIA suspend/resume warnings${RESET}"
else
  echo -e "${GREEN}No NVIDIA suspend/resume errors detected${RESET}"
fi

nv_status

# Show NVIDIA driver params
echo -e "\n${BOLD}📄 NVIDIA Driver Parameters:${RESET}"
cat /proc/driver/nvidia/params

echo -e "\n${GREEN}✅ System NVIDIA Status: Complete${RESET}"

# Show environment vars relevant to GPU & Wayland
echo -e "\n${BOLD}⚙️ Environment Variables:${RESET}"
echo "GBM_BACKEND=$GBM_BACKEND"
echo "XDG_SESSION_TYPE=$XDG_SESSION_TYPE"
