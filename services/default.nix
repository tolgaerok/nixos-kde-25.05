{ config, pkgs, lib, ... }:

{
  imports = [

    # -----------------------------------------------
    # UDEV device manager
    # -----------------------------------------------
    ./udev.nix
  ];

  # ----------------------------------------------------------------------------
  # List services that you want to enable:
  # ----------------------------------------------------------------------------
  services = {
    accounts-daemon.enable = true;
    devmon.enable = true;

    earlyoom = {
      enable = true;
      extraArgs =
        [ "-m 5" "-s 20" ]; # Optional: tweak memory/swap kill thresholds
    };

    envfs.enable = true;
    flatpak.enable = true;
    fstrim.enable = true;
    fwupd.enable = true;
    openssh.enable = true;
    printing.enable = true;
    pulseaudio.enable = false;
    rpcbind.enable = true;
    udisks2.enable = true;

    smartd = {
      enable = true;
      autodetect = true;
    };

    pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
    };

    xserver.xkb = {
      layout = "au";
      variant = "";
    };
  };
}

