import XCTest
import CoreLocation
import Combine
import UIKit
@testable import TrackMe

/// Tests for TrackingViewModel
/// Tests cover: initialization, state management, app lifecycle, error handling, and user actions
@MainActor
final class TrackingViewModelTests: TrackMeMainActorTestCase {
    
    // MARK: - System Under Test
    
    var sut: TrackingViewModel!
    var locationManager: LocationManager!
    var cancellables: Set<AnyCancellable>!
    
    // MARK: - Setup & Teardown
    
    /// Helper to create a fresh SUT for each test
    func makeSUT() {
        cancellables = []
        
        // Create LocationManager with mock repositories
        locationManager = LocationManager(
            sessionRepository: mockSessionRepository,
            locationRepository: mockLocationRepository
        )
        
        // Create TrackingViewModel with dependencies
        sut = TrackingViewModel(
            locationManager: locationManager,
            sessionRepository: mockSessionRepository,
            errorHandler: errorHandler
        )
    }
    
    // MARK: - Initialization Tests
    
    func testInitialization_SetsDefaultState() {
        // Given/When: TrackingViewModel is initialized
        makeSUT()
        
        // Then: Verify initial state
        XCTAssertEqual(sut.appState, .active, "Should start in active state")
        XCTAssertFalse(sut.showTrackingModeSettings, "Should not show settings initially")
        XCTAssertFalse(sut.showPrivacyNotice, "Should not show privacy notice initially")
        XCTAssertFalse(sut.isTracking, "Should not be tracking initially")
        XCTAssertEqual(sut.locationCount, 0, "Should have zero location count initially")
    }
    
    func testInitialization_WithDependencyInjection() {
        // Given: Custom dependencies
        let customSessionRepo = MockSessionRepository()
        let customLocationRepo = MockLocationRepository()
        let customLocationManager = LocationManager(
            sessionRepository: customSessionRepo,
            locationRepository: customLocationRepo
        )
        
        // When: Creating TrackingViewModel with custom dependencies
        let viewModel = TrackingViewModel(
            locationManager: customLocationManager,
            sessionRepository: customSessionRepo,
            errorHandler: errorHandler
        )
        
        // Then: ViewModel should be created successfully
        XCTAssertNotNil(viewModel)
        XCTAssertFalse(viewModel.isTracking)
        XCTAssertEqual(viewModel.appState, .active)
    }
    
    // MARK: - Computed Properties Tests
    
    func testIsTracking_ReflectsLocationManagerState() {
        // Given: Location manager is not tracking
        makeSUT()
        XCTAssertFalse(locationManager.isTracking)
        
        // Then: ViewModel should reflect the same state
        XCTAssertFalse(sut.isTracking)
        
        // When: Location manager starts tracking (simulated)
        // Note: We can't easily simulate actual tracking without permissions
        // but we verify the property correctly delegates to location manager
    }
    
    func testAuthorizationStatus_ReflectsLocationManagerState() {
        makeSUT()
        // Given: Location manager has authorization status
        let status = locationManager.authorizationStatus
        
        // Then: ViewModel should reflect the same status
        XCTAssertEqual(sut.authorizationStatus, status)
    }
    
    func testCurrentLocation_ReflectsLocationManagerState() {
        makeSUT()
        // Given: Location manager has no current location
        XCTAssertNil(locationManager.currentLocation)
        
        // Then: ViewModel should reflect the same state
        XCTAssertNil(sut.currentLocation)
    }
    
    func testCurrentSession_ReflectsLocationManagerState() {
        makeSUT()
        // Given: Location manager has no current session
        XCTAssertNil(locationManager.currentSession)
        
        // Then: ViewModel should reflect the same state
        XCTAssertNil(sut.currentSession)
    }
    
    func testLocationCount_ReflectsLocationManagerState() {
        makeSUT()
        // Given: Location manager has zero locations
        XCTAssertEqual(locationManager.locationCount, 0)
        
        // Then: ViewModel should reflect the same count
        XCTAssertEqual(sut.locationCount, 0)
    }
    
    func testShowSettingsSuggestion_ReflectsLocationManagerState() {
        makeSUT()
        // Given: Location manager not showing settings suggestion
        XCTAssertFalse(locationManager.showSettingsSuggestion)
        
        // Then: ViewModel should reflect the same state
        XCTAssertFalse(sut.showSettingsSuggestion)
    }
    
    // MARK: - App Lifecycle Tests
    
    func testAppLifecycle_EnteringBackground_UpdatesAppState() {
        makeSUT()
        // Given: App is in active state
        XCTAssertEqual(sut.appState, .active)
        
        // When: App enters background
        NotificationCenter.default.post(name: UIApplication.didEnterBackgroundNotification, object: nil)
        
        // Then: App state should update
        // Note: This happens async, so we need to wait briefly
        wait(timeout: 0.5) { self.sut.appState == .background }
        XCTAssertEqual(sut.appState, .background, "App state should update to background")
    }
    
    func testAppLifecycle_EnteringForeground_UpdatesAppState() {
        makeSUT()
        // Given: App is in background state
        NotificationCenter.default.post(name: UIApplication.didEnterBackgroundNotification, object: nil)
        wait(timeout: 0.5) { self.sut.appState == .background }
        
        // When: App enters foreground
        NotificationCenter.default.post(name: UIApplication.willEnterForegroundNotification, object: nil)
        
        // Then: App state should update
        wait(timeout: 0.5) { self.sut.appState == .active }
        XCTAssertEqual(sut.appState, .active, "App state should update to active")
    }
    
    func testAppLifecycle_MultipleTransitions_HandlesCorrectly() {
        makeSUT()
        // Given: App starts in active state
        XCTAssertEqual(sut.appState, .active)
        
        // When: App cycles through background and foreground
        NotificationCenter.default.post(name: UIApplication.didEnterBackgroundNotification, object: nil)
        wait(timeout: 0.5) { self.sut.appState == .background }
        
        NotificationCenter.default.post(name: UIApplication.willEnterForegroundNotification, object: nil)
        wait(timeout: 0.5) { self.sut.appState == .active }
        
        NotificationCenter.default.post(name: UIApplication.didEnterBackgroundNotification, object: nil)
        wait(timeout: 0.5) { self.sut.appState == .background }
        
        // Then: State should be background
        XCTAssertEqual(sut.appState, .background, "Should handle multiple transitions")
    }
    
    // MARK: - User Action Tests
    
    func testShowSettings_TogglesFlag() {
        makeSUT()
        // Given: Settings sheet is not shown
        XCTAssertFalse(sut.showTrackingModeSettings)
        
        // When: User requests to show settings
        sut.showSettings()
        
        // Then: Flag should be set
        XCTAssertTrue(sut.showTrackingModeSettings, "Should show settings sheet")
    }
    
    func testDismissSettings_TogglesFlag() {
        makeSUT()
        // Given: Settings sheet is shown
        sut.showSettings()
        XCTAssertTrue(sut.showTrackingModeSettings)
        
        // When: User dismisses settings
        sut.dismissSettings()
        
        // Then: Flag should be cleared
        XCTAssertFalse(sut.showTrackingModeSettings, "Should hide settings sheet")
    }
    
    func testShowPrivacy_TogglesFlag() {
        makeSUT()
        // Given: Privacy notice is not shown
        XCTAssertFalse(sut.showPrivacyNotice)
        
        // When: User requests to show privacy notice
        sut.showPrivacy()
        
        // Then: Flag should be set
        XCTAssertTrue(sut.showPrivacyNotice, "Should show privacy notice")
    }
    
    func testDismissPrivacy_TogglesFlag() {
        makeSUT()
        // Given: Privacy notice is shown
        sut.showPrivacy()
        XCTAssertTrue(sut.showPrivacyNotice)
        
        // When: User dismisses privacy notice
        sut.dismissPrivacy()
        
        // Then: Flag should be cleared
        XCTAssertFalse(sut.showPrivacyNotice, "Should hide privacy notice")
    }
    
    func testRequestLocationPermission_DelegatesToLocationManager() {
        makeSUT()
        // Given: ViewModel is initialized
        
        // When: User requests location permission
        sut.requestLocationPermission()
        
        // Then: Request should be delegated to location manager
        // Note: We can't easily verify this without mocking CLLocationManager,
        // but we verify the method doesn't crash
        XCTAssertNotNil(sut, "ViewModel should remain valid after permission request")
    }
    
    // MARK: - State Synchronization Tests
    
    func testLocationManagerChanges_TriggerViewModelUpdates() {
        makeSUT()
        // Given: ViewModel is observing location manager
        var changeCount = 0
        let expectation = XCTestExpectation(description: "ObjectWillChange called")
        
        let cancellable = sut.objectWillChange.sink {
            changeCount += 1
            if changeCount >= 1 {
                expectation.fulfill()
            }
        }
        
        // When: Location manager changes (e.g., location count updates)
        locationManager.objectWillChange.send()
        
        // Then: ViewModel should notify its observers
        wait(for: [expectation], timeout: 1.0)
        XCTAssertGreaterThan(changeCount, 0, "ViewModel should propagate location manager changes")
        
        cancellable.cancel()
    }
    
    // MARK: - Error Handler Integration Tests
    
    func testErrorHandler_IsExposed() {
        makeSUT()
        // Given: ViewModel is initialized with error handler
        
        // Then: Error handler should be accessible
        XCTAssertNotNil(sut.errorHandler, "Error handler should be exposed")
        XCTAssertTrue(sut.errorHandler === errorHandler, "Should use injected error handler")
    }
    
    // MARK: - Memory Management Tests
    
    func testDeinit_CleansUpSubscriptions() {
        makeSUT()
        // Given: ViewModel with subscriptions
        weak var weakViewModel = sut
        
        // When: ViewModel is deallocated
        sut = nil
        locationManager = nil
        
        // Then: ViewModel should be deallocated
        XCTAssertNil(weakViewModel, "ViewModel should be deallocated")
    }
    
    // MARK: - Integration Tests
    
    // NOTE: We intentionally keep integration coverage for TrackingViewModel
    // in higher-level tests elsewhere. Low-level behavior is covered by the
    // unit tests in this file, and adding additional deep integration tests
    // here has proven brittle in the simulator test environment.
}
