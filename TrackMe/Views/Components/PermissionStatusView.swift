import SwiftUI
import CoreLocation
import UIKit

/// View showing permission status and action buttons
struct PermissionStatusView: View {
    let authorizationStatus: CLAuthorizationStatus
    let onRequestPermission: () -> Void

    var body: some View {
        Group {
            switch authorizationStatus {
            case .notDetermined:
                notDeterminedView

            case .denied, .restricted:
                deniedView

            case .authorizedWhenInUse:
                whenInUseView

            case .authorizedAlways:
                authorizedView

            @unknown default:
                EmptyView()
            }
        }
    }

    private var notDeterminedView: some View {
        VStack(spacing: 12) {
            Button("Request Location Permission") {
                onRequestPermission()
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
    }

    private var deniedView: some View {
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
    }

    private var whenInUseView: some View {
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
    }

    private var authorizedView: some View {
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
    }
}
