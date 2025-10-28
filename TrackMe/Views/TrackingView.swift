import SwiftUI
import CoreLocation

struct TrackingView: View {
    @EnvironmentObject var locationManager: LocationManager
    @State private var narrative = ""
    @State private var showingNarrativeInput = false
    @State private var appState = UIApplication.shared.applicationState
    
    // Computed properties to simplify type-checking
    private var statusGradientColors: [Color] {
        locationManager.isTracking ? 
            [Color.green.opacity(0.3), Color.green.opacity(0.1)] : 
            [Color.gray.opacity(0.3), Color.gray.opacity(0.1)]
    }
    
    private var statusColor: Color {
        locationManager.isTracking ? .green : .gray
    }
    
    private var statusIconName: String {
        locationManager.isTracking ? "location.fill" : "location"
    }
    
    private var statusText: String {
        locationManager.isTracking ? "ACTIVE" : "STOPPED"
    }
    
    private var trackingStatusText: String {
        locationManager.isTracking ? "GPS Tracking Active" : "GPS Tracking Stopped"
    }
    
    private var backgroundIconName: String {
        appState == .background ? "moon.fill" : "sun.max.fill"
    }
    
    private var backgroundStatusColor: Color {
        appState == .background ? .indigo : .orange
    }
    
    private var backgroundStatusText: String {
        appState == .background ? "Running in Background" : "Active in Foreground"
    }
    
    private var backgroundStrokeColor: Color {
        appState == .background ? Color.indigo.opacity(0.3) : Color.orange.opacity(0.3)
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Hero Status Section
                    VStack(spacing: 20) {
                        // Main status indicator
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        gradient: Gradient(colors: statusGradientColors),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 140, height: 140)
                                .overlay(
                                    Circle()
                                        .stroke(statusColor, lineWidth: 3)
                                )
                            
                            VStack(spacing: 8) {
                                Image(systemName: statusIconName)
                                    .font(.system(size: 40, weight: .medium))
                                    .foregroundColor(statusColor)
                                
                                Text(statusText)
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .foregroundColor(statusColor)
                            }
                        }
                        .scaleEffect(locationManager.isTracking ? 1.0 : 0.9)
                        .animation(.easeInOut(duration: 0.3), value: locationManager.isTracking)
                        
                        // Status text
                        VStack(spacing: 8) {
                            Text(trackingStatusText)
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundStyle(
                                    LinearGradient(
                                        gradient: Gradient(colors: [.primary, .secondary]),
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                            
                            // Background status indicator
                            if locationManager.isTracking {
                                HStack(spacing: 8) {
                                    Image(systemName: backgroundIconName)
                                        .font(.caption)
                                        .foregroundColor(backgroundStatusColor)
                                    
                                    Text(backgroundStatusText)
                                        .font(.caption)
                                        .fontWeight(.medium)
                                        .foregroundColor(backgroundStatusColor)
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(
                                    Capsule()
                                        .fill(Color(.systemGray6))
                                        .overlay(
                                            Capsule()
                                                .stroke(backgroundStrokeColor, lineWidth: 1)
                                        )
                                )
                            }
                        }
                    }
                    .padding(.top, 20)
                    // Statistics Cards
                    if locationManager.isTracking {
                        VStack(spacing: 16) {
                            HStack(spacing: 16) {
                                StatCard(
                                    icon: "number.circle.fill",
                                    title: "Locations",
                                    value: "\(locationManager.locationCount)",
                                    color: .blue
                                )
                                
                                if let session = locationManager.currentSession,
                                   let startDate = session.startDate {
                                    StatCard(
                                        icon: "clock.fill",
                                        title: "Started",
                                        value: startDate.formatted(date: .omitted, time: .shortened),
                                        color: .purple
                                    )
                                }
                            }
                            
                            if let session = locationManager.currentSession,
                               let narrative = session.narrative {
                                VStack(alignment: .leading, spacing: 8) {
                                    HStack {
                                        Image(systemName: "quote.bubble.fill")
                                            .foregroundColor(.mint)
                                        Text("Current Session")
                                            .font(.headline)
                                            .fontWeight(.semibold)
                                        Spacer()
                                    }
                                    
                                    Text(narrative)
                                        .font(.body)
                                        .foregroundColor(.secondary)
                                        .multilineTextAlignment(.leading)
                                }
                                .padding(20)
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(Color(.systemGray6))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 16)
                                                .stroke(Color.mint.opacity(0.3), lineWidth: 1)
                                        )
                                )
                            }
                        }
                    }
                
                // Current Location Display
                if let location = locationManager.currentLocation {
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Image(systemName: "location.north.circle.fill")
                                .foregroundColor(.blue)
                                .font(.title2)
                            Text("Current Location")
                                .font(.headline)
                                .fontWeight(.semibold)
                            Spacer()
                        }
                        
                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: 12) {
                            LocationDataCard(
                                title: "Latitude",
                                value: String(format: "%.6f", location.coordinate.latitude),
                                icon: "globe.americas"
                            )
                            
                            LocationDataCard(
                                title: "Longitude", 
                                value: String(format: "%.6f", location.coordinate.longitude),
                                icon: "globe.asia.australia"
                            )
                            
                            LocationDataCard(
                                title: "Accuracy",
                                value: "±\(Int(location.horizontalAccuracy))m",
                                icon: "target"
                            )
                            
                            LocationDataCard(
                                title: "Updated",
                                value: location.timestamp.formatted(date: .omitted, time: .shortened),
                                icon: "clock"
                            )
                        }
                    }
                    .padding(20)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [Color(.systemGray6), Color(.systemGray5)]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(Color.blue.opacity(0.2), lineWidth: 1)
                            )
                    )
                }
                
                    Spacer(minLength: 20)
                    
                    // Control Buttons
                    VStack(spacing: 20) {
                        if !locationManager.isTracking {
                            if locationManager.authorizationStatus == .authorizedAlways {
                                Button(action: {
                                    showingNarrativeInput = true
                                }) {
                                    HStack(spacing: 12) {
                                        Image(systemName: "play.circle.fill")
                                            .font(.title2)
                                        Text("Start Tracking")
                                            .font(.title3)
                                            .fontWeight(.semibold)
                                    }
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 56)
                                    .background(
                                        LinearGradient(
                                            gradient: Gradient(colors: [Color.green, Color.green.opacity(0.8)]),
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .clipShape(RoundedRectangle(cornerRadius: 28))
                                    .shadow(color: Color.green.opacity(0.3), radius: 8, x: 0, y: 4)
                                }
                            }
                        } else {
                            Button(action: {
                                locationManager.stopTracking()
                            }) {
                                HStack(spacing: 12) {
                                    Image(systemName: "stop.circle.fill")
                                        .font(.title2)
                                    Text("Stop Tracking")
                                        .font(.title3)
                                        .fontWeight(.semibold)
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 56)
                                .background(
                                    LinearGradient(
                                        gradient: Gradient(colors: [Color.red, Color.red.opacity(0.8)]),
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 28))
                                .shadow(color: Color.red.opacity(0.3), radius: 8, x: 0, y: 4)
                            }
                        }

                        // Permission status
                        permissionStatusView

                        // Background tracking info
                        if locationManager.isTracking {
                            backgroundTrackingInfoView
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
            .sheet(isPresented: $showingNarrativeInput) {
                NarrativeInputView(narrative: $narrative) {
                    locationManager.startTracking(with: narrative)
                    narrative = ""
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.didEnterBackgroundNotification)) { _ in
                appState = .background
            }
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
                appState = .active
            }
        }
    }
    
    
    @ViewBuilder
    private var backgroundTrackingInfoView: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "shield.checkered")
                    .foregroundColor(.mint)
                Text("Background Tracking Active")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.mint)
            }
            
            Text("This app continues tracking your location when:")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            VStack(alignment: .leading, spacing: 6) {
                FeatureBullet(text: "App is minimized or closed")
                FeatureBullet(text: "Device screen is locked") 
                FeatureBullet(text: "You switch to other apps")
            }
            .padding(.leading, 8)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.mint.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.mint.opacity(0.3), lineWidth: 1)
                )
        )
    }
    
    @ViewBuilder
    private var permissionStatusView: some View {
        switch locationManager.authorizationStatus {
        case .notDetermined:
            VStack(spacing: 12) {
                Button("Request Location Permission") {
                    locationManager.requestLocationPermission()
                }
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.blue)
                .padding(.vertical, 12)
                .padding(.horizontal, 24)
                .background(Color.blue.opacity(0.1))
                .clipShape(Capsule())
                Text("To enable background tracking, select 'Allow While Using the App' first, then accept the next prompt for 'Always Allow'.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }

        case .denied, .restricted:
            VStack(spacing: 12) {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                    Text("Location Permission Required")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.orange)
                }
                Button("Open Settings") {
                    if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(settingsUrl)
                    }
                }
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.white)
                .padding(.vertical, 10)
                .padding(.horizontal, 20)
                .background(Color.orange)
                .clipShape(Capsule())
                Text("To enable background tracking, select 'Allow While Using the App' first, then accept the next prompt for 'Always Allow', or enable 'Always' in Settings.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(16)
            .background(Color.orange.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 12))

        case .authorizedWhenInUse:
            VStack(spacing: 12) {
                HStack {
                    Image(systemName: "info.circle.fill")
                        .foregroundColor(.yellow)
                    Text("Background Access Needed")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.yellow)
                }
                Text("Please allow 'Always' location access for background tracking. After selecting 'Allow While Using the App', accept the next prompt for 'Always Allow', or enable 'Always' in Settings.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(16)
            .background(Color.yellow.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 12))

        case .authorizedAlways:
            HStack {
                Image(systemName: "checkmark.shield.fill")
                    .foregroundColor(.green)
                Text("Location permission granted")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.green)
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 20)
            .background(Color.green.opacity(0.1))
            .clipShape(Capsule())

        @unknown default:
            EmptyView()
        }
    }
}

struct NarrativeInputView: View {
    @Binding var narrative: String
    @Environment(\.presentationMode) var presentationMode
    let onStart: () -> Void
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 16) {
                        Image(systemName: "quote.bubble.fill")
                            .font(.system(size: 60))
                            .foregroundStyle(
                                LinearGradient(
                                    gradient: Gradient(colors: [.blue, .purple]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                        
                        VStack(spacing: 8) {
                            Text("Describe Your Journey")
                                .font(.title2)
                                .fontWeight(.bold)
                            
                            Text("Add a description to help you remember this tracking session")
                                .font(.body)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                    }
                    .padding(.top, 20)
                    
                    // Text input
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Description")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        ZStack(alignment: .topLeading) {
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color(.systemGray6))
                                .frame(height: 120)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(narrative.isEmpty ? Color.clear : Color.blue.opacity(0.5), lineWidth: 2)
                                )
                            
                            if narrative.isEmpty {
                                Text("Enter a description for this tracking session...")
                                    .foregroundColor(.secondary)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 12)
                            }
                            
                            TextEditor(text: $narrative)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(Color.clear)
                        }
                    }
                    
                    // Example suggestions
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Suggestions")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: 12) {
                            SuggestionCard(text: "Morning jog around the neighborhood", icon: "figure.run") {
                                narrative = "Morning jog around the neighborhood"
                            }
                            
                            SuggestionCard(text: "Drive to work", icon: "car.fill") {
                                narrative = "Drive to work"
                            }
                            
                            SuggestionCard(text: "Weekend hiking trip", icon: "mountain.2.fill") {
                                narrative = "Weekend hiking trip"
                            }
                            
                            SuggestionCard(text: "Bicycle ride to the park", icon: "bicycle") {
                                narrative = "Bicycle ride to the park"
                            }
                        }
                    }
                    
                    Spacer(minLength: 20)
                    
                    // Start button
                    Button(action: {
                        onStart()
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        HStack(spacing: 12) {
                            Image(systemName: "location.fill")
                                .font(.title3)
                            Text("Start Tracking")
                                .font(.title3)
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: narrative.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 
                                    [Color.gray, Color.gray.opacity(0.8)] : 
                                    [Color.green, Color.green.opacity(0.8)]
                                ),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 28))
                        .shadow(
                            color: (narrative.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? Color.gray : Color.green).opacity(0.3), 
                            radius: 8, x: 0, y: 4
                        )
                    }
                    .disabled(narrative.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .scaleEffect(narrative.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.95 : 1.0)
                    .animation(.easeInOut(duration: 0.2), value: narrative.isEmpty)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 30)
            }
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [Color(.systemBackground), Color(.systemGray6).opacity(0.3)]),
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .navigationTitle("New Session")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button(action: {
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Text("Cancel")
                        .foregroundColor(.blue)
                }
            )
        }
    }
}

struct SuggestionCard: View {
    let text: String
    let icon: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(.blue)
                
                Text(text)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 80)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemGray6))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.blue.opacity(0.2), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    TrackingView()
        .environmentObject(LocationManager())
}

// MARK: - Custom Components

struct StatCard: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text(value)
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(color.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

struct LocationDataCard: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.blue)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text(value)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.primary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
        )
    }
}

struct FeatureBullet: View {
    let text: String
    
    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(Color.mint)
                .frame(width: 4, height: 4)
            
            Text(text)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Spacer()
        }
    }
}