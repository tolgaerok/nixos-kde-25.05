 fileSystems."/mnt/Relationships" = {
    device = "//192.168.0.17/RELATIONSHIPS";
    fsType = "cifs";
    options = [
      "cache=loose"
      "credentials=/etc/nixos/samba/mnt/smb-secrets"
      "gid=100"
      "iocharset=utf8"
      "noauto"
      "nofail"
      "rw"
      "soft"
      "uid=1000"
      "vers=2"
      # "x-systemd.automount" 
      "x-systemd.device-timeout=5s"
      "x-systemd.idle-timeout=10s"
      "x-systemd.mount-timeout=5s"
      "x-systemd.requires=network-online.target"
      "_netdev"
    ];
  };

  fileSystems."/mnt/Public" = {
    device = "//192.168.0.17/Public";
    fsType = "cifs";
    options = let
      uid = "1000";
      gid = "100";
      credentials = "/etc/nixos/samba/mnt/smb-secrets";
    in [
      "cache=loose"
      "credentials=${credentials}"
      "gid=${gid}"
      "iocharset=utf8"
      "noauto"
      "nofail"
      "rw"
      "soft"
      "uid=${uid}"
      "vers=3"
      # "x-systemd.automount" 
      "x-systemd.device-timeout=5s"
      "x-systemd.idle-timeout=10"
      "x-systemd.mount-timeout=5s"
      "x-systemd.requires=network-online.target"
      "_netdev"
    ];
  };