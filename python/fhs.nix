# fhs.nix
with import <nixpkgs> {};

let
  pythonEnv = python311.withPackages (ps: with ps; [
    pygobject3
  ]);
in

buildFHSUserEnv {
  name = "gtk4-python-env";
  targetPkgs = pkgs: with pkgs; [
    gtk4
    gobject-introspection
    pythonEnv
  ];
  multiPkgs = pkgs: with pkgs; [ ];
  runScript = "bash";
}

# must run from home dir
#     nix-build fhs.nix
#     ./result/bin/gtk4-python-env