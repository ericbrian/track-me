# TrackMe - Privacy-First GPS Tracking iOS App

A comprehensive, privacy-first iOS application that tracks your movements using GPS with the ability to store data locally on your device. All data stays private—no cloud sync, no servers, no data transmission.

## Looking for a Mentor

I'm very new to iOS development and would greatly appreciate guidance from an experienced iOS developer who can help mentor this project. If you're interested in helping shape this privacy-first GPS tracking app and sharing your expertise in Swift, SwiftUI, Core Data, and iOS best practices, please reach out! I'm eager to learn and improve both the codebase and my development skills.

## Features

- **Real-time GPS Tracking**: Accurate location tracking using Core Location
- **Background Tracking**: Continues tracking when the app is in the background with configurable tracking modes
- **Session Management**: Start and stop tracking sessions with custom narratives
- **Local Database**: Uses Core Data to store all tracking data exclusively on your device
- **Detailed History**: View all past tracking sessions with comprehensive statistics
- **Interactive Maps**: View your routes on a map with location markers and polylines
- **Data Export**: Export sessions to CSV or GeoJSON formats
- **Privacy-First**: 100% local storage - no cloud sync, no servers, no external data transmission
- **User-Friendly Interface**: Clean SwiftUI interface with intuitive controls
- **Comprehensive Testing**: Full test suite with unit and integration tests

## Privacy Commitment

**Your location data never leaves your device.** TrackMe is built on privacy-first principles:

- ✅ 100% local storage using Core Data
- ✅ No network connectivity or data transmission
- ✅ No third-party analytics or tracking
- ✅ No user accounts or authentication
- ✅ Complete data control and ownership
- ✅ Open source for transparency

See [PRIVACY.md](PRIVACY.md) for our complete privacy policy.

## Core Components

### 1. LocationManager (`Services/LocationManager.swift`)

- Centralized GPS location tracking and management
- Handles location permissions and authorization
- Supports multiple tracking modes (Normal, High Accuracy, Power Saving, Custom)
- Background location tracking with battery optimization
- Kalman filtering for improved accuracy
- Saves location data to Core Data database

### 2. ViewModels (`ViewModels/`)

- **HistoryListViewModel**: Manages session list display and deletion with FetchedResultsController
- **MapViewModel**: Handles map display, camera positioning, and route visualization
- **TrackingControlBarViewModel**: Controls tracking start/stop logic and narrative input
- MVVM architecture separating business logic from views

### 3. Core Data Model (`TrackMe.xcdatamodeld`)

- **TrackingSession**: Stores session information (narrative, start/end times, active status)

- **LocationEntry**: Stores individual GPS points with coordinates, timestamp, accuracy, speed, altitude, course
- Repository pattern for data access via `SessionRepository` and `LocationRepository`

### 4. User Interface (`Views/`)

- **TrackingView**: Main interface for starting/stopping tracking with narrative input and real-time stats

- **HistoryView**: Displays all tracking sessions with modern card-based UI
- **TripMapView**: Interactive map showing routes with polylines and location markers
- **PrivacyNoticeView**: Comprehensive privacy information and data handling explanation
- Modular component structure in `Views/Components/`

### 5. Export & Sharing (`Services/ExportService.swift`)

- CSV export with all location details
- GeoJSON export for geographic applications
- GPX export for GPS device compatibility
- Share via iOS Share Sheet

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
   - Interactive map with route visualization
   - GPS coordinates and timestamps
   - Distance calculations and speed statistics
   - Accuracy information
3. Export sessions to CSV or GeoJSON format via the share button

### Managing Data

- Delete unwanted sessions by swiping left in the history list
- Export data before deletion if you want to keep a backup
- All data is stored locally on your device
- Deleting the app removes all data permanently (no cloud backup)

## Privacy & Permissions

### Location Permissions Required

- **When In Use**: Allows tracking while app is active
- **Always**: Required for background tracking (recommended for continuous tracking)

### Privacy Features

- **100% Local Storage**: All GPS data stays exclusively on your device
- **No Network Connectivity**: App never transmits data over the internet
- **No Third-Party Services**: No analytics, crash reporting, or advertising SDKs
- **No User Accounts**: No authentication or personal information collected
- **Full Data Control**: Export or delete your data anytime
- **Open Source**: Verify our privacy claims by reviewing the code

Access the in-app Privacy Notice by tapping the privacy icon in the toolbar, or read [PRIVACY.md](PRIVACY.md) for our complete privacy policy.

## Technical Details

### Database Schema

```swift
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

### Tracking Modes

- **Normal Mode**: Balanced accuracy and battery life (default)
- **High Accuracy Mode**: Maximum precision for detailed tracking
- **Power Saving Mode**: Extended battery life for long trips
- **Custom Mode**: User-configurable settings

### Location Accuracy

- Configurable accuracy levels based on tracking mode
- Filters out locations with poor accuracy
- Distance-based update filtering (prevents redundant points)
- Records speed, course, and altitude when available
- Kalman filtering for smoothing (in High Accuracy mode)

### Background Operation

- Enabled for location updates in background
- Multiple tracking modes optimize battery vs. accuracy
- Maintains GPS connection for continuous tracking
- Background task management for data processing

### Testing

- Comprehensive unit test suite in `TrackMeTests/`
- Tests cover LocationManager, Core Data, ViewModels, and integration scenarios
- Run tests via `xcodebuild test` or Cmd+U in Xcode
- Code coverage reporting available

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

- **MVVM pattern** with SwiftUI for clear separation of concerns
- **Repository pattern** for data access abstraction
- **Dependency injection** for testability and flexibility
- **Core Data** for robust local persistence
- **Combine framework** for reactive updates and data flow
- **Core Location** for comprehensive GPS functionality

### Project Structure

```tree
TrackMe/
├── Services/           # Business logic and managers
│   ├── LocationManager.swift
│   ├── ExportService.swift
│   ├── ErrorHandling.swift
│   └── MapMath.swift
├── ViewModels/         # MVVM view models
│   ├── HistoryListViewModel.swift
│   ├── MapViewModel.swift
│   └── TrackingControlBarViewModel.swift
├── Views/              # SwiftUI views
│   ├── TrackingView.swift
│   ├── HistoryView.swift
│   ├── TripMapView.swift
│   └── Components/     # Reusable UI components
├── Data/               # Core Data and repositories
│   ├── Persistence.swift
│   ├── CoreDataRepositories.swift
│   └── RepositoryProtocols.swift
└── Models/             # Data models and extensions
```

### Key Files

- `Services/LocationManager.swift`: GPS tracking, permissions, and location logic
- `ViewModels/`: MVVM view models for UI state management
- `Views/TrackingView.swift`: Main tracking interface
- `Views/HistoryView.swift`: Session history and management
- `Views/TripMapView.swift`: Interactive map visualization
- `Data/Persistence.swift`: Core Data stack and configuration
- `Data/CoreDataRepositories.swift`: Data access layer
- `TrackMe.xcdatamodeld`: Database schema definition

### Documentation

- [PRIVACY.md](PRIVACY.md): Complete privacy policy
- [.github/copilot-instructions.md](.github/copilot-instructions.md): Development guidelines and patterns
- Architecture Decision Records (ADRs) in `docs/adr/`

### Contributing

1. Follow the project's MVVM architecture
2. Write tests for new features
3. Never force unwrap optionals (except in tests)
4. Maintain privacy-first principles
5. Keep all data local—no network calls

## License

This project is intended for personal use. Modify and distribute according to your needs.

## Support

For issues or questions:

- Review the [Privacy Policy](PRIVACY.md)
- Check [Copilot Instructions](.github/copilot-instructions.md) for development patterns
- Review Architecture Decision Records in `docs/adr/`
- Ensure you're using a physical device (not simulator) for GPS functionality
- Verify location permissions are set to "Always Allow" in iOS Settings
