{ config, pkgs, lib, ... }:

# -----------------------------------------------------------
# My personal wifi restarter after resume - fuck knows why
# -----------------------------------------------------------

let
  resumeScript = pkgs.writeShellScript "nm-resume-repair" ''
    set -e

    export PATH=${
      lib.makeBinPath [
        pkgs.coreutils
        pkgs.gawk
        pkgs.kmod
        pkgs.networkmanager
        pkgs.procps
        pkgs.systemd
        pkgs.util-linux
        pkgs.libnotify
      ]
    }

    echo ""
    echo "  [🔁] Resume hook triggered at $(date)"

    IFACE=$(nmcli device status | awk '$2=="wifi" {print $1}' | head -n1)

    if [ -z "$IFACE" ]; then
      echo "  [-] No Wi-Fi interface detected"
      exit 0
    fi

    DRIVER=$(basename "$(readlink -f /sys/class/net/$IFACE/device/driver)")

    if [ -z "$DRIVER" ]; then
      echo "[-] Could not determine Wi-Fi driver"
      exit 0
    fi

    # echo ""
    echo "  [✳️ ] Reloading Wi-Fi driver: $DRIVER"
    modprobe -r "$DRIVER" || true
    sleep 2
    modprobe "$DRIVER" || true

    echo "  [✳️ ] Restarting NetworkManager"
    systemctl restart NetworkManager || true

    echo "  [✓] Network resume fix complete, brother"
    echo ""

    # KDE Plasma-aware notify-send
    USER_ID=$(loginctl list-users | awk 'NR==2 {print $1}') # get first logged in user UID
    USER_NAME=$(id -nu "$USER_ID") || exit 0

    export DISPLAY=:0
    export XDG_RUNTIME_DIR="/run/user/$USER_ID"

    if command -v notify-send >/dev/null 2>&1; then
      runuser -u "$USER_NAME" -- env DISPLAY=$DISPLAY XDG_RUNTIME_DIR=$XDG_RUNTIME_DIR notify-send "WiFi Restarting.." "✅  wifi is ready!" --app-name="💻  HOOK has run" -i /etc/nixos/flatpaks/LinuxTweak.png -u NORMAL
      
    fi
  '';
in {

  imports = [
    # ./networkmanager.nix

  ];

  environment.etc."nm-resume-repair".source = resumeScript;

  # ✳️ Ensure resume.target is active and part of systemd dependency graph
  #systemd.targets.resume = {
  #  description = "Resume from suspend/hibernate";
  #  wantedBy = [ "multi-user.target" ];
  #};

  # 🔁 Service to run after resume
  #systemd.services.networkmanager-resume = {
  #  description = "Reload Wi-Fi driver and restart NetworkManager after suspend-resume";
  #  after = [ "suspend.target" "hibernate.target" "hybrid-sleep.target" ];
  #  wantedBy = [ "resume.target" ];
  #  serviceConfig = {
  #    Type = "oneshot";
  #    ExecStart = "/etc/nm-resume-repair";
  #  };
  #};

  # ⚡ Optional: faster laptop resume
  # boot.kernelParams = [ "mem_sleep_default=s2idle" ];

  # 🧼 Avoid startup wait
  systemd.services."NetworkManager-wait-online".enable = lib.mkForce true;
}

# sudo nixos-rebuild switch
# sudo systemctl start networkmanager-resume.service
# journalctl -u networkmanager-resume.service -b

# alias nwr="sudo /etc/nm-resume-repair"
