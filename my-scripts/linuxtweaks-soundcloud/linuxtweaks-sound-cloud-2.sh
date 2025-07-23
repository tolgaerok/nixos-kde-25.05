#!/usr/bin/env bash
# Tolga Erok

# My Personal SoundCloud Downloader GUI with YAD
# Agent: TolgaOps 3/7/2025

# option: https://github.com/scdl-org/scdl?tab=readme-ov-file
# PKG:    https://github.com/scdl-org/scdl/wiki/Installation-Instruction

# Check if scdl pkg exists
if ! command -v scdl &>/dev/null; then
    yad --error --title="scdl missing" \
    --text="Install scdl:\n\npip3 install scdl\n\nor from GitHub:\npip3 install git+https://github.com/flyingrub/scdl"
    exit 1
fi

# figure out real user
REAL_USER="${SUDO_USER:-$(logname)}"
USER_HOME=$(eval echo "~$REAL_USER")

# icon URL
icon_URL="https://raw.githubusercontent.com/tolgaerok/linuxtweaks/main/MY_PYTHON_APP/images/LinuxTweak.png"

# icon destination
icon_dir="$USER_HOME/.config"
icon_path="$icon_dir/LinuxTweak.png"

# make sure .config exists
mkdir -p "$icon_dir"

# download the icon
wget -q -O "$icon_path" "$icon_URL"

# permissions
chmod 644 "$icon_path"

echo "✅ Icon downloaded to $icon_path" && sleep 0.4 && clear

intro=$(
  cat <<'EOF'
🎧 LinuxTweaks SoundCloud Downloader Options

This tool gives you extra modes for music control:

    🟢  Download a single track or a full playlist
    🟢  Sync playlists using archive.txt
    🟢  Download only *new* tracks from a playlist
    🟢  Grab *all* user uploads (with or without reposts)
    🟢  Save all user likes directly to your music folder

💡  Customize how deep you want to go. Minimal hassle.

🎯  No gimmicks. Just sound.

EOF
)

downloading=$(
  cat <<'EOF'
🎧 LinuxTweaks SoundCloud Downloader live progress

    🟢  Download in progrss
    $CMD

💡  Standby ...

EOF
)

# cd download folder
cd "$HOME/Music/SOUNDCLOUD" || mkdir -p "$HOME/Music/SOUNDCLOUD" && cd "$HOME/Music/SOUNDCLOUD"

# Show combinned form for both dropdown and URL entry
result=$(yad --form \
    --title="🎵 Linuxtweaks SoundCloud Downloader" \
    --image="$icon_path" \
    --text="$intro" \
    --width=600 --height=200 \
    --field="Download mode:CB" \
    --field="SoundCloud URL or slug:" \
    "Single Track!Playlist!All Tracks of User (no reposts)!All Tracks + Reposts of User!All Likes of User!Only New Tracks from Playlist!Sync Playlist" \
    "" \
--center)

# cancel
[[ $? -ne 0 ]] && exit 0

# Parse results
MODE=$(echo "$result" | cut -d"|" -f1)
INPUT=$(echo "$result" | cut -d"|" -f2)

# Trim input/slug
INPUT=$(echo "$INPUT" | sed -E 's#^https?://soundcloud\.com/##; s#^/##; s#/$##; s# *$##')

# make final URL
URL="https://soundcloud.com/$INPUT"

# Build scdl command depending on chosen mode/option: https://github.com/scdl-org/scdl?tab=readme-ov-file
case "$MODE" in
    "Single Track")
        CMD="scdl -l \"$URL\""
    ;;
    "Playlist")
        CMD="scdl -l \"$URL\""
    ;;
    "All Tracks of User (no reposts)")
        CMD="scdl -l \"$URL\" -t"
    ;;
    "All Tracks + Reposts of User")
        CMD="scdl -l \"$URL\" -a"
    ;;
    "All Likes of User")
        CMD="scdl -l \"$URL\" -f"
    ;;
    "Only New Tracks from Playlist")
        CMD="scdl -l \"$URL\" --download-archive archive.txt -c"
    ;;
    "Sync Playlist")
        CMD="scdl -l \"$URL\" --sync archive.txt"
    ;;
    *)
        yad --error --title="Error" --text="Unknown mode."
        exit 1
    ;;
esac

# live window
echo -e "\nRunning:\n\n$CMD\n" > scdl_log.txt

# Execute scdl and stream output to YAD in real time! Yes Babe!
bash -c "$CMD" 2>&1 | tee -a scdl_log.txt | \
yad --title="Linuxtweaks SoundCloud Progress" \
--image="$icon_path" \
--text="$downloading" \
--width=800 --height=500 \
--text-info --tail --fontname="monospace" --show-uri

yad --info --title="Finished" --text="Download complete."
