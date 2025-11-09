# Configuration Management

TrackMe uses a centralized configuration system to manage app-wide settings. All configuration is defined in `Config.swift` and loaded from `Config.plist`.

## Structure

Configuration is organized into five groups:

### Location
Controls GPS tracking behavior:
- `desiredAccuracy`: Location accuracy level
- `distanceFilter`: Minimum distance before updates (meters)
- `activityType`: Type of activity (navigation, fitness, etc.)
- `showBackgroundIndicator`: Show blue bar during background tracking
- `pausesAutomatically`: Pause location updates when stationary

### UI
User interface constants:
- `mapDefaultZoom`: Default map zoom level
- `animationDuration`: Standard animation duration (seconds)
- `updateDelay`: Delay for UI updates (seconds)
- `shadowOpacity`: Opacity for shadows
- `shadowRadius`: Blur radius for shadows

### Performance
Optimization settings:
- `fetchBatchSize`: Core Data fetch batch size
- `backgroundRefreshInterval`: Background task interval (seconds)
- `enableKalmanFilter`: Enable location smoothing

### Features
Feature flags:
- `enableWatchSync`: Enable Watch connectivity
- `enableGPXExport`: Enable GPX export
- `enableCSVExport`: Enable CSV export
- `maxPermissionDenials`: Permission prompt limit

### Debug
Debugging options:
- `verboseLogging`: Enable detailed logging
- `logLocationValidation`: Log location filtering
- `logCoreData`: Log Core Data operations
- `logConnectivity`: Log Watch connectivity

## Usage

Access configuration values through the shared singleton:

```swift
// Location configuration
let accuracy = AppConfig.shared.location.desiredAccuracy
let filter = AppConfig.shared.location.distanceFilter

// UI configuration
let zoom = AppConfig.shared.ui.mapDefaultZoom
let duration = AppConfig.shared.ui.animationDuration

// Performance configuration
let batchSize = AppConfig.shared.performance.fetchBatchSize
let enableKalman = AppConfig.shared.performance.enableKalmanFilter

// Feature flags
let watchEnabled = AppConfig.shared.features.enableWatchSync
let maxDenials = AppConfig.shared.features.maxPermissionDenials

// Debug settings
let verbose = AppConfig.shared.debug.verboseLogging
```

## Modifying Configuration

### Production
Edit `Config.plist` to change default values. The plist is loaded once at app launch.

### Testing
Inject test configuration using JSON:

```swift
let json = """
{
  "Location": {
    "DistanceFilter": 10.0,
    "DesiredAccuracy": -2.0
  },
  "Features": {
    "EnableWatchSync": false
  }
}
""".data(using: .utf8)!

let testConfig = AppConfig.loadFromJSON(data: json)
```

## Adding New Configuration

1. Add property to appropriate config struct in `Config.swift`
2. Update initializer with default value
3. Add plist loading logic in `init(from:)` method
4. Add entry to `Config.plist`
5. Document in this guide

## Best Practices

- **Don't over-configure**: Only make things configurable if they need to vary
- **Use safe defaults**: Ensure defaults work well if plist is missing
- **Group logically**: Keep related settings together
- **Document values**: Add comments in plist explaining each setting
- **Type safety**: Use enums and structs, not stringly-typed values

## Related

- ADR-006: Centralized Configuration Management
- `Config.swift`: Implementation
- `Config.plist`: Default values
