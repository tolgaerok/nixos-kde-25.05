{ config, pkgs, lib, username, ... }:

with lib;

let
  name = "tolga";
in
{
  # --------------------------------------------------------------------
  # System optimisations and Nix configuration
  # --------------------------------------------------------------------

  # Allow unfree packages (e.g. proprietary drivers)
  nixpkgs.config.allowUnfree = true;

  nix = {
    settings = {
      # Bigger buffer for downloads (helps with large store paths)
      download-buffer-size = 250000000;

      # Users allowed to run nix commands
      allowed-users = [ "@wheel" "${name}" ];

      # Auto deduplicate identical files in /nix/store
      auto-optimise-store = true;

      # Enable flakes and new nix command
      experimental-features = [
        "flakes"
        "nix-command"
        # "repl-flake"
      ];

      # Use all available cores (0 = auto detect)
      cores = 0;

      # Relax sandboxing a bit for some builds
      sandbox = "relaxed";

      # Users trusted to run nix builds as root
      trusted-users = [ "${name}" "@wheel" "root" ];

      # Keep derivations and outputs in GC roots (helps debugging)
      keep-derivations = true;
      keep-outputs = true;

      # Silence warnings when building from a dirty git repo
      warn-dirty = false;

      # How long nix should trust downloaded tarballs
      tarball-ttl = 300;

      # Substitute caches to fetch prebuilt binaries
      substituters = [
        "https://cache.nixos.org"
        # "https://cache.nix.cachix.org"
      ];

      # Which substituters are trusted for binary downloads
      trusted-substituters = [
        "https://cache.nixos.org"
        # "https://cache.nix.cachix.org"
      ];
    };

    # Set low CPU scheduling priority for the nix daemon
    daemonCPUSchedPolicy = "idle";

    # Lower IO priority for nix daemon (7 = low priority)
    daemonIOSchedPriority = 7;

    # Garbage collection settings
    gc = {
      automatic = true;
      dates = "Mon 3:40";
      randomizedDelaySec = "14m";
      options = "--delete-older-than 30d";
    };
  };
}
