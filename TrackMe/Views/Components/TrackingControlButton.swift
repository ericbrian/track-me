import SwiftUI
import CoreLocation

/// Start/Stop tracking button
struct TrackingControlButton: View {
    let isTracking: Bool
    let authorizationStatus: CLAuthorizationStatus
    let onStart: () -> Void
    let onStop: () -> Void

    var body: some View {
        if isTracking {
            Button(action: onStop) {
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
            .padding(.horizontal, 20)
        } else if authorizationStatus == .authorizedAlways {
            Button(action: onStart) {
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
    }
}
