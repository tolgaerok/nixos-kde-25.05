with import <nixpkgs> { }; {
  environment.systemPackages = with pkgs; [
    (pkgs.buildFHSEnvBubblewrap {
      name = "linuxtweaks";
      targetPkgs = pkgs: with pkgs; [
        (python311.withPackages (ps: with ps; [
          numpy
          opencv4
          pillow
          pycairo
          pygobject3
          pyqt6
          pyqt6-sip
          ocrmypdf
        ]))
        gtk4
        gtk4.dev
        gtk3
        gtk3.dev
        gobject-introspection
        gobject-introspection.dev
        adwaita-icon-theme
        atk
        cairo
        ffmpeg
        glib
        glib.dev
        libGL
        libxkbcommon
        pango
        qt5.qtbase
        qt5.qtwayland
        zlib
      ];

      profile = ''
        export QT_QPA_PLATFORM=wayland
        export GI_TYPELIB_PATH=${pkgs.gtk4.dev}/lib/girepository-1.0:${pkgs.gtk3}/lib/girepository-1.0:${pkgs.gobject-introspection}/lib/girepository-1.0
        export LD_LIBRARY_PATH=${pkgs.gtk4}/lib:${pkgs.glib}/lib:$LD_LIBRARY_PATH
      '';
      runScript = "bash";
    })
  ];
}
