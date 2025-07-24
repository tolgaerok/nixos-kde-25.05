#!/run/current-system/sw/bin/bash
export PATH=/run/current-system/sw/bin:$PATH


/run/current-system/sw/bin/notify-send "" "🌐 ☀️ Checking for flatpak cruft" --app-name="🔧  Flatpak Maintenance" -i /etc/nixos/flatpaks/LinuxTweak.png -u NORMAL
/run/current-system/sw/bin/flatpak --system uninstall --unused -y --noninteractive

sleep 5

/run/current-system/sw/bin/notify-send "" "📡  Checking for flatpak UPDATES" --app-name="📡  Flatpak Updater" -i /etc/nixos/flatpaks/LinuxTweak.png -u NORMAL
/run/current-system/sw/bin/flatpak update -y --noninteractive

sleep 5

/run/current-system/sw/bin/notify-send "" "💻  Checking and repairing Flatpaks" --app-name="🔧  Flatpak Repair Service" -i /etc/nixos/flatpaks/LinuxTweak.png -u NORMAL
/run/current-system/sw/bin/flatpak repair

sleep 5

/run/current-system/sw/bin/notify-send "Flatpaks checked, fixed and updated" "✅  Your computer is ready!" --app-name="💻  Flatpak Update Service" -i /etc/nixos/flatpaks/LinuxTweak.png -u NORMAL
