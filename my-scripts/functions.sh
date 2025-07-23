#!/run/current-system/sw/bin/bash
#export PATH=/run/current-system/sw/bin:$PATH

fns() {
    sudo nix-store --verify --check-contents --repair
}

