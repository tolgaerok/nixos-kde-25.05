{ config, lib, ... }: {

  ## 32bit Video drivers
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };
  boot = {
    # 1. Kill conflict modules early
    blacklistedKernelModules = lib.mkDefault [
      "nouveau"
      "nvidiafb"
      "rivafb"
      "rivatv"
      "vga16fb"
      "iTCO_wdt"
    ];

    # 2. Load these kernel modules at boot
    kernelModules = [ "nvidia" "nvidia_drm" "nvidia_modeset" ]; # "nvidia_uvm"

    # 3. Add kernel-specific module package
    # extraModulePackages = with config.boot.kernelPackages; [ nvidia_x11 ];

    # 4. NVIDIA driver options — optimized and grouped
    extraModprobeConfig = ''
      options nvidia NVreg_DynamicPowerManagement=0 NVreg_EnableMSI=1 NVreg_EnablePCIERelaxedOrderingMode=1 NVreg_EnablePCIeGen3=1 NVreg_EnableResizableBar=1 NVreg_EnableStreamMemOPs=1 NVreg_PreserveVideoMemoryAllocations=1 NVreg_RegistryDwords=RMIntrLockingMode=1 NVreg_UsePageAttributeTable=1
      options nvidia_drm modeset=1
    '';

    # 5. Runtime kernel params for GRUB and early boot
    kernelParams = [
      "nvidia.modeset=1"
      "nvidia_drm.modeset=1"
      "rd.driver.blacklist=nouveau"

    ];
  };

  services.xserver.videoDrivers = [ "nvidia" ];

  hardware.nvidia = {
    modesetting.enable = true;
    powerManagement.enable = true;
    powerManagement.finegrained = false;
    nvidiaPersistenced = true;

    open = false;
    nvidiaSettings = true;

    # package = config.boot.kernelPackages.nvidiaPackages.production;   
    package = config.boot.kernelPackages.nvidiaPackages.mkDriver {
      version = "575.64.03";
      sha256_64bit = "sha256-S7eqhgBLLtKZx9QwoGIsXJAyfOOspPbppTHUxB06DKA=";
      openSha256 = "sha256-PMh5efbSEq7iqEMBr2+VGQYkBG73TGUh6FuDHZhmwHk=";
      settingsSha256 = "sha256-ZpuVZybW6CFN/gz9rx+UJvQ715FZnAOYfHn5jt5Z2C8=";
      persistencedSha256 =
        "sha256-/3OAZx8iMxQLp1KD5evGXvp0nBvWriYapMwlMSc57h8=";
    };
  };

}
