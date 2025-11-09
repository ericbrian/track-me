import Foundation
import CoreLocation
import Combine

// MARK: - Tracking ViewModel

/// ViewModel for tracking view - manages tracking session state and user interactions
class TrackingViewModel: ObservableObject {
    
    // MARK: - Dependencies
    
    private let locationManager: LocationManager
    private let sessionRepository: SessionRepositoryProtocol
    private let errorHandler: ErrorHandler
    
    // MARK: - Published State
    
    @Published var isTracking = false
    @Published var narrative = ""
    @Published var currentLocation: CLLocation?
    @Published var locationCount = 0
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published var showPermissionBanner = false
    @Published var showSettingsSuggestion = false
    
    // MARK: - Private State
    
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    init(locationManager: LocationManager,
         sessionRepository: SessionRepositoryProtocol,
         errorHandler: ErrorHandler) {
        self.locationManager = locationManager
        self.sessionRepository = sessionRepository
        self.errorHandler = errorHandler
        
        setupBindings()
    }
    
    // MARK: - Setup
    
    private func setupBindings() {
        // Observe location manager state
        locationManager.$isTracking
            .assign(to: &$isTracking)
        
        locationManager.$currentLocation
            .assign(to: &$currentLocation)
        
        locationManager.$locationCount
            .assign(to: &$locationCount)
        
        locationManager.$authorizationStatus
            .assign(to: &$authorizationStatus)
        
        locationManager.$showSettingsSuggestion
            .assign(to: &$showSettingsSuggestion)
        
        // Compute permission banner visibility
        locationManager.$authorizationStatus
            .map { status in
                status != .authorizedAlways && status != .notDetermined
            }
            .assign(to: &$showPermissionBanner)
    }
    
    // MARK: - Actions
    
    func startTracking() {
        guard !narrative.isEmpty else {
            errorHandler.handle(.invalidNarrative)
            return
        }
        
        locationManager.startTracking(with: narrative)
    }
    
    func stopTracking() {
        locationManager.stopTracking()
        narrative = "" // Clear narrative for next session
    }
    
    func requestLocationPermission() {
        locationManager.requestLocationPermission()
    }
    
    func openSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }
}

// MARK: - History ViewModel

/// ViewModel for history view - manages session list and filtering
class HistoryViewModel: ObservableObject {
    
    // MARK: - Dependencies
    
    private let sessionRepository: SessionRepositoryProtocol
    private let locationRepository: LocationRepositoryProtocol
    
    // MARK: - Published State
    
    @Published var sessions: [TrackingSession] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var searchText = ""
    @Published var selectedSession: TrackingSession?
    
    // MARK: - Computed Properties
    
    var filteredSessions: [TrackingSession] {
        if searchText.isEmpty {
            return sessions
        }
        return sessions.filter { session in
            session.narrative?.localizedCaseInsensitiveContains(searchText) ?? false
        }
    }
    
    // MARK: - Initialization
    
    init(sessionRepository: SessionRepositoryProtocol,
         locationRepository: LocationRepositoryProtocol) {
        self.sessionRepository = sessionRepository
        self.locationRepository = locationRepository
        
        loadSessions()
    }
    
    // MARK: - Actions
    
    func loadSessions() {
        isLoading = true
        errorMessage = nil
        
        do {
            sessions = try sessionRepository.fetchAllSessions()
            isLoading = false
        } catch {
            errorMessage = "Failed to load sessions: \(error.localizedDescription)"
            isLoading = false
        }
    }
    
    func deleteSession(_ session: TrackingSession) {
        do {
            try sessionRepository.deleteSession(session)
            loadSessions() // Reload after deletion
        } catch {
            errorMessage = "Failed to delete session: \(error.localizedDescription)"
        }
    }
    
    func deleteSessions(at offsets: IndexSet) {
        for index in offsets {
            let session = filteredSessions[index]
            deleteSession(session)
        }
    }
    
    func refreshSessions() {
        loadSessions()
    }
    
    func locationCount(for session: TrackingSession) -> Int {
        (try? locationRepository.locationCount(for: session)) ?? 0
    }
}

// MARK: - Trip Map ViewModel

/// ViewModel for trip map view - manages map state and location display
class TripMapViewModel: ObservableObject {
    
    // MARK: - Dependencies
    
    private let session: TrackingSession
    private let locationRepository: LocationRepositoryProtocol
    
    // MARK: - Published State
    
    @Published var locations: [LocationEntry] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var mapRegion: MapRegion?
    
    // MARK: - Computed Properties
    
    var sessionTitle: String {
        session.narrative ?? "Untitled Session"
    }
    
    var sessionDate: String {
        guard let startDate = session.startDate else { return "Unknown" }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: startDate)
    }
    
    var totalDistance: Double {
        calculateTotalDistance()
    }
    
    // MARK: - Initialization
    
    init(session: TrackingSession,
         locationRepository: LocationRepositoryProtocol) {
        self.session = session
        self.locationRepository = locationRepository
        
        loadLocations()
    }
    
    // MARK: - Actions
    
    func loadLocations() {
        isLoading = true
        errorMessage = nil
        
        do {
            locations = try locationRepository.fetchLocations(for: session)
            calculateMapRegion()
            isLoading = false
        } catch {
            errorMessage = "Failed to load locations: \(error.localizedDescription)"
            isLoading = false
        }
    }
    
    // MARK: - Private Helpers
    
    private func calculateMapRegion() {
        guard !locations.isEmpty else { return }
        
        let latitudes = locations.map { $0.latitude }
        let longitudes = locations.map { $0.longitude }
        
        let minLat = latitudes.min() ?? 0
        let maxLat = latitudes.max() ?? 0
        let minLon = longitudes.min() ?? 0
        let maxLon = longitudes.max() ?? 0
        
        let centerLat = (minLat + maxLat) / 2
        let centerLon = (minLon + maxLon) / 2
        let spanLat = (maxLat - minLat) * 1.2 // Add 20% padding
        let spanLon = (maxLon - minLon) * 1.2
        
        mapRegion = MapRegion(
            centerLatitude: centerLat,
            centerLongitude: centerLon,
            spanLatitude: spanLat,
            spanLongitude: spanLon
        )
    }
    
    private func calculateTotalDistance() -> Double {
        guard locations.count > 1 else { return 0 }
        
        var totalDistance: Double = 0
        for i in 1..<locations.count {
            let prevLocation = locations[i - 1]
            let currentLocation = locations[i]
            
            let distance = CLLocation(
                latitude: prevLocation.latitude,
                longitude: prevLocation.longitude
            ).distance(from: CLLocation(
                latitude: currentLocation.latitude,
                longitude: currentLocation.longitude
            ))
            
            totalDistance += distance
        }
        
        return totalDistance
    }
}

// MARK: - Supporting Types

struct MapRegion {
    let centerLatitude: Double
    let centerLongitude: Double
    let spanLatitude: Double
    let spanLongitude: Double
}

// MARK: - Error Extension

extension AppError {
    static var invalidNarrative: AppError {
        .custom(
            message: "Please enter a narrative for this tracking session",
            severity: .warning
        )
    }
}
