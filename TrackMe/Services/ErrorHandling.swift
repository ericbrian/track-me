import Foundation
import CoreLocation

// MARK: - App Errors

/// Centralized error types for the application
enum AppError: Error {
    // Location Errors
    case locationPermissionDenied
    case locationPermissionNotAlways
    case locationServicesDisabled
    case locationAccuracyTooLow
    case locationUpdateFailed(Error)

    // Tracking Session Errors
    case sessionAlreadyActive
    case sessionCreationFailed(Error)
    case sessionNotFound
    case sessionEndFailed(Error)
    case noActiveSession
    case sessionQueryFailed(Error)

    // Core Data Errors
    case dataStorageError(Error)
    case dataFetchFailed(Error)
    case dataDeleteFailed(Error)
    case dataSaveFailed(Error)

    // Export Errors
    case exportNoLocations
    case exportFileCreationFailed
    case exportFormatUnsupported
    case exportSaveFailed(Error)

    // Watch Connectivity Errors
    case watchNotPaired
    case watchAppNotInstalled
    case watchCommunicationFailed(Error)

    // Network Errors
    case networkUnavailable
    case networkTimeout

    // General Errors
    case unknown(Error)
}

// MARK: - User-Facing Error Messages

extension AppError: LocalizedError {
    /// User-friendly error description
    var errorDescription: String? {
        switch self {
        // Location Errors
        case .locationPermissionDenied:
            return "Location Access Denied"
        case .locationPermissionNotAlways:
            return "Background Location Required"
        case .locationServicesDisabled:
            return "Location Services Disabled"
        case .locationAccuracyTooLow:
            return "Poor GPS Signal"
        case .locationUpdateFailed:
            return "Location Update Failed"

        // Tracking Session Errors
        case .sessionAlreadyActive:
            return "Session Already Running"
        case .sessionCreationFailed:
            return "Failed to Start Tracking"
        case .sessionNotFound:
            return "Session Not Found"
        case .sessionEndFailed:
            return "Failed to Stop Tracking"
        case .noActiveSession:
            return "No Active Session"
        case .sessionQueryFailed:
            return "Failed to Query Sessions"

        // Core Data Errors
        case .dataStorageError:
            return "Data Storage Error"
        case .dataFetchFailed:
            return "Failed to Load Data"
        case .dataDeleteFailed:
            return "Failed to Delete Data"
        case .dataSaveFailed:
            return "Failed to Save Data"

        // Export Errors
        case .exportNoLocations:
            return "No Location Data"
        case .exportFileCreationFailed:
            return "Export Failed"
        case .exportFormatUnsupported:
            return "Format Not Supported"
        case .exportSaveFailed:
            return "Failed to Save File"

        // Watch Connectivity Errors
        case .watchNotPaired:
            return "Apple Watch Not Paired"
        case .watchAppNotInstalled:
            return "Watch App Not Installed"
        case .watchCommunicationFailed:
            return "Watch Communication Error"

        // Network Errors
        case .networkUnavailable:
            return "No Network Connection"
        case .networkTimeout:
            return "Network Timeout"

        // General
        case .unknown:
            return "Unexpected Error"
        }
    }

    /// Detailed error message with guidance
    var failureReason: String? {
        switch self {
        // Location Errors
        case .locationPermissionDenied:
            return "TrackMe needs location permission to track your movements. Please enable location access in Settings."
        case .locationPermissionNotAlways:
            return "For background tracking, TrackMe needs 'Always Allow' location permission. Please enable it in Settings > Privacy > Location Services > TrackMe."
        case .locationServicesDisabled:
            return "Location Services are disabled on your device. Please enable them in Settings > Privacy > Location Services."
        case .locationAccuracyTooLow:
            return "The current GPS signal is too weak. Try moving to an area with better sky visibility or wait for the signal to improve."
        case .locationUpdateFailed(let error):
            return "Unable to get your current location: \(error.localizedDescription)"

        // Tracking Session Errors
        case .sessionAlreadyActive:
            return "Another tracking session is already running. Please stop the current session before starting a new one."
        case .sessionCreationFailed(let error):
            return "Unable to create a new tracking session. Error: \(error.localizedDescription). Please try again."
        case .sessionNotFound:
            return "The requested tracking session could not be found. It may have been deleted."
        case .sessionEndFailed(let error):
            return "Unable to stop the tracking session. Error: \(error.localizedDescription). Please try again."
        case .noActiveSession:
            return "There is no active tracking session to stop."
        case .sessionQueryFailed(let error):
            return "Unable to check for active sessions. Error: \(error.localizedDescription). Please try again."

        // Core Data Errors
        case .dataStorageError(let error):
            return "Unable to access the data store. Error: \(error.localizedDescription). Try restarting the app."
        case .dataFetchFailed(let error):
            return "Unable to load your tracking data. Error: \(error.localizedDescription)"
        case .dataDeleteFailed(let error):
            return "Unable to delete the selected items. Error: \(error.localizedDescription)"
        case .dataSaveFailed(let error):
            return "Unable to save your data. Error: \(error.localizedDescription). Your changes may be lost."

        // Export Errors
        case .exportNoLocations:
            return "This session has no location data to export. Start tracking to collect location data."
        case .exportFileCreationFailed:
            return "Unable to create the export file. Please check available storage space and try again."
        case .exportFormatUnsupported:
            return "The selected export format is not currently supported."
        case .exportSaveFailed(let error):
            return "Unable to save the exported file. Error: \(error.localizedDescription)"

        // Watch Connectivity Errors
        case .watchNotPaired:
            return "No Apple Watch is currently paired with this iPhone. Pair your watch in the Watch app to enable this feature."
        case .watchAppNotInstalled:
            return "The TrackMe app is not installed on your Apple Watch. Please install it from the Watch App Store."
        case .watchCommunicationFailed(let error):
            return "Unable to communicate with your Apple Watch. Error: \(error.localizedDescription)"

        // Network Errors
        case .networkUnavailable:
            return "No internet connection is available. Some features may not work correctly."
        case .networkTimeout:
            return "The network request timed out. Please check your connection and try again."

        // General
        case .unknown(let error):
            return "An unexpected error occurred: \(error.localizedDescription)"
        }
    }

    /// Recovery suggestions for the user
    var recoverySuggestion: String? {
        switch self {
        // Location Errors
        case .locationPermissionDenied, .locationPermissionNotAlways:
            return "Tap 'Open Settings' to grant location permission."
        case .locationServicesDisabled:
            return "Enable Location Services in your device settings."
        case .locationAccuracyTooLow:
            return "Move to an open area with clear sky visibility."
        case .locationUpdateFailed:
            return "Wait a moment and try again."

        // Tracking Session Errors
        case .sessionAlreadyActive:
            return "Stop the current session from the Track tab."
        case .sessionCreationFailed, .sessionEndFailed:
            return "Try again in a few moments."
        case .sessionNotFound:
            return "Refresh the history view."
        case .noActiveSession:
            return "Start a new tracking session first."
        case .sessionQueryFailed:
            return "Try again in a few moments."

        // Core Data Errors
        case .dataStorageError, .dataSaveFailed:
            return "Restart the app. If the problem persists, reinstall the app."
        case .dataFetchFailed, .dataDeleteFailed:
            return "Try again. If the problem persists, contact support."

        // Export Errors
        case .exportNoLocations:
            return "Start tracking to collect location data."
        case .exportFileCreationFailed:
            return "Check available storage space."
        case .exportFormatUnsupported:
            return "Try a different export format."
        case .exportSaveFailed:
            return "Ensure you have sufficient storage space."

        // Watch Connectivity Errors
        case .watchNotPaired:
            return "Open the Watch app to pair your Apple Watch."
        case .watchAppNotInstalled:
            return "Install TrackMe on your watch from the App Store."
        case .watchCommunicationFailed:
            return "Ensure your watch is nearby and connected."

        // Network Errors
        case .networkUnavailable, .networkTimeout:
            return "Check your internet connection."

        // General
        case .unknown:
            return "Try restarting the app."
        }
    }
}

// MARK: - Error Handler

/// Centralized error handling service
@MainActor
class ErrorHandler: ObservableObject {
    static let shared = ErrorHandler()

    @Published var currentError: AppError?
    @Published var showErrorAlert = false

    nonisolated private init() {}

    /// Handle an error and prepare it for display
    func handle(_ error: AppError) {
        currentError = error
        showErrorAlert = true

        // Log error for debugging
        logError(error)
    }

    /// Handle a generic error and convert to AppError
    func handle(_ error: Error, context: ErrorContext) {
        let appError = convertToAppError(error, context: context)
        handle(appError)
    }

    /// Clear the current error
    func clearError() {
        currentError = nil
        showErrorAlert = false
    }

    /// Log error for debugging/analytics
    private func logError(_ error: AppError) {
        let description = error.errorDescription ?? "Unknown error"
        let reason = error.failureReason ?? "No details"

        print("⚠️ ERROR: \(description)")
        print("   Reason: \(reason)")

        #if DEBUG
        print("   Recovery: \(error.recoverySuggestion ?? "None")")
        #endif
    }

    /// Convert generic Error to AppError based on context
    private func convertToAppError(_ error: Error, context: ErrorContext) -> AppError {
        // Handle CLError
        if let clError = error as? CLError {
            switch clError.code {
            case .denied:
                return .locationPermissionDenied
            case .locationUnknown:
                return .locationUpdateFailed(error)
            case .network:
                return .networkUnavailable
            default:
                return .locationUpdateFailed(error)
            }
        }

        // Handle NSError (Core Data errors)
        if let nsError = error as NSError? {
            if nsError.domain == "NSCocoaErrorDomain" {
                switch context {
                case .dataFetch:
                    return .dataFetchFailed(error)
                case .dataSave:
                    return .dataSaveFailed(error)
                case .dataDelete:
                    return .dataDeleteFailed(error)
                default:
                    return .dataStorageError(error)
                }
            }
        }

        // Context-based conversion
        switch context {
        case .sessionStart:
            return .sessionCreationFailed(error)
        case .sessionStop:
            return .sessionEndFailed(error)
        case .exportFile:
            return .exportSaveFailed(error)
        case .watchCommunication:
            return .watchCommunicationFailed(error)
        default:
            return .unknown(error)
        }
    }
}

// MARK: - Error Context

/// Context for error handling
enum ErrorContext {
    case sessionStart
    case sessionStop
    case locationUpdate
    case dataFetch
    case dataSave
    case dataDelete
    case exportFile
    case watchCommunication
    case other
}
