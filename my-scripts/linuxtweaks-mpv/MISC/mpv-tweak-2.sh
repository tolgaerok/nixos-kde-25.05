#!/bin/bash

# MPV AIO Optimizer for Fedora (DNF) & Arch-based KDE/GNOME setups
# Includes: Config, Scripts, Detection, Desktop launcher

set -e

# Detect real (non-root) user and their home directory
REAL_USER="${SUDO_USER:-$(logname)}"
USER_HOME=$(eval echo "~$REAL_USER")

# Check if yad is installed, install if missing
if ! command -v yad &>/dev/null; then
  echo "📦 'yad' not found. Installing..."
  if command -v dnf &>/dev/null; then
    dnf install -y yad
  elif command -v pacman &>/dev/null; then
    pacman -Sy --noconfirm yad
  else
    echo "❌ Package manager not supported. Please install 'yad' manually."
    exit 1
  fi
fi

# Check if mpv is installed
if ! command -v mpv &>/dev/null; then
  echo "📦 'mpv' not found. Installing..."
  if command -v dnf &>/dev/null; then
    dnf install -y mpv
  elif command -v pacman &>/dev/null; then
    pacman -Sy --noconfirm mpv
  else
    echo "❌ Package manager not supported. Please install 'mpv' manually."
    exit 1
  fi
fi

yad --title="MPV Tweak 2 Setup" --text="⚠️  📥 Installing useful MPV scripts...." --timeout=2 --button=OK:0

CONFIG_DIR="$USER_HOME/.config/mpv"
SCRIPT_DIR="$CONFIG_DIR/scripts"
HOOKS_DIR="$CONFIG_DIR/script-opts"

mkdir -p "$CONFIG_DIR" "$SCRIPT_DIR" "$HOOKS_DIR"

# GPU Detection
GPU="$(lspci | grep -i VGA | grep -E 'NVIDIA|AMD|Intel')"
if echo "$GPU" | grep -qi nvidia; then
  HWDEC="nvdec"
elif echo "$GPU" | grep -qi amd; then
  HWDEC="vaapi"
elif echo "$GPU" | grep -qi intel; then
  HWDEC="vaapi"
else
  HWDEC="auto-safe"
fi

CPU_THREADS="$(nproc)"

# mpv.conf
cat > "$CONFIG_DIR/mpv.conf" <<EOF
vo=gpu-next
gpu-context=wayland
demuxer-thread=yes
demuxer-lavf-o=analyzeduration=1000000
hwdec=$HWDEC
scale=ewa_lanczossharp
cscale=ewa_lanczossharp
dscale=mitchell
tscale=oversample
hdr-compute-peak=yes
tone-mapping=bt.2390
target-peak=400
deband=yes
deband-iterations=1
deband-threshold=48
deband-range=16
video-sync=display-resample
interpolation=yes
tscale=oversample
msg-level=vo=error
msg-level=lavf/demux=error
cache=yes
cache-secs=180
audio-delay=0.1
EOF

# input.conf
cat > "$CONFIG_DIR/input.conf" <<EOF
SPACE        cycle pause
q            quit
ESC          quit
RIGHT        seek 5
LEFT         seek -5
UP           seek 60
DOWN         seek -60
>            add speed 0.1
<            add speed -0.1
BS           set speed 1.0
v            cycle sub
j            cycle sub down
J            cycle sub up
z            add sub-delay -0.1
x            add sub-delay +0.1
PGUP         add chapter 1
PGDWN        add chapter -1
i            show-text "\${filename}"
I            show-text "\${media-title}"
o            show-progress
TAB          script-binding stats/display-stats-toggle
s            screenshot
S            screenshot video
WHEEL_UP     add panscan 0.1
WHEEL_DOWN   add panscan -0.1
f            cycle fullscreen
EOF

# scripts.conf
cat > "$CONFIG_DIR/scripts.conf" <<EOF
[stats]
enabled=yes
key=TAB

[autoload]
enabled=yes
EOF

# Download useful MPV scripts
cd "$SCRIPT_DIR"
curl -sLO https://raw.githubusercontent.com/mpv-player/mpv/master/TOOLS/lua/autoload.lua
curl -sLO https://raw.githubusercontent.com/Argon-/mpv-stats/master/stats.lua
curl -sLO https://raw.githubusercontent.com/mpv-player/mpv/master/player/lua/ytdl_hook.lua

# Create .desktop launcher
DESKTOP_FILE="$USER_HOME/Desktop/mpv-tweak-2.desktop"
mkdir -p "$USER_HOME/.local/share/applications" "$USER_HOME/Desktop"

cat > "$DESKTOP_FILE" <<EOF
[Desktop Entry]
Name=MPV Tweak 2
Exec=$USER_HOME/Documents/MEGA/Documents/LINUX/fedora/RPM-BIILD/NEW-IDEAS/mpv-tweak-2/MPV_Tweak_2-x86_64.AppImage %f
Icon=mpv.svg
Type=Application
Categories=AudioVideo;Player;Video;
Terminal=true
StartupNotify=true
EOF

chmod +x "$DESKTOP_FILE"
cp "$DESKTOP_FILE" "$USER_HOME/.local/share/applications/"

# Notifications
yad --title="MPV Tweak 2 Setup" --text="⚠️  Do NOT run 'mpv' inside ~/.config/mpv or ~/Videos/ unless you're playing a specific file." --timeout=2 --button=OK:0
yad --title="MPV Tweak 2 Setup" --text="✅ MPV setup complete with GPU: $HWDEC and Threads: $CPU_THREADS" --timeout=2 --button=OK:0
yad --title="MPV Tweak 2 Setup" --text="🚀 Run 'mpv /path/to/video.mp4' or use the desktop launcher." --button=OK:0
