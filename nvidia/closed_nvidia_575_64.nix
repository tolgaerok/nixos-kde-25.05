{ lib, pkgs, config, username, ... }:

# ──── MY PERSONAL NVIDIA DEBUGGING & DIAGNOSTIC NOTES ──────────────────────────────────────
# Use these commands to inspect driver status, unknown params, and kernel hooks

# View unknown NVIDIA parameters (detect misconfig or typos)
# ──────────────────────────────────────────────────────────────
# sudo dmesg | grep -i nvidia | grep -i unknown

# Display loaded NVIDIA kernel module details
# ────────────────────────────────────────────
# modinfo nvidia

# Show active NVIDIA driver parameter values
# ───────────────────────────────────────────
# cat /proc/driver/nvidia/params

with lib;

let
  cfg = config.GTX1650.nvidia;
  nvidiaPackage = if cfg.enable then
    config.boot.kernelPackages.nvidiaPackages.mkDriver {
      # https://download.nvidia.com/XFree86/Linux-x86_64/
      # openSha256 = "sha256-PMh5efbSEq7iqEMBr2+VGQYkBG73TGUh6FuDHZhmwHk=";
      # persistencedSha256 = lib.fakeSha256;
      version = "575.64";
      sha256_64bit = "sha256-6wG8/nOwbH0ktgg8J+ZBT2l5VC8G5lYBQhtkzMCtaLE=";
      sha256_aarch64 = "sha256-uHj8fB1sSJfX0NWZEE1eZN1LQQkf7J0jPV3EeQCSG10=";
      openSha256 = "sha256-y93FdR5TZuurDlxc/p5D5+a7OH93qU4hwQqMXorcs/g=";
      settingsSha256 = "sha256-3BvryH7p0ioweNN4S8oLDCTSS47fQPWVYwNq4AuWQgQ=";
      persistencedSha256 =
        "sha256-QkDNQKwCsakZOLcSie1NBiFCM5e5NFGiIKtPSFeWdXs=";
    }
  else
    null;
in {

  # -------------------------------------------------------------
  # My Custom NVIDIA module options
  # -------------------------------------------------------------
  options.GTX1650.nvidia = {
    enable = mkEnableOption "Enable NVIDIA driver and configuration";

    nvidiaSettings = mkOption {
      type = types.bool;
      default = true;
      description = "Install NVIDIA Settings GUI tool";
    };
  };

  # -------------------------------------------------------------
  # sybola font bug: Tolga erok
  # -------------------------------------------------------------
  config = mkIf cfg.enable {
    imports = [

      # -----------------------------------------------
      # Nvidia section
      # -----------------------------------------------
      ./enable_GTX1650.nix

    ];

    # -------------------------------------------------------------
    # Kernel module options for NVIDIA
    # -------------------------------------------------------------
    # "NVreg_EnableGpuFirmware=18"  "NVreg_EnableGpuFirmwareLogs=0"   Not supported by GTX1650 
    # "NVreg_InitializeSystemMemoryAllocations=0"                     slowed resume on some setups 
    # "NVreg_DynamicPowerManagement=0x02"                             caused powermanagment issues
    boot = {
      extraModprobeConfig = "options nvidia " + lib.concatStringsSep " " [
        "NVreg_DynamicPowerManagement=0"
        "NVreg_EnableMSI=1"
        "NVreg_EnablePCIERelaxedOrderingMode=1"
        "NVreg_EnablePCIeGen3=1"
        "NVreg_EnableResizableBar=1"
        "NVreg_EnableStreamMemOPs=1"
        "NVreg_PreserveVideoMemoryAllocations=1"
        "NVreg_RegistryDwords=RMIntrLockingMode=1"
        "NVreg_UsePageAttributeTable=1"
        "nvidia_drm modeset=1"
      ];
      blacklistedKernelModules = lib.mkDefault [
        "iTCO_wdt"
        "nouveau"
        "nvidiafb"
        "rivafb"
        "rivatv"
        "vga16fb"
      ];
      kernelParams = [
        "nvidia.modeset=1"
        "nvidia_drm.modeset=1"
        "rd.driver.blacklist=nouveau"
        # "nvidia_drm.fbdev=1"
        # "pcie_aspm=off"
        # "video.allow_duplicates=1"
      ];
    };

    # -------------------------------------------------------------
    # Accept NVIDIA EULA
    # -------------------------------------------------------------
    nixpkgs.config.nvidia.acceptLicense = true;

    # -------------------------------------------------------------
    # Set NVIDIA as primary X11 driver
    # -------------------------------------------------------------
    services.xserver = {
      videoDrivers = [ "nvidia" ];
      enable =
        true; # Enable the X11 windowing system or you can disable this if you're only using the Wayland session.
    };

    # -------------------------------------------------------------
    # Global environment variables (boot/system level)
    # -------------------------------------------------------------
    environment.variables = {
      # VDPAU_DRIVER = "nvidia";
      # __GLX_VENDOR_LIBRARY_NAME = "nvidia";
      # __GL_GSYNC_ALLOWED = "1";
      # __GL_SHADER_CACHE = "1";
      # __GL_VRR_ALLOWED = "1";
      # ─── NVIDIA Driver ────────────────────────────────
      __GL_SHADER_DISK_CACHE = "1"; # ✅ Keeps things snappy
      __GL_SHADER_DISK_CACHE_PATH = "/tmp"; # ✅ Keeps cache in RAM
      __GL_SYNC_TO_VBLANK = "1"; # ✅ For smooth frames.

      # ─── Vulkan and Rendering ─────────────────────────
      # GBM_BACKEND = "nvidia-drm";
      # VK_ICD_FILENAMES = ""; # clear override
      LIBVA_DRIVER_NAME = "nvidia";

      # ─── Wayland Compatibility ───────────────────────
      # MOZ_DBUS_REMOTE = "1";
      # WLR_RENDERER_ALLOW_SOFTWARE = "1";
      # _JAVA_AWT_WM_NONREPARENTING = "1";

      # ─── QT Debugging (Optional Silence) ─────────────
      # QT_LOGGING_RULES = "*=false";
    };

    # -------------------------------------------------------------
    # Session-level environment variables (GUI)
    # -------------------------------------------------------------
    environment.sessionVariables = {
      MOZ_ENABLE_WAYLAND = "1";
      NIXOS_OZONE_WL = "1";
      OBS_USE_EGL = "1";
      WLR_NO_HARDWARE_CURSORS = "1";
      __GL_YIELD = "USLEEP";
      __GL_GSYNC_ALLOWED = "1";
      __GL_VRR_ALLOWED = "1";
    };

    # -------------------------------------------------------------
    # System packages for NVIDIA / Vulkan
    # -------------------------------------------------------------
    environment.systemPackages = with pkgs; [
      # libva-utils
      # libva
      # nvidia-persistenced
      # nvidia-vaapi-driver
      # nvidiaPackage.persistenced
      # xrandr
      symbola
      egl-wayland
      vulkan-loader
      vulkan-tools
      vulkan-validation-layers
    ];

    # -------------------------------------------------------------
    # Main NVIDIA driver config
    # -------------------------------------------------------------   
    # systemctl status nvidia-persistenced.service ✅ Good addition as it helps with driver reliability.
    hardware.nvidia = {
      modesetting.enable = true;
      nvidiaPersistenced = true;
      nvidiaSettings = cfg.nvidiaSettings;
      open = true;
      package = nvidiaPackage;
      powerManagement = {
        enable = true; # disable if suspend fails
        finegrained = false; # true is for laptops with hybrid nvidia integrated
      };

    };

    # -------------------------------------------------------------
    # OpenGL + VAAPI integration
    # -------------------------------------------------------------
    hardware.graphics = {
      enable = true;
      # enable32Bit = true;
      extraPackages = with pkgs;
        [
          # nvidia-vaapi-driver   # NVIDIA VAAPI driver is experimental and not always reliable on Turing cards. You might skip nvidia-vaapi-driver if you see glitches!!!
          # libvdpau-va-gl
          # vaapiVdpau
          libva-utils
        ];
    };

  };

}
