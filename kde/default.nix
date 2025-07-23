{ config, pkgs, lib, ... }:

{
  # ------------------------------------------------------------
  # Enable XDG portals
  # ------------------------------------------------------------
  xdg.portal = {
    enable = true;
    extraPortals = [
      pkgs.kdePackages.xdg-desktop-portal-kde
      pkgs.xdg-desktop-portal-gtk

    ];
    config.common.default = "kde";
  };

  # ------------------------------------------------------------
  # Install essential packages
  # ------------------------------------------------------------
  environment.systemPackages = with pkgs; [
    flatpak
    libnotify
    shadow
    util-linux
    xdg-desktop-portal
  ];

  # ------------------------------------------------------------
  # Enable the KDE Plasma 6 Desktop Environment
  # ------------------------------------------------------------
  services.desktopManager.plasma6.enable = true;

  # ------------------------------------------------------------
  # Enable the SDDM display manager
  # ------------------------------------------------------------
  services.displayManager.sddm.enable = true;
}
