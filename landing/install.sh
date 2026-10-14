#!/bin/bash
set -e

echo "🏝️ Installing Atoll for macOS..."
TMP_DIR=$(mktemp -d)
DMG_PATH="$TMP_DIR/Atoll.dmg"

echo "⬇️ Downloading Atoll.dmg..."
curl -fsSL "https://atoll-nine.vercel.app/downloads/Atoll.dmg" -o "$DMG_PATH"

echo "💿 Mounting installer..."
MOUNT_DIR=$(hdiutil attach "$DMG_PATH" -nobrowse | grep "/Volumes" | awk -F '\t' '{print $NF}')

echo "📦 Installing to /Applications..."
rm -rf /Applications/Atoll.app
cp -R "$MOUNT_DIR/Atoll.app" /Applications/

echo "🧹 Cleaning up..."
hdiutil detach "$MOUNT_DIR" -quiet || true
rm -rf "$TMP_DIR"

echo "🔓 Granting permissions..."
xattr -cr /Applications/Atoll.app

echo "✅ Atoll is ready! Launching now..."
open /Applications/Atoll.app
