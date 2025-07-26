{ config, pkgs, username, user, ... }:

# ---------------------------------------------------
# 🌐 Flatpak Auto Updater After Suspend
#    LinuxTweaks systemD converted over to my nixos
#    Tolga Erok
# ---------------------------------------------------
{
  # user-level Flatpak update service
  systemd.user.services.linuxtweaks-flatpak-auto-update = {
    description = "🛠️ Tolga's User Flatpak Auto Update";
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "/etc/nixos/flatpaks/linuxtweaks-flatpak-update-copy.sh";
    };
  };

  # user-level timer service
  systemd.user.timers.linuxtweaks-flatpak = {
    description = "⏱️ Run LinuxTweaks Flatpak Update every 30mins";
    wantedBy = [ "default.target" "timers.target" ];
    timerConfig = {
      # OnBootSec = "1min";
      # OnUnitActiveSec = "6h";
      # OnUnitInactiveSec = "1h";
      # RandomizedDelaySec = "0";
      # RandomizedDelaySec = "5min";
      # WakeSystem = true;
      AccuracySec = "1s";
      OnBootSec = "5s";                # Run after 5 minutes post-boot
      OnUnitActiveSec = "30min";       # interval: every 30 minutes
      OnUnitInactiveSec = "1min";      # Catches up if system was off
      Persistent = true;               # run missed updates after boo
      Unit = "linuxtweaks-flatpak-auto-update.service";
    };
    # Leave this commented out — it's laptop-only
    # unitConfig = { ConditionACPower = true; };
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

}

# system
# cl && systemctl --no-pager status linuxtweaks-flatpak-auto-update.service linuxtweaks-flatpak.timer && systemctl is-active linuxtweaks-flatpak-auto-update.service linuxtweaks-flatpak.timer

#user
# cl && systemctl --user --no-pager status linuxtweaks-flatpak-auto-update.service linuxtweaks-flatpak.timer && systemctl --user is-active linuxtweaks-flatpak-auto-update.service linuxtweaks-flatpak.timer
# sudo systemctl reset-failed && sudo systemctl daemon-reexec && sudo systemctl daemon-reload

