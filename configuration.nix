# ==============================================================================
#  Tolga Erok - 30/6/2025
#  My personal NIXOS KDE configuration
# ==============================================================================
#
#             ¯\_(ツ)_/¯
#   ███▄    █     ██▓   ▒██   ██▒    ▒█████       ██████
#   ██ ▀█   █    ▓██▒   ▒▒ █ █ ▒░   ▒██▒  ██▒   ▒██    ▒
#  ▓██  ▀█ ██▒   ▒██▒   ░░  █   ░   ▒██░  ██▒   ░ ▓██▄
#  ▓██▒  ▐▌██▒   ░██░    ░ █ █ ▒    ▒██   ██░     ▒   ██▒
#  ▒██░   ▓██░   ░██░   ▒██▒ ▒██▒   ░ ████▓▒░   ▒██████▒▒
#  ░ ▒░   ▒ ▒    ░▓     ▒▒ ░ ░▓ ░   ░ ▒░▒░▒░    ▒ ▒▓▒ ▒ ░
#  ░ ░░   ░ ▒░    ▒ ░   ░░   ░▒ ░     ░ ▒ ▒░    ░ ░▒  ░ ░
#     ░   ░ ░     ▒ ░    ░    ░     ░ ░ ░ ▒     ░  ░  ░
#           ░     ░      ░    ░         ░ ░           ░
#
# ====================== HP EliteDesk 800 G4 SFF ================================
#
#  BLUE-TOOTH        REALTEK 5G
#  CPU               Intel(R) Core(TM) i7-8700 CPU @ 3.2GHz - 4.6GHz (Turbo) x6
#  MODEL             HP EliteDesk 800 G4 SFF
#  MOTHERBOARD       Intel Q370 PCH-H—vPro
#  NETWORK           Intel Wi-Fi 6 AX210/AX211/AX411 160MHz
#  PSU               250W
#  RAM               Max: 64GB DDR4-2666 (16GB x 4)
#  STORAGE           256GB M.2 2280 PCIe NVMe SSD
#  d-GPU             NVIDIA GeForce GTX 1650
#  i-GPU             Intel UHD Graphics 630
#  EXPANSION SLOTS   1x M.2 WLAN, 2x M.2 storage, 2x PCIe x1, 1x PCIe x16 (x4 wired), 1x PCIe x16
#  SOURCE            https://support.hp.com/au-en/document/c06047207
#
# ==============================================================================

# sudo chown -R $(whoami):$(id -gn) /etc/nixos && sudo chmod -R 777 /etc/nixos && sudo chmod +x /etc/nixos/* && export NIXPKGS_ALLOW_INSECURE=1

{ config, pkgs, lib, modulesPath, user, username, ... }:

let
  G4 = builtins.filterSource (p: t: true) ./my-scripts;
  MyFlatpaks = false; # set false to skip or true to include!
  fontsModule = import ./fonts/default.nix { inherit pkgs; };
  host = "G4800-NIXOS";

  konsoleFunctions = G4 + "/functions.sh";
  myFunctions = ./my-scripts/functions.sh;

  user = "tolga";
  user_desp = "King Tolga";

  nixos-hardware = builtins.fetchTarball {
    url = "https://github.com/NixOS/nixos-hardware/archive/master.tar.gz";
  };

  cfg = config.local.hardware-clock;
in {

  imports = [

    # -----------------------------------------------
    # Nvidia section
    # -----------------------------------------------
    "${nixos-hardware}/common/gpu/nvidia"
    # ./nvidia/closed_nvidia_575_64.nix
    # ./nvidia/closed_nvidia_575_64_03_32bit.nix
    # ./nvidia/open_nvidia_570_153_02_32bit.nix
    ./nvidia/closed_nvidia_575_64_03.nix # EXCELLENT => My Master config

    # -----------------------------------------------
    # System section
    # -----------------------------------------------
    ./boot
    ./environment
    ./folder-permissions
    ./hardware-configuration.nix
    ./kde
    ./konsole
    ./networking/networkmanager-resume.nix
    ./nix
    ./printing
    ./services
    ./systemD
    ./tmpfs

    # -----------------------------------------------
    # Networking section
    # -----------------------------------------------
    ./firewall
    ./samba

    # -----------------------------------------------
    # Modules section
    # -----------------------------------------------
    # ./python/shell.nix
    ./akonadi.nix
    ./cleanup-dups
    ./distrobox
    ./fonts
    ./packages
    ./python/linuxtweaks-shell.nix
    ./vm

    # --------------------------------------------------
    # Work arounds
    # --------------------------------------------------
    ./refresh-plasma-bug
    ./flatpaks/update-flatpaks-service.nix
    #./core
    #./local-networking
    #./program-settings

    #./scripts
    #./security
    #./services
    #./steam
    #./systemD   
    #./tweaks
    #./zram

  ] ++ lib.optional MyFlatpaks ./flatpaks/default.nix;

  # ----------------------------------------------------------------------------
  # Which kernel:
  # ----------------------------------------------------------------------------
  # boot.kernelPackages = pkgs.linuxPackages_6_14;
  # zramSwap.enable = true;
  boot.kernelPackages = pkgs.linuxPackages_latest;

  # ----------------------------------------------------------------------------
  # Networking
  # ----------------------------------------------------------------------------
  networking = {
    hostName = "${host}";
    networkmanager.enable = true;
    timeServers = [ "pool.ntp.org" ];
  };

  systemd.services.NetworkManager-wait-online.enable = false;

  # ----------------------------------------------------------------------------
  # time zone && ix clock to be compatible with windows
  # ----------------------------------------------------------------------------
  time = {
    timeZone = "Australia/Perth";
    hardwareClockInLocalTime = true;

  };

  # ----------------------------------------------------------------------------
  # Select internationalisation properties.
  # ----------------------------------------------------------------------------
  i18n = {
    defaultLocale = "en_AU.UTF-8";
    extraLocaleSettings = {
      LC_ADDRESS = "en_AU.UTF-8";
      LC_IDENTIFICATION = "en_AU.UTF-8";
      LC_MEASUREMENT = "en_AU.UTF-8";
      LC_MONETARY = "en_AU.UTF-8";
      LC_NAME = "en_AU.UTF-8";
      LC_NUMERIC = "en_AU.UTF-8";
      LC_PAPER = "en_AU.UTF-8";
      LC_TELEPHONE = "en_AU.UTF-8";
      LC_TIME = "en_AU.UTF-8";
    };
  };

  # ----------------------------------------------------------------------------
  # Security
  # ----------------------------------------------------------------------------
  security = {
    rtkit.enable = true;
    pam.services.sddm.enableKwallet = true;

  };

  # ----------------------------------------------------------------------------
  # Define a user account. Don't forget to set a password with ‘passwd’.
  # ----------------------------------------------------------------------------
  users.users."${user}" = {
    isNormalUser = true;
    description = "${user_desp}";
    extraGroups = [
      "${user}"
      "audio"
      "code"
      "corectrl"
      "disk"
      "docker"
      "input"
      "kvm"
      "libvirtd"
      "lp"
      "minidlna"
      "mongodb"
      "mysql"
      "network"
      "networkmanager"
      "pipewire"
      "plugdev"
      "postgres"
      "power"
      "qemu-libvirtd"
      "samba"
      "scanner"
      "smb"
      "sound"
      "storage"
      "systemd-journal"
      "udev"
      "users"
      "usershares" # for samba GUI shares
      "video"
      "wheel"
      "wireshark"
    ];

    group = "tolga";
    packages = with pkgs;
      [

      ];

  };

  users.groups.tolga = { };

  # ----------------------------------------------------------------------------
  # Program Varibles
  # ----------------------------------------------------------------------------
  programs = {
    direnv.enable = true;
    direnv.nix-direnv.enable = true;
    firefox.enable = true;
    fuse.userAllowOther = true;
    mtr.enable = true;
    nix-ld.enable = true;

    gnupg.agent = {
      enable = true;
      enableSSHSupport = true;
    };
  };

  # ----------------------------------------------------------------------------
  # Allow unfree packages
  # ----------------------------------------------------------------------------
  nixpkgs.config.allowUnfree = true;

  # ----------------------------------------------------------------------------
  # System State
  # ----------------------------------------------------------------------------
  system = {
    stateVersion = "25.05";
    copySystemConfiguration = true;

    autoUpgrade = {
      allowReboot = false;
      channel = "https://nixos.org/channels/nixos-25.05";
      dates = "Mon 04:40";
      enable = false;
      operation = "boot";
    };

    # ----------------------------------------------------------------------------
    # Personal script to display extra info after rebuild
    # ----------------------------------------------------------------------------
    activationScripts = {
      customInfoScript = {
        text = ''
          /etc/nixos/activation-scripts/run-custom-info-script.sh
        '';
      };
    };
  };

}
