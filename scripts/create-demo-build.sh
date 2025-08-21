#!/bin/bash

# Create a demo build for immediate testing
echo "Creating demo build for LevelMap..."

# Check if we're on macOS
if [[ "$OSTYPE" != "darwin"* ]]; then
    echo "This script requires macOS with Xcode installed."
    echo "For Windows users, use the TestFlight method instead."
    exit 1
fi

# Build for device
echo "Building for device..."
xcodebuild archive \
  -project LevelMap.xcodeproj \
  -scheme LevelMap \
  -configuration Release \
  -archivePath ./demo-build/LevelMap.xcarchive \
  -destination generic/platform=iOS

# Create IPA
echo "Creating IPA..."
xcodebuild -exportArchive \
  -archivePath ./demo-build/LevelMap.xcarchive \
  -exportPath ./demo-build/ipa \
  -exportOptionsPlist exportOptions.plist

echo "✅ Demo build created at: ./demo-build/ipa/LevelMap.ipa"
echo ""
echo "To install on your iPhone:"
echo "1. Copy the IPA file to your Mac"
echo "2. Open Xcode → Window → Devices and Simulators"
echo "3. Select your iPhone"
echo "4. Drag the IPA file to the 'Installed Apps' section"
echo ""
echo "Or use TestFlight for easier distribution!"
