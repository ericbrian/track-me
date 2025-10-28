import Foundation
import CoreLocation
import CoreData
import UIKit
import BackgroundTasks

class LocationManager: NSObject, ObservableObject {
    private let locationManager = CLLocationManager()
    private var persistenceController = PersistenceController.shared
    private var backgroundTask: UIBackgroundTaskIdentifier = .invalid
    
    @Published var isTracking = false
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published var currentLocation: CLLocation?
    @Published var currentSession: TrackingSession?
    @Published var locationCount = 0
    
    override init() {
        super.init()
        setupLocationManager()
        setupBackgroundTasks()
        authorizationStatus = locationManager.authorizationStatus
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
    
    private func setupBackgroundTasks() {
        // Register background tasks
        BGTaskScheduler.shared.register(forTaskWithIdentifier: "com.ericbrian.TrackMe.background-location", using: nil) { task in
            self.handleBackgroundLocationTask(task: task as! BGAppRefreshTask)
        }
        
        BGTaskScheduler.shared.register(forTaskWithIdentifier: "com.ericbrian.TrackMe.data-sync", using: nil) { task in
            self.handleDataSyncTask(task: task as! BGProcessingTask)
        }
    }
    
    private func handleBackgroundLocationTask(task: BGAppRefreshTask) {
        // Schedule next background task
        scheduleBackgroundLocationTask()
        
        task.expirationHandler = {
            task.setTaskCompleted(success: false)
        }
        
        // Perform background location work
        if isTracking && authorizationStatus == .authorizedAlways {
            locationManager.requestLocation()
        }
        
        task.setTaskCompleted(success: true)
    }
    
    private func handleDataSyncTask(task: BGProcessingTask) {
        task.expirationHandler = {
            task.setTaskCompleted(success: false)
        }
        
        // Perform any data maintenance or sync
        task.setTaskCompleted(success: true)
    }
    
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
            return
        }
        
        // Begin background task to ensure we don't get terminated
        beginBackgroundTask()
        
        // Create new tracking session
        let context = persistenceController.container.viewContext
        let session = TrackingSession(context: context)
        session.id = UUID()
        session.narrative = narrative
        session.startDate = Date()
        session.isActive = true
        
        currentSession = session
        isTracking = true
        locationCount = 0
        
        // Notify Watch about tracking state change
        NotificationCenter.default.post(name: NSNotification.Name("TrackingStateChanged"), object: nil)
        
        // Save the session
        do {
            try context.save()
        } catch {
            print("Error creating tracking session: \(error)")
            return
        }
        
        // Enable background location updates only when tracking and on real device
        // Simulator has limitations with background location
        #if !targetEnvironment(simulator)
        if authorizationStatus == .authorizedAlways {
            locationManager.allowsBackgroundLocationUpdates = true
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
        
        // Add app lifecycle observers
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
        } catch {
            print("Error ending tracking session: \(error)")
        }
        
        currentSession = nil
        isTracking = false
        
        // Notify Watch about tracking state change
        NotificationCenter.default.post(name: NSNotification.Name("TrackingStateChanged"), object: nil)
        
        // Re-enable idle timer
        UIApplication.shared.isIdleTimerDisabled = false
        
        // End background task
        endBackgroundTask()
        
        // Remove observers
        NotificationCenter.default.removeObserver(self, name: UIApplication.didEnterBackgroundNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIApplication.willEnterForegroundNotification, object: nil)
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
        
        // Begin background task for database operation
        let taskId = UIApplication.shared.beginBackgroundTask {
            print("Background task for location save expired")
        }
        
        let context = persistenceController.container.viewContext
        let locationEntry = LocationEntry(context: context)
        
        locationEntry.id = UUID()
        locationEntry.latitude = location.coordinate.latitude
        locationEntry.longitude = location.coordinate.longitude
        locationEntry.timestamp = location.timestamp
        locationEntry.accuracy = location.horizontalAccuracy
        locationEntry.altitude = location.altitude
        locationEntry.speed = location.speed
        locationEntry.course = location.course
        locationEntry.session = session
        
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
        case .authorizedWhenInUse:
            print("Location permission granted for when in use")
            // Request always authorization for background tracking
            locationManager.requestAlwaysAuthorization()
        case .denied, .restricted:
            print("Location permission denied")
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