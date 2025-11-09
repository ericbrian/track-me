import SwiftUI
import CoreLocation

/// Banner shown when location permission is not set to "Always"
struct PermissionBanner: View {
    let authorizationStatus: CLAuthorizationStatus
    @State private var showPrivacyNotice = false

    var body: some View {
        if authorizationStatus != .authorizedAlways {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 10) {
                    Image(systemName: "exclamationmark.shield.fill")
                        .foregroundColor(.red)
                        .font(.title2)
                    Text("'Always' Location Permission Required")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.red)
                }
                
                Text("TrackMe requires 'Always Allow' location access to function correctly, including background tracking. Please grant 'Always' permission when prompted, or enable it in Settings > Privacy > Location Services > TrackMe.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                // Privacy assurance
                HStack(spacing: 8) {
                    Image(systemName: "lock.fill")
                        .font(.caption)
                        .foregroundColor(.blue)
                    
                    Text("Your location data stays private on your device")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Button("Learn More") {
                        showPrivacyNotice = true
                    }
                    .font(.caption)
                    .foregroundColor(.blue)
                }
                .padding(.top, 4)
            }
            .padding(16)
            .background(Color.red.opacity(0.07))
            .cornerRadius(12)
            .padding(.top, 8)
            .sheet(isPresented: $showPrivacyNotice) {
                PrivacyNoticeView()
            }
        }
    }
}
