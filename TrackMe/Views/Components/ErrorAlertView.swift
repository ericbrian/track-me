import SwiftUI

/// Reusable error alert modifier
struct ErrorAlert: ViewModifier {
    @ObservedObject var errorHandler: ErrorHandler
    let onOpenSettings: (() -> Void)?

    init(errorHandler: ErrorHandler = .shared, onOpenSettings: (() -> Void)? = nil) {
        self.errorHandler = errorHandler
        self.onOpenSettings = onOpenSettings
    }

    func body(content: Content) -> some View {
        content
            .alert(
                errorHandler.currentError?.errorDescription ?? "Error",
                isPresented: $errorHandler.showErrorAlert,
                presenting: errorHandler.currentError
            ) { error in
                alertButtons(for: error)
            } message: { error in
                alertMessage(for: error)
            }
    }

    @ViewBuilder
    private func alertButtons(for error: AppError) -> some View {
        // Check if this error needs a Settings button
        if needsSettingsButton(error) {
            Button("Open Settings") {
                openSettings()
                errorHandler.clearError()
            }
            Button("Cancel", role: .cancel) {
                errorHandler.clearError()
            }
        } else {
            Button("OK") {
                errorHandler.clearError()
            }
        }
    }

    private func alertMessage(for error: AppError) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            if let reason = error.failureReason {
                Text(reason)
            }
            if let suggestion = error.recoverySuggestion {
                Text(suggestion)
                    .font(.caption)
            }
        }
    }

    private func needsSettingsButton(_ error: AppError) -> Bool {
        switch error {
        case .locationPermissionDenied,
             .locationPermissionNotAlways,
             .locationServicesDisabled:
            return true
        default:
            return false
        }
    }

    private func openSettings() {
        if let onOpenSettings = onOpenSettings {
            onOpenSettings()
        } else {
            if let url = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(url)
            }
        }
    }
}

// MARK: - View Extension

extension View {
    /// Adds error alert handling to any view
    func errorAlert(handler: ErrorHandler = .shared, onOpenSettings: (() -> Void)? = nil) -> some View {
        modifier(ErrorAlert(errorHandler: handler, onOpenSettings: onOpenSettings))
    }
}

// MARK: - Inline Error Banner

/// Inline error banner for non-critical errors
struct ErrorBanner: View {
    let error: AppError
    let onDismiss: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: iconName)
                .font(.title2)
                .foregroundColor(iconColor)

            VStack(alignment: .leading, spacing: 4) {
                Text(error.errorDescription ?? "Error")
                    .font(.headline)
                    .foregroundColor(.primary)

                if let reason = error.failureReason {
                    Text(reason)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
            }

            Spacer()

            Button(action: onDismiss) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.secondary)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(backgroundColor)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(borderColor, lineWidth: 1)
                )
        )
        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
    }

    private var iconName: String {
        switch error {
        case .locationPermissionDenied,
             .locationPermissionNotAlways,
             .locationServicesDisabled:
            return "location.slash.fill"
        case .sessionAlreadyActive:
            return "exclamationmark.triangle.fill"
        case .exportNoLocations:
            return "doc.badge.ellipsis"
        case .watchNotPaired,
             .watchAppNotInstalled:
            return "applewatch.slash"
        case .networkUnavailable,
             .networkTimeout:
            return "wifi.slash"
        default:
            return "exclamationmark.circle.fill"
        }
    }

    private var iconColor: Color {
        switch error {
        case .locationPermissionDenied,
             .sessionCreationFailed,
             .sessionEndFailed,
             .dataStorageError,
             .dataSaveFailed:
            return .red
        case .locationPermissionNotAlways,
             .sessionAlreadyActive,
             .exportNoLocations:
            return .orange
        default:
            return .blue
        }
    }

    private var backgroundColor: Color {
        iconColor.opacity(0.1)
    }

    private var borderColor: Color {
        iconColor.opacity(0.3)
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 20) {
        ErrorBanner(
            error: .locationPermissionDenied,
            onDismiss: {}
        )

        ErrorBanner(
            error: .sessionAlreadyActive,
            onDismiss: {}
        )

        ErrorBanner(
            error: .exportNoLocations,
            onDismiss: {}
        )
    }
    .padding()
}
