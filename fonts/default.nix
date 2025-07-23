{ pkgs, ... }:

let
  username = "tolga";

  mkUFASFont = name: info:
    pkgs.stdenv.mkDerivation {
      pname = name;
      version = "latest";
      # src = "/etc/nixos/fonts/ufas-fonts/${info.file}";
      src = pkgs.lib.cleanSource ("/etc/nixos/fonts/ufas-fonts/${info.file}");

      nativeBuildInputs = [ pkgs.unzip ];
      unpackPhase = "true";
      installPhase = ''
        mkdir -p $out/share/fonts
        unzip $src -d $out/share/fonts
        find $out/share/fonts -type f ! -name '*.ttf' ! -name '*.otf' -delete
      '';
    };

  ufasFontsTable = {
    aegan = { file = "Aegean.zip"; };
    aegyptus = { file = "Aegyptus.zip"; };
    akkadian = { file = "Akkadian.zip"; };
    assyrian = { file = "Assyrian.zip"; };
    eemusic = { file = "EEMusic.zip"; };
    maya = { file = "MayaHieroglyphs.zip"; };
    symbola = { file = "Symbola.zip"; };
    textfonts = { file = "Textfonts.zip"; };
    unidings = { file = "Unidings.zip"; };
  };

  ufasFontsPkgs = pkgs.lib.attrsets.mapAttrs (name: info: mkUFASFont name info)
    ufasFontsTable;

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

  _module.args.username = username;

  fonts = {
    packages = (with pkgs; [
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
      # symbola
      wineWowPackages.fonts
      wpsFonts
    ]) ++ (pkgs.lib.attrValues ufasFontsPkgs);
  };

  environment.systemPackages = [ pkgs.fontconfig wpsFonts ]
    ++ (pkgs.lib.attrValues ufasFontsPkgs);

  system.activationScripts.updateFontCache = ''
    echo "Updating font cache..."
    # ${pkgs.fontconfig}/bin/fc-cache -f -v
  '';
}

# /home/tolga/.local/share/fonts