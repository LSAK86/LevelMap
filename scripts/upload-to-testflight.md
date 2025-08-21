# Manual TestFlight Upload Guide

## Step 1: Download the Build

1. **Go to your GitHub repository**: https://github.com/lsak86/LevelMap
2. **Click "Actions" tab**
3. **Click on the successful build**
4. **Look for "Show Export Results" step**
5. **Download the IPA file** (if available)

## Step 2: Upload to App Store Connect

### Option A: Using Xcode (Recommended)
1. **Open Xcode**
2. **Go to Window** → **Organizer**
3. **Click "Archives" tab**
4. **Click "+"** → **"Add Archive"**
5. **Select your IPA file**
6. **Click "Distribute App"**
7. **Choose "App Store Connect"**
8. **Follow the upload process**

### Option B: Using App Store Connect
1. **Go to [App Store Connect](https://appstoreconnect.apple.com)**
2. **Click "My Apps"** → **"LevelMap"**
3. **Click "TestFlight" tab**
4. **Click "+"** → **"Upload Build"**
5. **Drag and drop your IPA file**

## Step 3: Alternative - Create New Build

If the IPA isn't available, we can create a new build:

### Using Xcode:
1. **Open LevelMap.xcodeproj in Xcode**
2. **Select your device** (or Generic iOS Device)
3. **Product** → **Archive**
4. **Click "Distribute App"**
5. **Choose "App Store Connect"**
6. **Follow the upload process**

## Step 4: Wait for Processing

After upload:
- **Processing time**: 15-30 minutes
- **You'll get an email** when ready
- **Check TestFlight tab** for status

## Troubleshooting

### If upload fails:
1. **Check your Apple Developer account** - make sure it's active
2. **Verify Team ID** - should be `3GJF2X7ANU`
3. **Check bundle identifier** - should be `com.levelmap.app`
4. **Ensure code signing** is set up correctly

### If you don't see the app:
1. **Refresh App Store Connect** - sometimes takes a moment
2. **Check "Activity" tab** for any errors
3. **Verify you're signed in** with the correct Apple ID
