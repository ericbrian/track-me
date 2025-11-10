import Foundation
import CoreLocation
import CoreData
import UIKit
import BackgroundTasks

// Note: Repository protocols and implementations are defined in TrackMe/Data/
// - RepositoryProtocols.swift: SessionRepositoryProtocol, LocationRepositoryProtocol
// - CoreDataRepositories.swift: CoreDataSessionRepository, CoreDataLocationRepository

// MARK: - Location Validation Configuration

/// Configuration for location data validation and filtering
struct LocationValidationConfig {
    /// Maximum acceptable horizontal accuracy in meters
    /// Locations with accuracy worse than this will be filtered out
    let maxHorizontalAccuracy: Double

    /// Maximum acceptable speed in meters per second
    /// Speeds above this are considered anomalous (e.g., 250 km/h = ~69 m/s)
    let maxReasonableSpeed: Double

    /// Maximum acceptable distance jump in meters between consecutive points
    /// Larger jumps may indicate GPS errors or teleportation
    let maxDistanceJump: Double

    /// Minimum time interval in seconds between saved locations
    /// Prevents saving too many points too quickly
    let minTimeBetweenUpdates: TimeInterval

    /// Minimum distance in meters that must be traveled before saving a new point
    /// This is the primary filter for reducing dataset size on long trips
    /// Nil means distance filtering is disabled (time-based only)
    let minDistanceBetweenPoints: Double?

    /// Enable adaptive sampling based on speed
    /// When true, saves more points when stationary/slow, fewer when moving fast
    let adaptiveSampling: Bool

    /// Default configuration - optimized for long trips with reasonable data size
    /// 350km trip: ~700-1,750 points (depending on route complexity)
    static let `default` = LocationValidationConfig(
        maxHorizontalAccuracy: 50.0,       // 50m - good accuracy
        maxReasonableSpeed: 69.0,          // ~250 km/h - very fast but possible
        maxDistanceJump: 1000.0,           // 1km - large but possible in vehicles
        minTimeBetweenUpdates: 5.0,        // 5 seconds between points (reduced from 1s)
        minDistanceBetweenPoints: 200.0,   // Save every 200m - key for long trips!
        adaptiveSampling: true             // Use adaptive sampling
    )

    /// High-precision configuration for walking, hiking, or detailed tracking
    /// 10km walk: ~5,000-10,000 points (very detailed)
    static let highPrecision = LocationValidationConfig(
        maxHorizontalAccuracy: 20.0,       // 20m - high accuracy
        maxReasonableSpeed: 30.0,          // ~108 km/h - fast car speed
        maxDistanceJump: 500.0,            // 500m - moderate jump
        minTimeBetweenUpdates: 2.0,        // 2 seconds between points
        minDistanceBetweenPoints: 10.0,    // Save every 10m - very detailed
        adaptiveSampling: false            // Disable adaptive (want all detail)
    )

    /// Efficient configuration for very long trips (road trips, flights)
    /// 350km trip: ~350-700 points (very efficient)
    static let efficient = LocationValidationConfig(
        maxHorizontalAccuracy: 65.0,       // 65m - moderate accuracy
        maxReasonableSpeed: 150.0,         // ~540 km/h - airplane speed
        maxDistanceJump: 5000.0,           // 5km - very large jump
        minTimeBetweenUpdates: 10.0,       // 10 seconds between points
        minDistanceBetweenPoints: 500.0,   // Save every 500m - very efficient!
        adaptiveSampling: true             // Use adaptive sampling
    )

    /// Legacy permissive configuration (kept for compatibility)
    /// Not recommended for trips - will generate huge datasets
    static let permissive = LocationValidationConfig(
        maxHorizontalAccuracy: 100.0,      // 100m - original threshold
        maxReasonableSpeed: 150.0,         // ~540 km/h - airplane speed
        maxDistanceJump: 5000.0,           // 5km - very large jump
        minTimeBetweenUpdates: 1.0,        // 1 second between points
        minDistanceBetweenPoints: nil,     // No distance filtering
        adaptiveSampling: false            // No adaptive sampling
    )
}

class LocationManager: NSObject, ObservableObject {
    private let deniedAlwaysKey = "TrackMeDeniedAlwaysCount"
    @Published var showSettingsSuggestion = false
    private var phoneConnectivity: PhoneConnectivityManager? {
        PhoneConnectivityManager.shared
    }
    private let locationManager = CLLocationManager()
    private var backgroundTask: UIBackgroundTaskIdentifier = .invalid
    private var hasSetupObservers = false
    var kalmanFilter: KalmanFilter?
    
    // Injected dependencies
    private let sessionRepository: SessionRepositoryProtocol
    private let locationRepository: LocationRepositoryProtocol

    // Error handler - computed property to avoid main actor isolation warning
    private var errorHandler: ErrorHandler {
        ErrorHandler.shared
    }

    // Location validation - uses user's selected tracking mode
    private var validationConfig: LocationValidationConfig {
        UserDefaults.standard.selectedTrackingMode.validationConfig
    }
    private var lastSavedLocation: CLLocation?
    private var lastSaveTime: Date?

    @Published var isTracking = false
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published var currentLocation: CLLocation?
    @Published var currentSession: TrackingSession?
    @Published var locationCount = 0

    /// Deprecated: Use ErrorHandler.shared instead for centralized error handling
    /// This property is maintained for backward compatibility only
    @available(*, deprecated, message: "Use ErrorHandler.shared to handle errors instead")
    @Published var trackingStartError: String?
    
    /// Deprecated: Use ErrorHandler.shared instead for centralized error handling
    /// This property is maintained for backward compatibility only
    @available(*, deprecated, message: "Use ErrorHandler.shared to handle errors instead")
    @Published var trackingStopError: String?
    
    /// Initialize with injected dependencies
    init(sessionRepository: SessionRepositoryProtocol,
         locationRepository: LocationRepositoryProtocol) {
        self.sessionRepository = sessionRepository
        self.locationRepository = locationRepository
        super.init()
        // Defer heavy setup to asyncSetup()
    }
    
    /// Legacy initializer for backward compatibility (uses default repositories)
    /// - Note: Prefer dependency injection via init(sessionRepository:locationRepository:)
    @available(*, deprecated, message: "Use init(sessionRepository:locationRepository:) instead")
    override convenience init() {
        let persistence = PersistenceController.shared
        let context = persistence.container.viewContext
        self.init(
            sessionRepository: CoreDataSessionRepository(context: context),
            locationRepository: CoreDataLocationRepository(context: context)
        )
    }

    /// Call this after UI appears to perform heavy setup
    func asyncSetup() {
        setupLocationManager()
        DispatchQueue.main.async {
            self.authorizationStatus = self.locationManager.authorizationStatus
        }
        // Run orphaned session recovery asynchronously to avoid blocking UI
        DispatchQueue.global(qos: .userInitiated).async {
            self.recoverOrphanedSessions()
        }
        // Prompt for Always permission on launch if not already granted
        if locationManager.authorizationStatus != .authorizedAlways {
            let maxDenials = AppConfig.shared.features.maxPermissionDenials
            if UserDefaults.standard.integer(forKey: deniedAlwaysKey) < maxDenials {
                self.requestLocationPermission()
            } else {
                DispatchQueue.main.async {
                    self.showSettingsSuggestion = true
                }
            }
        }
    }

    /// Mark any orphaned active sessions as inactive on app launch
    private func recoverOrphanedSessions() {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            do {
                let recoveredCount = try self.sessionRepository.recoverOrphanedSessions()
                if recoveredCount > 0 {
                    print("Recovered \(recoveredCount) orphaned active sessions on launch.")
                }
                DispatchQueue.main.async {
                    self.phoneConnectivity?.sendStatusUpdateToWatch()
                }
            } catch {
                print("⚠️ Failed to recover orphaned sessions: \(error)")
                DispatchQueue.main.async {
                    // Non-critical error - log but don't show to user
                    self.phoneConnectivity?.sendStatusUpdateToWatch()
                }
            }
        }
    }
    
    private func setupLocationManager() {
        let config = AppConfig.shared.location
        
        locationManager.delegate = self
        locationManager.desiredAccuracy = config.desiredAccuracy
        locationManager.distanceFilter = config.distanceFilter
        locationManager.pausesLocationUpdatesAutomatically = config.pausesAutomatically
        locationManager.activityType = config.activityType
        locationManager.showsBackgroundLocationIndicator = config.showBackgroundIndicator
        
        // Note: allowsBackgroundLocationUpdates should only be set when tracking starts
        // and after authorization is granted
    }
    
    // Background task registration is centralized in TrackMeApp.registerBackgroundTasks().
    // This class only schedules requests when appropriate.
    
    private func scheduleBackgroundLocationTask() {
        let config = AppConfig.shared.performance
        let request = BGAppRefreshTaskRequest(identifier: "com.ericbrian.TrackMe.background-location")
        request.earliestBeginDate = Date(timeIntervalSinceNow: config.backgroundRefreshInterval)
        
        try? BGTaskScheduler.shared.submit(request)
    }
    
    private func beginBackgroundTask() {
        backgroundTask = UIApplication.shared.beginBackgroundTask { [weak self] in
            self?.endBackgroundTask()
        }
    }
    
    private func endBackgroundTask() {
        if backgroundTask != .invalid {
            UIApplication.shared.endBackgroundTask(backgroundTask)
            backgroundTask = .invalid
        }
    }
    
    func requestLocationPermission() {
        locationManager.requestAlwaysAuthorization()
    }
    
    func startTracking(with narrative: String) {
        guard authorizationStatus == .authorizedAlways else {
            requestLocationPermission()
            let error = AppError.locationPermissionNotAlways
            trackingStartError = error.failureReason // Backward compatibility
            Task { @MainActor in
                errorHandler.handle(error)
            }
            phoneConnectivity?.sendStatusUpdateToWatch()
            return
        }

        // Prevent multiple active sessions using repository
        do {
            let activeSessions = try sessionRepository.fetchActiveSessions()
            if !activeSessions.isEmpty {
                print("An active tracking session already exists. Only one tracker allowed at a time.")
                let error = AppError.sessionAlreadyActive
                trackingStartError = error.failureReason // Backward compatibility
                Task { @MainActor in
                    errorHandler.handle(error)
                }
                phoneConnectivity?.sendStatusUpdateToWatch()
                return
            }
        } catch {
            print("Error checking for active sessions: \(error)")
            let appError = AppError.sessionQueryFailed(error)
            trackingStartError = appError.failureReason
            Task { @MainActor in
                errorHandler.handle(appError)
            }
            phoneConnectivity?.sendStatusUpdateToWatch()
            return
        }

        // Begin background task to ensure we don't get terminated
        beginBackgroundTask()

        // Create new tracking session using repository
        do {
            let session = try sessionRepository.createSession(narrative: narrative, startDate: Date())
            currentSession = session
            isTracking = true
            locationCount = 0
            // Reset validation tracking for new session
            lastSavedLocation = nil
            lastSaveTime = nil
            
            // Initialize Kalman filter for this session if enabled
            if AppConfig.shared.performance.enableKalmanFilter {
                self.kalmanFilter = KalmanFilter()
            }
            
            // Notify Watch about tracking state change
            NotificationCenter.default.post(name: NSNotification.Name("TrackingStateChanged"), object: nil)
            phoneConnectivity?.sendStatusUpdateToWatch()
        } catch {
            print("Error creating tracking session: \(error)")
            let appError = AppError.sessionCreationFailed(error)
            trackingStartError = appError.failureReason // Backward compatibility
            Task { @MainActor in
                errorHandler.handle(appError)
            }
            phoneConnectivity?.sendStatusUpdateToWatch()
            return
        }

        // Only proceed if authorizedAlways
        guard authorizationStatus == .authorizedAlways else {
            print("Not authorized for always location. Aborting startTracking.")
            return
        }


        // Enable background location updates only if background mode is enabled and authorizedAlways is granted
        #if !targetEnvironment(simulator)
        if let modes = Bundle.main.infoDictionary?["UIBackgroundModes"] as? [String],
           modes.contains("location"),
           authorizationStatus == .authorizedAlways {
            locationManager.allowsBackgroundLocationUpdates = true
        } else {
            locationManager.allowsBackgroundLocationUpdates = false
        }
        #endif

        // Start location updates
        locationManager.startUpdatingLocation()

        // Also monitor significant location changes for better background performance
        locationManager.startMonitoringSignificantLocationChanges()

        // Keep the app alive in background
        UIApplication.shared.isIdleTimerDisabled = true

        // Schedule background tasks
        scheduleBackgroundLocationTask()

        // Add app lifecycle observers (only once)
        if !hasSetupObservers {
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(appDidEnterBackground),
                name: UIApplication.didEnterBackgroundNotification,
                object: nil
            )

            NotificationCenter.default.addObserver(
                self,
                selector: #selector(appWillEnterForeground),
                name: UIApplication.willEnterForegroundNotification,
                object: nil
            )
            hasSetupObservers = true
        }
    }
    
    func stopTracking() {
        guard let session = currentSession else { return }

        locationManager.stopUpdatingLocation()
        locationManager.stopMonitoringSignificantLocationChanges()

        // Disable background location updates when not tracking
        #if !targetEnvironment(simulator)
        locationManager.allowsBackgroundLocationUpdates = false
        #endif

        // End session using repository
        do {
            try sessionRepository.endSession(session, endDate: Date())
            currentSession = nil
            isTracking = false
            kalmanFilter = nil // Reset Kalman filter
            // Reset validation tracking
            lastSavedLocation = nil
            lastSaveTime = nil
            // Notify Watch about tracking state change
            NotificationCenter.default.post(name: NSNotification.Name("TrackingStateChanged"), object: nil)
            // Notify app to refresh history
            NotificationCenter.default.post(name: NSNotification.Name("HistoryShouldRefresh"), object: nil)
            phoneConnectivity?.sendStatusUpdateToWatch()
        } catch {
            print("Error ending tracking session: \(error)")
            let appError = AppError.sessionEndFailed(error)
            trackingStopError = appError.failureReason // Backward compatibility
            Task { @MainActor in
                errorHandler.handle(appError)
            }
            phoneConnectivity?.sendStatusUpdateToWatch()
            return
        }

        // Re-enable idle timer
        UIApplication.shared.isIdleTimerDisabled = false

        // End background task
        endBackgroundTask()

        // Remove observers
        if hasSetupObservers {
            NotificationCenter.default.removeObserver(self, name: UIApplication.didEnterBackgroundNotification, object: nil)
            NotificationCenter.default.removeObserver(self, name: UIApplication.willEnterForegroundNotification, object: nil)
            hasSetupObservers = false
        }
    }
    
    deinit {
        // Clean up observers on deallocation
        if hasSetupObservers {
            NotificationCenter.default.removeObserver(self)
        }
    }
    
    @objc private func appDidEnterBackground() {
        if isTracking {
            print("App entered background - continuing location tracking")
            // Ensure location updates continue in background
            beginBackgroundTask()
        }
    }
    
    @objc private func appWillEnterForeground() {
        if isTracking {
            print("App entering foreground - resuming full tracking")
            // Resume normal location updates
            locationManager.startUpdatingLocation()
        }
    }

    // MARK: - Location Validation

    /// Validates a location update against configured thresholds and anomaly detection
    /// - Parameter location: The location to validate
    /// - Returns: ValidationResult indicating whether the location is valid and why
    private func validateLocation(_ location: CLLocation) -> LocationValidationResult {
        // 1. Check horizontal accuracy
        if location.horizontalAccuracy < 0 {
            return .rejected(reason: "Invalid accuracy (negative)")
        }

        if location.horizontalAccuracy > validationConfig.maxHorizontalAccuracy {
            return .rejected(reason: "Poor accuracy: \(String(format: "%.1f", location.horizontalAccuracy))m (threshold: \(validationConfig.maxHorizontalAccuracy)m)")
        }

        // 2. Check time interval since last save
        if let lastTime = lastSaveTime {
            let timeSinceLastSave = location.timestamp.timeIntervalSince(lastTime)
            if timeSinceLastSave < validationConfig.minTimeBetweenUpdates {
                return .rejected(reason: "Too frequent: \(String(format: "%.1f", timeSinceLastSave))s since last save")
            }
        }

        // 3. Anomaly detection: Check for impossible speeds and distance jumps
        if let lastLocation = lastSavedLocation {
            let distance = location.distance(from: lastLocation)
            let timeInterval = location.timestamp.timeIntervalSince(lastLocation.timestamp)

            // Avoid division by zero
            if timeInterval > 0 {
                let speed = distance / timeInterval

                // Check for impossible speed
                if speed > validationConfig.maxReasonableSpeed {
                    return .rejected(reason: "Impossible speed: \(String(format: "%.1f", speed * 3.6)) km/h (threshold: \(String(format: "%.1f", validationConfig.maxReasonableSpeed * 3.6)) km/h)")
                }

                // Check for unreasonable distance jump
                if distance > validationConfig.maxDistanceJump {
                    return .rejected(reason: "Large distance jump: \(String(format: "%.0f", distance))m (threshold: \(String(format: "%.0f", validationConfig.maxDistanceJump))m)")
                }
            }
        }

        return .accepted
    }

    /// Result of location validation
    private enum LocationValidationResult {
        case accepted
        case rejected(reason: String)

        var isValid: Bool {
            if case .accepted = self {
                return true
            }
            return false
        }

        var rejectionReason: String? {
            if case .rejected(let reason) = self {
                return reason
            }
            return nil
        }
    }

    private func saveLocation(_ location: CLLocation) {
        guard let session = currentSession else { return }

        // Validate location with comprehensive checks
        let validationResult = validateLocation(location)
        guard validationResult.isValid else {
            if let reason = validationResult.rejectionReason {
                print("⚠️ Location filtered out: \(reason)")
            }
            return
        }
        
        // Begin background task for database operation
        let taskId = UIApplication.shared.beginBackgroundTask {
            print("Background task for location save expired")
        }

        // Use repository to save location in background
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else {
                UIApplication.shared.endBackgroundTask(taskId)
                return
            }
            
            do {
                _ = try self.locationRepository.saveLocation(location, for: session)
                
                // Update location count and tracking info on main thread
                DispatchQueue.main.async {
                    self.locationCount += 1
                    // Update last saved location for anomaly detection
                    self.lastSavedLocation = location
                    self.lastSaveTime = location.timestamp
                    // Notify Watch about location count change
                    NotificationCenter.default.post(name: NSNotification.Name("LocationCountChanged"), object: nil)
                }
                print("Location saved successfully using repository")
            } catch {
                print("⚠️ Error saving location: \(error)")
                // Don't show error to user for individual location save failures
                // Log for debugging but continue tracking
            }

            // End background task after save completes
            UIApplication.shared.endBackgroundTask(taskId)
        }
    }
}

// MARK: - CLLocationManagerDelegate
extension LocationManager: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        
        DispatchQueue.main.async {
            self.currentLocation = location
        }
        
        // Only save location if we're actively tracking
        if isTracking {
            saveLocation(location)
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        DispatchQueue.main.async {
            self.authorizationStatus = status
        }

        switch status {
        case .authorizedAlways:
            print("Location permission granted for always")
            UserDefaults.standard.set(0, forKey: deniedAlwaysKey)
            showSettingsSuggestion = false
        case .authorizedWhenInUse:
            print("Location permission granted for when in use")
            // Always request 'Always' authorization if not already granted
            let maxDenials = AppConfig.shared.features.maxPermissionDenials
            if UserDefaults.standard.integer(forKey: deniedAlwaysKey) < maxDenials {
                manager.requestAlwaysAuthorization()
            } else {
                showSettingsSuggestion = true
            }
        case .denied, .restricted:
            print("Location permission denied")
            let deniedCount = UserDefaults.standard.integer(forKey: deniedAlwaysKey) + 1
            UserDefaults.standard.set(deniedCount, forKey: deniedAlwaysKey)
            let maxDenials = AppConfig.shared.features.maxPermissionDenials
            if deniedCount >= maxDenials {
                showSettingsSuggestion = true
            }
            
            // Show error to user
            Task { @MainActor in
                if status == .denied {
                    errorHandler.handle(.locationPermissionDenied)
                } else {
                    errorHandler.handle(.locationServicesDisabled)
                }
            }
            
            if isTracking {
                stopTracking()
            }
        case .notDetermined:
            print("Location permission not determined")
        @unknown default:
            break
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("⚠️ Location manager failed with error: \(error)")

        if let clError = error as? CLError {
            switch clError.code {
            case .denied:
                print("Location access denied")
                Task { @MainActor in
                    errorHandler.handle(.locationPermissionDenied)
                }
                if isTracking {
                    stopTracking()
                }
            case .locationUnknown:
                print("Location unknown, but keep trying")
                // Don't show error - this is transient and common
                // Location services will continue attempting to get a fix
            case .network:
                print("Network error affecting location accuracy")
                // Show error only if tracking is active
                // Network errors can affect GPS accuracy but aren't fatal
                if isTracking {
                    Task { @MainActor in
                        errorHandler.handle(.networkUnavailable)
                    }
                }
            case .headingFailure:
                print("Heading failure - compass may be uncalibrated")
                // Don't show error - we don't use heading/compass features
            case .rangingUnavailable, .rangingFailure:
                print("Ranging unavailable or failed")
                // Don't show error - we don't use ranging features
            case .promptDeclined:
                print("User declined location prompt")
                Task { @MainActor in
                    errorHandler.handle(.locationPermissionDenied)
                }
                if isTracking {
                    stopTracking()
                }
            default:
                print("Other location error: \(clError.localizedDescription)")
                // Show generic location update error for other cases
                if isTracking {
                    Task { @MainActor in
                        errorHandler.handle(.locationUpdateFailed(error))
                    }
                }
            }
        } else {
            // Non-CLError - show generic error
            print("Unknown location error: \(error.localizedDescription)")
            if isTracking {
                Task { @MainActor in
                    errorHandler.handle(.locationUpdateFailed(error))
                }
            }
        }
    }
}