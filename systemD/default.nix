{ config, pkgs, lib, user, username, ... }:

{
  systemd = {

    # ------------------------------------------------------------
    # Shorten timeout for user services
    # ------------------------------------------------------------
    services = {

      #--------------------------------------------------------------------- 
      # Modify autoconnect priority of the connection to tolgas home network
      #---------------------------------------------------------------------
      modify-autoconnect-priority = {
        description =
          "Modify autoconnect priority of OPTUS_DADS_5GHz connection";
        wantedBy = [ "multi-user.target" ];
        serviceConfig = {
          Type = "oneshot";
          ExecStart =
            "${pkgs.networkmanager}/bin/nmcli connection modify OPTUS_DADS_5GHz connection.autoconnect-priority 1";
        };
      };

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
            "${pkgs.systemd}/bin/loginctl terminate-user ${username} || true";
          TimeoutStopSec = "3s";
        };
      };

      # ---------------------------------------------------------------------
      # Do not restart these, since it messes up the current session
      # Idea's used from previous fedora woe's
      # ---------------------------------------------------------------------
      NetworkManager.restartIfChanged = false;
      display-manager.restartIfChanged = false;
      libvirtd.restartIfChanged = false;
      polkit.restartIfChanged = false;
      systemd-logind.restartIfChanged = false;
      wpa_supplicant.restartIfChanged = false;

      lock-before-sleeping = {
        restartIfChanged = false;
        unitConfig = {
          Description = "Helper service to bind locker to sleep.target";
        };

        serviceConfig = {
          ExecStart = "${pkgs.slock}/bin/slock";
          Type = "simple";
        };

        before = [ "pre-sleep.service" ];
        wantedBy = [ "pre-sleep.service" ];

        environment = {
          DISPLAY = ":0";
          XAUTHORITY = "/home/tolga/.Xauthority";
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
