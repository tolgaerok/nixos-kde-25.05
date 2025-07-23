#!/usr/bin/env bash
set -euo pipefail

DEST_DIR="${1:-$HOME/sources/ufas-fonts}"

mkdir -p "$DEST_DIR"

declare -A fonts=(
  [Aegean.zip]="https://web.archive.org/web/20221006174450/https://dn-works.com/wp-content/uploads/2020/UFAS-Fonts/Aegean.zip"
  [Aegyptus.zip]="https://web.archive.org/web/20221006174450/https://dn-works.com/wp-content/uploads/2020/UFAS-Fonts/Aegyptus.zip"
  [Akkadian.zip]="https://web.archive.org/web/20221006174450/https://dn-works.com/wp-content/uploads/2020/UFAS-Fonts/Akkadian.zip"
  [Assyrian.zip]="https://web.archive.org/web/20221006174450/https://dn-works.com/wp-content/uploads/2020/UFAS-Fonts/Assyrian.zip"
  [EEMusic.zip]="https://web.archive.org/web/20221006174450/https://dn-works.com/wp-content/uploads/2020/UFAS-Fonts/EEMusic.zip"
  [Maya%20Hieroglyphs.zip]="https://web.archive.org/web/20221006174450/https://dn-works.com/wp-content/uploads/2020/UFAS-Fonts/Maya%20Hieroglyphs.zip"
  [Symbola.zip]="https://web.archive.org/web/20221006174450/https://dn-works.com/wp-content/uploads/2020/UFAS-Fonts/Symbola.zip"
  [Textfonts.zip]="https://web.archive.org/web/20221006174450/https://dn-works.com/wp-content/uploads/2020/UFAS-Fonts/Textfonts.zip"
  [Unidings.zip]="https://web.archive.org/web/20221006174450/https://dn-works.com/wp-content/uploads/2020/UFAS-Fonts/Unidings.zip"
)

echo "Downloading UFAS fonts to $DEST_DIR"

for file in "${!fonts[@]}"; do
  url="${fonts[$file]}"
  target="$DEST_DIR/$file"
  if [[ -f "$target" ]]; then
    echo "Skipping existing: $file"
  else
    echo "Downloading $file ..."
    curl -L --fail --retry 3 -o "$target" "$url"
  fi
done

echo "All downloads complete."


# Text to render
TEXT="KingTolga Was Here"

# Output directory
OUTDIR="$HOME/ufas-test"
mkdir -p "$OUTDIR"

# Font names to test (as known to fontconfig)
FONTS=(
  "Aegean"
  "Aegyptus"
  "Akkadian"
  "Assyrian"
  "EEMusic"
  "Maya"
  "Symbola"
)

for font in "${FONTS[@]}"; do
  outfile="$OUTDIR/${font}.png"
  echo "Creating test image for: $font → $outfile"
  
  convert -size 800x200 xc:white \
    -gravity Center \
    -pointsize 48 \
    -font "$font" \
    -fill black \
    -annotate +0+0 "$TEXT" \
    "$outfile"
done

echo "✅ Test images created in $OUTDIR"

# Optionally open them all in an image viewer
if command -v feh >/dev/null; then
  feh "$OUTDIR"/*.png
else
  echo "Open $OUTDIR/*.png in your favorite image viewer."
fi
