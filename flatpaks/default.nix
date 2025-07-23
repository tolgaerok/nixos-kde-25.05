{ config, pkgs, lib, ... }:

# ----------------------------------------------------
# My over the top flatpak snippet
# ---------------------------------------------------

let
  flatpakApps = [
    "app/com.dec05eba.gpu_screen_recorder/x86_64/stable"
    "app/com.heroicgameslauncher.hgl/x86_64/stable"
    "app/com.ranfdev.DistroShelf"
    "app/com.valvesoftware.Steam/x86_64/stable"
    "app/io.github.getnf.embellish"
    "app/io.github.ilya_zlobintsev.LACT/x86_64/stable"
    "app/io.podman_desktop.PodmanDesktop"
    "app/me.iepure.devtoolbox"
    "app/net.davidotek.pupgui2/x86_64/stable"
    "app/net.lutris.Lutris/x86_64/stable"
    "app/org.fedoraproject.MediaWriter"
    "app/org.gustavoperedo.FontDownloader"
    "app/sh.loft.devpod"
    "com.discordapp.Discord"
    "com.github.tchx84.Flatseal"
    "com.obsproject.Studio"
    "com.obsproject.Studio.Plugin.GStreamerVaapi"
    "com.obsproject.Studio.Plugin.OBSVkCapture"
    "com.rtosta.zapzap"
    "com.wps.Office"
    "io.github.aandrew_me.ytdn"
    "io.github.dvlv.boxbuddyrs"
    "io.github.flattool.Warehouse"
    "io.missioncenter.MissionCenter"
    "org.gnome.Connections"
    "org.gnome.DejaDup"
    "org.gnome.Rhythmbox3"
    "org.gnome.World.PikaBackup"
    "org.gnome.baobab"
    "org.gtk.Gtk3theme.Arc-Dark"
    "org.mozilla.firefox"
    "org.virt_manager.virt-manager"
    "runtime/com.obsproject.Studio.Plugin.OBSVkCapture/x86_64/stable"
    "runtime/org.freedesktop.Platform.VulkanLayer.MangoHud/x86_64/23.08"
    "runtime/org.freedesktop.Platform.VulkanLayer.MangoHud/x86_64/24.08"
    "runtime/org.freedesktop.Platform.VulkanLayer.OBSVkCapture/x86_64/24.08"
    "runtime/org.freedesktop.Platform.VulkanLayer.gamescope/x86_64/23.08"
    "runtime/org.freedesktop.Platform.VulkanLayer.gamescope/x86_64/24.08"
    "runtime/org.gtk.Gtk3theme.Breeze"
    "runtime/org.gtk.Gtk3theme.Yaru-Blue/x86_64/stable"
    "runtime/org.gtk.Gtk3theme.Yaru-Deepblue/x86_64/stable"
    "runtime/org.gtk.Gtk3theme.adw-gtk3"
    "runtime/org.gtk.Gtk3theme.adw-gtk3-dark"
  ];
in {

  services.flatpak.enable = true;

  environment.etc."flatpak-repo".text = ''
    [remote "flathub"]
    url=https://flathub.org/repo/flathub.flatpakrepo
  '';

  # flatpak repo
  systemd.services.flatpak-repo = {
    enable = true;
    wantedBy = [ "multi-user.target" ];
    path = [ pkgs.flatpak ];
    script = ''
      echo -e "\033[1;34m[Flatpak]\033[0m Adding Flathub repo..."
      flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
    '';
    serviceConfig = {
      Type = "oneshot"; # runs script then exits
      RemainAfterExit = true; # keep as active after script finishes
    };
  };

  # flatpak update service
  systemd.services.flatpak-update = {
    enable = true;
    # wantedBy = [ "multi-user.target" ];      # bombs out on rebuilds as theres no network

    path = [ pkgs.flatpak ];
    script = ''
      LOGFILE="/var/log/flatpak-update.log"
      echo -e "\n🔁 $(date) - Brother, flatpak update triggered" >> "$LOGFILE"

      i=0
      while [ $i -lt 5 ]; do
        if ping -c1 flathub.org >/dev/null 2>&1; then break; fi
        echo "[Flatpak] Fucking Network not ready, retrying in 5s..." >> "$LOGFILE"
        sleep 5
        i=$((i+1))
      done

      if [ $i -eq 5 ]; then
        echo "[Flatpak] ❌ Network unreachable. Aborting... fuck knows brother" >> "$LOGFILE"
        exit 1
      fi

      flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo >> "$LOGFILE" 2>&1

      echo -e "[Flatpak] Installing or updating..." >> "$LOGFILE"
      ${lib.concatStringsSep "\n" (map (app:
        ''
          flatpak install -y --noninteractive --system --or-update flathub ${app} >> "$LOGFILE" 2>&1'')
        flatpakApps)}

      echo "✅ Done at $(date)" >> "$LOGFILE"
    '';
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      After = [ "network-online.target" ];
      Wants = [ "network-online.target" ];
    };
  };

  # timer for the Flatpak update service
  systemd.timers.flatpak-update = {
    enable = true;
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnBootSec = "10min";
      OnUnitActiveSec = "1d";
    };
  };

  system.activationScripts.installFlatpaks = ''
    ${pkgs.flatpak}/bin/flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo

  '' + builtins.concatStringsSep "\n" (map (pkg:
    ''printf "\\e[36mInstalling \\e[1m'' + pkg + ''
      \\e[0m  "
          if ${pkgs.flatpak}/bin/flatpak install -y --noninteractive --system --or-update flathub ''
    + pkg + ''
      ; then
            printf "\\e[32m==> ✅ Successfully installed '' + pkg + ''
        \\e[0m\\n"
            else
              printf "\\e[31m==> ❌ Failed to install '' + pkg + ''
          \\e[0m\\n"
              fi
        '') flatpakApps) + "\n";

}
