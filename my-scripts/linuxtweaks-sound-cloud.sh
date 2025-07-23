#!/usr/bin/env bash

# SoundCloud Downloader GUI with YAD
# Agent: TolgaOps

# Check if scdl exists
if ! command -v scdl &>/dev/null; then
    yad --error --title="scdl missing" \
        --text="Install scdl:\n\npip3 install scdl\n\nor from GitHub:\npip3 install git+https://github.com/flyingrub/scdl"
    exit 1
fi

# Set download folder
cd "$HOME/Music/SOUNDCLOUD" || mkdir -p "$HOME/Music/SOUNDCLOUD" && cd "$HOME/Music/SOUNDCLOUD"

# Show combined form for both dropdown and URL entry
result=$(yad --form \
    --title="🎵 SoundCloud Downloader" \
    --width=600 --height=200 \
    --field="Download mode:CB" \
    --field="SoundCloud URL or slug:" \
    "Single Track!Playlist!All Tracks of User (no reposts)!All Tracks + Reposts of User!All Likes of User!Only New Tracks from Playlist!Sync Playlist" \
    "" \
    --center)

# Check cancel
[[ $? -ne 0 ]] && exit 0

# Parse results
MODE=$(echo "$result" | cut -d"|" -f1)
INPUT=$(echo "$result" | cut -d"|" -f2)

# Trim input
INPUT=$(echo "$INPUT" | sed -E 's#^https?://soundcloud\.com/##; s#^/##; s#/$##; s# *$##')

# Build final URL
URL="https://soundcloud.com/$INPUT"

# Build scdl command depending on chosen mode
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

# Show command and run it
yad --text-info --title="Executing SCDL" \
    --width=600 --height=300 \
    --filename=<(echo -e "Executing:\n\n$CMD\n\nPlease wait...") &

eval "$CMD"

kill $!

yad --info --title="Finished" --text="Download complete."
