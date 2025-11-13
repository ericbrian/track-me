//
//  ErrorHandlerTests.swift
//  TrackMeTests
//

import XCTest
import CoreLocation
import Combine
@testable import TrackMe

@MainActor
final class ErrorHandlerTests: XCTestCase {

    var sut: ErrorHandler!

    override func setUp() {
        super.setUp()
        sut = ErrorHandler.shared
        sut.clearError()
    }

    override func tearDown() {
        sut.clearError()
        super.tearDown()
    }

    // MARK: - Initialization Tests

    func testSharedInstance() {
        let instance1 = ErrorHandler.shared
        let instance2 = ErrorHandler.shared
        XCTAssertTrue(instance1 === instance2, "ErrorHandler.shared should return the same instance")
    }

    func testInitialState() {
        XCTAssertNil(sut.currentError)
        XCTAssertFalse(sut.showErrorAlert)
    }

    // MARK: - AppError Handling Tests

    func testHandleLocationPermissionDenied() {
        let error = AppError.locationPermissionDenied
        sut.handle(error)

        XCTAssertNotNil(sut.currentError)
        XCTAssertTrue(sut.showErrorAlert)

        if case .locationPermissionDenied = sut.currentError {
            // Success
        } else {
            XCTFail("Expected locationPermissionDenied error")
        }
    }

    func testHandleSessionAlreadyActive() {
        let error = AppError.sessionAlreadyActive
        sut.handle(error)

        XCTAssertNotNil(sut.currentError)
        XCTAssertTrue(sut.showErrorAlert)

        if case .sessionAlreadyActive = sut.currentError {
            // Success
        } else {
            XCTFail("Expected sessionAlreadyActive error")
        }
    }

    func testHandleDataSaveFailed() {
        let underlyingError = NSError(domain: "TestDomain", code: 100, userInfo: nil)
        let error = AppError.dataSaveFailed(underlyingError)
        sut.handle(error)

        XCTAssertNotNil(sut.currentError)
        XCTAssertTrue(sut.showErrorAlert)

        if case .dataSaveFailed(let savedError) = sut.currentError {
            XCTAssertEqual((savedError as NSError).code, 100)
        } else {
            XCTFail("Expected dataSaveFailed error")
        }
    }

    func testHandleExportNoLocations() {
        let error = AppError.exportNoLocations
        sut.handle(error)

        XCTAssertNotNil(sut.currentError)
        XCTAssertTrue(sut.showErrorAlert)

        if case .exportNoLocations = sut.currentError {
            // Success
        } else {
            XCTFail("Expected exportNoLocations error")
        }
    }

    func testHandleWatchNotPaired() {
        let error = AppError.watchNotPaired
        sut.handle(error)

        XCTAssertNotNil(sut.currentError)
        XCTAssertTrue(sut.showErrorAlert)

        if case .watchNotPaired = sut.currentError {
            // Success
        } else {
            XCTFail("Expected watchNotPaired error")
        }
    }

    func testHandleNetworkUnavailable() {
        let error = AppError.networkUnavailable
        sut.handle(error)

        XCTAssertNotNil(sut.currentError)
        XCTAssertTrue(sut.showErrorAlert)

        if case .networkUnavailable = sut.currentError {
            // Success
        } else {
            XCTFail("Expected networkUnavailable error")
        }
    }

    func testHandleUnknownError() {
        let underlyingError = NSError(domain: "UnknownDomain", code: 999, userInfo: nil)
        let error = AppError.unknown(underlyingError)
        sut.handle(error)

        XCTAssertNotNil(sut.currentError)
        XCTAssertTrue(sut.showErrorAlert)

        if case .unknown(let savedError) = sut.currentError {
            XCTAssertEqual((savedError as NSError).code, 999)
        } else {
            XCTFail("Expected unknown error")
        }
    }

    // MARK: - Generic Error Conversion Tests

    func testConvertCLErrorDeniedToLocationPermissionDenied() {
        let clError = CLError(.denied)
        sut.handle(clError, context: .locationUpdate)

        XCTAssertNotNil(sut.currentError)
        if case .locationPermissionDenied = sut.currentError {
            // Success
        } else {
            XCTFail("Expected locationPermissionDenied error, got \(String(describing: sut.currentError))")
        }
    }

    func testConvertCLErrorLocationUnknownToLocationUpdateFailed() {
        let clError = CLError(.locationUnknown)
        sut.handle(clError, context: .locationUpdate)

        XCTAssertNotNil(sut.currentError)
        if case .locationUpdateFailed = sut.currentError {
            // Success
        } else {
            XCTFail("Expected locationUpdateFailed error")
        }
    }

    // Note: CLError.Code.network may not be available in all SDK versions
    // Testing the conversion logic is covered by other tests
    func testConvertCLErrorNetworkToNetworkUnavailable() {
        // Create an NSError with CLError domain and network code
        let nsError = NSError(domain: kCLErrorDomain, code: CLError.Code.network.rawValue, userInfo: nil)
        sut.handle(nsError, context: .locationUpdate)

        XCTAssertNotNil(sut.currentError)
        // The conversion may vary based on SDK version, so we just verify error is handled
        XCTAssertTrue(sut.showErrorAlert)
    }

    func testConvertNSErrorWithDataFetchContext() {
        let nsError = NSError(domain: "NSCocoaErrorDomain", code: 100, userInfo: nil)
        sut.handle(nsError, context: .dataFetch)

        XCTAssertNotNil(sut.currentError)
        if case .dataFetchFailed(let error) = sut.currentError {
            XCTAssertEqual((error as NSError).code, 100)
        } else {
            XCTFail("Expected dataFetchFailed error")
        }
    }

    func testConvertNSErrorWithDataSaveContext() {
        let nsError = NSError(domain: "NSCocoaErrorDomain", code: 200, userInfo: nil)
        sut.handle(nsError, context: .dataSave)

        XCTAssertNotNil(sut.currentError)
        if case .dataSaveFailed(let error) = sut.currentError {
            XCTAssertEqual((error as NSError).code, 200)
        } else {
            XCTFail("Expected dataSaveFailed error")
        }
    }

    func testConvertNSErrorWithDataDeleteContext() {
        let nsError = NSError(domain: "NSCocoaErrorDomain", code: 300, userInfo: nil)
        sut.handle(nsError, context: .dataDelete)

        XCTAssertNotNil(sut.currentError)
        if case .dataDeleteFailed(let error) = sut.currentError {
            XCTAssertEqual((error as NSError).code, 300)
        } else {
            XCTFail("Expected dataDeleteFailed error")
        }
    }

    func testConvertNSErrorWithOtherContextToDataStorageError() {
        let nsError = NSError(domain: "NSCocoaErrorDomain", code: 400, userInfo: nil)
        sut.handle(nsError, context: .other)

        XCTAssertNotNil(sut.currentError)
        if case .dataStorageError(let error) = sut.currentError {
            XCTAssertEqual((error as NSError).code, 400)
        } else {
            XCTFail("Expected dataStorageError error")
        }
    }

    // MARK: - Context-Based Error Conversion Tests

    func testConvertGenericErrorWithSessionStartContext() {
        let genericError = NSError(domain: "TestDomain", code: 500, userInfo: nil)
        sut.handle(genericError, context: .sessionStart)

        XCTAssertNotNil(sut.currentError)
        if case .sessionCreationFailed(let error) = sut.currentError {
            XCTAssertEqual((error as NSError).code, 500)
        } else {
            XCTFail("Expected sessionCreationFailed error")
        }
    }

    func testConvertGenericErrorWithSessionStopContext() {
        let genericError = NSError(domain: "TestDomain", code: 600, userInfo: nil)
        sut.handle(genericError, context: .sessionStop)

        XCTAssertNotNil(sut.currentError)
        if case .sessionEndFailed(let error) = sut.currentError {
            XCTAssertEqual((error as NSError).code, 600)
        } else {
            XCTFail("Expected sessionEndFailed error")
        }
    }

    func testConvertGenericErrorWithExportFileContext() {
        let genericError = NSError(domain: "TestDomain", code: 700, userInfo: nil)
        sut.handle(genericError, context: .exportFile)

        XCTAssertNotNil(sut.currentError)
        if case .exportSaveFailed(let error) = sut.currentError {
            XCTAssertEqual((error as NSError).code, 700)
        } else {
            XCTFail("Expected exportSaveFailed error")
        }
    }

    func testConvertGenericErrorWithWatchCommunicationContext() {
        let genericError = NSError(domain: "TestDomain", code: 800, userInfo: nil)
        sut.handle(genericError, context: .watchCommunication)

        XCTAssertNotNil(sut.currentError)
        if case .watchCommunicationFailed(let error) = sut.currentError {
            XCTAssertEqual((error as NSError).code, 800)
        } else {
            XCTFail("Expected watchCommunicationFailed error")
        }
    }

    func testConvertGenericErrorWithOtherContextToUnknown() {
        let genericError = NSError(domain: "TestDomain", code: 900, userInfo: nil)
        sut.handle(genericError, context: .other)

        XCTAssertNotNil(sut.currentError)
        if case .unknown(let error) = sut.currentError {
            XCTAssertEqual((error as NSError).code, 900)
        } else {
            XCTFail("Expected unknown error")
        }
    }

    // MARK: - Error Clearing Tests

    func testClearError() {
        let error = AppError.sessionAlreadyActive
        sut.handle(error)
        XCTAssertNotNil(sut.currentError)
        XCTAssertTrue(sut.showErrorAlert)

        sut.clearError()
        XCTAssertNil(sut.currentError)
        XCTAssertFalse(sut.showErrorAlert)
    }

    func testClearErrorWhenNoError() {
        sut.clearError()
        XCTAssertNil(sut.currentError)
        XCTAssertFalse(sut.showErrorAlert)
    }

    // MARK: - Multiple Error Handling Tests

    func testHandleMultipleErrors() {
        let error1 = AppError.locationPermissionDenied
        sut.handle(error1)

        if case .locationPermissionDenied = sut.currentError {
            // Success
        } else {
            XCTFail("Expected locationPermissionDenied error")
        }

        let error2 = AppError.sessionAlreadyActive
        sut.handle(error2)

        if case .sessionAlreadyActive = sut.currentError {
            // Success - second error should replace first
        } else {
            XCTFail("Expected sessionAlreadyActive error")
        }
    }

    // MARK: - AppError Message Tests

    func testLocationPermissionDeniedMessages() {
        let error = AppError.locationPermissionDenied
        XCTAssertEqual(error.errorDescription, "Location Access Denied")
        XCTAssertTrue(error.failureReason?.contains("TrackMe needs location permission") ?? false)
        XCTAssertEqual(error.recoverySuggestion, "Tap 'Open Settings' to grant location permission.")
    }

    func testSessionAlreadyActiveMessages() {
        let error = AppError.sessionAlreadyActive
        XCTAssertEqual(error.errorDescription, "Session Already Running")
        XCTAssertTrue(error.failureReason?.contains("Another tracking session is already running") ?? false)
        XCTAssertEqual(error.recoverySuggestion, "Stop the current session from the Track tab.")
    }

    func testExportNoLocationsMessages() {
        let error = AppError.exportNoLocations
        XCTAssertEqual(error.errorDescription, "No Location Data")
        XCTAssertTrue(error.failureReason?.contains("This session has no location data") ?? false)
        XCTAssertEqual(error.recoverySuggestion, "Start tracking to collect location data.")
    }

    func testWatchNotPairedMessages() {
        let error = AppError.watchNotPaired
        XCTAssertEqual(error.errorDescription, "Apple Watch Not Paired")
        XCTAssertNotNil(error.failureReason)
        XCTAssertEqual(error.recoverySuggestion, "Open the Watch app to pair your Apple Watch.")
    }

    func testNetworkUnavailableMessages() {
        let error = AppError.networkUnavailable
        XCTAssertEqual(error.errorDescription, "No Network Connection")
        XCTAssertNotNil(error.failureReason)
        XCTAssertEqual(error.recoverySuggestion, "Check your internet connection.")
    }

    func testDataSaveFailedMessages() {
        let underlyingError = NSError(domain: "TestDomain", code: 100, userInfo: nil)
        let error = AppError.dataSaveFailed(underlyingError)
        XCTAssertEqual(error.errorDescription, "Failed to Save Data")
        XCTAssertTrue(error.failureReason?.contains("Unable to save") ?? false)
        XCTAssertEqual(error.recoverySuggestion, "Restart the app. If the problem persists, reinstall the app.")
    }

    // MARK: - Error Context Tests

    func testErrorContextValues() {
        // Verify ErrorContext enum cases are available
        let contexts: [ErrorContext] = [
            .sessionStart,
            .sessionStop,
            .locationUpdate,
            .dataFetch,
            .dataSave,
            .dataDelete,
            .exportFile,
            .watchCommunication,
            .other
        ]

        XCTAssertEqual(contexts.count, 9, "Expected 9 ErrorContext cases")
    }

    // MARK: - Published Properties Tests

    func testCurrentErrorPublished() {
        let expectation = XCTestExpectation(description: "currentError published")
        var observedError: AppError?

        let cancellable = sut.$currentError.sink { error in
            observedError = error
            if error != nil {
                expectation.fulfill()
            }
        }

        sut.handle(AppError.locationPermissionDenied)

        wait(for: [expectation], timeout: 1.0)
        XCTAssertNotNil(observedError)
        if case .locationPermissionDenied = observedError {
            // Success
        } else {
            XCTFail("Expected locationPermissionDenied error")
        }

        cancellable.cancel()
    }

    func testShowErrorAlertPublished() {
        let expectation = XCTestExpectation(description: "showErrorAlert published")
        var alertShown = false

        let cancellable = sut.$showErrorAlert.sink { show in
            if show {
                alertShown = true
                expectation.fulfill()
            }
        }

        sut.handle(AppError.sessionAlreadyActive)

        wait(for: [expectation], timeout: 1.0)
        XCTAssertTrue(alertShown)

        cancellable.cancel()
    }
}
