{ config, pkgs, username, user, ... }:

# ---------------------------------------------------
# 🌐 Flatpak Auto Updater After Suspend
#    LinuxTweaks systemD converted over to my nixos
#    Tolga Erok
# ---------------------------------------------------
{
  # User-level Flatpak update service
  systemd.user.services.linuxtweaks-flatpak-auto-update = {
    description = "🛠️ Tolga's User Flatpak Auto Update";
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "/etc/nixos/flatpaks/linuxtweaks-flatpak-update-copy.sh";
    };
  };

  #systemd.services.linuxtweaks-flatpak-resume = {
  #  description = "⚡ Run LinuxTweaks Flatpak Auto Update on resume";
  #  wantedBy = [ "sleep.target" ];
  #  before = [ "sleep.target" ];
  #  serviceConfig = {
  #    Type = "oneshot";
  #    ExecStart =
  #      "/run/current-system/sw/bin/systemctl start linuxtweaks-flatpak-auto-update.service";
  #  };
  #};

  # Timer targeting the user-level service
  systemd.user.timers.linuxtweaks-flatpak = {
    description =
      "⏱️ Run LinuxTweaks Flatpak Update every 10 sec's for testing purposes";
    wantedBy = [ "default.target" "timers.target" ];
    timerConfig = {
      # OnBootSec = "1min";
      # OnUnitActiveSec = "6h";
      # OnUnitInactiveSec = "1h";
      # RandomizedDelaySec = "0";
      # RandomizedDelaySec = "5min";
      # WakeSystem = true;
      AccuracySec = "1s"; 
      OnBootSec = "5s";
      OnUnitActiveSec = "10s";
      OnUnitInactiveSec = "1min";
      Persistent = true;
      Unit = "linuxtweaks-flatpak-auto-update.service";
    };
    #unitConfig = { ConditionACPower = true; };
  };

}

# cl && systemctl --no-pager status linuxtweaks-flatpak-auto-update.service linuxtweaks-flatpak.timer && systemctl is-active linuxtweaks-flatpak-auto-update.service linuxtweaks-flatpak.timer
# sudo systemctl reset-failed && sudo systemctl daemon-reexec && sudo systemctl daemon-reload

