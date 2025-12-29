#!/bin/bash

# FileOrganizer Build Script
# This script compiles the app and updates the macOS App Bundle.

# Exit on error
set -e

APP_NAME="FileOrganizer"
BINARY_NAME="FileOrganizerApp"
APP_BUNDLE="$APP_NAME.app"
CONTENTS_DIR="$APP_BUNDLE/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
RESOURCES_DIR="$CONTENTS_DIR/Resources"

echo "🚀 Building $APP_NAME..."

# 1. Compile the project
swift build

# 2. Get the binary path
BIN_PATH=$(swift build --show-bin-path)

# 3. Create bundle structure if missing
echo "📦 Updating $APP_BUNDLE content..."
mkdir -p "$MACOS_DIR"
mkdir -p "$RESOURCES_DIR"

# 4. Copy the fresh binary into the bundle
cp "$BIN_PATH/$BINARY_NAME" "$MACOS_DIR/"

# 5. Copy Info.plist
if [ -f "Info.plist" ]; then
    cp "Info.plist" "$CONTENTS_DIR/"
else
    echo "⚠️  Warning: Info.plist not found in project root"
fi

# 6. Sign the app (Ad-hoc) to prevent launch errors (Code 162)
echo "🔏 Signing $APP_BUNDLE..."
codesign --force --deep --sign - "$APP_BUNDLE"

echo "✅ Build complete! Run with: open $APP_BUNDLE"
