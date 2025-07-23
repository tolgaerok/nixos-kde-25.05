{ config, pkgs, lib, modulesPath, user, username, ... }:
# sudo chown -R $(whoami):$(id -gn) /etc/nixos && sudo chmod -R 777 /etc/nixos && sudo chmod +x /etc/nixos/* && export NIXPKGS_ALLOW_INSECURE=1

let

in {

  imports = [
    # -----------------------------------------------
    # 
    # -----------------------------------------------
  ];

  
  # ----------------------------------------------------------------------------
  # Environment values
  # ----------------------------------------------------------------------------
  environment = {
    sessionVariables.NIXPKGS_ALLOW_UNFREE = "1";
    systemPackages = with pkgs;
      [

      ];
  };

  # ----------------------------------------------- #
  # Baloo indexing daemon disable
  # ----------------------------------------------- #
  environment = {
    etc."xdg/baloofilerc".source = (pkgs.formats.ini { }).generate "baloorc" {
      "Basic Settings" = {
        "Indexing-Enabled" = false;

      };
    };
  };
}
