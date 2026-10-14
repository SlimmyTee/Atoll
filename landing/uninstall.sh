#!/bin/bash
set -e

echo "🗑️  Uninstalling Atoll..."

# Quit running instances
killall DynamicIsland 2>/dev/null || true
killall Atoll 2>/dev/null || true

# Remove app from /Applications
if [ -d "/Applications/Atoll.app" ]; then
    rm -rf /Applications/Atoll.app
    echo "  ✓ Removed /Applications/Atoll.app"
fi

if [ -d "/Applications/DynamicIsland.app" ]; then
    rm -rf /Applications/DynamicIsland.app
    echo "  ✓ Removed /Applications/DynamicIsland.app"
fi

# Clean application support files and caches
rm -rf "$HOME/Library/Application Support/DynamicIsland"
rm -rf "$HOME/Library/Caches/DynamicIsland"
rm -f "$HOME/Library/Preferences/app.atoll.desktop.plist"
rm -f "$HOME/Library/Preferences/com.danielumoren.dynamicisland.plist"

echo "✅ Atoll has been completely uninstalled from your Mac."
