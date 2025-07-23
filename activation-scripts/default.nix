{ config, pkgs, lib, username, ... }:

with lib;
let
  username = builtins.getEnv "USER";
  name = "tolga"; # Define the user name

  createUserXauthority = lib.mkForce ''
    if [ ! -f "/home/${name}/.Xauthority" ]; then
      xauth generate :0 . trusted
      touch /home/${name}/.Xauthority
      chmod 600 /home/${name}/.Xauthority
    fi
  '';
in {
  #---------------------------------------------------------------------
  # Custom activationScripts
  #---------------------------------------------------------------------
  system.activationScripts = {

    # Custom Information Script shown after rebuilds
    # customInfoScript = lib.mkAfter ''
    #  ${pkgs.bash}/bin/bash /etc/nixos/core/system/systemd/custom-info-script.sh
    # '';

    #---------------------------------------------------------------------
    # Create personal directories
    #---------------------------------------------------------------------
    text = ''
      for dir in MUM DAD WORK SNU Documents Downloads Music Pictures Videos MyGit DLNA Applications Universal .icons .ssh; do
        mkdir -p /home/${name}/$dir
        chown ${name}:${name} /home/${name}/$dir
      done
    '';
  };
}
