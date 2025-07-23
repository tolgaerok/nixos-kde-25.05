{ config, pkgs, lib, user, ... }:

{

  # ----------------------------------------------- #
  # Temu Stick
  # ----------------------------------------------- #

  systemd.tmpfiles.rules = [
    "L /Temu - - - - /mnt/TemuStick"

  ];

  fileSystems."/mnt/TemuStick" = {
    device = "/dev/disk/by-uuid/3b23d4a5-b33f-4782-a8f8-721a820ee7b4";
    fsType = "ext4";
    options = [
      "async"
      "barrier=0"
      "data=writeback"
      "noauto"
      "nofail"
      "rw"
      "x-systemd.automount"
      "x-systemd.device-timeout=5s"
      "x-systemd.mount-timeout=5s"
    ];
  };
}
