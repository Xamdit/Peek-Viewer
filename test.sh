#!/bin/bash
# test.sh - Build and Run the Menu Bar App

set -e

# Define project variables
PROJECT_NAME="Peek"
SCHEME_NAME="Peek"
BUILD_DIR="./build"

echo "⚙️  Generating project..."
xcodegen generate

echo "============================================"
echo " 🚀 Building ${PROJECT_NAME}..."
echo "============================================"

# Create build directory if it doesn't exist
mkdir -p "${BUILD_DIR}"

# Build the project using xcodebuild
# We use -derivedDataPath to keep the build artifacts local and easy to find
xcodebuild -project "${PROJECT_NAME}.xcodeproj" \
           -scheme "${SCHEME_NAME}" \
           -configuration Debug \
           -derivedDataPath "${BUILD_DIR}" \
           build | grep -E "build/Build/Products|Succeeded|Failed|error:"

echo "✅ Build process finished."

# Locate the .app bundle
# Path is usually: build/Build/Products/Debug/MenuBarApp.app
APP_PATH=$(find "${BUILD_DIR}" -name "${PROJECT_NAME}.app" -type d | head -n 1)

if [ -z "${APP_PATH}" ]; then
    echo "❌ Error: Could not find ${PROJECT_NAME}.app bundle."
    exit 1
fi

echo "📦 App found at: ${APP_PATH}"

# Check if the app is already running and terminate it to refresh
echo "🔄 Refreshing application..."
if pgrep -x "${PROJECT_NAME}" > /dev/null; then
    echo "   - Closing existing instance..."
    killall "${PROJECT_NAME}" 2>/dev/null || true
    sleep 1
fi

# Open the application
echo "✨ Launching ${PROJECT_NAME}..."
open "${APP_PATH}"

echo "============================================"
echo " SUCCESS! Check your Menu Bar for the icon."
echo "============================================"
