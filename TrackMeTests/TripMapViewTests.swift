import XCTest
import CoreData
import MapKit
import SwiftUI
@testable import TrackMe

/// Tests for TripMapView to diagnose map display issues
/// Validates location fetching, region calculation, and map rendering logic
class TripMapViewTests: XCTestCase {
    var persistenceController: PersistenceController!
    var context: NSManagedObjectContext!
    
    override func setUpWithError() throws {
        persistenceController = PersistenceController(inMemory: true)
        context = persistenceController.container.viewContext
    }
    
    override func tearDownWithError() throws {
        persistenceController = nil
        context = nil
    }
    
    // MARK: - Location Fetching Tests
    
    func testFetchLocationsWithValidSession() throws {
        // Create a session with locations
        let session = TrackingSession(context: context)
        session.id = UUID()
        session.startDate = Date()
        session.narrative = "Test Trip"
        
        // Add multiple locations
        let locations = createLocations(count: 5, for: session)
        try context.save()
        
        // Fetch locations for the session
        let fetchRequest: NSFetchRequest<LocationEntry> = LocationEntry.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "session == %@", session)
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: true)]
        
        let fetchedLocations = try context.fetch(fetchRequest)
        
        XCTAssertEqual(fetchedLocations.count, 5, "Should fetch all 5 locations")
        XCTAssertEqual(fetchedLocations.first?.latitude, locations.first?.latitude)
        XCTAssertEqual(fetchedLocations.last?.latitude, locations.last?.latitude)
    }
    
    func testFetchLocationsWithEmptySession() throws {
        // Create a session with NO locations
        let session = TrackingSession(context: context)
        session.id = UUID()
        session.startDate = Date()
        session.narrative = "Empty Trip"
        
        try context.save()
        
        // Fetch locations
        let fetchRequest: NSFetchRequest<LocationEntry> = LocationEntry.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "session == %@", session)
        
        let fetchedLocations = try context.fetch(fetchRequest)
        
        XCTAssertEqual(fetchedLocations.count, 0, "Should return empty array for session with no locations")
    }
    
    func testFetchLocationsOrdering() throws {
        // Create session with locations in specific order
        let session = TrackingSession(context: context)
        session.id = UUID()
        session.startDate = Date()
        session.narrative = "Ordered Trip"
        
        // Add locations with specific timestamps
        for i in 0..<5 {
            let location = LocationEntry(context: context)
            location.id = UUID()
            location.latitude = 37.7749 + Double(i) * 0.01
            location.longitude = -122.4194 + Double(i) * 0.01
            location.timestamp = Date().addingTimeInterval(TimeInterval(i * 60))
            location.accuracy = 10.0
            location.speed = 5.0
            session.addToLocations(location)
        }
        
        try context.save()
        
        // Fetch with ascending order
        let fetchRequest: NSFetchRequest<LocationEntry> = LocationEntry.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "session == %@", session)
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: true)]
        
        let locations = try context.fetch(fetchRequest)
        
        XCTAssertEqual(locations.count, 5)
        
        // Verify ordering
        for i in 0..<(locations.count - 1) {
            let current = locations[i].timestamp ?? Date.distantPast
            let next = locations[i + 1].timestamp ?? Date.distantPast
            XCTAssertLessThanOrEqual(current, next, "Locations should be in ascending timestamp order")
        }
    }
    
    // MARK: - Region Calculation Tests
    
    func testRegionCalculationWithSingleLocation() throws {
        let session = TrackingSession(context: context)
        session.id = UUID()
        session.startDate = Date()
        
        let location = LocationEntry(context: context)
        location.id = UUID()
        location.latitude = 37.7749
        location.longitude = -122.4194
        location.timestamp = Date()
        location.accuracy = 10.0
        session.addToLocations(location)
        
        try context.save()
        
        let locations = [location]
        let region = calculateRegion(from: locations)
        
        XCTAssertEqual(region.center.latitude, 37.7749, accuracy: 0.0001)
        XCTAssertEqual(region.center.longitude, -122.4194, accuracy: 0.0001)
        XCTAssertGreaterThan(region.span.latitudeDelta, 0.01, "Should have minimum span")
        XCTAssertGreaterThan(region.span.longitudeDelta, 0.01, "Should have minimum span")
    }
    
    func testRegionCalculationWithMultipleLocations() throws {
        let session = TrackingSession(context: context)
        session.id = UUID()
        session.startDate = Date()
        
        // Create locations in a rectangle pattern
        let locationData: [(Double, Double)] = [
            (37.7749, -122.4194),  // San Francisco
            (37.7849, -122.4194),  // North
            (37.7849, -122.4094),  // North-East
            (37.7749, -122.4094)   // East
        ]
        
        var locations: [LocationEntry] = []
        for (lat, lon) in locationData {
            let location = LocationEntry(context: context)
            location.id = UUID()
            location.latitude = lat
            location.longitude = lon
            location.timestamp = Date()
            location.accuracy = 10.0
            session.addToLocations(location)
            locations.append(location)
        }
        
        try context.save()
        
        let region = calculateRegion(from: locations)
        
        // Center should be between min and max
        let minLat = 37.7749
        let maxLat = 37.7849
        let minLon = -122.4194
        let maxLon = -122.4094
        let expectedCenterLat = (minLat + maxLat) / 2
        let expectedCenterLon = (minLon + maxLon) / 2
        
        XCTAssertEqual(region.center.latitude, expectedCenterLat, accuracy: 0.0001)
        XCTAssertEqual(region.center.longitude, expectedCenterLon, accuracy: 0.0001)
        
        // Span should encompass all locations with padding
        XCTAssertGreaterThanOrEqual(region.span.latitudeDelta, (maxLat - minLat) * 1.2)
        XCTAssertGreaterThanOrEqual(region.span.longitudeDelta, (maxLon - minLon) * 1.2)
    }
    
    func testRegionCalculationWithEmptyLocations() {
        let locations: [LocationEntry] = []
        let region = calculateRegion(from: locations)
        
        // Should return a default region
        XCTAssertEqual(region.center.latitude, 0.0, accuracy: 0.0001)
        XCTAssertEqual(region.center.longitude, 0.0, accuracy: 0.0001)
    }
    
    func testRegionCalculationWithCloseLocations() throws {
        let session = TrackingSession(context: context)
        session.id = UUID()
        session.startDate = Date()
        
        // Create locations very close together (walking distance)
        var locations: [LocationEntry] = []
        for i in 0..<5 {
            let location = LocationEntry(context: context)
            location.id = UUID()
            location.latitude = 37.7749 + Double(i) * 0.0001  // ~10 meters apart
            location.longitude = -122.4194 + Double(i) * 0.0001
            location.timestamp = Date().addingTimeInterval(TimeInterval(i * 10))
            location.accuracy = 10.0
            session.addToLocations(location)
            locations.append(location)
        }
        
        try context.save()
        
        let region = calculateRegion(from: locations)
        
        // Should apply minimum span of 0.01
        XCTAssertGreaterThanOrEqual(region.span.latitudeDelta, 0.01)
        XCTAssertGreaterThanOrEqual(region.span.longitudeDelta, 0.01)
    }
    
    // MARK: - Coordinate Conversion Tests
    
    func testCoordinateConversion() throws {
        let session = TrackingSession(context: context)
        session.id = UUID()
        session.startDate = Date()
        
        let locationData: [(Double, Double)] = [
            (37.7749, -122.4194),
            (40.7128, -74.0060),
            (51.5074, -0.1278)
        ]
        
        var locations: [LocationEntry] = []
        for (lat, lon) in locationData {
            let location = LocationEntry(context: context)
            location.id = UUID()
            location.latitude = lat
            location.longitude = lon
            location.timestamp = Date()
            location.accuracy = 10.0
            session.addToLocations(location)
            locations.append(location)
        }
        
        try context.save()
        
        // Convert to CLLocationCoordinate2D
        let coordinates = locations.map { CLLocationCoordinate2D(latitude: $0.latitude, longitude: $0.longitude) }
        
        XCTAssertEqual(coordinates.count, 3)
        XCTAssertEqual(coordinates[0].latitude, 37.7749, accuracy: 0.0001)
        XCTAssertEqual(coordinates[0].longitude, -122.4194, accuracy: 0.0001)
        XCTAssertEqual(coordinates[1].latitude, 40.7128, accuracy: 0.0001)
        XCTAssertEqual(coordinates[2].latitude, 51.5074, accuracy: 0.0001)
    }
    
    // MARK: - Start/End Location Tests
    
    func testStartLocationIdentification() throws {
        let session = TrackingSession(context: context)
        session.id = UUID()
        session.startDate = Date()
        
        let locations = createLocations(count: 5, for: session)
        try context.save()
        
        // Fetch sorted locations
        let fetchRequest: NSFetchRequest<LocationEntry> = LocationEntry.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "session == %@", session)
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: true)]
        let sortedLocations = try context.fetch(fetchRequest)
        
        let firstLocation = sortedLocations.first!
        
        // Test start location identification
        XCTAssertTrue(isStartLocation(firstLocation, in: sortedLocations))
        XCTAssertFalse(isStartLocation(sortedLocations[1], in: sortedLocations))
        XCTAssertFalse(isStartLocation(sortedLocations.last!, in: sortedLocations))
    }
    
    func testEndLocationIdentification() throws {
        let session = TrackingSession(context: context)
        session.id = UUID()
        session.startDate = Date()
        
        let locations = createLocations(count: 5, for: session)
        try context.save()
        
        // Fetch sorted locations
        let fetchRequest: NSFetchRequest<LocationEntry> = LocationEntry.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "session == %@", session)
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: true)]
        let sortedLocations = try context.fetch(fetchRequest)
        
        let lastLocation = sortedLocations.last!
        
        // Test end location identification
        XCTAssertTrue(isEndLocation(lastLocation, in: sortedLocations))
        XCTAssertFalse(isEndLocation(sortedLocations[0], in: sortedLocations))
        XCTAssertFalse(isEndLocation(sortedLocations[1], in: sortedLocations))
    }
    
    // MARK: - Route Polyline Tests
    
    func testPolylineCreationWithMultipleCoordinates() throws {
        let coordinates: [CLLocationCoordinate2D] = [
            CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
            CLLocationCoordinate2D(latitude: 37.7849, longitude: -122.4194),
            CLLocationCoordinate2D(latitude: 37.7849, longitude: -122.4094)
        ]
        
        let polyline = MKPolyline(coordinates: coordinates, count: coordinates.count)
        
        XCTAssertEqual(polyline.pointCount, 3)
        XCTAssertNotNil(polyline.boundingMapRect)
    }
    
    func testPolylineCreationWithTwoCoordinates() {
        let coordinates: [CLLocationCoordinate2D] = [
            CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
            CLLocationCoordinate2D(latitude: 37.7849, longitude: -122.4194)
        ]
        
        let polyline = MKPolyline(coordinates: coordinates, count: coordinates.count)
        
        XCTAssertEqual(polyline.pointCount, 2)
    }
    
    func testPolylineCreationWithSingleCoordinate() {
        // Should not create a route with single coordinate
        let coordinates: [CLLocationCoordinate2D] = [
            CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194)
        ]
        
        XCTAssertLessThan(coordinates.count, 2, "Need at least 2 coordinates for a route")
    }
    
    // MARK: - Session Validation Tests
    
    func testSessionWithLocationsIsValid() throws {
        let session = TrackingSession(context: context)
        session.id = UUID()
        session.startDate = Date()
        session.narrative = "Valid Trip"
        
        let locations = createLocations(count: 10, for: session)
        try context.save()
        
        XCTAssertNotNil(session.id)
        XCTAssertNotNil(session.startDate)
        XCTAssertEqual(session.locations?.count, 10)
        XCTAssertFalse(locations.isEmpty)
    }
    
    func testSessionWithoutLocationsIsEmpty() throws {
        let session = TrackingSession(context: context)
        session.id = UUID()
        session.startDate = Date()
        session.narrative = "Empty Trip"
        
        try context.save()
        
        let fetchRequest: NSFetchRequest<LocationEntry> = LocationEntry.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "session == %@", session)
        let locations = try context.fetch(fetchRequest)
        
        XCTAssertTrue(locations.isEmpty, "Session should have no locations")
    }
    
    // MARK: - Map Display Issues Tests
    
    func testSessionLocationRelationship() throws {
        // This test validates the Core Data relationship
        let session = TrackingSession(context: context)
        session.id = UUID()
        session.startDate = Date()
        
        let location1 = LocationEntry(context: context)
        location1.id = UUID()
        location1.latitude = 37.7749
        location1.longitude = -122.4194
        location1.timestamp = Date()
        location1.accuracy = 10.0
        
        session.addToLocations(location1)
        
        try context.save()
        
        // Verify relationship
        XCTAssertNotNil(location1.session, "Location should have session relationship")
        XCTAssertEqual(location1.session?.id, session.id, "Location should reference correct session")
        XCTAssertTrue(session.locations?.contains(location1) ?? false, "Session should contain location")
    }
    
    func testLocationFetchAfterSave() throws {
        // Test that locations can be fetched immediately after save
        let session = TrackingSession(context: context)
        session.id = UUID()
        session.startDate = Date()
        session.narrative = "Immediate Fetch Test"
        
        for i in 0..<5 {
            let location = LocationEntry(context: context)
            location.id = UUID()
            location.latitude = 37.7749 + Double(i) * 0.01
            location.longitude = -122.4194 + Double(i) * 0.01
            location.timestamp = Date().addingTimeInterval(TimeInterval(i * 60))
            location.accuracy = 10.0
            session.addToLocations(location)
        }
        
        try context.save()
        
        // Immediate fetch
        let fetchRequest: NSFetchRequest<LocationEntry> = LocationEntry.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "session == %@", session)
        let fetchedLocations = try context.fetch(fetchRequest)
        
        XCTAssertEqual(fetchedLocations.count, 5, "Should immediately fetch all saved locations")
    }
    
    func testMapRegionIsValid() throws {
        let session = TrackingSession(context: context)
        session.id = UUID()
        session.startDate = Date()
        
        let locations = createLocations(count: 3, for: session)
        try context.save()
        
        let region = calculateRegion(from: locations)
        
        // Validate region coordinates are valid
        XCTAssertTrue(CLLocationCoordinate2DIsValid(region.center), "Region center should be valid")
        XCTAssertGreaterThan(region.span.latitudeDelta, 0, "Latitude span should be positive")
        XCTAssertGreaterThan(region.span.longitudeDelta, 0, "Longitude span should be positive")
        XCTAssertLessThan(region.span.latitudeDelta, 180, "Latitude span should be reasonable")
        XCTAssertLessThan(region.span.longitudeDelta, 360, "Longitude span should be reasonable")
    }
    
    func testLocationEntriesHaveValidCoordinates() throws {
        let session = TrackingSession(context: context)
        session.id = UUID()
        session.startDate = Date()
        
        let locations = createLocations(count: 5, for: session)
        try context.save()
        
        for location in locations {
            let coordinate = CLLocationCoordinate2D(latitude: location.latitude, longitude: location.longitude)
            XCTAssertTrue(CLLocationCoordinate2DIsValid(coordinate), "Location coordinate should be valid")
            XCTAssertGreaterThanOrEqual(location.latitude, -90)
            XCTAssertLessThanOrEqual(location.latitude, 90)
            XCTAssertGreaterThanOrEqual(location.longitude, -180)
            XCTAssertLessThanOrEqual(location.longitude, 180)
        }
    }
    
    // MARK: - Helper Methods
    
    private func createLocations(count: Int, for session: TrackingSession) -> [LocationEntry] {
        var locations: [LocationEntry] = []
        for i in 0..<count {
            let location = LocationEntry(context: context)
            location.id = UUID()
            location.latitude = 37.7749 + Double(i) * 0.001
            location.longitude = -122.4194 + Double(i) * 0.001
            location.timestamp = Date().addingTimeInterval(TimeInterval(i * 30))
            location.accuracy = 10.0
            location.speed = 5.0
            location.altitude = 100.0
            location.course = Double(i * 10)
            session.addToLocations(location)
            locations.append(location)
        }
        return locations
    }
    
    private func calculateRegion(from locations: [LocationEntry]) -> MKCoordinateRegion {
        guard !locations.isEmpty else {
            return MKCoordinateRegion()
        }
        
        let latitudes = locations.map { $0.latitude }
        let longitudes = locations.map { $0.longitude }
        let minLat = latitudes.min() ?? 0
        let maxLat = latitudes.max() ?? 0
        let minLon = longitudes.min() ?? 0
        let maxLon = longitudes.max() ?? 0
        let centerLat = (minLat + maxLat) / 2
        let centerLon = (minLon + maxLon) / 2
        let spanLat = max(maxLat - minLat, 0.01) * 1.2
        let spanLon = max(maxLon - minLon, 0.01) * 1.2
        
        return MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: centerLat, longitude: centerLon),
            span: MKCoordinateSpan(latitudeDelta: spanLat, longitudeDelta: spanLon)
        )
    }
    
    private func isStartLocation(_ location: LocationEntry, in locations: [LocationEntry]) -> Bool {
        return location.id == locations.first?.id
    }
    
    private func isEndLocation(_ location: LocationEntry, in locations: [LocationEntry]) -> Bool {
        return location.id == locations.last?.id
    }
}
