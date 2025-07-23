{ config, pkgs, lib, ... }:

let
  installFlatpaksUserScript =
    pkgs.writeShellScriptBin "install-flatpaks-user" ''
      #!/usr/bin/env bash
      set -euo pipefail

      echo "Adding Flathub remote for user..."
      ${pkgs.flatpak}/bin/flatpak --user remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo

      echo "Installing user Flatpaks..."
      ${pkgs.flatpak}/bin/flatpak install --user -y flathub \
        com.github.tchx84.Flatseal \
        io.github.aandrew_me.ytdn \
        io.github.flattool.Warehouse \
        io.missioncenter.MissionCenter \
        org.gnome.Connections \
        org.gnome.DejaDup \
        org.gnome.World.PikaBackup \
        org.gnome.baobab \
        org.mozilla.firefox

      echo "User Flatpak installation complete."
    '';

  installFlatpaksSystemScript =
    pkgs.writeShellScriptBin "install-flatpaks-system" ''
        #!/usr/bin/env bash
        set -euo pipefail

        echo "Adding Flathub remote for system..."
        ${pkgs.flatpak}/bin/flatpak --system remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo

        ${pkgs.flatpak}/bin/flatpak install -y --noninteractive --system flathub \
          app/com.dec05eba.gpu_screen_recorder/x86_64/stable \
          app/com.heroicgameslauncher.hgl/x86_64/stable \
          app/com.valvesoftware.Steam/x86_64/stable \
          app/io.github.ilya_zlobintsev.LACT/x86_64/stable \
          app/net.davidotek.pupgui2/x86_64/stable \
          app/net.lutris.Lutris/x86_64/stable \
          com.github.tchx84.Flatseal \
          com.wps.Office \
          io.github.aandrew_me.ytdn \
          io.github.flattool.Warehouse \
          io.missioncenter.MissionCenter \
          org.gnome.Connections \
          org.gnome.DejaDup \
          org.gnome.World.PikaBackup \
          org.gnome.baobab \
          org.mozilla.firefox \
          org.virt_manager.virt-manager \
          runtime/com.obsproject.Studio.Plugin.OBSVkCapture/x86_64/stable \
          runtime/org.freedesktop.Platform.VulkanLayer.MangoHud/x86_64/23.08 \
          runtime/org.freedesktop.Platform.VulkanLayer.MangoHud/x86_64/24.08 \
          runtime/org.freedesktop.Platform.VulkanLayer.OBSVkCapture/x86_64/24.08 \
          runtime/org.freedesktop.Platform.VulkanLayer.gamescope/x86_64/23.08 \
          runtime/org.freedesktop.Platform.VulkanLayer.gamescope/x86_64/24.08

      echo "System Flatpak installation complete."
    '';
in {
  imports = [ ./flatpak-auto-update.nix ];

  options.flatpakInstall.enable = lib.mkOption {
    type = lib.types.bool;
    default = false;
    description = "Enable Flatpak install services for user and system.";
  };

  config = lib.mkIf config.flatpakInstall.enable {

    systemd.services.install-flatpaks-system = {
      description = "Install system Flatpaks";
      after = [ "network-online.target" ];
      wants = [ "network-online.target" ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        Type = "oneshot";
        ExecStart =
          "${installFlatpaksSystemScript}/bin/install-flatpaks-system";
        Restart = "no";
      };
    };

    systemd.timers.install-flatpaks-system = {
      description = "Run system flatpak install daily";
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnCalendar = "daily";
        Persistent = true;
      };
      enable = true; # ✅ FIXED: must go here!
    };

    #systemd.user.services."install-flatpaks-user" = {
    #  description = "Install user Flatpaks";
    #  wants = [ "default.target" ];
    #  after = [ "default.target" "network-online.target" ];
    #  serviceConfig = {
    #    Type = "oneshot";
    #    ExecStart = "${installFlatpaksUserScript}/bin/install-flatpaks-user";
    #    Restart = "no";
    #  };
    #  wantedBy = [ "default.target" ];
    #};

    systemd.user.timers."install-flatpaks-user" = {
      description = "Run user flatpak install daily";
      timerConfig = {
        OnCalendar = "daily";
        Persistent = true;
      };
      wantedBy = [ "timers.target" ];
    };

    # ✅ Flatpak support
    services.flatpak.enable = true;

    # ✅ Portals
    xdg.portal = {
      enable = true;
      extraPortals = [

        pkgs.kdePackages.xdg-desktop-portal-kde
        pkgs.xdg-desktop-portal-gtk
      ];
    };

    # ✅ Tools
    environment.systemPackages = with pkgs; [
      flatpak
      libnotify
      kdePackages.xdg-desktop-portal-kde
      util-linux
      xdg-desktop-portal
      shadow
    ];
  };
}
