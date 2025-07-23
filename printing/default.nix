{ config, lib, pkgs, ... }:

let
  extraBackends = [ pkgs.epkowa ];

  #---------------------------------------------------------------------
  #   Printers and printer drivers (To suit my HP LaserJet 600 M601)
  #---------------------------------------------------------------------
  printerDrivers = [
    # pkgs.brgenml1cupswrapper      # Generic drivers for more Brother printers
    # pkgs.brgenml1lpr              # Generic drivers for more Brother printers
    # pkgs.brlaser                  # Drivers for some Brother printers
    # pkgs.cnijfilter2              # Generic cannon
    pkgs.gutenprint # Drivers for many different printers from many different vendors
    pkgs.gutenprintBin # Additional, binary-only drivers for some printers
    pkgs.hplip # Drivers for HP printers
    pkgs.hplipWithPlugin # Drivers for HP printers, with the proprietary plugin. Use in terminal  NIXPKGS_ALLOW_UNFREE=1 nix-shell -p hplipWithPlugin --run 'sudo -E hp-setup'
  ];

in {
  services.avahi = {
    enable = true;
    nssmdns4 = true;
    openFirewall = true;
    publish = {
      enable = true;
      addresses = true;
      domain = true;
      hinfo = true;
      userServices = true;
      workstation = true;
    };

  };

  services.printing = {
    enable = true;
    listenAddresses = [ "*:631" ];
    allowFrom = [ "all" ];
    browsing = true;
    defaultShared = true;
    openFirewall = true;
    drivers = printerDrivers;
  };

  hardware = {
    # Enable SANE (Scanner Access Now Easy) support for scanners
    sane.enable = true;

    # Specify extra backends (drivers) for scanners if needed
    sane.extraBackends =
      extraBackends; # Customize this if you have special scanner drivers
  };
}
