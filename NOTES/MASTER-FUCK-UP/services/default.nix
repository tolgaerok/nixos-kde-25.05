{ config, pkgs, lib, username, ... }:

let
  #---------------------------------------------------------------------
  #   PRINTER DRIVERS (For HP LaserJet 600 M601 and others)
  #---------------------------------------------------------------------
  printerDrivers =
    [ pkgs.gutenprint pkgs.gutenprintBin pkgs.hplip pkgs.hplipWithPlugin ];

in {
  #---------------------------------------------------------------------
  #   IMPORTS (Extend config from local modules)
  #---------------------------------------------------------------------
  imports = [
    # ./samba
    # ./extra-printers/HL2130_NET_DADS_LASER.nix
  ];

  #---------------------------------------------------------------------
  #   PRINTING & SCANNING
  #---------------------------------------------------------------------
  #services.printing = {
  #  enable = true;
  #  browsing = true;
  #  # drivers = printerDrivers;
  #};

  #---------------------------------------------------------------------
  #   NETWORK & CONNECTIVITY
  #---------------------------------------------------------------------
  services.openssh = {
    enable = true;
    banner = ''
      # SSH login banner
           Tolga Erok ¯\_(ツ)_/¯⠀  ⢀⣠⣴⣾⣿⣿⣿⣿⣿
           >ligma
    '';
    hostKeys = [
      {
        type = "rsa";
        bits = 4096;
        path = "/etc/ssh/ssh_host_rsa_key";
      }
      {
        type = "ed25519";
        path = "/etc/ssh/ssh_host_ed25519_key";
      }
    ];
    settings = {
      PermitRootLogin = lib.mkForce "yes";
      UseDns = false;
      X11Forwarding = false;
      PasswordAuthentication = lib.mkForce true;
      KbdInteractiveAuthentication = true;
    };
  };

  # Redundant but explicit SSH daemon enable
  services.sshd.enable = lib.mkForce true;

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
    # Optional extra services:
    # extraServiceFiles = {
    #   smb = ''
    #     <?xml version="1.0" standalone='no'?><!--*-nxml-*-->
    #     <!DOCTYPE service-group SYSTEM "avahi-service.dtd">
    #     <service-group>
    #       <name replace-wildcards="yes">%h</name>
    #       <service>
    #         <type>_smb._tcp</type>
    #         <port>445</port>
    #       </service>
    #     </service-group>
    #   '';
    # };
  };

  services.printing = {
    enable = true;
    listenAddresses = [ "*:631" ];
    allowFrom = [ "all" ];
    browsing = true;
    defaultShared = true;
    openFirewall = true;
  };
  # services.geoclue2.enable = true;

  #---------------------------------------------------------------------
  #   AUDIO, MEDIA & FILESYSTEM
  #---------------------------------------------------------------------
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    # alsa.support32Bit = true;
    pulse.enable = true;
  };

  services.envfs.enable = true;
  services.udisks2.enable = true;
  # services.devmon.enable = true;

  #---------------------------------------------------------------------
  #   HARDWARE & PERFORMANCE
  #---------------------------------------------------------------------
  services.udev = {
    enable = true;
    extraRules = ''
      # sound devices to audio group
      KERNEL=="rtc0", GROUP="audio"
      KERNEL=="hpet", GROUP="audio"

      # set mq-deadline for SSDs (SATA, eMMC)
      ACTION=="add|change", KERNEL=="sd[a-z]", ATTR{queue/scheduler}="mq-deadline"
      ACTION=="add|change", KERNEL=="mmcblk[0-9]", ATTR{queue/scheduler}="mq-deadline"

      # power saving tweaks
      ACTION=="add", SUBSYSTEM=="usb", TEST=="power/control", ATTR{power/control}="auto"
      ACTION=="add", SUBSYSTEM=="pci", TEST=="power/control", ATTR{power/control}="auto"
    '';
  };

  services.hardware.bolt.enable = true;

  #---------------------------------------------------------------------
  #   Core SYSTEM MANAGEMENT
  #---------------------------------------------------------------------
  services.timesyncd.enable = true;
  services.fstrim.enable = true;

  services.logind.extraConfig = ''
    RuntimeDirectorySize=100%
    RuntimeDirectoryInodesMax=1048576
  '';

  #---------------------------------------------------------------------
  #   BLUETOOTH & PERIPHERALS
  #---------------------------------------------------------------------
  services.blueman.enable = true;

  #---------------------------------------------------------------------
  #   D-BUS & DESKTOP INTEGRATION
  #---------------------------------------------------------------------
  services.dbus = {
    enable = true;
    packages = with pkgs; [ dconf gcr udisks2 ];
  };

  #---------------------------------------------------------------------
  #   OPTIONAL/EXPERIMENTAL
  #---------------------------------------------------------------------

  # iPhone support (disabled)
  #iphone = {
  #  enable = true;
  #  user = "tolga";
  #};

  # Flatpak (disabled)
  #services.flatpak.enable = true;

  # TeamViewer (disabled)
  #services.teamviewer.enable = true;

  # GVFS overrides (disabled)
  #services.gvfs = {
  #  enable = true;
  #  package = lib.mkForce pkgs.gnome.gvfs;
  #};

  # Thermald (disabled)
  #services.thermald.enable = false;
}
