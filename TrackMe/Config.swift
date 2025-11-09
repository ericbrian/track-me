import Foundation
import CoreLocation

// MARK: - AppConfig

/// Centralized configuration management for TrackMe
/// Loads settings from Config.plist with type-safe defaults
struct AppConfig {
    
    // MARK: - Singleton
    
    /// Shared configuration instance
    static let shared: AppConfig = {
        if let config = AppConfig.loadFromPlist() {
            return config
        }
        print("⚠️ Failed to load Config.plist, using defaults")
        return AppConfig()
    }()
    
    // MARK: - Configuration Groups
    
    let location: LocationConfig
    let ui: UIConfig
    let performance: PerformanceConfig
    let features: FeatureConfig
    let debug: DebugConfig
    
    // MARK: - Initialization
    
    /// Initialize with default values
    init(
        location: LocationConfig = LocationConfig(),
        ui: UIConfig = UIConfig(),
        performance: PerformanceConfig = PerformanceConfig(),
        features: FeatureConfig = FeatureConfig(),
        debug: DebugConfig = DebugConfig()
    ) {
        self.location = location
        self.ui = ui
        self.performance = performance
        self.features = features
        self.debug = debug
    }
    
    // MARK: - Plist Loading
    
    /// Load configuration from Config.plist
    private static func loadFromPlist() -> AppConfig? {
        guard let path = Bundle.main.path(forResource: "Config", ofType: "plist"),
              let data = FileManager.default.contents(atPath: path),
              let plist = try? PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any] else {
            return nil
        }
        
        return AppConfig(
            location: LocationConfig(from: plist["Location"] as? [String: Any]),
            ui: UIConfig(from: plist["UI"] as? [String: Any]),
            performance: PerformanceConfig(from: plist["Performance"] as? [String: Any]),
            features: FeatureConfig(from: plist["Features"] as? [String: Any]),
            debug: DebugConfig(from: plist["Debug"] as? [String: Any])
        )
    }
    
    /// Load configuration from JSON (for testing)
    static func loadFromJSON(data: Data) -> AppConfig? {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return nil
        }
        
        return AppConfig(
            location: LocationConfig(from: json["Location"] as? [String: Any]),
            ui: UIConfig(from: json["UI"] as? [String: Any]),
            performance: PerformanceConfig(from: json["Performance"] as? [String: Any]),
            features: FeatureConfig(from: json["Features"] as? [String: Any]),
            debug: DebugConfig(from: json["Debug"] as? [String: Any])
        )
    }
}

// MARK: - LocationConfig

/// Configuration for location tracking and GPS management
struct LocationConfig {
    
    /// Desired accuracy for location updates
    let desiredAccuracy: CLLocationAccuracy
    
    /// Minimum distance (in meters) before an update is generated
    let distanceFilter: Double
    
    /// Activity type for location tracking
    let activityType: CLActivityType
    
    /// Show background location indicator
    let showBackgroundIndicator: Bool
    
    /// Pause location updates automatically when possible
    let pausesAutomatically: Bool
    
    /// Default values
    static let defaults = LocationConfig()
    
    init(
        desiredAccuracy: CLLocationAccuracy = kCLLocationAccuracyBest,
        distanceFilter: Double = 5.0,
        activityType: CLActivityType = .otherNavigation,
        showBackgroundIndicator: Bool = true,
        pausesAutomatically: Bool = false
    ) {
        self.desiredAccuracy = desiredAccuracy
        self.distanceFilter = distanceFilter
        self.activityType = activityType
        self.showBackgroundIndicator = showBackgroundIndicator
        self.pausesAutomatically = pausesAutomatically
    }
    
    init(from dict: [String: Any]?) {
        self.desiredAccuracy = {
            guard let accuracy = dict?["DesiredAccuracy"] as? Double else {
                return kCLLocationAccuracyBest
            }
            return accuracy
        }()
        
        self.distanceFilter = dict?["DistanceFilter"] as? Double ?? 5.0
        
        self.activityType = {
            guard let typeString = dict?["ActivityType"] as? String else {
                return .otherNavigation
            }
            switch typeString {
            case "Other": return .other
            case "AutomotiveNavigation": return .automotiveNavigation
            case "Fitness": return .fitness
            case "OtherNavigation": return .otherNavigation
            case "Airborne": return .airborne
            default: return .otherNavigation
            }
        }()
        
        self.showBackgroundIndicator = dict?["ShowBackgroundIndicator"] as? Bool ?? true
        self.pausesAutomatically = dict?["PausesAutomatically"] as? Bool ?? false
    }
}

// MARK: - UIConfig

/// Configuration for user interface constants
struct UIConfig {
    
    /// Default map zoom level (coordinate span)
    let mapDefaultZoom: Double
    
    /// Animation duration for standard transitions (seconds)
    let animationDuration: Double
    
    /// Delay for UI updates (seconds)
    let updateDelay: Double
    
    /// Shadow opacity for elevated UI elements
    let shadowOpacity: Double
    
    /// Shadow radius for elevated UI elements
    let shadowRadius: Double
    
    /// Default values
    static let defaults = UIConfig()
    
    init(
        mapDefaultZoom: Double = 0.01,
        animationDuration: Double = 0.3,
        updateDelay: Double = 0.1,
        shadowOpacity: Double = 0.1,
        shadowRadius: Double = 4.0
    ) {
        self.mapDefaultZoom = mapDefaultZoom
        self.animationDuration = animationDuration
        self.updateDelay = updateDelay
        self.shadowOpacity = shadowOpacity
        self.shadowRadius = shadowRadius
    }
    
    init(from dict: [String: Any]?) {
        self.mapDefaultZoom = dict?["MapDefaultZoom"] as? Double ?? 0.01
        self.animationDuration = dict?["AnimationDuration"] as? Double ?? 0.3
        self.updateDelay = dict?["UpdateDelay"] as? Double ?? 0.1
        self.shadowOpacity = dict?["ShadowOpacity"] as? Double ?? 0.1
        self.shadowRadius = dict?["ShadowRadius"] as? Double ?? 4.0
    }
}

// MARK: - PerformanceConfig

/// Configuration for performance optimization
struct PerformanceConfig {
    
    /// Batch size for Core Data fetch requests
    let fetchBatchSize: Int
    
    /// Background task refresh interval (minutes)
    let backgroundRefreshInterval: TimeInterval
    
    /// Enable Kalman filtering for location smoothing
    let enableKalmanFilter: Bool
    
    /// Default values
    static let defaults = PerformanceConfig()
    
    init(
        fetchBatchSize: Int = 100,
        backgroundRefreshInterval: TimeInterval = 15 * 60,
        enableKalmanFilter: Bool = true
    ) {
        self.fetchBatchSize = fetchBatchSize
        self.backgroundRefreshInterval = backgroundRefreshInterval
        self.enableKalmanFilter = enableKalmanFilter
    }
    
    init(from dict: [String: Any]?) {
        self.fetchBatchSize = dict?["FetchBatchSize"] as? Int ?? 100
        self.backgroundRefreshInterval = (dict?["BackgroundRefreshInterval"] as? Double).map { $0 * 60 } ?? (15 * 60)
        self.enableKalmanFilter = dict?["EnableKalmanFilter"] as? Bool ?? true
    }
}

// MARK: - FeatureConfig

/// Configuration for feature flags
struct FeatureConfig {
    
    /// Enable Watch connectivity and sync
    let enableWatchSync: Bool
    
    /// Enable GPX export functionality
    let enableGPXExport: Bool
    
    /// Enable CSV export functionality
    let enableCSVExport: Bool
    
    /// Maximum number of denied permission prompts before showing settings suggestion
    let maxPermissionDenials: Int
    
    /// Default values
    static let defaults = FeatureConfig()
    
    init(
        enableWatchSync: Bool = true,
        enableGPXExport: Bool = true,
        enableCSVExport: Bool = true,
        maxPermissionDenials: Int = 2
    ) {
        self.enableWatchSync = enableWatchSync
        self.enableGPXExport = enableGPXExport
        self.enableCSVExport = enableCSVExport
        self.maxPermissionDenials = maxPermissionDenials
    }
    
    init(from dict: [String: Any]?) {
        self.enableWatchSync = dict?["EnableWatchSync"] as? Bool ?? true
        self.enableGPXExport = dict?["EnableGPXExport"] as? Bool ?? true
        self.enableCSVExport = dict?["EnableCSVExport"] as? Bool ?? true
        self.maxPermissionDenials = dict?["MaxPermissionDenials"] as? Int ?? 2
    }
}

// MARK: - DebugConfig

/// Configuration for debugging and development
struct DebugConfig {
    
    /// Enable verbose logging
    let verboseLogging: Bool
    
    /// Enable location validation debug output
    let logLocationValidation: Bool
    
    /// Enable Core Data debug output
    let logCoreData: Bool
    
    /// Enable connectivity debug output
    let logConnectivity: Bool
    
    /// Default values
    static let defaults = DebugConfig()
    
    init(
        verboseLogging: Bool = false,
        logLocationValidation: Bool = false,
        logCoreData: Bool = false,
        logConnectivity: Bool = false
    ) {
        self.verboseLogging = verboseLogging
        self.logLocationValidation = logLocationValidation
        self.logCoreData = logCoreData
        self.logConnectivity = logConnectivity
    }
    
    init(from dict: [String: Any]?) {
        self.verboseLogging = dict?["VerboseLogging"] as? Bool ?? false
        self.logLocationValidation = dict?["LogLocationValidation"] as? Bool ?? false
        self.logCoreData = dict?["LogCoreData"] as? Bool ?? false
        self.logConnectivity = dict?["LogConnectivity"] as? Bool ?? false
    }
}
