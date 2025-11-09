# Copilot Instructions for TrackMe

## Project Overview

TrackMe is a privacy-first iOS app for real-time GPS tracking, session management, and local data storage. It uses SwiftUI, Core Location, Core Data, and Combine. The app is structured for clarity and extensibility, with a focus on user privacy and offline operation.

## Architecture & Key Components

- **MVVM with SwiftUI**: Views in `Views/`, logic in `Services/`, persistence in `Data/`.
- **LocationManager** (`Services/LocationManager.swift`): Handles all GPS logic, permissions, and background tracking. Updates are filtered for accuracy and frequency.
- **Core Data** (`Data/Persistence.swift`, `TrackMe.xcdatamodeld/`): Stores sessions (`TrackingSession`) and location points (`LocationEntry`).
- **Phone/Watch Communication**: `PhoneConnectivityManager.swift` and `WatchConnectivityManager.swift` manage cross-device sync (if implemented).
- **UI**: Main screens are `TrackingView.swift` (start/stop, narrative), `HistoryView.swift` (session list), and `TripMapView.swift` (map display).

## Developer Workflows

- **Build**: Open `TrackMe.xcodeproj` in Xcode 15+, select a physical iOS device, and run. Simulator does not provide real GPS data.
- **Debug**: Use Xcode's debugger and device logs. Location updates require device permissions.
- **Database**: Schema is defined in `TrackMe.xcdatamodeld`. Use Core Data tools for inspection.
- **Testing**: Unit tests are in `TrackMeTests/`. Run tests via:
  ```bash
  xcodebuild test -scheme TrackMe -destination 'platform=iOS Simulator,id=0609225E-F180-495E-8270-D487A0FB5219'
  ```
  Or use Cmd+U in Xcode. Tests cover LocationManager, Core Data persistence, connectivity managers, and integration scenarios.

## Project-Specific Patterns

- **Session Management**: Each tracking session has a narrative, start/end times, and a list of `LocationEntry` points. See `TrackingView.swift` and `LocationManager.swift` for flow.
- **Background Tracking**: Enabled via Core Location; ensure permissions are set to "Always Allow" for full functionality.
- **Data Privacy**: All data is local; no network sync or analytics. Do not add external data transmission without explicit user consent.
- **Combine**: Used for reactive updates between services and views.

## Integration Points

- **Core Location**: All location logic is centralized in `LocationManager.swift`.
- **Core Data**: Accessed via `Persistence.swift` and the Core Data model.
- **Watch App**: Communication logic is in `PhoneConnectivityManager.swift` and `WatchConnectivityManager.swift`.

## Conventions

- **SwiftUI for all UI**; UIKit is not used.
- **MVVM separation**: Keep business logic out of views.
- **No external analytics or tracking**.
- **All data is local by default**.

## Examples

- To add a new data field to sessions, update the Core Data model and relevant Swift files in `Data/` and `Views/`.
- To change location update frequency, adjust `LocationManager.swift` (distance filter, accuracy).

## Key Files/Directories

- `TrackMe/Services/LocationManager.swift`
- `TrackMe/Data/Persistence.swift`
- `TrackMe/Views/TrackingView.swift`, `HistoryView.swift`, `TripMapView.swift`
- `TrackMe.xcdatamodeld/`
- `TrackMeTests/` - Unit tests for all major components

# Critical Directives:

- Before fixing bugs and the like, create a unit test that reproduces the issue. Then fix the issue and ensure the test passes.
- Ensure all new features have corresponding unit tests.
- After adding a unit test, run the full test suite to ensure no regressions and then update the code coverage report.
- Never Force Unwrap optionals. Use guard statements or optional binding.


---

For questions, review the README or inspect the above files for implementation patterns. Run unit tests to validate changes.
