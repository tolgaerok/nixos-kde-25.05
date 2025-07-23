{ config, pkgs, ... }:

# ----------------------------------------------- #
# NixOS refresh plasma taskbar
# ----------------------------------------------- #
#  systemctl --user daemon-reexec && systemctl --user daemon-reload && systemctl --user enable --now kplasma-restart.timer && systemctl --user enable kplasma-restart.service && systemctl --user status kplasma-restart.service --no-pager
#  systemctl --user start kplasma-restart.service

# systemctl --user daemon-reexec && \
# systemctl --user daemon-reload && \
# systemctl --user enable --now kplasma-restart.timer && \
# systemctl --user status kplasma-restart.service --no-pager

{
  systemd.user.services.kplasma-restart = {
    description = "Restart My Fucking plasmashell";
    serviceConfig = {
      Type = "simple";
      ExecStart = "${pkgs.procps}/bin/pkill -9 plasmashell";
      ExecStartPost = "/usr/bin/setsid /run/current-system/sw/bin/plasmashell";
      Environment = "PATH=/run/current-system/sw/bin:/usr/bin";
    };
  };

  systemd.user.timers.kplasma-restart = {
    description = "Restart My Fucking plasmashell every 3 minutes";
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnBootSec = "3min";
      OnUnitActiveSec = "3min";
      AccuracySec = "30s";
    };
  };
}
