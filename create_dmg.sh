#!/bin/bash
set -e

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
cd "$DIR"

echo "🔨 Ensuring latest release build of DynamicIsland..."
./bundle.sh

DMG_NAME="DynamicIsland.dmg"
VOLUME_NAME="DynamicIsland"
STAGING_DIR="$DIR/.build/dmg_staging"

echo "🧹 Preparing DMG staging directory..."
rm -rf "$STAGING_DIR"
mkdir -p "$STAGING_DIR"

echo "📦 Copying DynamicIsland.app..."
cp -R "$DIR/DynamicIsland.app" "$STAGING_DIR/"

echo "🔗 Creating /Applications drag-and-drop link..."
ln -s /Applications "$STAGING_DIR/Applications"

echo "💿 Creating compressed disk image ($DMG_NAME)..."
rm -f "$DIR/$DMG_NAME"
hdiutil create \
    -volname "$VOLUME_NAME" \
    -srcfolder "$STAGING_DIR" \
    -ov \
    -format UDZO \
    "$DIR/$DMG_NAME"

# Clean up staging directory
rm -rf "$STAGING_DIR"

echo "🔏 Ad-hoc signing disk image..."
codesign --force --sign - "$DIR/$DMG_NAME"

DMG_SIZE=$(ls -lh "$DIR/$DMG_NAME" | awk '{print $5}')
echo ""
echo "🎉 Successfully created DMG installer!"
echo "📍 Location: $DIR/$DMG_NAME ($DMG_SIZE)"
echo "✨ Users can double-click this DMG and drag DynamicIsland to Applications."
