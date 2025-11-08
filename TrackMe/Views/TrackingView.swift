import SwiftUI
import CoreLocation

struct TrackingView: View {
    @EnvironmentObject var locationManager: LocationManager
    @State private var narrative = ""
    @State private var showingNarrativeInput = false
    @State private var appState = UIApplication.shared.applicationState
    @State private var showTrackingErrorAlert = false
    @State private var showSettingsAlert = false
    @State private var showTrackingStopErrorAlert = false
    @State private var showTrackingModeSettings = false

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Permission banner
                    PermissionBanner(authorizationStatus: locationManager.authorizationStatus)

                    // Hero status section
                    TrackingStatusIndicator(
                        isTracking: locationManager.isTracking,
                        appState: appState
                    )

                    // Control button
                    TrackingControlButton(
                        isTracking: locationManager.isTracking,
                        authorizationStatus: locationManager.authorizationStatus,
                        onStart: { showingNarrativeInput = true },
                        onStop: { locationManager.stopTracking() }
                    )

                    // Statistics cards
                    if locationManager.isTracking {
                        SessionStatisticsView(
                            locationCount: locationManager.locationCount,
                            currentSession: locationManager.currentSession
                        )
                    }

                    // Current location display
                    if let location = locationManager.currentLocation {
                        CurrentLocationView(location: location)
                    }

                    Spacer(minLength: 20)

                    // Permission status and background tracking info
                    VStack(spacing: 20) {
                        if !locationManager.isTracking {
                            PermissionStatusView(
                                authorizationStatus: locationManager.authorizationStatus,
                                onRequestPermission: { locationManager.requestLocationPermission() }
                            )
                        }

                        if locationManager.isTracking {
                            BackgroundTrackingInfoView()
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 30)
            }
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [Color(.systemBackground), Color(.systemGray6).opacity(0.3)]),
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .navigationTitle("GPS Tracker")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showTrackingModeSettings = true
                    } label: {
                        Image(systemName: "gearshape")
                            .foregroundColor(.primary)
                    }
                }
            }
            .sheet(isPresented: $showingNarrativeInput) {
                NarrativeInputView(narrative: $narrative) {
                    locationManager.startTracking(with: narrative)
                    // Only close the sheet if tracking actually started
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        if locationManager.trackingStartError == nil {
                            showingNarrativeInput = false
                            narrative = ""
                        } else {
                            showTrackingErrorAlert = true
                        }
                    }
                }
            }
            .sheet(isPresented: $showTrackingModeSettings) {
                TrackingModeSettingsView()
            }
            .alert(isPresented: $showTrackingErrorAlert) {
                Alert(
                    title: Text("Unable to Start Tracking"),
                    message: Text(locationManager.trackingStartError ?? "Unknown error"),
                    dismissButton: .default(Text("OK")) {
                        locationManager.trackingStartError = nil
                    }
                )
            }
            .onReceive(locationManager.$showSettingsSuggestion) { show in
                if show {
                    showSettingsAlert = true
                }
            }
            .onReceive(locationManager.$trackingStopError) { err in
                if err != nil {
                    showTrackingStopErrorAlert = true
                }
            }
            .alert(isPresented: $showSettingsAlert) {
                Alert(
                    title: Text("Enable 'Always' Location in Settings"),
                    message: Text("You've denied 'Always' location permission multiple times. Please enable it manually in Settings > Privacy > Location Services > TrackMe."),
                    primaryButton: .default(Text("Open Settings")) {
                        if let url = URL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.open(url)
                        }
                        locationManager.showSettingsSuggestion = false
                    },
                    secondaryButton: .cancel {
                        locationManager.showSettingsSuggestion = false
                    }
                )
            }
            .alert(isPresented: $showTrackingStopErrorAlert) {
                Alert(
                    title: Text("Unable to Stop Tracking"),
                    message: Text(locationManager.trackingStopError ?? "Unknown error"),
                    dismissButton: .default(Text("OK")) {
                        locationManager.trackingStopError = nil
                    }
                )
            }
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.didEnterBackgroundNotification)) { _ in
                appState = .background
            }
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
                appState = .active
            }
        }
        .navigationViewStyle(.stack)
    }
}

#Preview {
    TrackingView()
        .environmentObject(LocationManager())
}
