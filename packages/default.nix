{ config, pkgs, lib, ... }:

with lib;

let
  # Binary paths for SSH operations
  add = "${pkgs.openssh}/bin/ssh-add";
  agent = "${pkgs.openssh}/bin/ssh-agent";
  keygen = "${pkgs.openssh}/bin/ssh-keygen";

  # Script to generate an SSH key if it doesn't exist
  genSshKey = pkgs.writeShellScriptBin "gen-ssh-key" ''
    set -e

    if [[ -f $HOME/.ssh/id_ed25519 ]]; then
      echo "🔐 SSH key already exists."
      exit 0
    fi

    ${keygen} -t ed25519 -C "$1" -f "$HOME/.ssh/id_ed25519"
    eval $(${agent} -s)
    ${add} $HOME/.ssh/id_ed25519
    echo "🔑 SSH key generated and added to agent."
  '';
in {
  imports = [ ./custom-pkgs ];

  environment.systemPackages = with pkgs; [
    # Core tools
    curl
    direnv
    distrobox
    figlet
    fortune
    git
    libnotify
    lsd
    vim
    wget

    # KDE / Qt tools
    kdePackages.kate
    kdePackages.konsole
    qt5.qtbase
    qt5.qtwayland

    # Browsers
    google-chrome

    # Office & productivity
    variety
    wpsoffice

    # Compression and archive tools
    atool
    gzip
    lz4
    lzip
    lzo
    lzop
    p7zip
    rar
    rzip
    unzip
    xz
    zip
    zstd
    file

    # Network & file systems
    cifs-utils
    nfs-utils

    # Audio & multimedia
    alsa-utils
    audacity
    ffmpeg
    ffmpegthumbnailer
    libdvdcss
    libdvdread
    libopus
    libvorbis
    mediainfo
    mediainfo-gui
    mpg123
    mplayer
    mpv
    ocamlPackages.gstreamer
    pavucontrol
    pulseaudio
    simplescreenrecorder
    video-trimmer

    # Graphics
    gimp-with-plugins

    # Backup tools
    borgbackup
    restic
    restique

    # Development tools
    busybox

    gcc
    glxinfo
    imagemagickBig
    inxi
    killall
    libeatmydata
    libnotify
    lshw
    ncdu
    nix-direnv
    nixfmt-classic
    nixfmt-rfc-style
    nixos-option
    pciutils
    pkg-config

    rPackages.convert
    ripgrep
    ripgrep-all
    ruby
    socat
    # toybox
    vscode
    vscode-extensions.brettm12345.nixfmt-vscode
    vscode-extensions.mkhl.direnv

    # Fun & fancy
    fastfetch
    lolcat
    nordic
    rofimoji
    yad
    zenity

    # Flatpak
    flatpak

    # Other utilities
    duf
    kdePackages.kde-cli-tools
    kdePackages.kpipewire
    libsForQt5.kpipewire
    pipewire
    scdl

    nvme-cli

    # Custom tools
    genSshKey

    adwaita-icon-theme
    atk
    cairo
    ffmpeg
    glib
    glib.dev
    gobject-introspection
    gobject-introspection.dev
    gtk3
    gtk3.dev
    gtk4
    libGL
    libxkbcommon
    pango
    qt5.qtbase
    qt5.qtwayland
    zlib

    python311
    python311Full
    python311Packages.numpy
    python311Packages.opencv4
    python311Packages.pillow
    python311Packages.pip
    python311Packages.pycairo
    python311Packages.pygobject3
    python311Packages.pyqt6
    python311Packages.pyqt6-sip
    python313Packages.pip
    python313Packages.pipx

  ];
}
