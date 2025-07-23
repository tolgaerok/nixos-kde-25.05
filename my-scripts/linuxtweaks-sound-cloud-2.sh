#!/usr/bin/env bash
# Tolga Erok

# My Personal SoundCloud Downloader GUI with YAD
# Agent: TolgaOps 3/7/2025

# option: https://github.com/scdl-org/scdl?tab=readme-ov-file
# PKG: https://github.com/scdl-org/scdl/wiki/Installation-Instruction

# Check if scdl exists
if ! command -v scdl &>/dev/null; then
    yad --error --title="scdl missing" \
        --text="Install scdl:\n\npip3 install scdl\n\nor from GitHub:\npip3 install git+https://github.com/flyingrub/scdl"
    exit 1
fi

# cd download folder
cd "$HOME/Music/SOUNDCLOUD" || mkdir -p "$HOME/Music/SOUNDCLOUD" && cd "$HOME/Music/SOUNDCLOUD"

# Show combinned form for both dropdown and URL entry
result=$(yad --form \
    --title="🎵 SoundCloud Downloader" \
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
    yad --title="SCDL Progress" \
        --width=800 --height=500 \
        --text-info --tail --fontname="monospace" --show-uri

yad --info --title="Finished" --text="Download complete."
