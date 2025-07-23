#!/bin/bash
# Tolga Erok
# 29/04/2025
# BETA
# CREDITS: https://yad-guide.ingk.se/
# EMOJI  : https://emojipedia.org/en

# check for YAD; install if missing
if ! command -v yad &>/dev/null; then
    echo "Installing yad..."
    sudo dnf5 install -y yad &>/dev/null || {
        zenity --error --text="Failed to install 'yad'. Exiting."
        exit 1
    }
fi

# confirmation prompt at start
yad --question \
    --title="Confirm NVIDIA Installation" \
    --image="/home/tolga/Pictures/combined.png" \
    --text=" 👋 Welcome to the LinuxTweaks NVIDIA Installer

This utility will guide you through a complete setup of proprietary NVIDIA drivers on Fedora.

It will perform the following actions:

🟢  Remove conflicting NVIDIA packages
🟢  Add the official Negativo17 NVIDIA repository
🟢  Install NVIDIA drivers with CUDA and VAAPI support
🟢  Apply kernel and GRUB optimizations
🟢  Configure X11 and essential systemd services
🟢  Set environment variables for desktop and app compatibility
🟢  Rebuild initramfs for all kernels
🟢  Configure MPV for VAAPI acceleration
🟢  Perform final checks and verifications

🖳   Do you want to proceed with the installation?" \
    --width=500 --center \
    --button="No:1" --button="Yes:0"

# exit if yes
if [[ $? -ne 0 ]]; then
    yad --info \
        --title="Cancelled" \
        --image="/home/tolga/Pictures/LT.png" \
        --text="Installation aborted by user.\n\nThank you for trying out LinuxTweaks!" \
        --width=400 --center
    exit 1
fi

# YAD progress bar wrapper: CREDITS: https://yad-guide.ingk.se/
fancy() {
    local width=40
    local line1="📡 Downloading & Installing:"
    local line2="$1"
    local padded1 padded2

    # Escape & for GTK markup
    line1=${line1//&/&amp;}
    line2=${line2//&/&amp;}

    # Center text using padded printf
    padded1=$(printf "%*s" $(((${#line1} + width) / 2)) "$line1")
    padded2=$(printf "%*s" $(((${#line2} + width) / 3)) "$line2")

    (
        echo "10"
        echo "# Starting: $1"
        sleep 0.3
        echo "30"
        eval "$2" &>>/tmp/task.log
        sleep 0.3
        echo "70"
        sleep 0.3
        echo "100"
        echo "# Done: $1"
    ) | yad --progress \
        --title="LinuxTweaks NVIDIA Installer" \
        --image="/home/tolga/Pictures/LT2.png" \
        --text="<tt>$padded1\n$padded2</tt>" \
        --percentage=0 \
        --width=500 \
        --center \
        --auto-close \
        --no-buttons \
        --window-icon=dialog-information

    if [[ $? -ne 0 ]]; then
        yad --text-info \
            --title="Error Log: $1 Failed" \
            --filename="/tmp/task.log" \
            --width=600 --height=400 \
            --button="Close":0
    fi
}

# reboot
reboot() {
    yad --question \
        --title="Reboot Required" \
        --image="/home/tolga/Pictures/LT2.png" \
        --text="Reboot now to apply changes?" \
        --width=350 --center \
        --button="No":1 --button="Yes":0

    if [[ $? -eq 0 ]]; then
        sudo reboot
    else
        yad --info \
            --title="Reboot Later" \
            --image="/home/tolga/Pictures/LT2.png" \
            --text="You can reboot manually later to apply changes." \
            --width=350 --center
    fi
}

# NVIDIA service status
status() {
    summary=""

    for service in \
        nvidia-persistenced.service \
        nvidia-hibernate.service \
        nvidia-resume.service \
        nvidia-suspend.service; do

        if systemctl is-enabled --quiet "$service"; then
            # persistenced should always be actively running if enabled
            if [[ "$service" == "nvidia-persistenced.service" ]]; then
                if systemctl is-active --quiet "$service"; then
                    icon="🟢"
                    state="Active"
                else
                    icon="🔴"
                    state="Enabled but not running!"
                fi

                # on-demand units: treat "enabled" as yellow, "active" as green
            else
                if systemctl is-active --quiet "$service"; then
                    icon="🟢"
                    state="Active (triggered)"
                else
                    icon="🟡"
                    state="Enabled (on-demand)"
                fi
            fi

        else
            icon="�"
            state="Disabled"
        fi

        summary="$summary\n$icon $service — $state"
    done

    yad --info \
        --title="NVIDIA Services Status" \
        --image="/home/tolga/Pictures/LT2.png" \
        --no-markup \
        --text="Summary of NVIDIA services:\n$summary" \
        --width=500 --height=300 --center --button="OK:0"
}

# -----------------------------
# Main Tasks (TESTING GROUND)
# -----------------------------
# fancy "Installing gum and dnf plugins" "sudo dnf5 install -y gum dnf-plugins-core"
# fancy "Updating system packages" "sudo dnf5 update --refresh -y"
# fancy "Setting up NVIDIA repository" "sudo curl -o /etc/yum.repos.d/fedora-nvidia.repo https://negativo17.org/repos/fedora-nvidia.repo"
# fancy "Installing NVIDIA drivers" "sudo dnf5 install -y akmod-nvidia nvidia-driver nvidia-settings"
fancy " 🔧 Updating system and removing conflicting NVIDIA components..." 'bash -c "
echo \"🔄 Removing old NVIDIA and VA-API packages...\"
sudo dnf5 remove -y dkms-nvidia libva-nvidia-driver libva-vdpau-driver nvidia-settings

echo \"🧹 Cleaning DNF cache...\"
sudo dnf5 clean all
sudo rm -rf /var/cache/dnf5

echo \"🔄 Refreshing and upgrading system packages...\"
sudo dnf5 upgrade --refresh -y

echo \"📦 Installing DNF plugins and Gum...\"
sudo dnf5 install -y dnf-plugins-core gum

echo \"✅ System updated and conflicts removed.\"
"'
fancy " 📦 Setting up Negativo17 NVIDIA repository..." 'bash -c "
echo \"📥 Downloading Negativo17 repo file...\"
sudo curl -fsSL -o /etc/yum.repos.d/fedora-nvidia.repo https://negativo17.org/repos/fedora-nvidia.repo

echo \"🔧 Enabling Negativo17 repository...\"
sudo dnf5 config-manager --set-enabled fedora-nvidia

echo \"✅ Negativo17 NVIDIA repository configured.\"
"'
fancy " 🔍 Checking nvidia-settings dependencies..." 'bash -c "
echo \"🔍 Querying dependencies for nvidia-settings...\"
sudo dnf5 repoquery --requires nvidia-settings

echo \"✅ Dependency check complete.\"
"'
fancy " 📦 Installing NVIDIA driver packages using akmod..." 'bash -c "
echo \"📦 Installing NVIDIA driver packages...\"
sudo dnf5 install -y \
    akmod-nvidia \
    nvidia-driver \
    nvidia-driver-cuda \
    nvidia-driver-libs.i686 \
    nvidia-persistenced \
    libva-utils \
    nvidia-vaapi-driver \
    nvidia-settings \
    vulkan \
    vulkan-tools \
    vulkan-loader \
    vulkan-validation-layers \
    --allowerasing

echo \"✅ NVIDIA driver packages installed.\"
"'
fancy " 🧹 Removing VA-API conflicts..." 'bash -c "
echo \"🧹 Uninstalling conflicting libva-vdpau-driver...\"
sudo dnf remove -y libva-vdpau-driver

echo \"🔄 Installing nvidia-vaapi-driver...\"
sudo dnf install -y nvidia-vaapi-driver --allowerasing --skip-broken

echo \"✅ VA-API conflicts resolved.\"
"'
fancy " 🛠️ Rebuilding initramfs and loading NVIDIA modules, please wait ..." 'bash -c "
echo \"🛠️ Regenerating initramfs with dracut...\"
sudo dracut --regenerate-all --force

echo \"🧱 Forcing akmods to build NVIDIA modules...\"
sudo akmods --force

echo \"🔌 Loading nvidia-drm kernel module...\"
sudo modprobe nvidia-drm

echo \"✅ Initramfs and NVIDIA modules successfully updated.\"
"'
fancy " 🚫 Blacklisting Nouveau and legacy framebuffer drivers..." 'bash -c "
echo \"🚫 Writing /etc/modprobe.d/blacklist-nvidia.conf...\"

sudo tee /etc/modprobe.d/blacklist-nvidia.conf > /dev/null <<EOF
blacklist nouveau
blacklist nvidiafb
blacklist rivafb
blacklist rivatv
blacklist vga16fb
blacklist iTCO_wdt
EOF

echo \"✅ Nouveau and legacy framebuffer modules blacklisted.\"
"'
fancy " 🖥️ Configuring X11 for NVIDIA" 'bash -c "
XORG_CONF_DIR=\"/etc/X11/xorg.conf.d\"
CONFIG_FILE=\"10-nvidia.conf\"

if [ ! -d \"$XORG_CONF_DIR\" ]; then
    echo \"❌ Error: X11 config directory does not exist.\"
    exit 1
fi

if [ -f \"$XORG_CONF_DIR/$CONFIG_FILE\" ]; then
    echo \"ℹ️ \$CONFIG_FILE already exists. Skipping creation.\"
else
    echo \"🖥️ Creating \$CONFIG_FILE with NVIDIA configuration...\"
    sudo tee \"$XORG_CONF_DIR/\$CONFIG_FILE\" > /dev/null <<EOF
Section \"OutputClass\"
    Identifier \"nvidia\"
    MatchDriver \"nvidia-drm\"
    Driver \"nvidia\"
    Option \"AllowEmptyInitialConfiguration\"
    Option \"SLI\" \"Auto\"
    Option \"BaseMosaic\" \"on\"
EndSection
EOF
    echo \"✅ NVIDIA X11 config added.\"
fi
"'
fancy " 🧩 Enabling NVIDIA DRM KMS..." 'bash -c "
echo \"🧩 Writing NVIDIA DRM KMS configuration...\"

echo \"🧩 Enable DRM KMS for NVIDIA (Wayland support, smooth boot splash):...\"
echo "options nvidia-drm modeset=1" | sudo tee /etc/modprobe.d/nvidia-drm.conf > /dev/null

echo \"🧩 Enable memory preservation and PAT for performance and resume-from-suspend stability:...\"
echo "options nvidia NVreg_PreserveVideoMemoryAllocations=1 NVreg_UsePageAttributeTable=1" | sudo tee /etc/modprobe.d/nvidia-triple.conf > /dev/null

echo \"🧩 Ensure nvidia-drm loads early (useful for initrd or Wayland setups):...\"
echo "nvidia-drm" | sudo tee -a /etc/modules-load.d/nvidia.conf > /dev/null

echo \"🧩 Prevent Nouveau from being included in the initramfs (when using dracut):...\"
echo 'omit_drivers+=" nouveau "' | sudo tee /etc/dracut.conf.d/omit-nouveau.conf > /dev/null

echo \"✅ NVIDIA DRM KMS enabled and Nouveau omitted from initramfs.\"
"'
fancy " 🧠 Applying GRUB Kernel Parameters..." 'bash -c "
new_params=\"modprobe.blacklist=nouveau nvidia.modeset=1 nvidia-drm.modeset=1 zswap.enabled=1 zswap.compressor=lz4 zswap.max_pool_percent=10 zswap.zpool=zsmalloc transparent_hugepage=never io_delay=none rootdelay=0 iomem=relaxed\"
grub_file=\"/etc/default/grub\"

if ! grep -q \"$new_params\" \"\$grub_file\"; then
    echo \"🧠 Adding kernel parameters to GRUB...\"
    sudo sed -i \"/GRUB_CMDLINE_LINUX/ s/\\\"$/ \$new_params\\\"/\" \"\$grub_file\"
    echo \"✅ Kernel parameters added to GRUB.\"
else
    echo \"ℹ️ Kernel parameters already present. No changes made.\"
fi

echo \"🔃 Regenerating GRUB configuration...\"
sudo grub2-mkconfig -o /boot/grub2/grub.cfg > /dev/null
echo \"✅ GRUB configuration updated.\"
"'
fancy " 🌍 Setting environment variables..." 'bash -c "
echo \"🌍 Writing to /etc/environment...\"

sudo tee /etc/environment > /dev/null <<EOF
LIBVA_DRIVER_NAME=nvidia
MOZ_ENABLE_WAYLAND=1
NIXOS_OZONE_WL=1
OBS_USE_EGL=1
QT_LOGGING_RULES=\\\"*=false\\\"
WLR_NO_HARDWARE_CURSORS=1
__GL_SHADER_CACHE=1
EOF

echo \"✅ Environment variables set in /etc/environment.\"
"'

# Apply environment for current session
export LIBVA_DRIVER_NAME=nvidia
export MOZ_ENABLE_WAYLAND=1
export NIXOS_OZONE_WL=1
export OBS_USE_EGL=1
export QT_LOGGING_RULES='*=false'
export WLR_NO_HARDWARE_CURSORS=1
export __GL_SHADER_CACHE=1

fancy " 🎞️ Configuring MPV for VA-API..." 'bash -c "
mpv_conf_dir=\"$HOME/.config/mpv\"
mpv_conf_file=\"$mpv_conf_dir/mpv.conf\"

echo \"📁 Creating MPV config directory at: $mpv_conf_dir\"
mkdir -p \"$mpv_conf_dir\"

echo \"🎞️ Writing MPV VA-API settings to: $mpv_conf_file\"
cat > \"$mpv_conf_file\" <<EOF
# Use the modern GPU output path
vo=gpu-next
gpu-context=wayland

# Hardware decoding with (hwdec=auto-safe == safety fallback) performance
hwdec=vaapi

# High-quality scaling filters
scale=ewa_lanczossharp
cscale=ewa_lanczossharp
dscale=mitchell
tscale=oversample

# HDR tone-mapping (if needed)
hdr-compute-peak=yes
tone-mapping=bt.2390
tone-mapping-mode=auto
target-peak=400  # Adjust if your display supports higher nits

# Improve gradients on compressed content
deband=yes
deband-iterations=1
deband-threshold=48
deband-range=16

# Reduce CPU/GPU logging noise
msg-level=vo=error

# Avoid syncing quirks, improves smoothness
video-sync=display-resample
interpolation=yes
tscale=oversample
EOF

echo \"✅ MPV configured to use VA-API.\"
"'
# fancy "⚙️ Enabling NVIDIA system services..."  "sudo systemctl enable nvidia-{persistenced,hibernate,resume,suspend}.service"
# fancy "⚙️ Disable NVIDIA system services..."  "sudo systemctl disable nvidia-{persistenced,hibernate,resume,suspend}.service && systemctl --no-pager status nvidia-{persistenced,hibernate,resume,suspend}.service"
fancy " ⚙️ Enabling NVIDIA system services..." 'bash -c "
echo \"⚙️ Enabling NVIDIA system services...\"
sudo systemctl enable nvidia-{persistenced,hibernate,resume,suspend}.service
echo \"✅ NVIDIA services enabled.\"
"'

fancy " 🔧 Enabling NVIDIA systemd services..." 'bash -c "
echo \"🔧 Enabling NVIDIA services...\"
sudo systemctl enable nvidia-persistenced.service
sudo systemctl enable nvidia-suspend.service
sudo systemctl enable nvidia-resume.service
sudo systemctl enable nvidia-hibernate.service
echo \"✅ NVIDIA systemd services enabled.\"
"'

fancy " 🔁 Reloading system configuration..." 'bash -c "
echo \"🔁 Reloading udev rules...\"
sudo udevadm control --reload-rules && sudo udevadm trigger

echo \"📏 Applying sysctl configuration...\"
sudo sysctl --system && sudo sysctl -p

echo \"🗂️ Remounting filesystems and reloading systemd...\"
sudo mount -a && sudo systemctl daemon-reload

echo \"✅ System configuration reloaded successfully.\"
"'
fancy " 📋 Checking for pending restarts, please wait..." 'bash -c "
echo \"📋 Running: sudo dnf needs-restarting\"
sudo dnf needs-restarting

echo \"✅ Restart check complete.\"
"'
status
reboot
