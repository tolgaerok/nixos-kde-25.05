#!/bin/bash
set -e

# ---------------------------
# CONFIGURATION
# ---------------------------
APP_NAME="linuxtweaks-mpv-tweak"
ARCH="x86_64"
APPDIR_PATH="$PWD/AppDir"
OUTPUT_NAME="${APP_NAME}-${ARCH}.AppImage"
APPIMAGETOOL_URL="https://github.com/AppImage/AppImageKit/releases/latest/download/appimagetool-${ARCH}.AppImage"
TOOLS_DIR="$HOME/.local/bin"
APPIMAGETOOL="$TOOLS_DIR/appimagetool"
# ---------------------------

# Ensure tool directory exists
mkdir -p "$TOOLS_DIR"

# Download appimagetool if not present
if [ ! -x "$APPIMAGETOOL" ]; then
  echo "📥 Downloading appimagetool..."
  curl -Lo "$APPIMAGETOOL" "$APPIMAGETOOL_URL"
  chmod a+x "$APPIMAGETOOL"
fi

# Ensure all required directories exist in the AppDir
echo "📦 Ensuring AppDir structure..."
mkdir -p "$APPDIR_PATH/usr/bin"                                 # Executables
mkdir -p "$APPDIR_PATH/usr/lib"                                 # App-specific libraries
mkdir -p "$APPDIR_PATH/usr/share/applications"                  # .desktop file
mkdir -p "$APPDIR_PATH/usr/share/icons/hicolor/256x256/apps"    # App icon
mkdir -p "$APPDIR_PATH/usr/share/doc"                           # Optional docs/README
mkdir -p "$APPDIR_PATH/usr/share/locale"                        # Translations (optional)
mkdir -p "$APPDIR_PATH/etc"                                     # App-specific config (optional)
mkdir -p "$APPDIR_PATH/tmp"                                     # Runtime temp data (optional)

# Create the desktop file if it's missing or incorrect
if [ ! -f "$APPDIR_PATH/usr/share/applications/$APP_NAME.desktop" ]; then
  echo "📄 Creating desktop entry for $APP_NAME..."
  cat > "$APPDIR_PATH/usr/share/applications/$APP_NAME.desktop" <<EOF
[Desktop Entry]
Name=$APP_NAME
Exec=$APP_NAME
Icon=$APP_NAME
Type=Application
Categories=Utility;Application;
EOF
fi

# Create a dummy executable if it doesn't exist
if [ ! -f "$APPDIR_PATH/usr/bin/$APP_NAME" ]; then
  echo "🔧 Creating dummy executable..."
  cat > "$APPDIR_PATH/usr/bin/$APP_NAME" <<EOF
#!/bin/bash
echo "Hello from $APP_NAME AppImage!"
read -p "Press Enter to exit..."
EOF
  chmod a+x "$APPDIR_PATH/usr/bin/$APP_NAME"
fi

# Create a dummy icon if it doesn't exist (requires ImageMagick)
if [ ! -f "$APPDIR_PATH/usr/share/icons/hicolor/256x256/apps/$APP_NAME.png" ]; then
  echo "🖼 Creating dummy icon..."
  convert -size 256x256 xc:steelblue -gravity Center -pointsize 32 -annotate 0 "$APP_NAME" \
    "$APPDIR_PATH/usr/share/icons/hicolor/256x256/apps/$APP_NAME.png"
fi

# Build AppImage
echo "🛠 Building AppImage from $APPDIR_PATH..."
ARCH="$ARCH" "$APPIMAGETOOL" "$APPDIR_PATH"

# Find the generated AppImage (latest by modification time)
APPIMAGE_FILE=$(find "$PWD" -maxdepth 1 -name "*.AppImage" -printf "%T@ %p\n" | sort -n | tail -1 | cut -d' ' -f2-)

# Rename it to the desired output name
if [ -f "$APPIMAGE_FILE" ]; then
  mv -v "$APPIMAGE_FILE" "$OUTPUT_NAME"
  echo "✅ Done: $PWD/$OUTPUT_NAME"
else
  echo "❌ AppImage not found."
  exit 1
fi
