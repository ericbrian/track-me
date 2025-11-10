import SwiftUI
import CoreLocation
import Combine

// MARK: - Tracking Control Bar View

/// Sub-view for tracking controls (start/stop button and narrative input)
struct TrackingControlBarView: View {
    @StateObject private var viewModel: TrackingControlBarViewModel
    
    init(locationManager: LocationManager) {
        _viewModel = StateObject(wrappedValue: TrackingControlBarViewModel(locationManager: locationManager))
    }
    
    var body: some View {
        VStack(spacing: 16) {
            TrackingControlButton(
                isTracking: viewModel.isTracking,
                authorizationStatus: viewModel.authorizationStatus,
                onStart: viewModel.requestStartTracking,
                onStop: viewModel.stopTracking
            )
        }
        .sheet(isPresented: $viewModel.showingNarrativeInput) {
            NarrativeInputView(narrative: $viewModel.narrative) {
                viewModel.startTracking()
            }
        }
    }
}

// MARK: - Tracking Statistics View Model

@MainActor
final class TrackingStatsViewModel: ObservableObject {
    private let locationManager: LocationManager
    
    var locationCount: Int {
        locationManager.locationCount
    }
    
    var currentSession: TrackingSession? {
        locationManager.currentSession
    }
    
    var isTracking: Bool {
        locationManager.isTracking
    }
    
    init(locationManager: LocationManager) {
        self.locationManager = locationManager
    }
}

// MARK: - Tracking Statistics Sub-View

/// Sub-view for displaying tracking statistics during an active session
struct TrackingStatsView: View {
    @StateObject private var viewModel: TrackingStatsViewModel
    @EnvironmentObject var locationManager: LocationManager
    
    init(locationManager: LocationManager) {
        _viewModel = StateObject(wrappedValue: TrackingStatsViewModel(locationManager: locationManager))
    }
    
    var body: some View {
        Group {
            if viewModel.isTracking {
                SessionStatisticsView(
                    locationCount: viewModel.locationCount,
                    currentSession: viewModel.currentSession
                )
            }
        }
    }
}

// MARK: - Tracking Permissions View Model

@MainActor
final class TrackingPermissionsViewModel: ObservableObject {
    private let locationManager: LocationManager
    
    @Published var showSettingsAlert = false
    
    var authorizationStatus: CLAuthorizationStatus {
        locationManager.authorizationStatus
    }
    
    var isTracking: Bool {
        locationManager.isTracking
    }
    
    var showPermissionBanner: Bool {
        authorizationStatus != .authorizedAlways && authorizationStatus != .notDetermined
    }
    
    var showPermissionStatus: Bool {
        !isTracking
    }
    
    init(locationManager: LocationManager) {
        self.locationManager = locationManager
        setupBindings()
    }
    
    private func setupBindings() {
        locationManager.$showSettingsSuggestion
            .sink { [weak self] show in
                if show {
                    self?.showSettingsAlert = true
                }
            }
            .store(in: &cancellables)
    }
    
    func requestLocationPermission() {
        locationManager.requestLocationPermission()
    }
    
    func openSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
        locationManager.showSettingsSuggestion = false
    }
    
    func dismissSettingsAlert() {
        locationManager.showSettingsSuggestion = false
    }
    
    private var cancellables = Set<AnyCancellable>()
}

// MARK: - Tracking Permissions Sub-View

/// Sub-view for displaying permission banners and status
struct TrackingPermissionsView: View {
    @StateObject private var viewModel: TrackingPermissionsViewModel
    
    init(locationManager: LocationManager) {
        _viewModel = StateObject(wrappedValue: TrackingPermissionsViewModel(locationManager: locationManager))
    }
    
    var body: some View {
        VStack(spacing: 20) {
            // Permission banner at top
            if viewModel.showPermissionBanner {
                PermissionBanner(authorizationStatus: viewModel.authorizationStatus)
            }
            
            // Permission status when not tracking
            if viewModel.showPermissionStatus {
                PermissionStatusView(
                    authorizationStatus: viewModel.authorizationStatus,
                    onRequestPermission: viewModel.requestLocationPermission
                )
            }
        }
        .alert(isPresented: $viewModel.showSettingsAlert) {
            Alert(
                title: Text("Enable 'Always' Location in Settings"),
                message: Text("You've denied 'Always' location permission multiple times. Please enable it manually in Settings > Privacy > Location Services > TrackMe."),
                primaryButton: .default(Text("Open Settings")) {
                    viewModel.openSettings()
                },
                secondaryButton: .cancel {
                    viewModel.dismissSettingsAlert()
                }
            )
        }
    }
}

// MARK: - Previews

#Preview("Control Bar") {
    TrackingControlBarView(locationManager: LocationManager())
}

#Preview("Statistics") {
    TrackingStatsView(locationManager: LocationManager())
        .environmentObject(LocationManager())
}

#Preview("Permissions") {
    TrackingPermissionsView(locationManager: LocationManager())
}
