{ pkgs ? import <nixpkgs> { } }:

pkgs.mkShell {
  buildInputs = with pkgs; [
    ruby # Includes Ruby development headers
    gcc # The C compiler
    make # The build tool
    pkg-config # Often useful for finding libraries
    # Add any other specific development libraries if errors persist
    # (e.g., pkgs.libyaml for gems that might depend on YAML)
  ];
}
