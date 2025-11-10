import Foundation
import CoreLocation
import Combine

/// ViewModel for tracking control bar - manages start/stop tracking and narrative input
@MainActor
final class TrackingControlBarViewModel: ObservableObject {
    
    // MARK: - Dependencies
    
    private let locationManager: LocationManager
    private let errorHandler: ErrorHandler
    
    // MARK: - Published State
    
    @Published var narrative = ""
    @Published var showingNarrativeInput = false
    
    // Deprecated: Use ErrorHandler instead
    @Published var showTrackingErrorAlert = false
    @Published var showTrackingStopErrorAlert = false
    @Published var trackingStartError: String?
    @Published var trackingStopError: String?
    
    // MARK: - Computed Properties
    
    var isTracking: Bool {
        locationManager.isTracking
    }
    
    var authorizationStatus: CLAuthorizationStatus {
        locationManager.authorizationStatus
    }
    
    var canStartTracking: Bool {
        !isTracking && (authorizationStatus == .authorizedAlways || authorizationStatus == .authorizedWhenInUse)
    }
    
    // MARK: - Private State
    
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    init(locationManager: LocationManager, errorHandler: ErrorHandler = .shared) {
        self.locationManager = locationManager
        self.errorHandler = errorHandler
        setupBindings()
    }
    
    // MARK: - Setup
    
    private func setupBindings() {
        // Observe changes to location manager's published properties
        locationManager.objectWillChange
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)
        
        // Observe tracking start errors (backward compatibility)
        locationManager.$trackingStartError
            .sink { [weak self] error in
                if let error = error {
                    self?.trackingStartError = error
                    self?.showTrackingErrorAlert = true
                }
            }
            .store(in: &cancellables)
        
        // Observe tracking stop errors (backward compatibility)
        locationManager.$trackingStopError
            .sink { [weak self] error in
                if let error = error {
                    self?.trackingStopError = error
                    self?.showTrackingStopErrorAlert = true
                }
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Actions
    
    func requestStartTracking() {
        showingNarrativeInput = true
    }
    
    func startTracking() {
        guard !narrative.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            errorHandler.handle(.sessionCreationFailed(
                NSError(domain: "TrackMe", code: 1001, 
                       userInfo: [NSLocalizedDescriptionKey: "Please enter a narrative for this tracking session"])
            ))
            return
        }
        
        locationManager.startTracking(with: narrative)
        
        // Check if tracking started successfully after a brief delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            guard let self = self else { return }
            if self.locationManager.trackingStartError == nil {
                self.showingNarrativeInput = false
                self.narrative = ""
            }
        }
    }
    
    func stopTracking() {
        locationManager.stopTracking()
    }
    
    func dismissNarrativeInput() {
        showingNarrativeInput = false
        narrative = ""
    }
    
    func clearStartError() {
        trackingStartError = nil
        locationManager.trackingStartError = nil
    }
    
    func clearStopError() {
        trackingStopError = nil
        locationManager.trackingStopError = nil
    }
}
