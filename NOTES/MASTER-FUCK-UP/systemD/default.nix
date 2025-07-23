{ config, pkgs, lib, ... }:
with lib; {
  # ---------------------------------------------------------------------
  # Add a systemd tmpfiles rule that creates a directory /var/spool/samba
  # with permissions 1777 and ownership set to root:root.
  # ---------------------------------------------------------------------

  services.flatpak.enable = true;

  # Create Share1 and Share2 directories in each user's home directory using systemd tmpfiles #
  systemd = {
    tmpfiles.rules = [
      "D! /tmp 1777 root root 0"
      "d /home/tolga/Share1 0775 tolga users -"
      "d /home/tolga/Share2 0775 tolga users -"
      "d /home/tolga/Documents/MEGA 0775 tolga samba -"
      "d /var/spool/samba 1777 root root -"
      "r! /tmp/**/*"
    ];
    # Default timeout for stopping services managed by systemd to 10 seconds
    extraConfig = ''
      DefaultLimitNOFILE=1048576
      DefaultTimeoutStopSec=3s
    '';
    # When a program crashes, systemd will create a core dump file, typically in the /var/lib/systemd/coredump/ directory.
    coredump.enable = true;
  };

  systemd.services = {
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

    # ---------------------------------------------------------------------
    # Configure the flathub remote
    # Terminal: sudo systemctl status configure-flathub-repo
    # ---------------------------------------------------------------------
    configure-flathub-repo = {
      enable = true;
      after = [ "multi-user.target" "network.target" ];
      wantedBy = [ "multi-user.target" ];
      path = [ pkgs.flatpak ];
      script = ''
        if flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo; then
          echo "¯\_(ツ)_/¯  Flathub repo added and configured successfully ==>  [✔] "
        else
          echo "¯\_(ツ)_/¯  Error: Failed to configure Flathub repo ==>  [✘]"
          exit 1  # Exit with an error code to indicate failure
        fi
      '';
    };

    customInfoScript = {
      description = "Custom Info Script";
      script = "/etc/nixos/systemD/custom-info-script.sh";
      wantedBy = [ "multi-user.target" ];
    };

    check-update = {
      serviceConfig.Type = "oneshot";
      path = [ pkgs.espeak-classic ];
      script = ''
        #!/bin/sh
        espeak -v en+m7 -s 165 "PUNK! " --punct=","
         
          nixos-check-updates
          
      '';
    };

    #--------------------------------------------------------------------- 
    # Make nixos boot a tad faster by turning these off during boot
    #--------------------------------------------------------------------- 
    NetworkManager-wait-online.enable = false;
    systemd-udev-settle.enable = false;

  };

  systemd.timers.check-updates = {
    wantedBy = [ "timers.target" ];
    partOf = [ "check-update.service" ];
    timerConfig = {
      # every 10 seconds
      OnCalendar = "*-*-* *-*-*:00/10:00:00";
      Unit = "check-update.service";
    };
  };

}

# sudo chown -R $(whoami):$(id -gn) /etc/nixos && sudo chmod -R 777 /etc/nixos && sudo chmod +x /etc/nixos/* && export NIXPKGS_ALLOW_INSECURE=1
