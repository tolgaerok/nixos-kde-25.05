{ config, lib, pkgs, ... }:

{
  # ----------------------------------------
  # open drivers test for my GTX1650
  # ----------------------------------------
  # sudo lsmod | grep nvidia ; modinfo nvidia | grep filename ; modinfo nvidia | grep license ; sudo dmesg | grep -i nvidia

  boot = {
    blacklistedKernelModules = lib.mkDefault [
      "iTCO_wdt"
      "nouveau"
      "nvidiafb"
      "rivafb"
      "rivatv"
      "vga16fb"
    ];
    extraModulePackages = [
      config.boot.kernelPackages.nvidia_x11

    ];
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
    kernelModules = [
      "nvidia"
      "nvidia_uvm"
      "nvidia_modeset"
      "nvidia_drm"

    ];
  };

  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

  # -------------------------------------------------------------
  # Set NVIDIA to X11
  # -------------------------------------------------------------
  services.xserver = {
    videoDrivers = [ "nvidia" ];
    enable = true; # true = X11 false =  Wayland session.
  };

  hardware.nvidia = {
    # enable = true;
    modesetting.enable = true;
    nvidiaPersistenced = true;
    nvidiaSettings = true;
    open = true;
    powerManagement.enable = true;
    powerManagement.finegrained = false;
  };

}
