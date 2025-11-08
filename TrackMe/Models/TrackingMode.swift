import Foundation

/// User-facing tracking modes that map to LocationValidationConfig presets
/// These provide clear, simple choices for different use cases
enum TrackingMode: String, CaseIterable, Identifiable {
    case detailed = "detailed"
    case balanced = "balanced"
    case efficient = "efficient"

    var id: String { rawValue }

    /// User-friendly display name
    var displayName: String {
        switch self {
        case .detailed:
            return "Detailed Tracking"
        case .balanced:
            return "Balanced (Recommended)"
        case .efficient:
            return "Efficient Travel"
        }
    }

    /// Short description for the mode
    var description: String {
        switch self {
        case .detailed:
            return "High precision for walking, hiking, or city tours"
        case .balanced:
            return "Good balance of detail and efficiency for most trips"
        case .efficient:
            return "Optimized for long road trips and flights"
        }
    }

    /// Detailed information about what this mode captures
    var details: String {
        switch self {
        case .detailed:
            return "Records a point every 10 meters. Perfect for detailed tracking of walks, hikes, or exploring a city on foot. Captures every turn and movement."
        case .balanced:
            return "Records a point every 200 meters. Ideal for most driving trips, capturing all route details while keeping data size reasonable. Uses adaptive sampling to capture more detail when slow."
        case .efficient:
            return "Records a point every 500 meters. Best for very long trips (300+ km), flights, or when minimizing data size is important. Still captures your complete route."
        }
    }

    /// Example of data volume for different trip types
    var dataVolumeExamples: String {
        switch self {
        case .detailed:
            return """
            Examples:
            • 5km walk: ~500 points (~75 KB)
            • 10km hike: ~1,000 points (~150 KB)
            • 50km bike ride: ~5,000 points (~750 KB)
            """
        case .balanced:
            return """
            Examples:
            • 50km drive: ~250 points (~40 KB)
            • 200km trip: ~1,000 points (~150 KB)
            • 500km journey: ~2,500 points (~375 KB)
            """
        case .efficient:
            return """
            Examples:
            • 100km drive: ~200 points (~30 KB)
            • 500km road trip: ~1,000 points (~150 KB)
            • 1000km flight: ~2,000 points (~300 KB)
            """
        }
    }

    /// Warnings about potential issues with this mode
    var warnings: [String] {
        switch self {
        case .detailed:
            return [
                "⚠️ Large data sets: Long trips will generate huge amounts of data",
                "⚠️ Map performance: Trips over 50km may have slow map rendering",
                "⚠️ Battery drain: High-frequency GPS use consumes more battery",
                "⚠️ Storage: Each 50km can use 500-750 KB of storage"
            ]
        case .balanced:
            return [
                "ℹ️ Good for most uses: Works well for trips up to ~500km",
                "ℹ️ May miss fine details: Not ideal for detailed walking tours",
                "ℹ️ Adaptive: Automatically captures more detail when moving slowly"
            ]
        case .efficient:
            return [
                "⚠️ Less detail: May miss small turns or details in cities",
                "⚠️ Not for walking: Too sparse for hiking or walking tours",
                "✅ Best for long trips: Perfect for road trips over 300km",
                "✅ Fast maps: Excellent map rendering performance"
            ]
        }
    }

    /// Technical specifications (for advanced users)
    var technicalSpecs: String {
        switch self {
        case .detailed:
            return "Min distance: 10m | Max accuracy: 20m | Adaptive: No"
        case .balanced:
            return "Min distance: 200m | Max accuracy: 50m | Adaptive: Yes"
        case .efficient:
            return "Min distance: 500m | Max accuracy: 65m | Adaptive: Yes"
        }
    }

    /// Maps this mode to the appropriate LocationValidationConfig
    var validationConfig: LocationValidationConfig {
        switch self {
        case .detailed:
            return .highPrecision
        case .balanced:
            return .default
        case .efficient:
            return .efficient
        }
    }

    /// Icon for UI display
    var iconName: String {
        switch self {
        case .detailed:
            return "figure.walk"
        case .balanced:
            return "car.fill"
        case .efficient:
            return "airplane"
        }
    }

    /// Color for UI display
    var colorHex: String {
        switch self {
        case .detailed:
            return "#34C759" // Green
        case .balanced:
            return "#007AFF" // Blue
        case .efficient:
            return "#FF9500" // Orange
        }
    }
}

/// UserDefaults storage for tracking mode preference
extension UserDefaults {
    private static let trackingModeKey = "selectedTrackingMode"

    var selectedTrackingMode: TrackingMode {
        get {
            guard let rawValue = string(forKey: UserDefaults.trackingModeKey),
                  let mode = TrackingMode(rawValue: rawValue) else {
                return .balanced // Default to balanced
            }
            return mode
        }
        set {
            set(newValue.rawValue, forKey: UserDefaults.trackingModeKey)
        }
    }
}
