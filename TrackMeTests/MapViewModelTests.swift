import XCTest
import CoreData
import CoreLocation
import MapKit
@testable import TrackMe

@MainActor
final class MapViewModelTests: XCTestCase {
    var viewContext: NSManagedObjectContext!
    var session: TrackingSession!
    var viewModel: MapViewModel!
    
    override func setUp() async throws {
        try await super.setUp()
        viewContext = PersistenceController.preview.container.viewContext
        
        // Create a test session
        session = TrackingSession(context: viewContext)
        session.id = UUID()
        session.narrative = "Test Trip"
        session.startDate = Date()
        session.endDate = Date()
        
        try viewContext.save()
        
        viewModel = MapViewModel(session: session, viewContext: viewContext)
    }
    
    override func tearDown() async throws {
        viewModel = nil
        session = nil
        viewContext = nil
        try await super.tearDown()
    }
    
    // MARK: - Initialization Tests
    
    func testInitialization() {
        XCTAssertNotNil(viewModel)
        XCTAssertEqual(viewModel.locations.count, 0)
        XCTAssertFalse(viewModel.hasLocations)
        XCTAssertTrue(viewModel.showRoute)
        XCTAssertNil(viewModel.selectedLocation)
    }
    
    // MARK: - Location Loading Tests
    
    func testLoadLocations_WithNoLocations() {
        // When
        viewModel.loadLocations()
        
        // Then
        XCTAssertEqual(viewModel.locations.count, 0)
        XCTAssertFalse(viewModel.hasLocations)
    }
    
    func testLoadLocations_WithLocations() {
        // Given
        let location1 = LocationEntry(context: viewContext)
        location1.id = UUID()
        location1.latitude = 37.7749
        location1.longitude = -122.4194
        location1.timestamp = Date()
        location1.session = session
        
        let location2 = LocationEntry(context: viewContext)
        location2.id = UUID()
        location2.latitude = 37.7750
        location2.longitude = -122.4195
        location2.timestamp = Date().addingTimeInterval(60)
        location2.session = session
        
        try? viewContext.save()
        
        // When
        viewModel.loadLocations()
        
        // Then
        XCTAssertEqual(viewModel.locations.count, 2)
        XCTAssertTrue(viewModel.hasLocations)
    }
    
    // MARK: - Route Toggle Tests
    
    func testToggleRoute() {
        // Given
        let initialState = viewModel.showRoute
        
        // When
        viewModel.toggleRoute()
        
        // Then
        XCTAssertNotEqual(viewModel.showRoute, initialState)
        
        // When - toggle again
        viewModel.toggleRoute()
        
        // Then
        XCTAssertEqual(viewModel.showRoute, initialState)
    }
    
    // MARK: - Location Selection Tests
    
    func testSelectLocation() {
        // Given
        let location = LocationEntry(context: viewContext)
        location.id = UUID()
        location.latitude = 37.7749
        location.longitude = -122.4194
        location.session = session
        try? viewContext.save()
        
        viewModel.loadLocations()
        
        // When
        viewModel.selectLocation(location)
        
        // Then
        XCTAssertNotNil(viewModel.selectedLocation)
        XCTAssertEqual(viewModel.selectedLocation?.id, location.id)
    }
    
    func testDeselectLocation() {
        // Given
        let location = LocationEntry(context: viewContext)
        location.id = UUID()
        location.latitude = 37.7749
        location.longitude = -122.4194
        location.session = session
        try? viewContext.save()
        
        viewModel.loadLocations()
        viewModel.selectLocation(location)
        
        // When
        viewModel.deselectLocation()
        
        // Then
        XCTAssertNil(viewModel.selectedLocation)
    }
    
    func testSelectLocation_TogglesSelection() {
        // Given
        let location = LocationEntry(context: viewContext)
        location.id = UUID()
        location.latitude = 37.7749
        location.longitude = -122.4194
        location.session = session
        try? viewContext.save()
        
        viewModel.loadLocations()
        
        // When - select
        viewModel.selectLocation(location)
        
        // Then
        XCTAssertNotNil(viewModel.selectedLocation)
        
        // When - select again (deselect)
        viewModel.selectLocation(location)
        
        // Then
        XCTAssertNil(viewModel.selectedLocation)
    }
    
    // MARK: - Start/End Location Tests
    
    func testIsStartLocation() {
        // Given
        let location1 = LocationEntry(context: viewContext)
        location1.id = UUID()
        location1.latitude = 37.7749
        location1.longitude = -122.4194
        location1.timestamp = Date()
        location1.session = session
        
        let location2 = LocationEntry(context: viewContext)
        location2.id = UUID()
        location2.latitude = 37.7750
        location2.longitude = -122.4195
        location2.timestamp = Date().addingTimeInterval(60)
        location2.session = session
        
        try? viewContext.save()
        viewModel.loadLocations()
        
        // Then
        XCTAssertTrue(viewModel.isStartLocation(location1))
        XCTAssertFalse(viewModel.isStartLocation(location2))
    }
    
    func testIsEndLocation() {
        // Given
        let location1 = LocationEntry(context: viewContext)
        location1.id = UUID()
        location1.latitude = 37.7749
        location1.longitude = -122.4194
        location1.timestamp = Date()
        location1.session = session
        
        let location2 = LocationEntry(context: viewContext)
        location2.id = UUID()
        location2.latitude = 37.7750
        location2.longitude = -122.4195
        location2.timestamp = Date().addingTimeInterval(60)
        location2.session = session
        
        try? viewContext.save()
        viewModel.loadLocations()
        
        // Then
        XCTAssertFalse(viewModel.isEndLocation(location1))
        XCTAssertTrue(viewModel.isEndLocation(location2))
    }
    
    // MARK: - Route Polyline Tests
    
    func testRoutePolylines_WithNoLocations() {
        // When
        viewModel.loadLocations()
        
        // Then
        XCTAssertEqual(viewModel.routePolylines.count, 0)
    }
    
    func testRoutePolylines_WithOneLocation() {
        // Given
        let location = LocationEntry(context: viewContext)
        location.id = UUID()
        location.latitude = 37.7749
        location.longitude = -122.4194
        location.timestamp = Date()
        location.session = session
        
        try? viewContext.save()
        
        // When
        viewModel.loadLocations()
        
        // Then
        XCTAssertEqual(viewModel.routePolylines.count, 0)
    }
    
    func testRoutePolylines_WithMultipleLocations() {
        // Given
        for i in 0..<5 {
            let location = LocationEntry(context: viewContext)
            location.id = UUID()
            location.latitude = 37.7749 + Double(i) * 0.001
            location.longitude = -122.4194 + Double(i) * 0.001
            location.timestamp = Date().addingTimeInterval(Double(i * 60))
            location.session = session
        }
        
        try? viewContext.save()
        
        // When
        viewModel.loadLocations()
        
        // Then
        XCTAssertGreaterThan(viewModel.routePolylines.count, 0)
    }
    
    // MARK: - Share Tests
    
    func testShareSession_WithNoLocations() {
        // When
        viewModel.shareSession()
        
        // Then - should not crash, and share URL should remain nil
        XCTAssertNil(viewModel.shareURL)
        XCTAssertFalse(viewModel.isPresentingShare)
    }
    
    func testShareSession_WithLocations() async {
        // Given
        let location = LocationEntry(context: viewContext)
        location.id = UUID()
        location.latitude = 37.7749
        location.longitude = -122.4194
        location.timestamp = Date()
        location.session = session
        
        try? viewContext.save()
        viewModel.loadLocations()
        
        // When
        viewModel.shareSession()
        
        // Wait for async export to complete
        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
        
        // Then
        // Note: The actual export might fail in test environment, 
        // but we're testing that it doesn't crash
    }
}
