import Foundation
import SwiftUI
import CoreLocation
import Combine

/// ViewModel for TrackingView - manages tracking state, app lifecycle, and user interactions
/// Follows MVVM architecture to keep UI logic separate from view code
@MainActor
final class TrackingViewModel: ObservableObject {
    
    // MARK: - Dependencies
    
    private let locationManager: LocationManager
    private let sessionRepository: SessionRepositoryProtocol
    private let errorHandler: ErrorHandler
    
    // MARK: - Published State
    
    /// Current application state (active, background, inactive)
    @Published var appState: UIApplication.State = .active
    
    /// Whether to show tracking mode settings sheet
    @Published var showTrackingModeSettings = false
    
    /// Whether to show privacy notice sheet
    @Published var showPrivacyNotice = false
    
    // MARK: - Computed Properties
    
    /// Whether location tracking is currently active
    var isTracking: Bool {
        locationManager.isTracking
    }
    
    /// Current location authorization status
    var authorizationStatus: CLAuthorizationStatus {
        locationManager.authorizationStatus
    }
    
    /// Current location, if available
    var currentLocation: CLLocation? {
        locationManager.currentLocation
    }
    
    /// Current tracking session, if active
    var currentSession: TrackingSession? {
        locationManager.currentSession
    }
    
    /// Number of locations recorded in current session
    var locationCount: Int {
        locationManager.locationCount
    }
    
    /// Whether to show settings suggestion banner
    var showSettingsSuggestion: Bool {
        locationManager.showSettingsSuggestion
    }
    
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
        setupAppLifecycleObservers()
    }
    
    // MARK: - Setup
    
    private func setupBindings() {
        // Observe changes to location manager's published properties
        // This ensures the view updates when location manager state changes
        locationManager.objectWillChange
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)
    }
    
    private func setupAppLifecycleObservers() {
        // Observe app entering background
        NotificationCenter.default.publisher(for: UIApplication.didEnterBackgroundNotification)
            .sink { [weak self] _ in
                self?.appState = .background
            }
            .store(in: &cancellables)
        
        // Observe app entering foreground
        NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)
            .sink { [weak self] _ in
                self?.appState = .active
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Actions
    
    /// Show the tracking mode settings sheet
    func showSettings() {
        showTrackingModeSettings = true
    }
    
    /// Show the privacy notice sheet
    func showPrivacy() {
        showPrivacyNotice = true
    }
    
    /// Dismiss the settings sheet
    func dismissSettings() {
        showTrackingModeSettings = false
    }
    
    /// Dismiss the privacy notice sheet
    func dismissPrivacy() {
        showPrivacyNotice = false
    }
    
    /// Request location permission from the user
    func requestLocationPermission() {
        locationManager.requestLocationPermission()
    }
    
    // MARK: - Cleanup
    
    deinit {
        cancellables.removeAll()
    }
}
