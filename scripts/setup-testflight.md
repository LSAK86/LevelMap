# Quick TestFlight Setup

## For Immediate Testing

### Step 1: App Store Connect Setup (5 minutes)
1. Go to [App Store Connect](https://appstoreconnect.apple.com)
2. Click "My Apps" → "+" → "New App"
3. Fill in:
   - **Platform**: iOS
   - **Name**: LevelMap
   - **Bundle ID**: com.levelmap.app
   - **SKU**: levelmap001
   - **User Access**: Full Access

### Step 2: Get Your Team ID
1. In App Store Connect, go to "Users and Access"
2. Click on your name/account in the top right
3. Look for **Team ID** - it's a 10-character code (like ABC123DEF4)
4. **Write it down** - you'll need it for the next step

### Step 3: Update exportOptions.plist
1. Open the file `exportOptions.plist` in your project
2. Find this line: `<string>YOUR_TEAM_ID</string>`
3. Replace `YOUR_TEAM_ID` with your actual Team ID (the 10-character code you found)
4. Save the file

**Example**: If your Team ID is `ABC123DEF4`, change:
```xml
<string>YOUR_TEAM_ID</string>
```
to:
```xml
<string>ABC123DEF4</string>
```

### Step 4: Push to GitHub
```bash
git add .
git commit -m "Ready for TestFlight"
git push origin main
```

### Step 5: Install TestFlight
1. Download "TestFlight" from App Store on your iPhone
2. Sign in with your Apple ID
3. Wait for build to appear (usually 10-15 minutes)

## Alternative: Direct Xcode Installation

If you have access to a Mac for 5 minutes:

1. **Copy project to Mac** (USB drive, email, etc.)
2. **Open in Xcode**: `open LevelMap.xcodeproj`
3. **Connect iPhone** via USB
4. **Select device** in Xcode dropdown
5. **Sign with your Apple ID**
6. **Press Cmd+R** to install

## Quick TestFlight Build

The GitHub Actions workflow will automatically:
- Build the app on macOS
- Create an IPA file
- Upload to TestFlight
- Make it available for testing

You'll get an email when the build is ready!
