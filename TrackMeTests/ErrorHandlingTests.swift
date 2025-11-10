import XCTest
import CoreLocation
import CoreData
@testable import TrackMe

@MainActor
final class ErrorHandlingTests: XCTestCase {
    
    var errorHandler: ErrorHandler!
    
    override func setUp() async throws {
        try await super.setUp()
        errorHandler = ErrorHandler.shared
        // Clear any existing errors
        errorHandler.clearError()
    }
    
    override func tearDown() async throws {
        errorHandler.clearError()
        try await super.tearDown()
    }
    
    // MARK: - Error Handler Tests
    
    func testErrorHandlerShowsAlert() async throws {
        // Given
        XCTAssertFalse(errorHandler.showErrorAlert)
        XCTAssertNil(errorHandler.currentError)
        
        // When
        errorHandler.handle(.locationPermissionDenied)
        
        // Then
        XCTAssertTrue(errorHandler.showErrorAlert)
        XCTAssertNotNil(errorHandler.currentError)
        
        if case .locationPermissionDenied = errorHandler.currentError {
            // Success
        } else {
            XCTFail("Expected locationPermissionDenied error")
        }
    }
    
    func testErrorHandlerClearsError() async throws {
        // Given
        errorHandler.handle(.sessionAlreadyActive)
        XCTAssertTrue(errorHandler.showErrorAlert)
        
        // When
        errorHandler.clearError()
        
        // Then
        XCTAssertFalse(errorHandler.showErrorAlert)
        XCTAssertNil(errorHandler.currentError)
    }
    
    func testLocationPermissionDeniedErrorMessage() async throws {
        // When
        errorHandler.handle(.locationPermissionDenied)
        
        // Then
        XCTAssertEqual(errorHandler.currentError?.errorDescription, "Location Access Denied")
        XCTAssertTrue(errorHandler.currentError?.failureReason?.contains("location permission") ?? false)
        XCTAssertTrue(errorHandler.currentError?.recoverySuggestion?.contains("Settings") ?? false)
    }
    
    func testLocationPermissionNotAlwaysErrorMessage() async throws {
        // When
        errorHandler.handle(.locationPermissionNotAlways)
        
        // Then
        XCTAssertEqual(errorHandler.currentError?.errorDescription, "Background Location Required")
        XCTAssertTrue(errorHandler.currentError?.failureReason?.contains("Always Allow") ?? false)
        XCTAssertTrue(errorHandler.currentError?.recoverySuggestion?.contains("Settings") ?? false)
    }
    
    func testSessionAlreadyActiveErrorMessage() async throws {
        // When
        errorHandler.handle(.sessionAlreadyActive)
        
        // Then
        XCTAssertEqual(errorHandler.currentError?.errorDescription, "Session Already Running")
        XCTAssertTrue(errorHandler.currentError?.failureReason?.contains("already running") ?? false)
        XCTAssertTrue(errorHandler.currentError?.recoverySuggestion?.contains("Stop") ?? false)
    }
    
    func testNetworkUnavailableErrorMessage() async throws {
        // When
        errorHandler.handle(.networkUnavailable)
        
        // Then
        XCTAssertEqual(errorHandler.currentError?.errorDescription, "No Network Connection")
        XCTAssertTrue(errorHandler.currentError?.failureReason?.contains("internet") ?? false)
    }
    
    func testSessionCreationFailedErrorMessage() async throws {
        // Given
        let underlyingError = NSError(domain: "TestDomain", code: 123, userInfo: [NSLocalizedDescriptionKey: "Test error"])
        
        // When
        errorHandler.handle(.sessionCreationFailed(underlyingError))
        
        // Then
        XCTAssertEqual(errorHandler.currentError?.errorDescription, "Failed to Start Tracking")
        XCTAssertTrue(errorHandler.currentError?.failureReason?.contains("Test error") ?? false)
    }
    
    func testGenericErrorConversion() async throws {
        // Given
        let genericError = NSError(domain: "TestDomain", code: 456, userInfo: [NSLocalizedDescriptionKey: "Generic error"])
        
        // When
        errorHandler.handle(genericError, context: .sessionStart)
        
        // Then
        if case .sessionCreationFailed = errorHandler.currentError {
            // Success
        } else {
            XCTFail("Expected sessionCreationFailed error")
        }
    }
    
    func testCLErrorConversion() async throws {
        // Given
        let clError = CLError(.denied)
        
        // When
        errorHandler.handle(clError, context: .locationUpdate)
        
        // Then
        if case .locationPermissionDenied = errorHandler.currentError {
            // Success
        } else {
            XCTFail("Expected locationPermissionDenied error")
        }
    }
    
    // MARK: - LocationManager Error Integration Tests
    
    func testLocationManagerHandlesPermissionDeniedError() async throws {
        // Given
        let persistence = PersistenceController(inMemory: true)
        let context = persistence.container.viewContext
        let sessionRepo = CoreDataSessionRepository(context: context)
        let locationRepo = CoreDataLocationRepository(context: context)
        let locationManager = LocationManager(sessionRepository: sessionRepo, locationRepository: locationRepo)
        
        // When - simulate permission denied by starting tracking without authorization
        locationManager.startTracking(with: "Test")
        
        // Small delay to allow async error handling
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        
        // Then - error should be set (either deprecated property or new error handler)
        // This test verifies backward compatibility
        XCTAssertNotNil(locationManager.trackingStartError)
    }
    
    func testLocationManagerHandlesSessionAlreadyActiveError() async throws {
        // Given
        let persistence = PersistenceController(inMemory: true)
        let context = persistence.container.viewContext
        let sessionRepo = CoreDataSessionRepository(context: context)
        let locationRepo = CoreDataLocationRepository(context: context)
        
        // Create an existing active session
        _ = try sessionRepo.createSession(narrative: "Existing Session", startDate: Date())
        
        let locationManager = LocationManager(sessionRepository: sessionRepo, locationRepository: locationRepo)
        
        // When - try to start another session
        locationManager.startTracking(with: "New Session")
        
        // Small delay to allow async error handling
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        
        // Then - error should be set
        XCTAssertNotNil(locationManager.trackingStartError)
        XCTAssertTrue(locationManager.trackingStartError?.contains("already") ?? false)
    }
    
    func testLocationManagerDoesNotStartTrackingWhenPermissionDenied() async throws {
        // Given
        let persistence = PersistenceController(inMemory: true)
        let context = persistence.container.viewContext
        let sessionRepo = CoreDataSessionRepository(context: context)
        let locationRepo = CoreDataLocationRepository(context: context)
        let locationManager = LocationManager(sessionRepository: sessionRepo, locationRepository: locationRepo)
        
        // When - try to start tracking without proper authorization
        locationManager.startTracking(with: "Test")
        
        // Small delay
        try await Task.sleep(nanoseconds: 100_000_000)
        
        // Then - tracking should not start
        XCTAssertFalse(locationManager.isTracking)
        XCTAssertNil(locationManager.currentSession)
    }
    
    func testLocationManagerPropagatesSessionEndError() async throws {
        // Given
        let persistence = PersistenceController(inMemory: true)
        let context = persistence.container.viewContext
        let sessionRepo = CoreDataSessionRepository(context: context)
        let locationRepo = CoreDataLocationRepository(context: context)
        let locationManager = LocationManager(sessionRepository: sessionRepo, locationRepository: locationRepo)
        
        // Create a session directly (bypassing authorization checks)
        let session = try sessionRepo.createSession(narrative: "Test", startDate: Date())
        locationManager.currentSession = session
        locationManager.isTracking = true
        
        // Corrupt the session to force an error (delete it from context)
        context.delete(session)
        try context.save()
        
        // When - try to stop tracking
        locationManager.stopTracking()
        
        // Small delay
        try await Task.sleep(nanoseconds: 100_000_000)
        
        // Then - error should be set
        XCTAssertNotNil(locationManager.trackingStopError)
    }
    
    // MARK: - Error Description Tests
    
    func testAllErrorsHaveDescriptions() {
        let errors: [AppError] = [
            .locationPermissionDenied,
            .locationPermissionNotAlways,
            .locationServicesDisabled,
            .locationAccuracyTooLow,
            .locationUpdateFailed(NSError(domain: "test", code: 1)),
            .sessionAlreadyActive,
            .sessionCreationFailed(NSError(domain: "test", code: 1)),
            .sessionNotFound,
            .sessionEndFailed(NSError(domain: "test", code: 1)),
            .noActiveSession,
            .sessionQueryFailed(NSError(domain: "test", code: 1)),
            .dataStorageError(NSError(domain: "test", code: 1)),
            .dataFetchFailed(NSError(domain: "test", code: 1)),
            .dataDeleteFailed(NSError(domain: "test", code: 1)),
            .dataSaveFailed(NSError(domain: "test", code: 1)),
            .exportNoLocations,
            .exportFileCreationFailed,
            .exportFormatUnsupported,
            .exportSaveFailed(NSError(domain: "test", code: 1)),
            .watchNotPaired,
            .watchAppNotInstalled,
            .watchCommunicationFailed(NSError(domain: "test", code: 1)),
            .networkUnavailable,
            .networkTimeout,
            .unknown(NSError(domain: "test", code: 1))
        ]
        
        for error in errors {
            XCTAssertNotNil(error.errorDescription, "Error \(error) missing errorDescription")
            XCTAssertNotNil(error.failureReason, "Error \(error) missing failureReason")
            XCTAssertNotNil(error.recoverySuggestion, "Error \(error) missing recoverySuggestion")
        }
    }
}
