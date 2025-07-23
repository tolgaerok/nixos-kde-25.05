{ config, pkgs, ... }:

{
  #---------------------------------------------------------------------
  # Flatpak Automatic Updates
  #---------------------------------------------------------------------
    systemd.services.flatpak-update = {
    description = "Tolga's Flatpak Automatic Update";
    documentation = [ "man:flatpak(1)" ];
    wants = [ "network-online.target" ];
    after = [ "network-online.target" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.flatpak}/bin/flatpak update -y --system";
      StandardOutput = "journal";
      StandardError = "journal";
    };
    wantedBy = [ "multi-user.target" ];
    enable = true;
  };

  systemd.timers.flatpak-update = {
    description = "Tolga's Flatpak Automatic Update Trigger";
    documentation = [ "man:flatpak(1)" ];
    wants = [ "network-online.target" ];
    after = [ "network-online.target" ];
    timerConfig = {
      OnBootSec = "1min";
      OnUnitActiveSec = "12h";
      Persistent = true;
      Unit = "flatpak-update.service";
    };
    wantedBy = [ "timers.target" ];
    enable = true;
  };
}
