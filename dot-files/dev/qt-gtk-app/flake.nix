{
  description = "Fast dev shell";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.05";

  outputs = { self, nixpkgs }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs { inherit system; };
    in {
      devShells.${system}.default = pkgs.mkShell {
        packages = with pkgs; [ bash coreutils ];
        shellHook = ''
          echo "🚀 Dev shell loaded."
        '';
      };
      shellHook = ''
  start=$(date +%s)
  echo "🚀 Dev shell loading..."
  end=$(date +%s)
  echo "⏱️ Loaded in $((end - start))s"
'';

    };
}
