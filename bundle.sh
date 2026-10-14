#!/bin/bash
set -e

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
cd "$DIR"

echo "🔨 Building DynamicIsland (Release mode)..."
swift build -c release

APP_NAME="DynamicIsland.app"
APP_DIR="$DIR/$APP_NAME"
CONTENTS_DIR="$APP_DIR/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
RESOURCES_DIR="$CONTENTS_DIR/Resources"

echo "📦 Updating $APP_NAME bundle..."
mkdir -p "$MACOS_DIR"
mkdir -p "$RESOURCES_DIR"

# Copy binary
cp "$DIR/.build/release/DynamicIsland" "$MACOS_DIR/DynamicIsland"
chmod +x "$MACOS_DIR/DynamicIsland"

# Copy Icon
if [ -f "$DIR/AppIcon.icns" ]; then
    cp "$DIR/AppIcon.icns" "$RESOURCES_DIR/AppIcon.icns"
fi

# Create Info.plist
cat <<EOF > "$CONTENTS_DIR/Info.plist"
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>en</string>
    <key>CFBundleExecutable</key>
    <string>DynamicIsland</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>CFBundleIdentifier</key>
    <string>com.danielumoren.dynamicisland</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>Atoll</string>
    <key>CFBundleDisplayName</key>
    <string>Atoll</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>LSMinimumSystemVersion</key>
    <string>14.0</string>
    <key>LSUIElement</key>
    <true/>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>NSCalendarsUsageDescription</key>
    <string>Dynamic Island needs access to your calendar to display upcoming meetings and events.</string>
    <key>NSCalendarsFullAccessUsageDescription</key>
    <string>Dynamic Island needs access to your calendar to display upcoming meetings and events.</string>
    <key>NSAppleEventsUsageDescription</key>
    <string>Dynamic Island needs permission to control Spotify and Apple Music to display your currently playing song and playback controls.</string>
    <key>NSHumanReadableCopyright</key>
    <string>Copyright © 2026. All rights reserved.</string>
</dict>
</plist>
EOF

echo "🔏 Code signing $APP_NAME with persistent designated requirement..."
codesign --force --deep --sign - -r='designated => identifier "com.danielumoren.dynamicisland"' "$APP_DIR"

echo "✅ App bundle created at: $APP_DIR"
echo "🚀 To run: open $APP_DIR"
