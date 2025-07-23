#!/bin/bash
# tolga erok
# 20/5/2025 - updated with After=local-fs.target Scheduler is set system-wide immediately after boot, so all users benefit the performance before login screen.

# ────────────────────────────────────────────────
# linuxtweaks i/o scheduler tool
# ────────────────────────────────────────────────
command -v yad >/dev/null 2>&1 || {
  echo "yad is required but not installed. aborting." >&2
  exit 1
}

service_name="io-scheduler.service"
service_path="/etc/systemd/system/$service_name"

get_block_device() {
  lsblk -ndo NAME,TYPE | grep -E 'disk$' | head -n 1 | awk '{print $1}'
}

get_device_type() {
  cat "/sys/block/$block_device/queue/rotational"
}

get_device_path() {
  echo "/sys/block/$block_device/queue/scheduler"
}

get_available_schedulers() {
  cat "$device_path" | sed 's/[][]//g'
}

get_current_scheduler() {
  cat "$device_path" | tr '[]' '*'
}

show_info() {
  yad --info --title="i/o scheduler info" --width=500 --text="
<b>about this tool:</b>\n\n
linuxtweaks tool manages i/o scheduler settings using a systemd service.\n
your detected primary disk: <b>/dev/$block_device</b>\n
disk type: <b>$([[ "$block_device" == nvme* ]] && echo "nvme" || ([[ "$device_type" == "0" ]] && echo "ssd" || echo "hdd"))</b>\n
current scheduler: <b>$current_scheduler</b>\n
recommended: <b>$default_scheduler</b>\n\n
you can change to any of the supported schedulers:\n<tt>$available_schedulers</tt>
"
}

choose_scheduler() {
  yad --list --title="select scheduler" --width=300 --height=220 --column="available schedulers" \
    $(for i in $available_schedulers; do echo "$i"; done) \
    --text="select i/o scheduler for /dev/$block_device" --button=ok:0 --button=cancel:1 | awk -F'|' '{print $1}'
}

install_service() {
  selected=$(choose_scheduler)
  [[ -z "$selected" ]] && selected="$default_scheduler"

  pkexec bash -c "cat > '$service_path' <<'EOF'
[Unit]
Description=Set I/O Scheduler on boot
DefaultDependencies=no
After=local-fs.target

[Service]
Type=oneshot
ExecStart=/bin/bash -c 'echo $selected > $device_path'

[Install]
WantedBy=multi-user.target
EOF"

  pkexec systemctl daemon-reexec
  pkexec systemctl enable "$service_name"
  pkexec systemctl start "$service_name" &&
    yad --info --text="✅ service installed and started with scheduler: <b>$selected</b>\ndevice: /dev/$block_device"
}

uninstall_service() {
  pkexec systemctl stop "$service_name"
  pkexec systemctl disable "$service_name"
  pkexec rm -f "$service_path"
  pkexec systemctl daemon-reexec

  yad --info --text="🗑️ service removed."
}

show_status() {
  status=$(systemctl is-active "$service_name" 2>/dev/null || echo "not running")
  enabled=$(systemctl is-enabled "$service_name" 2>/dev/null || echo "not enabled")
  current_scheduler=$(get_current_scheduler)

  yad --info --text="📊 <b>service status:</b>\nactive: $status\nenabled: $enabled\n\n<b>device:</b> /dev/$block_device\nscheduler: $current_scheduler"
}

# ────────────────────────────────────────────────
# main loop
# ────────────────────────────────────────────────
while true; do
  block_device=$(get_block_device)
  device_path=$(get_device_path)
  [[ ! -e "$device_path" ]] && yad --error --text="error: device path not found" && exit 1

  device_type=$(get_device_type)

  if [[ "$block_device" == nvme* ]]; then
    default_scheduler="none"
  elif [[ "$device_type" == "0" ]]; then
    default_scheduler="mq-deadline"
  else
    default_scheduler="mq-deadline"
  fi

  available_schedulers=$(get_available_schedulers)
  current_scheduler=$(get_current_scheduler)

  action=$(yad --width=400 --height=350 --center --title="i/o scheduler control" \
    --text="<b>primary device:</b> /dev/$block_device\n<b>recommended scheduler:</b> $default_scheduler\n<b>current:</b> $current_scheduler" \
    --button="install + set scheduler:0" \
    --button="start service:1" \
    --button="restart service:2" \
    --button="show status:3" \
    --button="uninstall:4" \
    --button="about:5" \
    --button="exit:6")

  case $? in
  0) install_service ;;
  1) pkexec systemctl start "$service_name" && yad --info --text="🚀 service started." ;;
  2) pkexec systemctl restart "$service_name" && yad --info --text="🔁 service restarted." ;;
  3) show_status ;;
  4) uninstall_service ;;
  5) show_info ;;
  6) yad --info --text="🙏 thank you for using linuxtweaks i/o scheduler." && break ;;
  esac
done
