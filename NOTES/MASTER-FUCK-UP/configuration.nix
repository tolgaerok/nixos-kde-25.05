# ==============================================================================
#  Tolga Erok - 29/05/2025
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

{ config, pkgs, lib, modulesPath, user, ... }:

let
  user = "tolga";
  fontsModule = import ./fonts/default.nix { inherit pkgs; };
  nixos-hardware = builtins.fetchTarball {
    url = "https://github.com/NixOS/nixos-hardware/archive/master.tar.gz";
  };
  cfg = config.local.hardware-clock;
in {

  # sudo chown -R $(whoami):$(id -gn) /etc/nixos && sudo chmod -R 777 /etc/nixos && sudo chmod +x /etc/nixos/* && export NIXPKGS_ALLOW_INSECURE=1

  imports = [
    "${nixos-hardware}/common/gpu/nvidia"
    ./activation-scripts
    ./boot
    ./core
    ./distrobox
    ./firewall
    ./flatpaks
    ./fonts
    ./hardware-configuration.nix
    ./local-networking
    ./nix
    ./nvidia
    ./packages
    ./printing
    ./program-settings
    ./samba
    ./scripts
    ./security
    ./services
    ./systemD
    ./tmpfs
    ./tweaks
    ./zram
    ./akonadi.nix
  ];

  options = {
    local.hardware-clock.enable =
      lib.mkEnableOption "Change Hardware Clock To Local Time";
  };

  config = lib.mkMerge [
    (lib.mkIf cfg.enable { time.hardwareClockInLocalTime = true; })

    {
      boot.kernelPackages = pkgs.linuxPackages_latest;

      # ----------------------------------------------------------------------------
      # NVIDIA Driver Control (Custom Module)
      # ----------------------------------------------------------------------------
      GTX1650.nvidia.enable = true;

      flatpakInstall.enable = true;

      time.hardwareClockInLocalTime = true;

      fonts = fontsModule.fonts;

      # programs.kde.wallet.enable = false;

      environment.etc."nixos/samba/mnt/smb-secrets" = {
        text = ''
          username=tolga
          domain=workgroup
          password=ibm450
        '';
        mode = "0600";
      };

      systemd.tmpfiles.rules = [ "d /mnt/QNAP 0755 tolga users -" ];

      # GTX1650.nvidia.enable = true;

      time.timeZone = "Australia/Perth";

      i18n.defaultLocale = "en_AU.UTF-8";
      i18n.extraLocaleSettings = {
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

      networking.networkmanager.enable = true;

      services.xserver.enable = true;

      services.xserver.xkb = {
        layout = "au";
        variant = "";
      };

      services.displayManager.sddm.enable = true;
      services.desktopManager.plasma6.enable = true;

      services.printing.enable = true;

      services.pulseaudio.enable = false;
      security.rtkit.enable = true;

      services.pipewire = {
        enable = true;
        alsa.enable = true;
        alsa.support32Bit = true;
        pulse.enable = true;
        wireplumber.enable = true;
        systemWide = true;
      };

      users.users.tolga = {
        isNormalUser = true;
        description = "${user}";
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
          "video"
          "wheel"
          "wireshark"
        ];

        group = "tolga";
        packages = with pkgs; [
          alsa-utils
          kdePackages.kate
          kdePackages.kdeplasma-addons
          kdePackages.plasma-desktop
          kdePackages.plasma-workspace
          pavucontrol
          pkg-config
          pkgs.libeatmydata
          pulseaudio
          wget
        ];
      };

      users.groups.tolga = { };

      programs.firefox.enable = true;

      nixpkgs.config.allowUnfree = true;
      environment.sessionVariables.NIXPKGS_ALLOW_UNFREE = "1";

      environment.systemPackages = with pkgs;
        [
          flatpak
          nordic
          python313Packages.pipx
          ripgrep
          rofimoji
          wayland-protocols
          wayland-utils
          wl-clipboard
          wlogout
        ] ++ fontsModule.environment.systemPackages;

      system = {
        stateVersion = "25.05";
        copySystemConfiguration = true;

        autoUpgrade = {
          enable = true;
          operation = "boot";
          dates = "Mon 04:40";
          allowReboot = false;
        };

        activationScripts = {
          customInfoScript = {
            text = ''
              /etc/nixos/activation-scripts/run-custom-info-script.sh
            '';
          };
        };
      };
    }
  ];

}
