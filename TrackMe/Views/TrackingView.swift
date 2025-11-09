import SwiftUI
import CoreLocation

struct TrackingView: View {
    @EnvironmentObject var locationManager: LocationManager
    @State private var appState = UIApplication.shared.applicationState
    @State private var showTrackingModeSettings = false

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Permission banner and status
                    TrackingPermissionsView(locationManager: locationManager)

                    // Hero status section
                    TrackingStatusIndicator(
                        isTracking: locationManager.isTracking,
                        appState: appState
                    )

                    // Control button with narrative input
                    TrackingControlBarView(locationManager: locationManager)

                    // Statistics cards
                    TrackingStatsView(locationManager: locationManager)

                    // Current location display
                    if let location = locationManager.currentLocation {
                        CurrentLocationView(location: location)
                    }

                    Spacer(minLength: 20)

                    // Background tracking info
                    if locationManager.isTracking {
                        BackgroundTrackingInfoView()
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
            .sheet(isPresented: $showTrackingModeSettings) {
                TrackingModeSettingsView()
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
