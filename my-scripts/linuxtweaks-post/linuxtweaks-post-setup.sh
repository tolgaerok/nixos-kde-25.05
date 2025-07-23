#!/usr/bin/bash
# Tolga Erok - My post setup script
# Date: 23/04/25
# Version: 3

done="✅"
error="⚠️"

#-----------------------------#
# temp directory              #
#-----------------------------#
temp_directory() {
    TMP_DIR=$(mktemp -d "${HOME}/$(date +'%d-%b-%Y-%I-%M%p').XXXXXX")

    # Check the temp directory
    if [ ! -d "$TMP_DIR" ]; then
        echo "⚠️ Error: Failed to create temp directory!"
        exit 1
    fi

    echo "Temp directory created at: $TMP_DIR"
}

#------------------------------------#
# check for YAD; install if missing  #
#------------------------------------#
if ! command -v yad &>/dev/null; then
    echo "Installing yad..."
    sudo dnf5 install -y yad &>/dev/null || {
        zenity --error --text="Failed to install 'yad'. Exiting."
        exit 1
    }
fi

#-----------------------------#
# check my temp directory     #
#-----------------------------#
temp_directory

#-----------------------------------#
# CD to the newly created temp dir  #
#-----------------------------------#
cd "$TMP_DIR" || exit 1
echo "Working in temp dir: $TMP_DIR"

# ─── Ensure Icon is Present ───────────────────────────────────────────────────
REAL_USER="${SUDO_USER:-$(logname)}"
USER_HOME=$(eval echo "~$REAL_USER")
icon_URL="https://raw.githubusercontent.com/tolgaerok/linuxtweaks/main/MY_PYTHON_APP/images/LinuxTweak.png"
icon_dir="$USER_HOME/.config"
icon_path="$icon_dir/LinuxTweak.png"
mkdir -p "$icon_dir"
wget -O "$icon_path" "$icon_URL"
chmod 644 "$icon_path"
clear

#-----------------------------#
# YAD progress bar wrapper    #
#-----------------------------#
fancy() {
    local width=40
    local line1="📡 Downloading & Installing:"
    local line2="$1"
    local padded1 padded2

    line1=${line1//&/&amp;}
    line2=${line2//&/&amp;}

    padded1=$(printf "%*s" $(((${#line1} + width) / 2)) "$line1")
    padded2=$(printf "%*s" $(((${#line2} + width) / 3)) "$line2")

    log_file="$HOME/linuxtweaks.log"
    touch "$log_file"
    status_file=$(mktemp)

    (
        echo "10"
        echo "# Starting: $1"
        sleep 0.3

        eval "$2" 2>&1 | tee -a "$log_file" | while IFS= read -r line; do
            if [[ "$line" == *"Downloading"* ]]; then
                echo "40"
            elif [[ "$line" == *"Installing"* ]]; then
                echo "70"
            elif [[ "$line" == *"Done"* ]]; then
                echo "100"
            fi
        done

        echo $? >"$status_file"
        sleep 0.3
    ) | yad --progress \
        --title="LinuxTweaks Post-Setup" \
        --image="$icon_path" \
        --text="<tt>$padded1\n$padded2</tt>" \
        --percentage=0 \
        --width=500 \
        --center \
        --auto-close

    cmd_exit_code=$(cat "$status_file")
    rm -f "$status_file"

    if [[ $cmd_exit_code -ne 0 ]]; then
        echo "⚠️  An error occurred during '$1'. Check log: $log_file"
        yad --error \
            --title="Error during $1" \
            --image="$icon_path" \
            --text="An error occurred while executing:\n\n$1\n\nCheck the log at:\n$log_file" \
            --width=400 \
            --center
    fi
}

reboot_func() {
    yad --question \
        --title="Reboot Required" \
        --image="$icon_path" \
        --text="Reboot now to apply changes?" \
        --width=350 --center \
        --button="No":1 --button="Yes":0

    if [[ $? -eq 0 ]]; then
        sudo reboot
    else
        yad --info \
            --title="Reboot Later" \
            --image="$icon_path" \
            --text="You can reboot manually later to apply changes." \
            --width=350 --center
    fi
}

#----------------------------------#
# 👋 confirmation prompt to start  #
#--------------------------- ------#
prompt_text=$(
    cat <<'EOF'
👋 Welcome to the LinuxTweaks Post-Setup Script

This utility will perform the following actions:

    🟢  Update your system and install DNF plugins
    🟢  Create a secure temporary workspace for installs
    🟢  Install WPS fonts from Tolga's GitHub repository
    🟢  Add system-wide useful fonts and refresh the cache
    🟢  Install essential CLI tools, utilities, and dev packages
    🟢  Install multimedia codecs, graphics, and photo tools
    🟢  Enable performance services like Preload
    🟢  Sync system time via `timedatectl`
    🟢  Set up SSH, virtualization tools, and networking utilities
    🟢  Download and install MegaSync and VSCode
    🟢  Provide a graphical progress bar and logging system
    🟢  Clean up temporary files after each stage

🚀   Do you want to proceed?
EOF
)

yad --question \
    --title="Confirm LinuxTweaks Post-Setup" \
    --image="$icon_path" \
    --no-markup \
    --text="$prompt_text" \
    --width=550 \
    --center \
    --button="No:1" \
    --button="Yes:0"

if [[ $? -ne 0 ]]; then
    yad --info \
        --title="Cancelled" \
        --image="$icon_path" \
        --no-markup \
        --text="Post-setup aborted by user.\n\nYou can run this script later when ready." \
        --width=400 \
        --center
    exit 1
fi

#-----------------------------#
# ⚠️ System Update
#-----------------------------#
fancy " ⚠️  Updating system and installing DNF plugins, please WAIT ..." 'bash -c "
    sudo dnf install -y \
        dnf dnf-plugins-core && sudo dnf upgrade --refresh -y"
'

#---------------------------------------#
# 🔧 WPS Font Installation from Tolga's Repo
#---------------------------------------#
fancy "🔧 Installing WPS Fonts..."

FONT_REPO="https://github.com/iamdh4/ttf-wps-fonts.git"
TMP_WPS="/tmp/wps_fonts_tmp"
CLONE_DIR="/tmp/ttf-wps-fonts"
SYS_FONT_DIR="/usr/share/fonts/wps-fonts"

#-----------------------------------#
# 🧹 Clean up any previous installs
#-----------------------------------#
fancy "🧹 Cleaning up previous installations..."
sudo rm -rf "$SYS_FONT_DIR" "$TMP_WPS" "$CLONE_DIR"
mkdir -p "$TMP_WPS"

#-----------------------------#
# 📥 Download fonts
#-----------------------------#
fancy "📥 Cloning font repo..."
git clone "$FONT_REPO" "$CLONE_DIR" || {
    fancy "❌ Download failed."
    exit 1
}

#-----------------------------#
# 📦 Install fonts to system
#-----------------------------#
fancy "📦 Installing fonts..."
sudo mkdir -p "$SYS_FONT_DIR"
sudo cp -v "$CLONE_DIR"/*.ttf "$SYS_FONT_DIR" || {
    fancy "❌ Font copy failed."
    exit 1
}

#-----------------------------#
# 🔐 Fix permissions
#-----------------------------#
sudo chmod 644 "$SYS_FONT_DIR"/*.ttf

#-----------------------------#
# 🔃 Refresh system font cache
#-----------------------------#
fancy "🔃 Refreshing font cache..."
fc-cache -f -v && sudo fc-cache -f -v
fancy "✅ Fonts installed to $SYS_FONT_DIR"

#-----------------------------#
# 🧹 Final cleanup
#-----------------------------#
fancy "🧹 Cleaning temp files..."
rm -rf "$TMP_WPS" "$CLONE_DIR"

#-----------------------------#
# 🛠️ Essential Tools
#-----------------------------#
fancy " 🔧 Installing essential tools & CLI utilities..." 'bash -c "
sudo dnf install -y \
    wget curl xclip rsync unzip zip unrar p7zip p7zip-plugins zstd \
    fd-find fzf lsd direnv python3 python3-pip openssl-devel libffi-devel \
    ffmpeg ffmpeg-devel mpv libva libva-utils libvdpau libvdpau-va-gl \
    cowsay fortune figlet lolcat neofetch htop nano gum duf kate iproute-tc \
    ghostscript ghostscript-tools-fonts ghostscript-tools-printing \
    git git-core git-core-doc \
    perl-Git perl-Error perl-TermReadKey perl-File-Find perl-lib \
    tesseract tesseract-langpack-eng tesseract-langpack-tur \
    yad --allowerasing --skip-unavailable"'

#-----------------------------#
# 🎞️ Multimedia Libraries
#-----------------------------#
fancy " 🔧 Installing multimedia and libraries..." 'bash -c "
sudo dnf install -y \
    @multimedia \
    gstreamer1-plugins-{bad-free,bad-free-libs,good,base} \
    lame{,-libs} \
    libjxl \
    fuse"'

#-----------------------------#
# 🧰 Development Tools
#-----------------------------#
fancy " 🔧 Installing development tools..." 'bash -c "
sudo dnf install -y \
    distribution-gpg-keys \
    fastfetch \
    fpaste \
    powertop \
    tuned-ppd \
    python3-deprecated python3-deprecation \
    python3-img2pdf python3-markdown-it-py python3-mdurl \
    python3-pdfminer python3-pikepdf python3-pluggy \
    python3-pygments python3-rich python3-wrapt qpdf-libs"'

#-------------------------------#
# 🖨️ Printing & Scanning Tools
#-------------------------------#
fancy " 🖨️ Installing printer & scanner support..." 'bash -c "
sudo dnf install -y \
    cups cups-browsed cups-filters cups-filters-driverless \
    cups-ipptool bluez-cups gutenprint-cups \
    plasma-print-manager plasma-print-manager-libs \
    hplip hplip-common hplip-libs libsane-hpaio \
    gspell gtksourceview3"'

#-----------------------------#
# 🎵 Media Tools
#-----------------------------#
fancy " 🎵 Installing media tools..." 'bash -c "
sudo dnf install -y \
    vlc vlc-core clementine rhythmbox mpg123 \
    ffmpeg ffmpegthumbnailer shotwell timeshift tumbler sassc"'

#-----------------------------#
# 🖼️ Graphics & Document Tools
#-----------------------------#
fancy " 🖼️ Installing graphics and document tools..." 'bash -c "
sudo dnf install -y \
    digikam sxiv variety gparted kate dconf-editor \
    antiword avahi-tools braille-printer-app libppd libcupsfilters \
    liblouisutdml liblouisutdml-utils net-snmp-libs \
    pngquant poppler-cpp poppler-utils"'

#-----------------------------#
# 🔒 Networking & SSH
#-----------------------------#
fancy " 🔒 Installing SSH and networking tools..." 'bash -c "
sudo dnf install -y \
    openssh-server openssh-clients sshpass"'

#-----------------------------#
# 💻 Virtualization
#-----------------------------#
fancy " 📦 Installing virtualization tools..." 'bash -c "
sudo dnf install -y \
    virt-manager dnfdragora rygel gtk3 libyui-mga-qt libyui-qt"'

#-----------------------------#
# ⚡ Preload
#-----------------------------#
fancy " ⚡ Enabling Preload for performance boost..." 'bash -c "
yes | sudo dnf copr enable atim/preload -y && \
yes | sudo dnf install -y preload && \
sudo systemctl enable --now preload.service && \
sudo systemctl status preload.service --no-pager"
'

#-----------------------------#
# ⏰ Time sync
#-----------------------------#
fancy " ⏰ Syncing system time..." 'bash -c "
sudo timedatectl set-ntp true"
'

#-----------------------------#
# 🔧 MegaSync and VSCode
#-----------------------------#
fancy " 🔧 Installing MegaSync and VSCode..." '
cd "$TMP_DIR" || exit 1

wget https://mega.nz/linux/repo/Fedora_42/x86_64/megasync-Fedora_42.x86_64.rpm
sudo dnf install -y megasync-Fedora_42.x86_64.rpm

sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc
echo "[code]
name=Visual Studio Code
baseurl=https://packages.microsoft.com/yumrepos/vscode
enabled=1
autorefresh=1
type=rpm-md
gpgcheck=1
gpgkey=https://packages.microsoft.com/keys/microsoft.asc" | sudo tee /etc/yum.repos.d/vscode.repo > /dev/null

sudo dnf check-update
sudo dnf install -y code

cd "$HOME"
rm -rf "$TMP_DIR"
'

#-----------------------------#
# 🔧 VSCode Extensions
#-----------------------------#
fancy " 🔧 Installing VSCode extensions..." '
cd "$HOME"
code --install-extension ms-vscode-remote.remote-containers
code --install-extension ms-vscode-remote.remote-ssh
code --install-extension ms-azuretools.vscode-docker
'

#-----------------------------#
# 🛠️ GRUB update
#-----------------------------#
fancy " 🛠️ Updating GRUB…" '
sudo grub2-mkconfig -o /etc/grub2.cfg
sudo grub2-mkconfig -o /etc/grub2-efi.cfg
'

#-----------------------------#
# 🧹 Cleanup
#-----------------------------#
fancy " 🧹 Cleaning up..." '
sudo dnf autoremove -y
sudo dnf clean all
'

#-----------------------------#
# Final reboot
#-----------------------------#
reboot_func
exit 0
