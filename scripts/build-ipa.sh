#!/bin/bash

# Build and create IPA for LevelMap
# Run this on a Mac with Xcode installed

set -e

echo "Building LevelMap for device testing..."

# Clean previous builds
xcodebuild clean -project LevelMap.xcodeproj -scheme LevelMap

# Build for device
xcodebuild archive \
  -project LevelMap.xcodeproj \
  -scheme LevelMap \
  -configuration Release \
  -archivePath ./build/LevelMap.xcarchive \
  -destination generic/platform=iOS

# Export IPA
xcodebuild -exportArchive \
  -archivePath ./build/LevelMap.xcarchive \
  -exportPath ./build/ipa \
  -exportOptionsPlist exportOptions.plist

echo "IPA created at: ./build/ipa/LevelMap.ipa"
echo "You can now install this on your device using:"
echo "1. iTunes (older method)"
echo "2. Xcode → Window → Devices and Simulators"
echo "3. TestFlight (after uploading to App Store Connect)"
