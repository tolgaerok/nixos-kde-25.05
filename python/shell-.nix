
with import <nixpkgs> {};

mkShell {
  buildInputs = [
    python311
    (python311.withPackages(ps: with ps; [
      pygobject       # This is the key to get gi module
      numpy
      opencv4
      pillow
      pycairo
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

  shellHook = ''
    export QT_QPA_PLATFORM=wayland
    export GI_TYPELIB_PATH=${gtk4.dev}/lib/girepository-1.0:${gtk3}/lib/girepository-1.0:${gobject-introspection}/lib/girepository-1.0
    export LD_LIBRARY_PATH=${gtk4}/lib:${glib}/lib:$LD_LIBRARY_PATH
  '';
}
