import Foundation
import CoreLocation
import CoreData
import UIKit
import BackgroundTasks

class LocationManager: NSObject, ObservableObject {
    private let deniedAlwaysKey = "TrackMeDeniedAlwaysCount"
    @Published var showSettingsSuggestion = false
    private var phoneConnectivity: PhoneConnectivityManager? {
        PhoneConnectivityManager.shared
    }
    private let locationManager = CLLocationManager()
    private var persistenceController = PersistenceController.shared
    private var backgroundTask: UIBackgroundTaskIdentifier = .invalid
    private var hasSetupObservers = false
    
    @Published var isTracking = false
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published var currentLocation: CLLocation?
    @Published var currentSession: TrackingSession?
    @Published var locationCount = 0
    @Published var trackingStartError: String?
    @Published var trackingStopError: String?
    
    override init() {
        super.init()
        // Defer heavy setup to asyncSetup()
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
            if UserDefaults.standard.integer(forKey: deniedAlwaysKey) < 2 {
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
        let context = persistenceController.container.newBackgroundContext()
        let fetchRequest: NSFetchRequest<TrackingSession> = TrackingSession.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "isActive == YES")
        do {
            let orphaned = try context.fetch(fetchRequest)
            if !orphaned.isEmpty {
                for session in orphaned {
                    session.isActive = false
                    session.endDate = Date()
                }
                try context.save()
                print("Recovered orphaned active sessions on launch.")
                DispatchQueue.main.async {
                    self.phoneConnectivity?.sendStatusUpdateToWatch()
                }
            }
        } catch {
            print("Failed to recover orphaned sessions: \(error)")
            DispatchQueue.main.async {
                self.phoneConnectivity?.sendStatusUpdateToWatch()
            }
        }
    }
    
    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = 5 // Update every 5 meters
        locationManager.pausesLocationUpdatesAutomatically = false
        locationManager.activityType = .otherNavigation // travel app
        locationManager.showsBackgroundLocationIndicator = true
        
        // Note: allowsBackgroundLocationUpdates should only be set when tracking starts
        // and after authorization is granted
    }
    
    // Background task registration is centralized in TrackMeApp.registerBackgroundTasks().
    // This class only schedules requests when appropriate.
    
    private func scheduleBackgroundLocationTask() {
        let request = BGAppRefreshTaskRequest(identifier: "com.ericbrian.TrackMe.background-location")
        request.earliestBeginDate = Date(timeIntervalSinceNow: 15 * 60) // 15 minutes
        
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
            trackingStartError = "Location permission is not set to 'Always'. Please enable it in Settings."
            phoneConnectivity?.sendStatusUpdateToWatch()
            return
        }

        // Prevent multiple active sessions
        let context = persistenceController.container.viewContext
        let fetchRequest: NSFetchRequest<TrackingSession> = TrackingSession.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "isActive == YES")
        fetchRequest.fetchLimit = 1
        if let activeSessions = try? context.fetch(fetchRequest), activeSessions.first != nil {
            print("An active tracking session already exists. Only one tracker allowed at a time.")
            trackingStartError = "A tracker is already running. Please stop it before starting a new one."
            phoneConnectivity?.sendStatusUpdateToWatch()
            return
        }

        // Begin background task to ensure we don't get terminated
        beginBackgroundTask()

        // Create new tracking session
        let session = TrackingSession(context: context)
        session.id = UUID()
        session.narrative = narrative
        session.startDate = Date()
        session.isActive = true

        // Save the session
        do {
            try context.save()
            currentSession = session
            isTracking = true
            locationCount = 0
            // Notify Watch about tracking state change
            NotificationCenter.default.post(name: NSNotification.Name("TrackingStateChanged"), object: nil)
            phoneConnectivity?.sendStatusUpdateToWatch()
        } catch {
            print("Error creating tracking session: \(error)")
            trackingStartError = "Failed to save tracking session. Please try again."
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

        let context = persistenceController.container.viewContext
        session.endDate = Date()
        session.isActive = false

        do {
            try context.save()
            currentSession = nil
            isTracking = false
            // Notify Watch about tracking state change
            NotificationCenter.default.post(name: NSNotification.Name("TrackingStateChanged"), object: nil)
            // Notify app to refresh history
            NotificationCenter.default.post(name: NSNotification.Name("HistoryShouldRefresh"), object: nil)
            phoneConnectivity?.sendStatusUpdateToWatch()
        } catch {
            print("Error ending tracking session: \(error)")
            trackingStopError = "Failed to end tracking session. Please try again."
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
    
    private func saveLocation(_ location: CLLocation) {
        guard let session = currentSession else { return }
        
        // Filter out inaccurate locations
        guard location.horizontalAccuracy > 0 && location.horizontalAccuracy < 100 else {
            print("Location filtered out due to poor accuracy: \(location.horizontalAccuracy)m")
            return
        }
        
        // Begin background task for database operation
        let taskId = UIApplication.shared.beginBackgroundTask {
            print("Background task for location save expired")
        }
        
        // Use background context for thread safety
        let context = persistenceController.container.newBackgroundContext()
        context.performAndWait {
            // Fetch the session in this context
            let sessionID = session.objectID
            guard let sessionInContext = try? context.existingObject(with: sessionID) as? TrackingSession else {
                UIApplication.shared.endBackgroundTask(taskId)
                return
            }
            
            let locationEntry = LocationEntry(context: context)
        
            locationEntry.id = UUID()
            locationEntry.latitude = location.coordinate.latitude
            locationEntry.longitude = location.coordinate.longitude
            locationEntry.timestamp = location.timestamp
            locationEntry.accuracy = location.horizontalAccuracy
            locationEntry.altitude = location.altitude
            locationEntry.speed = location.speed >= 0 ? location.speed : 0
            locationEntry.course = location.course >= 0 ? location.course : 0
            locationEntry.session = sessionInContext
            
            do {
                try context.save()
                DispatchQueue.main.async {
                    self.locationCount += 1
                    // Notify Watch about location count change
                    NotificationCenter.default.post(name: NSNotification.Name("LocationCountChanged"), object: nil)
                }
                print("Location saved successfully in background")
            } catch {
                print("Error saving location: \(error)")
            }
        }
        
        UIApplication.shared.endBackgroundTask(taskId)
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
            if UserDefaults.standard.integer(forKey: deniedAlwaysKey) < 2 {
                manager.requestAlwaysAuthorization()
            } else {
                showSettingsSuggestion = true
            }
        case .denied, .restricted:
            print("Location permission denied")
            let deniedCount = UserDefaults.standard.integer(forKey: deniedAlwaysKey) + 1
            UserDefaults.standard.set(deniedCount, forKey: deniedAlwaysKey)
            if deniedCount >= 2 {
                showSettingsSuggestion = true
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
        print("Location manager failed with error: \(error)")
        
        if let clError = error as? CLError {
            switch clError.code {
            case .denied:
                print("Location access denied")
                if isTracking {
                    stopTracking()
                }
            case .locationUnknown:
                print("Location unknown, but keep trying")
            case .network:
                print("Network error")
            default:
                print("Other location error: \(clError.localizedDescription)")
            }
        }
    }
}