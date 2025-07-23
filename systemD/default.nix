{ config, pkgs, lib, user, username, ... }:

{
  systemd = {

    # ------------------------------------------------------------
    # Shorten timeout for user services
    # ------------------------------------------------------------
    services = {
      "user@1000.service".serviceConfig = {
        TimeoutStopSec = "3s";
        KillMode = "process";
      };

      # ------------------------------------------------------------
      # Kill user tolga at shutdown
      # ------------------------------------------------------------
      force-kill-user = {
        description = "Force-kill lingering user sessions at shutdown";
        before = [ "shutdown.target" ];
        wantedBy = [ "shutdown.target" ];
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = false;
          ExecStart =
            "${pkgs.systemd}/bin/loginctl terminate-user tolga || true";
          TimeoutStopSec = "3s";
        };
      };
    };

    # ------------------------------------------------------------
    # User-level defaults
    # ------------------------------------------------------------
    user.extraConfig = ''
      DefaultLimitNOFILE=4096:524288
      DefaultTimeoutStopSec=1s
      KillUserProcesses=yes
    '';

    # ------------------------------------------------------------
    # Global systemd config
    # ------------------------------------------------------------
    extraConfig = ''
      DefaultTimeoutStopSec=1s
      KillUserProcesses=yes
    '';

  };
}
