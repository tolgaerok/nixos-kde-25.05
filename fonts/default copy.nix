{ pkgs, ... }:

let
  wpsFonts = pkgs.stdenv.mkDerivation {
    pname = "wps-fonts";
    version = "latest";
    src = pkgs.fetchzip {
      url = "https://github.com/tolgaerok/fonts-tolga/raw/main/WPS-FONTS.zip";
      sha256 = "Pzl1+g8vaRLm1c6A0fk81wDkFOnuvtohg/tW+G1nNQo=";
      stripRoot = false;
    };
    installPhase = ''
      mkdir -p $out/share/fonts
      cp -r $src/* $out/share/fonts/
      if [ -f "$out/share/fonts/WEBDINGS.TTF" ]; then
        mv "$out/share/fonts/WEBDINGS.TTF" "$out/share/fonts/Webdings.ttf"
      fi
    '';
  };
in {

  _module.args.username = "tolga";

  nixpkgs.overlays = [
    (self: super: {
      symbola = super.symbola.overrideAttrs (old: {
        src = builtins.path {
          # path = "/home/tolga/sources/symbola.zip";
          path = "/home/" + username + "/sources/symbola.zip";
          name = "symbola.zip";
        };
        dontUnpack = true;
        nativeBuildInputs = [ super.unzip ];
        installPhase = ''
          mkdir -p $out/share/fonts/truetype
          unzip $src '*.ttf' -d $out/share/fonts/truetype
        '';
      });
    })
  ];

  fonts = {
    packages = with pkgs; [
      corefonts
      fira-code
      fira-code-symbols
      font-awesome
      jetbrains-mono
      liberation_ttf
      material-icons
      nerd-fonts.jetbrains-mono
      noto-fonts
      noto-fonts-cjk-sans
      noto-fonts-emoji
      symbola
      wineWowPackages.fonts
      wpsFonts
    ];
  };
  environment.systemPackages = with pkgs; [ fontconfig wpsFonts ];

  #system.activationScripts.updateFontCache = ''
  #  echo "Updating font cache..."
  #  # ${pkgs.fontconfig}/bin/fc-cache -f -v
  #'';
}
