{ config, pkgs, lib, user, ... }:

{

  # ----------------------------------------------- #
  # QNAP Server vers=3.0
  # ----------------------------------------------- #
  
  fileSystems."/mnt/Relationships" = {
    device = "//192.168.0.17/RELATIONSHIPS";
    fsType = "cifs";
    options = [
      "credentials=/etc/nixos/samba/mnt/qnap-secrets"
      "noauto"
      "nofail"
      "rw"
      "sec=ntlmssp"
      "users"
      "vers=3.0"
      "x-systemd.automount"
      "x-systemd.device-timeout=5s"
      "x-systemd.idle-timeout=60s"
      "x-systemd.mount-timeout=5s"
      # "gid=100"
      # "uid=1000"
      # "x-systemd.requires=network-online.target"
    ];
  };
  fileSystems."/mnt/QNAP_Public" = {
    device = "//192.168.0.17/Public";
    fsType = "cifs";
    options = [
      "credentials=/etc/nixos/samba/mnt/qnap-secrets"
      "noauto"
      "nofail"
      "rw"
      "sec=ntlmssp"
      "users"
      "vers=3.0"
      "x-systemd.automount"
      "x-systemd.device-timeout=5s"
      "x-systemd.idle-timeout=60s"
      "x-systemd.mount-timeout=5s"
      # "gid=100"
      # "uid=1000"
      # "x-systemd.requires=network-online.target"
    ];
  };
}
