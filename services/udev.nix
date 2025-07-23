{ config, pkgs, lib, ... }:

{
  # ----------------------------------------------------------------------------
  # Udev is Linux’s device manager 
  # ----------------------------------------------------------------------------
  services = {

    udev = {
      enable = true;
      extraRules = ''
        # sound devices to audio group
        KERNEL=="rtc0", GROUP="audio"
        KERNEL=="hpet", GROUP="audio"

        # Set scheduler to 'none' for SSDs (SATA, eMMC, NVMe)
        ACTION=="add|change", KERNEL=="sd[a-z]", TEST=="queue/scheduler", ATTR{queue/rotational}=="0", ATTR{queue/scheduler}="none"
        ACTION=="add|change", KERNEL=="mmcblk[0-9]", TEST=="queue/scheduler", ATTR{queue/scheduler}="none"
        ACTION=="add|change", KERNEL=="nvme[0-9]n[0-9]", TEST=="queue/scheduler", ATTR{queue/scheduler}="none"

        # Power saving tweaks (adjust "auto" for laptops, "off" for aggressive desktop saving)
        ACTION=="add", SUBSYSTEM=="usb", TEST=="power/control", ATTR{power/control}="off"
        ACTION=="add", SUBSYSTEM=="pci", TEST=="power/control", ATTR{power/control}="off"
      '';
    };
  };
}
