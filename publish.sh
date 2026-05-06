#!/bin/bash

# Exit on error
set -e

APP_NAME="Peek"
BUILD_DIR="./build_publish"
DIST_DIR="./dist"

echo "🚀 Starting Publish Process for $APP_NAME..."

# 1. Clean up
echo "🧹 Cleaning up previous builds and caches..."
rm -rf "$BUILD_DIR"
rm -rf "$DIST_DIR"
rm -rf ~/Library/Developer/Xcode/DerivedData/Peek-* # Extra precaution
mkdir -p "$DIST_DIR"

# 2. Generate Xcode Project
echo "🏗 Generating Xcode project with XcodeGen..."
xcodegen generate

# 3. Build for Release
echo "🛠 Building $APP_NAME in Release mode (Clean Build)..."
xcodebuild clean build \
           -project "$APP_NAME.xcodeproj" \
           -scheme "$APP_NAME" \
           -configuration Release \
           -derivedDataPath "$BUILD_DIR"

# 4. Copy to Dist
echo "📦 Packaging application..."
APP_PATH=$(find "$BUILD_DIR" -name "$APP_NAME.app" -type d | head -n 1)

if [ -z "$APP_PATH" ]; then
    echo "❌ Error: Could not find the built .app file."
    exit 1
fi

cp -R "$APP_PATH" "$DIST_DIR/"

echo "✅ Publish Complete!"
echo "📍 Your application is ready at: $DIST_DIR/$APP_NAME.app"
echo "🚀 You can now move it to your Applications folder."
