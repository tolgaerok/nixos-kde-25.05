#!/usr/bin/env bash
# Tolga Erok
# my script sets up Virt-Manager, Gamemode, and Lutris/Wine dependencies on Fedora.
# It installs necessary packages, configures user groups, and ensures services are running.


set -euo pipefail
IFS=$'\n\t' # enable strict error handling and proper word splitting

# ══o 🎮 Lutris/Wine Dependencies ═══════════════════════════════════════════
echo -e "\n⏳ Fetching Lutris + Wine setup..."
# Fetch and run the Lutris Wine dependencies script
# This script installs necessary dependencies for Lutris and Wine on Fedora.
if curl -fsSL https://raw.githubusercontent.com/xelser/distro-scripts/main/modules/lutris_wine_dep.sh | bash; then
    echo "🎮 Lutris Wine setup done."
else
    echo "⚠️  Lutris Wine setup failed — continuing anyway."
fi

sudo dnf install --assumeyes wine-core{,.i686}

# ═══ 🕹️ Gaming + Vulkan + Steam Stack (Fedora) ════════════════════════════
echo -e "\n📦 Installing gaming tools..."
sudo dnf install --assumeyes steam lutris libayatana-appindicator-gtk3 \
    gamemode.{x86_64,i686} mangohud.{x86_64,i686} \
    vulkan-tools mesa-demos

# ═══ ⚙️ Enable Gamemode Group If Exists ════════════════════════════════════
if getent group gamemode >/dev/null; then
    sudo usermod -aG gamemode "$USER"
    echo "🧪 Added $USER to 'gamemode' group."
else
    echo "⚠️  Group 'gamemode' not found — skipping."
fi

# ═══ 🖥️ Install Virtualization Stack (Fedora) ══════════════════════════════
echo -e "\n📦 Installing virtualization packages..."
sudo dnf install --assumeyes qemu-kvm qemu-system-x86 libvirt-client \
    libvirt-daemon bridge-utils virt-manager

# ═══ 🔌 Enable and Start Libvirt Services ══════════════════════════════════
echo -e "\n🚀 Enabling libvirtd service..."
sudo systemctl enable --now libvirtd

echo -e "\n🌐 Starting default libvirt network..."
sudo virsh net-start default 2>/dev/null || echo "ℹ️  'default' network already active."
sudo virsh net-autostart default

# ═══ 🧠 Distro-Aware Group Assignment ══════════════════════════════════════
echo -e "\n🔍 Detecting distro and assigning groups..."
distro_id=$(source /etc/os-release && echo "$ID")

# ═══ 🛡️ Add User to Required Groups ═══════════════════════════════════════
for grp in libvirt kvm input disk; do
    if id -nG "$USER" | grep -qw "$grp"; then
        echo "👤 $USER already in $grp"
    else
        sudo usermod -aG "$grp" "$USER"
        echo "➕ Added $USER to $grp"
    fi
done

# Distro-specific
case "$distro_id" in
debian | ubuntu)
    sudo usermod -aG libvirt-qemu "$USER"
    ;;
arch)
    sudo usermod -aG uucp "$USER"
    ;;
fedora)
    : # already handled
    ;;
esac

# ═══ 🔥 Configure Firewall for Virtualization (Fedora) ═════════════════════
sudo firewall-cmd --zone=FedoraWorkstation --add-service=dns --permanent
sudo firewall-cmd --zone=FedoraWorkstation --add-masquerade --permanent
sudo firewall-cmd --zone=libvirt --add-masquerade --permanent
sudo firewall-cmd --reload

# ═══ 🔄 Reset Default Network (if needed) ══════════════════════════════════
if [[ -f /usr/share/libvirt/networks/default.xml ]]; then
    sudo virsh net-destroy default || true
    sudo virsh net-undefine default || true
    sudo cp /usr/share/libvirt/networks/default.xml /tmp
    sudo virsh net-define /tmp/default.xml
    sudo virsh net-start default
    sudo virsh net-autostart default
else
    echo "❌ default.xml not found. Skipping network redefinition."
fi

# ═══ ✅ Confirmation ═══════════════════════════════════════════════════════
echo -e "\n🛡️  User \e[1m$USER\e[0m is now in these groups:"
groups "$USER"

echo -e "\n🔁 You MUST reboot or re-log to apply all changes — especially group membership and virtualization."
echo -e "\n🎉 Setup complete! Enjoy your gaming and virtualization experience on Fedora!"
