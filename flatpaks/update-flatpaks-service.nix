{ config, pkgs, username, user, ... }:

# -----------------------------
# 🌐 Flatpak Auto Updater After Suspend
# Tolga Erok
# -----------------------------
{
  systemd.services.linuxtweaks-flatpak-auto-update = {
    description = "🛠️ Auto-maintain and update Flatpaks after resume";
    after = [ "suspend.target" "hibernate.target" "hybrid-sleep.target" ];
    wantedBy = [ "resume.target" ];
    serviceConfig = {
      Type = "oneshot";
      User = username;
      Environment = [
        "DISPLAY=:0"
        "DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/1000/bus"
        "XDG_RUNTIME_DIR=/run/user/1000"
      ];
      ExecStart = "/etc/nixos/flatpaks/linuxtweaks-flatpak-update.sh";
      TimeoutStopFailureMode = "abort";
    };
  };

  systemd.timers.linuxtweaks-flatpak = {
    description =
      "⏱️ Run LinuxTweaks Flatpak Update every 6 hours after boot, idle or wake";
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnBootSec = "1min";
      OnUnitActiveSec = "6h";
      OnUnitInactiveSec = "1h";
      RandomizedDelaySec = "5min";
      Unit = "linuxtweaks-flatpak-auto-update.service";
      Persistent = true;
      # WakeSystem = true;
    };
    unitConfig = { ConditionACPower = true; };
  };
}

# systemctl --no-pager status linuxtweaks-flatpak-auto-update.service linuxtweaks-flatpak.timer
# systemctl is-active linuxtweaks-flatpak-auto-update.service linuxtweaks-flatpak.timer
# sudo systemctl reset-failed
