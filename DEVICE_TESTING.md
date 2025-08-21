# Device Testing Guide for LevelMap

## Quick Start (Mac Users)

1. **Open in Xcode:**
   ```bash
   open LevelMap.xcodeproj
   ```

2. **Connect your iPhone** via USB

3. **Select your device** in Xcode's device dropdown (top toolbar)

4. **Sign the app:**
   - Click on "LevelMap" project in navigator
   - Select "LevelMap" target
   - Go to "Signing & Capabilities" tab
   - Check "Automatically manage signing"
   - Select your Apple ID

5. **Build and run:**
   - Press `Cmd+R` or click the Play button
   - App will install and launch on your device

## Windows Users - Alternative Methods

### Method 1: GitHub Actions + TestFlight (Recommended)

1. **Push to GitHub:**
   ```bash
   git add .
   git commit -m "Add device testing setup"
   git push origin main
   ```

2. **Set up App Store Connect:**
   - Go to [App Store Connect](https://appstoreconnect.apple.com)
   - Create a new app "LevelMap"
   - Get your Team ID and API keys

3. **Add GitHub Secrets:**
   - Go to your GitHub repo → Settings → Secrets
   - Add: `APPSTORE_CONNECT_API_KEY`, `APPSTORE_CONNECT_API_KEY_ID`, `APPSTORE_CONNECT_ISSUER_ID`

4. **Install TestFlight** on your iPhone and wait for the build

### Method 2: Remote Mac Service

- Use [MacStadium](https://www.macstadium.com/) or [MacinCloud](https://www.macincloud.com/)
- Install Xcode and build from there
- Download the IPA and install via Xcode

### Method 3: Local Mac (if available)

- Copy the project to a Mac
- Follow the "Quick Start" instructions above

## Testing Checklist

Once installed, test these features:

### ✅ Basic Functionality
- [ ] App launches without crashes
- [ ] Sign in with Apple works
- [ ] Subscription flow displays correctly
- [ ] Project creation works
- [ ] Settings are accessible

### ✅ AR Features (Requires Physical Device)
- [ ] Camera permission request appears
- [ ] AR session starts (you'll see camera feed)
- [ ] Plane detection works (move device around)
- [ ] Rectangle placement responds to taps
- [ ] Grid generation displays correctly

### ✅ Photo Capture
- [ ] Camera opens when tapping grid points
- [ ] Photo capture works
- [ ] AI reading interface appears (even if AI is placeholder)

### ✅ Data Persistence
- [ ] Projects save and reload
- [ ] Sessions persist between app launches
- [ ] Photos are saved to device

## Troubleshooting

### "Untrusted Developer" Error
- Go to Settings → General → VPN & Device Management
- Find your Apple ID and tap "Trust"

### Build Errors
- Make sure you're using iOS 17+ device
- Check that all frameworks are linked in Xcode
- Verify signing certificate is valid

### AR Not Working
- Ensure device has iOS 17+
- Check camera permissions
- Try in well-lit environment
- Move device slowly to detect planes

## Next Steps After Testing

1. **Report any issues** you find
2. **Test on different devices** if possible (iPhone 12 Pro+ for LiDAR)
3. **Verify all features** work as expected
4. **Prepare for App Store submission** if ready

## Support

If you encounter issues:
1. Check Xcode console for error messages
2. Verify device compatibility
3. Test in different lighting conditions
4. Contact for additional help
