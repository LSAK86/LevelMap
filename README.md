# LevelMap - AR Floor Level Verification

A production-quality iOS app for professional floor level verification using ARKit, RealityKit, and on-device AI for automatic ruler reading.

## Features

### Core Functionality
- **AR Plane Detection**: Automatically detect horizontal floor surfaces
- **Rectangle Placement**: Draw and lock measurement rectangles in real space
- **Customizable Grids**: Generate measurement grids (halves, fourths, eighths, or custom)
- **AI Measurement Reading**: On-device Vision framework for automatic ruler reading
- **LiDAR Integration**: Height deviation analysis using device depth sensing
- **Tolerance Engine**: Statistical analysis and pass/fail criteria
- **Professional Reports**: PDF, CSV, and JSON export with annotations

### Authentication & Subscriptions
- **Sign in with Apple**: Secure user authentication
- **StoreKit 2**: Individual monthly/yearly subscriptions
- **Organization Codes**: Multi-seat corporate plans with seat management
- **Offline-First**: All data stored locally with optional cloud sync

### Measurement Capabilities
- **Dual Units**: Imperial (fractional inches) and Metric (mm)
- **Fractional Precision**: 1/8" and 1/16" resolution support
- **Laser Detection**: Red and green laser dot recognition
- **Manual Override**: Edit AI readings with manual entry
- **Calibration**: One-tap calibration for improved accuracy

## Requirements

- **iOS 17.0+**
- **iPhone with ARKit support** (iPhone 6s or later)
- **LiDAR recommended** for enhanced height analysis (iPhone 12 Pro or later)
- **Xcode 15.0+**
- **Swift 5.9+**

## Installation

### Prerequisites
1. Install Xcode 15.0 or later from the Mac App Store
2. Ensure you have a valid Apple Developer account for device testing

### Build Instructions

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd LevelMap
   ```

2. **Open in Xcode**
   ```bash
   open LevelMap.xcodeproj
   ```

3. **Configure signing**
   - Select the LevelMap target
   - Go to Signing & Capabilities
   - Select your Team and Bundle Identifier

4. **Build and run**
   - Select your target device (iPhone recommended)
   - Press Cmd+R or click the Run button

### Testing

Run the test suite:
```bash
# Unit tests
xcodebuild test -scheme LevelMap -destination 'platform=iOS Simulator,name=iPhone 15'

# UI tests (requires device)
xcodebuild test -scheme LevelMap -destination 'platform=iOS,name=iPhone'
```

## Project Structure

```
LevelMap/
├── LevelMapApp.swift              # App entry point
├── ContentView.swift              # Main navigation
├── Core/                          # Core models and utilities
│   ├── Models.swift               # Data models
│   ├── GeometryUtils.swift        # Grid generation and math
│   ├── FractionUtils.swift        # Imperial fraction parsing
│   └── ToleranceEngine.swift      # Statistical analysis
├── Features/                      # Feature modules
│   ├── ARCapture/                 # AR plane detection and rectangle placement
│   ├── PointCapture/              # Photo capture and measurement UI
│   ├── Sessions/                  # Project/location/session management
│   ├── Export/                    # PDF/CSV/JSON export
│   ├── Auth/                      # Sign in with Apple
│   └── AIReading/                 # On-device measurement extraction
├── Services/                      # Business logic services
│   ├── DataStore.swift            # Local persistence
│   ├── AuthService.swift          # Authentication
│   ├── PurchaseService.swift      # StoreKit 2 integration
│   └── EntitlementService.swift   # Organization codes
├── DesignSystem/                  # Reusable UI components
└── Tests/                         # Unit and UI tests
```

## Usage

### Getting Started

1. **Sign In**: Use Sign in with Apple to create an account
2. **Choose Plan**: Select individual subscription or enter organization code
3. **Create Project**: Add project details and client information
4. **Add Location**: Specify measurement location and address
5. **Start Session**: Configure units, tolerance, and grid size

### AR Measurement Workflow

1. **Detect Floor**: Point camera at floor surface until plane is detected
2. **Place Rectangle**: Tap two corners to define measurement area
3. **Generate Grid**: Select grid preset or custom configuration
4. **Capture Measurements**: Tap grid points to capture ruler photos
5. **Review Results**: Check AI readings and tolerance analysis
6. **Export Report**: Generate professional PDF with statistics

### AI Measurement Tips

- **Good Lighting**: Ensure adequate lighting for accurate OCR
- **Steady Ruler**: Keep ruler steady during photo capture
- **Laser Alignment**: Use laser level for consistent measurements
- **Calibration**: Tap calibration if AI confidence is low
- **Manual Override**: Edit readings if AI interpretation is incorrect

## Configuration

### App Settings

- **Units**: Imperial (inches) or Metric (mm)
- **Precision**: 1/8" or 1/16" fractional resolution
- **Tolerance**: Default tolerance values for new sessions
- **Export Options**: Include AI values, photos, and format preferences

### Organization Codes

Test codes for development:
- `STARTER2024`: Starter plan (100 seats)
- `PRO2024`: Pro plan (300 seats)  
- `ENTERPRISE2024`: Enterprise plan (500 seats)

## API Integration

The app is designed for future backend integration:

### Data Models
All models implement `Codable` and include `toDictionary()` methods for API serialization.

### Export Formats
- **JSON**: Complete session data with AI values and metadata
- **CSV**: Tabular data for spreadsheet analysis
- **PDF**: Professional reports with photos and statistics

### OpenAPI Specification
See `/Docs/openapi.yaml` for API endpoint definitions.

## Testing

### Unit Tests
- Geometry calculations and grid generation
- Fraction parsing and formatting
- Tolerance engine statistics
- AI calibration mathematics

### UI Tests
- Complete session workflow
- Photo capture and measurement
- Export functionality
- Authentication flows

### Test Fixtures
Sample ruler photos for AI testing:
- Red and green laser dots
- Various lighting conditions
- Vertical and horizontal orientations

## Performance

### Target Metrics
- **AI Processing**: <300ms on A14+ devices
- **AR Tracking**: 60fps plane detection
- **Photo Capture**: <1s from tap to measurement
- **Export Generation**: <5s for typical sessions

### Optimization
- On-device AI processing (no network required)
- Efficient image compression and storage
- Lazy loading of session data
- Background processing for exports

## Privacy & Security

### Data Handling
- **Local Storage**: All data stored on device
- **No Cloud Sync**: Data remains private unless exported
- **AI Processing**: On-device Vision framework only
- **Photo Storage**: Encrypted in app documents folder

### Permissions
- **Camera**: Ruler photo capture
- **Photo Library**: Save measurement photos
- **AR**: Plane detection and tracking

## Deployment

### App Store Preparation

1. **App Icon**: Create 1024x1024 icon for App Store
2. **Screenshots**: Generate screenshots for all device sizes
3. **Metadata**: Prepare app description and keywords
4. **Testing**: Test on multiple devices and iOS versions

### Production Checklist

- [ ] Sign in with Apple configured
- [ ] StoreKit 2 products configured
- [ ] App Store Connect setup
- [ ] Privacy policy and terms of service
- [ ] Export compliance review
- [ ] Accessibility testing
- [ ] Performance profiling

## Limitations

### Current Limitations
- **Device Requirements**: Requires ARKit-capable iPhone
- **LiDAR**: Enhanced features require LiDAR-equipped devices
- **Network**: Offline-first design (no cloud sync)
- **AI Accuracy**: Depends on photo quality and ruler clarity

### Future Enhancements
- **Android Support**: Separate Android project
- **Cloud Sync**: Firebase/Supabase integration
- **Advanced AI**: Improved measurement accuracy
- **Real-time Collaboration**: Multi-user sessions
- **3D Visualization**: Enhanced AR overlays

## Support

### Documentation
- In-app help and tutorials
- Video demonstrations
- Best practices guide

### Contact
- **Support**: support@levelmap.app
- **Feature Requests**: github.com/levelmap/issues
- **Documentation**: docs.levelmap.app

## License

Copyright © 2024 LevelMap. All rights reserved.

This software is proprietary and confidential. Unauthorized copying, distribution, or use is strictly prohibited.

## Acknowledgments

- **ARKit & RealityKit**: Apple's AR frameworks
- **Vision Framework**: On-device AI processing
- **StoreKit 2**: In-app purchase management
- **PDFKit**: Professional report generation

---

**LevelMap** - Professional floor level verification powered by AR and AI.
