{
  lib,
  config,
  pkgs,
  ...
}:

with lib;
{
  # ---------------------------------------------
  # PROGRAM SETTINGS
  # ---------------------------------------------
  programs.nix-ld.enable = true;

  programs = {
    firefox.enable = true;
    # direnv.enable = true;
    direnv = {
      enable = true;
      nix-direnv.enable = true;
    };
    nix-ld.libraries = with pkgs; [
      stdenv.cc.cc
      zlib
      fuse3
      icu
      nss
      openssl
      curl
      expat
      python311
      # ...
    ];

    # Some programs need SUID wrappers, can be configured further or are started in user sessions.
    # mtr.enable = true;
    gnupg.agent = {
      enable = true;
      enableSSHSupport = true;
    };
  };
}
