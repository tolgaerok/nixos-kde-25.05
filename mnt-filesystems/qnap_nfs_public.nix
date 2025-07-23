{ config, ... }:

{
  fileSystems."/mnt/NFS_Public" = {
    device = "192.168.0.17:/Public";
    fsType = "nfs";
    options = [ "rw" "nofail" "x-systemd.automount" ];
  };

}
