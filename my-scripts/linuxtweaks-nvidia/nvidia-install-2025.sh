#!/bin/bash
# Tolga Erok
# 21/3/2025
# Personal Nvidia Installer

clear
echo "  ¯\_(ツ)_/¯"
echo "█████▒▓█████ ▓█████▄  ▒█████   ██▀███   ▄▄▄"
echo "▓██   ▒ ▓█   ▀ ▒██▀ ██▌▒██▒  ██▒▓██ ▒ ██▒▒████▄"
echo "▒████ ░ ▒███   ░██   █▌▒██░  ██▒▓██ ░▄█ ▒▒██  ▀█▄"
echo "░▓█▒  ░ ▒▓█  ▄ ░▓█▄   ▌▒██   ██░▒██▀▀█▄  ░██▄▄▄▄██"
echo "░▒█░    ░▒████▒░▒████▓ ░ ████▓▒░░██▓ ▒██▒ ▓█   ▓██▒"
echo "▒ ░    ░░ ▒░ ░ ▒▒▓  ▒ ░ ▒░▒░▒░ ░ ▒▓ ░▒▓░ ▒▒   ▓▒█░"
echo "░       ░ ░  ░ ░ ▒  ▒   ░ ▒ ▒░   ░▒ ░ ▒░  ▒   ▒▒ ░"
echo "░ ░       ░    ░ ░  ░ ░ ░ ░ ▒    ░░   ░   ░   ▒"
echo "░  ░      ░    ░ ░     ░              ░  ░   ░"
echo "https://github.com/massgravel/Microsoft-Activation-Scripts"

# Define RPM Fusion URLs for automatic installation
RPMFUSION_URLS=(
    "https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm"
    "https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm"
)

# Install RPM Fusion repositories
echo "Installing RPM Fusion repositories..."
sudo dnf install -y "${RPMFUSION_URLS[@]}"

# Install NVIDIA drivers and related packages
echo "Installing NVIDIA drivers and related packages..."
sudo dnf install -y akmod-nvidia xorg-x11-drv-nvidia-cuda xorg-x11-drv-nvidia-cuda-libs xorg-x11-drv-nvidia-power nvidia-settings nvidia-vaapi-driver libva-utils vdpauinfo

# Update GRUB configuration to enable NVIDIA modesetting
echo "Updating GRUB configuration..."
sudo grubby --update-kernel=ALL --args='nvidia-drm.modeset=1'

# Regenerate initramfs
echo "Regenerating initramfs..."
sudo dracut --regenerate-all --force

# Install DNF5 and its plugins
echo "Installing DNF5 and plugins..."
sudo dnf install -y dnf5
sudo dnf5 install -y dnf5 dnf5-plugins

# Update the system with DNF5 and refresh the cache
echo "Updating system with DNF5..."
sudo dnf5 update -y && sudo dnf5 makecache

# Update the system with DNF and install necessary packages
echo "Updating system with DNF..."
sudo dnf update -y
sudo dnf upgrade --refresh -y
sudo dnf install -y dnf-plugins-core fedora-workstation-repositories

# Enable RPM Fusion nonfree NVIDIA driver repository
echo "Enabling RPM Fusion nonfree NVIDIA driver repository..."
sudo dnf config-manager --set-enabled rpmfusion-nonfree-nvidia-driver

# Install additional packages (akmods, openssl)
echo "Installing akmods and openssl..."
sudo dnf install -y akmods openssl

# Blacklist certain kernel modules (nouveau and iTCO_wdt)
echo "Blacklisting nouveau and iTCO_wdt modules..."
echo "blacklist nouveau" | sudo tee -a /etc/modprobe.d/blacklist.conf
echo "blacklist iTCO_wdt" | sudo tee -a /etc/modprobe.d/blacklist.conf

# Modify GRUB to blacklist nouveau and enable NVIDIA modesetting
echo "Modifying GRUB for NVIDIA..."
sudo sed -i '/GRUB_CMDLINE_LINUX/ s/"$/ rd.driver.blacklist=nouveau modprobe.blacklist=nouveau nvidia-drm.modeset=1"/' /etc/default/grub

echo "Script completed. Please reboot your system for changes to take effect."
