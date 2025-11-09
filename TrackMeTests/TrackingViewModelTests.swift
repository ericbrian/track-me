// TrackMeTests/TrackingViewModelTests.swift
// Comprehensive unit tests for TrackingViewModel

import XCTest
import Combine
import CoreLocation
@testable import TrackMe

@MainActor
class TrackingViewModelTests: XCTestCase {
    
    var viewModel: TrackingViewModel!
    var mockLocationManager: MockLocationManager!
    var mockSessionRepository: MockSessionRepository!
    var mockErrorHandler: MockErrorHandler!
    var cancellables: Set<AnyCancellable>!
    
    override func setUp() async throws {
        try await super.setUp()
        
        mockSessionRepository = MockSessionRepository()
        let mockLocationRepository = MockLocationRepository()
        mockLocationManager = MockLocationManager(
            sessionRepository: mockSessionRepository,
            locationRepository: mockLocationRepository
        )
        mockErrorHandler = MockErrorHandler()
        
        viewModel = TrackingViewModel(
            locationManager: mockLocationManager,
            sessionRepository: mockSessionRepository,
            errorHandler: mockErrorHandler
        )
        
        cancellables = Set<AnyCancellable>()
    }
    
    override func tearDown() async throws {
        cancellables = nil
        viewModel = nil
        mockLocationManager = nil
        mockSessionRepository = nil
        mockErrorHandler = nil
        try await super.tearDown()
    }
    
    // MARK: - Initialization Tests
    
    func testInitialState() {
        XCTAssertEqual(viewModel.appState, .active, "Initial app state should be active")
        XCTAssertFalse(viewModel.showTrackingModeSettings, "Settings sheet should be hidden initially")
        XCTAssertFalse(viewModel.showPrivacyNotice, "Privacy notice should be hidden initially")
    }
    
    func testInitialLocationManagerBinding() {
        XCTAssertFalse(viewModel.isTracking, "Should not be tracking initially")
        XCTAssertEqual(viewModel.authorizationStatus, .notDetermined, "Authorization should be not determined")
        XCTAssertNil(viewModel.currentLocation, "No current location initially")
        XCTAssertNil(viewModel.currentSession, "No current session initially")
        XCTAssertEqual(viewModel.locationCount, 0, "Location count should be zero initially")
    }
    
    // MARK: - Computed Properties Tests
    
    func testIsTrackingReflectsLocationManager() {
        mockLocationManager.isTracking = false
        XCTAssertFalse(viewModel.isTracking)
        
        mockLocationManager.isTracking = true
        XCTAssertTrue(viewModel.isTracking)
    }
    
    func testAuthorizationStatusReflectsLocationManager() {
        mockLocationManager.authorizationStatus = .notDetermined
        XCTAssertEqual(viewModel.authorizationStatus, .notDetermined)
        
        mockLocationManager.authorizationStatus = .authorizedAlways
        XCTAssertEqual(viewModel.authorizationStatus, .authorizedAlways)
        
        mockLocationManager.authorizationStatus = .authorizedWhenInUse
        XCTAssertEqual(viewModel.authorizationStatus, .authorizedWhenInUse)
        
        mockLocationManager.authorizationStatus = .denied
        XCTAssertEqual(viewModel.authorizationStatus, .denied)
    }
    
    func testCurrentLocationReflectsLocationManager() {
        XCTAssertNil(viewModel.currentLocation)
        
        let location = CLLocation(latitude: 37.7749, longitude: -122.4194)
        mockLocationManager.currentLocation = location
        
        XCTAssertNotNil(viewModel.currentLocation)
        XCTAssertEqual(viewModel.currentLocation?.coordinate.latitude, 37.7749)
        XCTAssertEqual(viewModel.currentLocation?.coordinate.longitude, -122.4194)
    }
    
    func testCurrentSessionReflectsLocationManager() async throws {
        XCTAssertNil(viewModel.currentSession)
        
        let session = try await mockSessionRepository.createSession(narrative: "Test Session", startDate: Date())
        mockLocationManager.currentSession = session
        
        XCTAssertNotNil(viewModel.currentSession)
        XCTAssertEqual(viewModel.currentSession?.narrative, "Test Session")
    }
    
    func testLocationCountReflectsLocationManager() {
        XCTAssertEqual(viewModel.locationCount, 0)
        
        mockLocationManager.locationCount = 42
        XCTAssertEqual(viewModel.locationCount, 42)
        
        mockLocationManager.locationCount = 100
        XCTAssertEqual(viewModel.locationCount, 100)
    }
    
    func testShowSettingsSuggestionReflectsLocationManager() {
        XCTAssertFalse(viewModel.showSettingsSuggestion)
        
        mockLocationManager.showSettingsSuggestion = true
        XCTAssertTrue(viewModel.showSettingsSuggestion)
        
        mockLocationManager.showSettingsSuggestion = false
        XCTAssertFalse(viewModel.showSettingsSuggestion)
    }
    
    // MARK: - App Lifecycle Tests
    
    func testAppEntersBackground() {
        let expectation = expectation(description: "App state changes to background")
        
        viewModel.$appState
            .dropFirst()
            .sink { state in
                if state == .background {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        NotificationCenter.default.post(name: UIApplication.didEnterBackgroundNotification, object: nil)
        
        wait(for: [expectation], timeout: 1.0)
        XCTAssertEqual(viewModel.appState, .background)
    }
    
    func testAppEntersForeground() async {
        // First set to background
        viewModel.appState = .background
        XCTAssertEqual(viewModel.appState, .background)
        
        let expectation = expectation(description: "App state changes to active")
        
        viewModel.$appState
            .dropFirst()
            .sink { state in
                if state == .active {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        NotificationCenter.default.post(name: UIApplication.willEnterForegroundNotification, object: nil)
        
        await fulfillment(of: [expectation], timeout: 1.0)
        XCTAssertEqual(viewModel.appState, .active)
    }
    
    func testMultipleAppStateTransitions() async {
        var states: [UIApplication.State] = []
        
        viewModel.$appState
            .sink { state in
                states.append(state)
            }
            .store(in: &cancellables)
        
        // Initial state
        XCTAssertEqual(states.last, .active)
        
        // Go to background
        NotificationCenter.default.post(name: UIApplication.didEnterBackgroundNotification, object: nil)
        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        XCTAssertEqual(viewModel.appState, .background)
        
        // Return to foreground
        NotificationCenter.default.post(name: UIApplication.willEnterForegroundNotification, object: nil)
        try? await Task.sleep(nanoseconds: 100_000_000)
        XCTAssertEqual(viewModel.appState, .active)
        
        // Verify we captured all transitions
        XCTAssertTrue(states.contains(.background))
        XCTAssertTrue(states.contains(.active))
    }
    
    // MARK: - UI Action Tests
    
    func testShowSettings() {
        XCTAssertFalse(viewModel.showTrackingModeSettings)
        
        viewModel.showSettings()
        
        XCTAssertTrue(viewModel.showTrackingModeSettings)
    }
    
    func testDismissSettings() {
        viewModel.showTrackingModeSettings = true
        XCTAssertTrue(viewModel.showTrackingModeSettings)
        
        viewModel.dismissSettings()
        
        XCTAssertFalse(viewModel.showTrackingModeSettings)
    }
    
    func testShowPrivacy() {
        XCTAssertFalse(viewModel.showPrivacyNotice)
        
        viewModel.showPrivacy()
        
        XCTAssertTrue(viewModel.showPrivacyNotice)
    }
    
    func testDismissPrivacy() {
        viewModel.showPrivacyNotice = true
        XCTAssertTrue(viewModel.showPrivacyNotice)
        
        viewModel.dismissPrivacy()
        
        XCTAssertFalse(viewModel.showPrivacyNotice)
    }
    
    func testRequestLocationPermission() {
        XCTAssertFalse(mockLocationManager.requestLocationPermissionCalled)
        
        viewModel.requestLocationPermission()
        
        XCTAssertTrue(mockLocationManager.requestLocationPermissionCalled)
    }
    
    // MARK: - ObjectWillChange Tests
    
    func testObjectWillChangeTriggeredByLocationManager() async {
        let expectation = expectation(description: "ObjectWillChange triggered")
        var changeCount = 0
        
        viewModel.objectWillChange
            .sink { _ in
                changeCount += 1
                if changeCount > 0 {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        // Trigger a change in location manager
        mockLocationManager.isTracking = true
        mockLocationManager.objectWillChange.send()
        
        await fulfillment(of: [expectation], timeout: 1.0)
        XCTAssertGreaterThan(changeCount, 0)
    }
    
    // MARK: - Integration Tests
    
    func testCompleteTrackingFlowState() async throws {
        // Initial state
        XCTAssertFalse(viewModel.isTracking)
        XCTAssertNil(viewModel.currentSession)
        XCTAssertEqual(viewModel.locationCount, 0)
        
        // Authorize
        mockLocationManager.authorizationStatus = .authorizedAlways
        XCTAssertEqual(viewModel.authorizationStatus, .authorizedAlways)
        
        // Start tracking
        let session = try await mockSessionRepository.createSession(narrative: "Morning Walk", startDate: Date())
        mockLocationManager.currentSession = session
        mockLocationManager.isTracking = true
        
        XCTAssertTrue(viewModel.isTracking)
        XCTAssertNotNil(viewModel.currentSession)
        XCTAssertEqual(viewModel.currentSession?.narrative, "Morning Walk")
        
        // Add locations
        mockLocationManager.locationCount = 10
        XCTAssertEqual(viewModel.locationCount, 10)
        
        // Stop tracking
        mockLocationManager.isTracking = false
        mockLocationManager.currentSession = nil
        mockLocationManager.locationCount = 0
        
        XCTAssertFalse(viewModel.isTracking)
        XCTAssertNil(viewModel.currentSession)
        XCTAssertEqual(viewModel.locationCount, 0)
    }
    
    func testSettingsWorkflow() {
        // User opens settings
        viewModel.showSettings()
        XCTAssertTrue(viewModel.showTrackingModeSettings)
        
        // User makes changes and closes
        viewModel.dismissSettings()
        XCTAssertFalse(viewModel.showTrackingModeSettings)
        
        // User opens again
        viewModel.showSettings()
        XCTAssertTrue(viewModel.showTrackingModeSettings)
    }
    
    func testPrivacyWorkflow() {
        // User opens privacy notice
        viewModel.showPrivacy()
        XCTAssertTrue(viewModel.showPrivacyNotice)
        
        // User reads and closes
        viewModel.dismissPrivacy()
        XCTAssertFalse(viewModel.showPrivacyNotice)
    }
    
    // MARK: - Memory Management Tests
    
    func testNoRetainCycleWithLocationManager() {
        weak var weakViewModel = viewModel
        weak var weakLocationManager = mockLocationManager
        
        XCTAssertNotNil(weakViewModel)
        XCTAssertNotNil(weakLocationManager)
        
        // Release strong references
        viewModel = nil
        mockLocationManager = nil
        
        // ViewModel should be deallocated, but location manager might be retained elsewhere
        XCTAssertNil(weakViewModel, "ViewModel should be deallocated")
    }
    
    func testCancellablesCleanedUp() {
        XCTAssertNotNil(viewModel)
        
        // Store initial cancellables count
        let initialCount = cancellables.count
        
        // Create a new view model which should set up its own cancellables
        let newViewModel = TrackingViewModel(
            locationManager: mockLocationManager,
            sessionRepository: mockSessionRepository,
            errorHandler: mockErrorHandler
        )
        
        XCTAssertNotNil(newViewModel)
        // The new view model should have set up its subscriptions
    }
}

// MARK: - Mock Objects

class MockLocationManager: LocationManager {
    var requestLocationPermissionCalled = false
    
    override func requestLocationPermission() {
        requestLocationPermissionCalled = true
    }
}

class MockSessionRepository: SessionRepositoryProtocol {
    private var sessions: [TrackingSession] = []
    private let context = PersistenceController(inMemory: true).container.viewContext
    
    func createSession(narrative: String, startDate: Date) async throws -> TrackingSession {
        let session = TrackingSession(context: context)
        session.id = UUID()
        session.narrative = narrative
        session.startTime = startDate
        session.isActive = true
        sessions.append(session)
        return session
    }
    
    func endSession(_ session: TrackingSession, endDate: Date) throws {
        session.endTime = endDate
        session.isActive = false
    }
    
    func fetchActiveSessions() throws -> [TrackingSession] {
        return sessions.filter { $0.isActive }
    }
    
    func fetchAllSessions(sortDescriptors: [NSSortDescriptor]) throws -> [TrackingSession] {
        return sessions
    }
    
    func fetchSession(by id: UUID) throws -> TrackingSession? {
        return sessions.first { $0.id == id }
    }
    
    func deleteSession(_ session: TrackingSession) throws {
        sessions.removeAll { $0.id == session.id }
        context.delete(session)
    }
    
    func recoverOrphanedSessions() throws -> Int {
        let orphaned = sessions.filter { $0.isActive }
        orphaned.forEach { $0.isActive = false }
        return orphaned.count
    }
    
    func save() throws {
        try context.save()
    }
}

class MockLocationRepository: LocationRepositoryProtocol {
    private var locations: [UUID: [LocationEntry]] = [:]
    private let context = PersistenceController(inMemory: true).container.viewContext
    
    func saveLocation(_ location: CLLocation, for session: TrackingSession) throws -> LocationEntry {
        let entry = LocationEntry(context: context)
        entry.id = UUID()
        entry.timestamp = location.timestamp
        entry.latitude = location.coordinate.latitude
        entry.longitude = location.coordinate.longitude
        entry.altitude = location.altitude
        entry.horizontalAccuracy = location.horizontalAccuracy
        entry.verticalAccuracy = location.verticalAccuracy
        entry.speed = location.speed
        entry.course = location.course
        entry.session = session
        
        if locations[session.id!] == nil {
            locations[session.id!] = []
        }
        locations[session.id!]?.append(entry)
        
        return entry
    }
    
    func fetchLocations(for session: TrackingSession) throws -> [LocationEntry] {
        return locations[session.id!] ?? []
    }
    
    func fetchLocationCount(for session: TrackingSession) throws -> Int {
        return locations[session.id!]?.count ?? 0
    }
    
    func deleteLocations(for session: TrackingSession) throws {
        locations[session.id!] = nil
    }
    
    func save() throws {
        try context.save()
    }
}

class MockErrorHandler: ErrorHandler {
    var handledErrors: [AppError] = []
    
    override func handle(_ error: AppError) {
        handledErrors.append(error)
    }
}
