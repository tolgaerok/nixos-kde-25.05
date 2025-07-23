{ config, pkgs, lib, user, ... }:

{

  # ----------------------------------------------- #
  # OPTUS USB Router vers=1.0
  # ----------------------------------------------- #

  fileSystems."/mnt/Router" = {
    device = "//192.168.0.1/tolga";
    fsType = "cifs";
    options = [
      "credentials=/etc/nixos/samba/mnt/router-secrets"
      "noauto"
      "nofail"
      "rw"
      "sec=ntlmv2"
      "vers=1.0"
      "x-systemd.automount"
      "x-systemd.device-timeout=5s"
      "x-systemd.idle-timeout=60s"
      "x-systemd.mount-timeout=5s"
      "x-systemd.requires=network-online.target"
    ];
  };
}
