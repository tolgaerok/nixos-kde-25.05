{ config, pkgs, ... }:

{
  # ----------------------------------------------------------------------------
  # Bootloader & Initrd
  # ----------------------------------------------------------------------------
  boot.loader = {
    efi.canTouchEfiVariables = true;
    systemd-boot = {
      enable = true;
      editor = true;
    };
  };

  boot.initrd = {
    systemd.enable = true;
    verbose = false;
  };

  boot.plymouth = {
    enable = true;
    theme = "breeze";
  };
}
