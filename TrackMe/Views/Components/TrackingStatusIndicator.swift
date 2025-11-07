import SwiftUI

/// Hero status indicator showing current tracking state
struct TrackingStatusIndicator: View {
    let isTracking: Bool
    let appState: UIApplication.State

    private var statusGradientColors: [Color] {
        isTracking ?
            [Color.green.opacity(0.3), Color.green.opacity(0.1)] :
            [Color.gray.opacity(0.3), Color.gray.opacity(0.1)]
    }

    private var statusColor: Color {
        isTracking ? .green : .gray
    }

    private var statusIconName: String {
        isTracking ? "location.fill" : "location"
    }

    private var statusText: String {
        isTracking ? "ACTIVE" : "STOPPED"
    }

    private var trackingStatusText: String {
        isTracking ? "GPS Tracking Active" : "GPS Tracking Stopped"
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
            .scaleEffect(isTracking ? 1.0 : 0.9)
            .animation(.easeInOut(duration: 0.3), value: isTracking)

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
                if isTracking {
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
    }
}
