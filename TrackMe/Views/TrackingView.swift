import SwiftUI
import CoreLocation

struct TrackingView: View {
    @StateObject private var viewModel: TrackingViewModel
    @EnvironmentObject var locationManager: LocationManager
    
    init(viewModel: TrackingViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Permission banner and status
                    TrackingPermissionsView(locationManager: locationManager)

                    // Hero status section
                    TrackingStatusIndicator(
                        isTracking: viewModel.isTracking,
                        appState: viewModel.appState
                    )

                    // Control button with narrative input
                    TrackingControlBarView(locationManager: locationManager)

                    // Statistics cards
                    TrackingStatsView(locationManager: locationManager)

                    // Current location display
                    if let location = viewModel.currentLocation {
                        CurrentLocationView(location: location)
                    }

                    Spacer(minLength: 20)

                    // Background tracking info
                    if viewModel.isTracking {
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
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        viewModel.showPrivacy()
                    } label: {
                        Image(systemName: "hand.raised.fill")
                            .foregroundColor(.blue)
                    }
                    .accessibilityLabel("Privacy Information")
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        viewModel.showSettings()
                    } label: {
                        Image(systemName: "gearshape")
                            .foregroundColor(.primary)
                    }
                }
            }
            .sheet(isPresented: $viewModel.showTrackingModeSettings) {
                TrackingModeSettingsView()
            }
            .sheet(isPresented: $viewModel.showPrivacyNotice) {
                PrivacyNoticeView()
            }
        }
        .navigationViewStyle(.stack)
    }
}

#Preview {
    let container = DependencyContainer()
    return TrackingView(viewModel: container.makeTrackingViewModel())
        .environmentObject(container.locationManager)
}
