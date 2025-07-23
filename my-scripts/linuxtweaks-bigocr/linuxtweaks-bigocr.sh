#!/bin/bash
# tolga erok - 1/5/25
# BUG FIXES + SETUP SCRIPT

# ─── Safety Check ─────────────────────────────────────────────────────────────
if [[ "$EUID" -eq 0 ]]; then
    echo "❌ Do NOT run this script as root. Please run it as a normal user."
    exit 1
fi

# ─── Variables ────────────────────────────────────────────────────────────────
GREEN='\033[0;32m'
NC='\033[0m'
bigocrpdf_url="https://github.com/biglinux/bigocrpdf"
save_dir="$HOME/bigocrpdf"
desktop_shortcut="$HOME/Desktop/BigOCRPDF.desktop"
bigocrpdf_script="$save_dir/bigocrpdf/usr/share/biglinux/bigocrpdf/main.py"
icon_URL="https://raw.githubusercontent.com/tolgaerok/linuxtweaks/main/MY_PYTHON_APP/images/LinuxTweak.png"
icon_dir="$HOME/.local/share/icons"
icon_path="$icon_dir/LinuxTweak.png"
log_file="$HOME/linuxtweaks.log"

# ─── Fancy Output ─────────────────────────────────────────────────────────────
fancy() {
    local title="$1"
    local command="$2"
    touch "$log_file"

    (
        echo "10"
        echo "# Starting: $title"
        sleep 1

        if [[ -n "$command" ]]; then
            eval "$command" 2>&1 | tee -a "$log_file" | while IFS= read -r line; do
                echo "# $line"
                if [[ "$line" == "Downloading" ]]; then echo "40"; fi
                if [[ "$line" == "Installing" ]]; then echo "70"; fi
                if [[ "$line" == "Done" ]]; then echo "100"; fi
            done
        fi

        cmd_exit_code=${PIPESTATUS[0]}
        if [[ $cmd_exit_code -ne 0 ]]; then
            echo "90"
            echo "# ❌ Error during: $title"
            exit $cmd_exit_code
        fi
        sleep 1
    ) | yad --progress \
        --title="BigOCRPDF HACK setup" \
        --image="$icon_path" \
        --text="Running:\n $title" \
        --percentage=0 \
        --width=500 \
        --center \
        --auto-close

    if [[ $cmd_exit_code -ne 0 ]]; then
        yad --error \
            --title="Error" \
            --image="$icon_path" \
            --text="❌ $title failed. Check log at:\n$log_file" \
            --width=400 \
            --center
        exit 1
    fi
}

# ─── Install Essential Packages ─────────────────────────────────────────────
essential_packages() {
    PACKAGES=(
        ghostscript ghostscript-tools-fonts ghostscript-tools-printing
        git git-core git-core-doc perl-Git perl-Error perl-TermReadKey
        perl-File-Find perl-lib tesseract tesseract-langpack-eng tesseract-langpack-tur
        yad cups cups-browsed cups-filters cups-filters-driverless
        cups-ipptool bluez-cups gutenprint-cups plasma-print-manager plasma-print-manager-libs
        hplip hplip-common hplip-libs libsane-hpaio gspell gtksourceview3
        antiword avahi-tools braille-printer-app libppd libcupsfilters
        liblouisutdml liblouisutdml-utils net-snmp-libs pngquant poppler-cpp
        poppler-utils python3-deprecated python3-deprecation python3-img2pdf
        python3-markdown-it-py python3-mdurl python3-pdfminer python3-pikepdf
        python3-pluggy python3-pygments python3-rich python3-wrapt qpdf-libs
        skanpage unpaper
    )
    fancy "Installing ${#PACKAGES[@]} essential packages" "sudo dnf install -y \${PACKAGES[@]} && pip3 install --user ocrmypdf"
}

# ─── Clean Up Old Install ─────────────────────────────────────────────────────
rm -rf "$save_dir" "$desktop_shortcut" "$icon_path"
echo "🗑️ BigOCRPDF and its files have been removed."

# ─── Install YAD, WGET, esssential packages and GIT if missing ────────────────────────────────────
if ! command -v yad &>/dev/null || ! command -v wget &>/dev/null || ! command -v git &>/dev/null; then
    notify-send "BigOCRPDF Setup" "📦 Installing 'yad', 'wget', and 'git'... Please wait." \
        --app-name="BigOCRPDF" -i dialog-information -u NORMAL
    fancy "Installing required tools (yad, wget, git)" "sudo dnf install -y yad wget git"
fi

essential_packages

# ─── Ensure Icon is Present ───────────────────────────────────────────────────
mkdir -p "$icon_dir"
wget -O "$icon_path" "$icon_URL"
chmod 644 "$icon_path"

# ─── Opening Prompt ───────────────────────────────────────────────────────────
prompt_text=$(
    cat <<'EOF'
👋 Welcome to the BigOCRPDF HACK Setup Script

This script will help set up BigOCRPDF for Brian:

    🟢 Installs dependencies (Python, OCRMyPDF, Git, YAD, PyQt6)
    🟢 Clones the BigOCRPDF repository
    🟢 Fixes permissions
    🟢 Makes the main script executable
    🟢 Creates a desktop shortcut

⚠️ Would you like to proceed Dr Brian?
EOF
)

yad --question \
    --title="Confirm BigOCRPDF HACK setup" \
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
        --text="Setup aborted.\nYou can run this script later." \
        --width=400 \
        --center
    exit 1
fi

# ─── Clone Repo ───────────────────────────────────────────────────────────────
if [ -d "$save_dir" ]; then
    fancy "⚠️ Repo Exists - Skipping Clone" ""
else
    fancy "⚠️ Cloning BigOCRPDF" "git clone $bigocrpdf_url $save_dir"
fi

# ─── Fix Permissions ──────────────────────────────────────────────────────────
fancy "⚠️ Fixing Permissions" "chmod -R 777 $save_dir && chown -R $USER:$USER $save_dir"

# ─── Make Main Executable ─────────────────────────────────────────────────────
fancy "⚠️ Making Main Script Executable" "chmod +x $bigocrpdf_script"

# ─── Create Desktop Shortcut ──────────────────────────────────────────────────
fancy "⚠️ Creating Desktop Shortcut" \
    "cat > \"$desktop_shortcut\" <<EOF
[Desktop Entry]
Name=BigOCRPDF
Exec=python3 $bigocrpdf_script %U
Icon=$icon_path
Type=Application
Terminal=false
Categories=Utility;
EOF
chmod +x \"$desktop_shortcut\""

# ─── Done ─────────────────────────────────────────────────────────────────────
fancy "🎉 Setup Complete!" ""
