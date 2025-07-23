{ config, lib, ... }:

{
  environment.etc."nixos/samba/mnt/qnap-secrets" = {
    text = ''
      username=admin
      password=ibm450
    '';
    mode = "0600";
  };
  environment.etc."nixos/samba/mnt/router-secrets" = {
    text = ''
      username=tolga
      domain=workgroup
      password=ibm450
    '';
    mode = "0600";
  };
}
