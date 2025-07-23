with import <nixpkgs> {};

let
  python-with-pkgs = python311.withPackages (ps: with ps; [
    pip
    numpy
    opencv4
    pillow
    pycairo
    pyqt6
    ocrmypdf
    pygobject3
  ]);
in

mkShell {
  buildInputs = [
    pkgs.adwaita-icon-theme
    pkgs.cairo
    pkgs.ffmpeg
    pkgs.git
    pkgs.glib
    pkgs.glib.dev
    pkgs.gobject-introspection
    pkgs.gobject-introspection.dev
    #pkgs.gobject-introspection.typelib  # 🔥 ADD THIS
    pkgs.gtk3
    pkgs.gtk3.dev
    #pkgs.gtk3.typelib                    # 🔥 AND THIS
    pkgs.gtk4
    pkgs.gtk4.dev
    pkgs.libGL
    pkgs.libxkbcommon
    pkgs.pango
    python-with-pkgs
    pkgs.qt5.qtbase
    pkgs.qt5.qtwayland
    pkgs.qtcreator
    pkgs.zlib
  ];

  shellHook = ''
    export QT_QPA_PLATFORM=wayland

    export GI_TYPELIB_PATH="$(find ${pkgs.gtk3}/lib/girepository-1.0 -type d 2>/dev/null):$(find ${pkgs.gobject-introspection}/lib/girepository-1.0 -type d 2>/dev/null):$GI_TYPELIB_PATH"

    export LD_LIBRARY_PATH="${pkgs.gtk3}/lib:${pkgs.gobject-introspection}/lib:$LD_LIBRARY_PATH"
    export PS1="[\[\033[1;32m❄ nix-shell\033[0m\]] \w \$ "

    echo -e "\e[1;33m🎯  Entered Nix Dev Shell — PyQt6 and GTK environment is ready.\e[0m\n"

    python3 -c "from PyQt6.QtWidgets import QApplication; print('\033[1;32m      [+] ------ 🧿 PyQt6 is alive, brother ------ [+]\033[0m'); print()"
  '';

}
