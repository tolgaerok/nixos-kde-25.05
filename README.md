# nixos-kde-25.05
### My personal NixOs 25.05 config

# NixOS 25.05 KDE NVIDIA

```bash
# Tolga Erok
# 22/7/2025
# Post Nixos setup!
# ¯\_(ツ)_/¯

cd $HOME
nix-env -iA nixos.git
git clone https://github.com/tolgaerok/nixos-kde-25.05.git
cd nixos-kde
sudo cp /etc/nixos/configuration.nix /etc/nixos/configuration.nix.bak
sudo cp /etc/nixos/hardware-configuration.nix /etc/nixos/hardware-configuration.nix.bak
sudo rsync -av --exclude='.git' ./* /etc/nixos
sudo chown -R $(whoami):$(id -gn) /etc/nixos
sudo chmod -R 777 /etc/nixos
sudo chmod +x /etc/nixos/*
export NIXPKGS_ALLOW_INSECURE=1
```
