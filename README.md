# TrackMe - GPS Tracking iOS App

A comprehensive iOS application that tracks your movements using GPS with the ability to store data in an internal database, including timestamps and user-provided narratives.

## Features

- **Real-time GPS Tracking**: Accurate location tracking using Core Location
- **Background Tracking**: Continues tracking when the app is in the background
- **Session Management**: Start and stop tracking sessions with custom narratives
- **Internal Database**: Uses Core Data to store all tracking data locally
- **Detailed History**: View all past tracking sessions with comprehensive statistics
- **Privacy-First**: All data stays on your device
- **User-Friendly Interface**: Clean SwiftUI interface with intuitive controls

## Core Components

### 1. LocationManager
- Handles GPS location updates
- Manages location permissions
- Supports background location tracking
- Saves location data to Core Data database

### 2. Core Data Model
- **TrackingSession**: Stores session information (narrative, start/end times, active status)
- **LocationEntry**: Stores individual GPS points with coordinates, timestamp, accuracy, speed, etc.

### 3. User Interface
- **TrackingView**: Main interface for starting/stopping tracking with narrative input
- **HistoryView**: Displays all tracking sessions with detailed statistics
- **SessionDetailView**: Comprehensive view of individual tracking sessions

## Getting Started

### Prerequisites
- Xcode 15.0 or later
- iOS 17.0 or later
- iPhone device (location services required)

### Installation
1. Open `TrackMe.xcodeproj` in Xcode
2. Select your development team in project settings
3. Build and run on a physical iOS device (Simulator won't provide real GPS data)

### First Time Setup
1. Launch the app on your device
2. Grant location permissions when prompted
3. Choose "Always Allow" for background tracking capability
4. Start your first tracking session by tapping "Start Tracking"
5. Enter a descriptive narrative for your session
6. The app will begin recording your GPS coordinates

## Usage

### Starting a Tracking Session
1. Open the app and go to the "Track" tab
2. Tap "Start Tracking"
3. Enter a narrative description (e.g., "Morning jog", "Drive to work")
4. Confirm to begin tracking
5. The app will display real-time location updates and tracking status

### Stopping a Session
1. Tap "Stop Tracking" when you want to end the current session
2. The session will be saved with an end time
3. All recorded locations are preserved in the database

### Viewing History
1. Go to the "History" tab to see all past sessions
2. Tap any session to view detailed information including:
   - Session duration and location count
   - GPS coordinates and timestamps
   - Distance calculations and speed statistics
   - Accuracy information

### Managing Data
- Delete unwanted sessions by swiping left in the history list
- All data is stored locally on your device
- No data is transmitted to external servers

## Privacy & Permissions

### Location Permissions Required
- **When In Use**: Allows tracking while app is active
- **Always**: Required for background tracking (recommended)

### Privacy Features
- All GPS data stays on your device
- No external data transmission
- No analytics or tracking by third parties
- Full control over your data

## Technical Details

### Database Schema
```
TrackingSession
├── id: UUID
├── narrative: String
├── startDate: Date
├── endDate: Date (optional)
├── isActive: Boolean
└── locations: [LocationEntry]

LocationEntry
├── id: UUID
├── latitude: Double
├── longitude: Double
├── timestamp: Date
├── accuracy: Double
├── altitude: Double
├── speed: Double
├── course: Double
└── session: TrackingSession
```

### Location Accuracy
- Uses `kCLLocationAccuracyBest` for maximum precision
- Filters out locations with poor accuracy
- Updates every 5 meters of movement
- Records speed, course, and altitude when available

### Background Operation
- Enabled for location updates in background
- Prevents device sleep during active tracking
- Maintains GPS connection for continuous tracking

## Troubleshooting

### Location Not Updating
- Ensure location permissions are set to "Always Allow"
- Check that Location Services are enabled in iOS Settings
- Verify app has background refresh enabled

### Poor Accuracy
- Use outdoors with clear sky view
- Avoid areas with tall buildings or dense tree cover
- Wait a few moments for GPS to acquire better signal

### App Performance
- Large tracking sessions may take time to load in history
- Consider ending sessions periodically for better performance
- Delete old sessions you no longer need

## Development Notes

### Architecture
- MVVM pattern with SwiftUI
- Core Data for local persistence
- Combine framework for reactive updates
- Core Location for GPS functionality

### Key Files
- `LocationManager.swift`: GPS and location logic
- `TrackingView.swift`: Main tracking interface
- `HistoryView.swift`: Session history and details
- `Persistence.swift`: Core Data stack
- `TrackMe.xcdatamodel`: Database schema

## License

This project is intended for personal use. Modify and distribute according to your needs.

## Support

For issues or questions about the GPS tracking functionality:
1. Check location permissions in iOS Settings
2. Ensure the app is running on a physical device
3. Verify GPS signal availability in your location