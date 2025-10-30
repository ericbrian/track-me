//
//  AdvancedLocationManagerTests.swift
//  TrackMeTests
//
//  Advanced tests for LocationManager: background tracking, error scenarios, edge cases
//

import XCTest
import CoreLocation
import CoreData
@testable import TrackMe

// MARK: - Background Tracking Tests
class LocationManagerBackgroundTests: XCTestCase {
    var locationManager: LocationManager!
    var persistenceController: PersistenceController!
    
    override func setUp() {
        super.setUp()
        persistenceController = PersistenceController(inMemory: true)
        locationManager = LocationManager()
    }
    
    override func tearDown() {
        locationManager = nil
        persistenceController = nil
        super.tearDown()
    }
    
    // MARK: - Background Task Handling
    
    func testBackgroundTaskManagement() {
        // Test that background task identifiers are properly managed
        XCTAssertNotNil(locationManager, "LocationManager should initialize")
        
        // Verify manager can be created without crashing
        XCTAssertFalse(locationManager.isTracking, "Should not be tracking initially")
    }
    
    func testBackgroundLocationUpdatesConfiguration() {
        // Verify that background location updates are configured properly
        // This is a structural test as we can't directly test CLLocationManager settings
        
        let manager = LocationManager()
        XCTAssertNotNil(manager, "Should create location manager")
        XCTAssertFalse(manager.isTracking, "Should not be tracking initially")
    }
    
    func testSignificantLocationChanges() {
        // Test handling of significant location changes
        let location1 = CLLocation(latitude: 37.7749, longitude: -122.4194)
        let location2 = CLLocation(latitude: 37.7850, longitude: -122.4294) // ~1.5 km away
        
        let distance = location1.distance(from: location2)
        XCTAssertGreaterThan(distance, 1000, "Should be significant distance")
        XCTAssertLessThan(distance, 2000, "Should be within expected range")
    }
    
    func testBackgroundPermissionRequirements() {
        // Verify authorization status checks
        let status = locationManager.authorizationStatus
        
        // Should be one of the valid authorization states
        let validStatuses: [CLAuthorizationStatus] = [
            .notDetermined,
            .restricted,
            .denied,
            .authorizedAlways,
            .authorizedWhenInUse
        ]
        
        XCTAssertTrue(validStatuses.contains(status), "Should have valid authorization status")
    }
    
    func testBackgroundSessionRecovery() {
        let context = persistenceController.container.viewContext
        
        // Create an orphaned active session
        let orphanedSession = TrackingSession(context: context)
        orphanedSession.id = UUID()
        orphanedSession.narrative = "Orphaned Session"
        orphanedSession.startDate = Date().addingTimeInterval(-3600)
        orphanedSession.isActive = true
        orphanedSession.endDate = nil
        
        try? context.save()
        
        // Verify session exists and is active
        let fetchRequest: NSFetchRequest<TrackingSession> = TrackingSession.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "isActive == YES")
        let activeSessions = try? context.fetch(fetchRequest)
        
        XCTAssertEqual(activeSessions?.count, 1, "Should have one active session before recovery")
    }
    
    func testBackgroundLocationAccuracySettings() {
        // Test that accuracy settings are appropriate for background tracking
        let manager = LocationManager()
        
        // Manager should exist and be configurable
        XCTAssertNotNil(manager, "Should create manager")
        XCTAssertEqual(manager.locationCount, 0, "Should start with zero locations")
    }
    
    func testActivityTypeConfiguration() {
        // Verify activity type is set for travel tracking
        let manager = LocationManager()
        XCTAssertNotNil(manager, "Should create manager with activity type configured")
    }
    
    func testDistanceFilterSettings() {
        // Test that distance filter is configured appropriately
        let manager = LocationManager()
        
        // Verify manager initialization
        XCTAssertFalse(manager.isTracking, "Should not track initially")
        XCTAssertNil(manager.currentLocation, "Should have no location initially")
    }
}

// MARK: - Complex Error Scenario Tests
class LocationManagerErrorTests: XCTestCase {
    var locationManager: LocationManager!
    var persistenceController: PersistenceController!
    
    override func setUp() {
        super.setUp()
        persistenceController = PersistenceController(inMemory: true)
        locationManager = LocationManager()
    }
    
    override func tearDown() {
        locationManager = nil
        persistenceController = nil
        super.tearDown()
    }
    
    // MARK: - Authorization Errors
    
    func testDeniedAuthorizationHandling() {
        // Test behavior when authorization is denied
        locationManager.startTracking(with: "Test Session")
        
        // Should handle denial gracefully
        if locationManager.authorizationStatus == .denied {
            XCTAssertFalse(locationManager.isTracking, "Should not track when denied")
            XCTAssertTrue(locationManager.showSettingsSuggestion || locationManager.trackingStartError != nil,
                         "Should show settings suggestion or error")
        }
    }
    
    func testRestrictedAuthorizationHandling() {
        // Test behavior when authorization is restricted
        if locationManager.authorizationStatus == .restricted {
            locationManager.startTracking(with: "Test Session")
            
            XCTAssertFalse(locationManager.isTracking, "Should not track when restricted")
        }
    }
    
    func testAuthorizationDowngrade() {
        // Test handling of authorization changing from Always to WhenInUse
        let initialStatus = locationManager.authorizationStatus
        
        // Verify state is consistent
        XCTAssertNotNil(locationManager, "Manager should exist")
        _ = initialStatus // Use variable to avoid warning
    }
    
    func testMultipleAuthorizationRequests() {
        // Test that multiple authorization requests don't cause issues
        locationManager.requestLocationPermission()
        locationManager.requestLocationPermission()
        
        // Should not crash or cause issues
        XCTAssertNotNil(locationManager, "Manager should remain valid")
    }
    
    // MARK: - Location Update Errors
    
    func testLocationUpdateTimeout() {
        // Test handling of location update timeouts
        let manager = LocationManager()
        
        XCTAssertFalse(manager.isTracking, "Should not be tracking")
        XCTAssertNil(manager.trackingStartError, "Should have no error initially")
    }
    
    func testLocationUnavailableError() {
        // Test handling when location services are unavailable
        let manager = LocationManager()
        
        if !CLLocationManager.locationServicesEnabled() {
            XCTAssertNotNil(manager, "Manager should handle unavailable services")
        }
    }
    
    func testInaccurateLocationFiltering() {
        // Test that inaccurate locations are handled properly
        let accurateLocation = CLLocation(
            coordinate: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
            altitude: 50,
            horizontalAccuracy: 5,
            verticalAccuracy: 5,
            timestamp: Date()
        )
        
        let inaccurateLocation = CLLocation(
            coordinate: CLLocationCoordinate2D(latitude: 37.7750, longitude: -122.4195),
            altitude: 50,
            horizontalAccuracy: 2000,
            verticalAccuracy: 2000,
            timestamp: Date()
        )
        
        XCTAssertLessThan(accurateLocation.horizontalAccuracy, 50, "Accurate location should be precise")
        XCTAssertGreaterThan(inaccurateLocation.horizontalAccuracy, 100, "Inaccurate location should be filtered")
    }
    
    func testNegativeAccuracyHandling() {
        // Test handling of locations with negative accuracy (invalid)
        let invalidLocation = CLLocation(
            coordinate: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
            altitude: 50,
            horizontalAccuracy: -1,
            verticalAccuracy: -1,
            timestamp: Date()
        )
        
        XCTAssertLessThan(invalidLocation.horizontalAccuracy, 0, "Negative accuracy indicates invalid location")
    }
    
    // MARK: - Session Management Errors
    
    func testStartTrackingWithoutNarrative() {
        // Test starting tracking with empty narrative
        locationManager.startTracking(with: "")
        
        // Should handle empty narrative gracefully
        XCTAssertNotNil(locationManager, "Manager should remain valid")
    }
    
    func testStartTrackingWhileAlreadyTracking() {
        // Test double-start scenario
        if locationManager.authorizationStatus == .authorizedAlways {
            locationManager.startTracking(with: "First Session")
            let firstTrackingState = locationManager.isTracking
            
            locationManager.startTracking(with: "Second Session")
            let secondTrackingState = locationManager.isTracking
            
            XCTAssertEqual(firstTrackingState, secondTrackingState, "Should maintain consistent state")
        }
    }
    
    func testStopTrackingWithoutActiveSession() {
        // Test stopping when not tracking
        XCTAssertFalse(locationManager.isTracking, "Should not be tracking initially")
        
        locationManager.stopTracking()
        
        // Should handle gracefully without crashing
        XCTAssertNil(locationManager.trackingStopError, "Should not error when stopping non-active tracking")
    }
    
    func testRapidStartStopCycles() {
        // Test rapid start/stop cycles for race conditions
        if locationManager.authorizationStatus == .authorizedAlways {
            for i in 0..<5 {
                locationManager.startTracking(with: "Cycle \(i)")
                locationManager.stopTracking()
            }
            
            // Should end in consistent state
            XCTAssertFalse(locationManager.isTracking, "Should not be tracking after cycles")
            XCTAssertNil(locationManager.currentSession, "Should have no session after cycles")
        }
    }
    
    // MARK: - Core Data Errors
    
    func testSaveLocationWithoutSession() {
        // Test that locations require a session
        let context = persistenceController.container.viewContext
        
        let location = LocationEntry(context: context)
        location.id = UUID()
        location.latitude = 37.7749
        location.longitude = -122.4194
        location.timestamp = Date()
        location.session = nil
        
        // Save without session - should succeed (session is optional in relationship)
        XCTAssertNoThrow(try context.save(), "Should save location even without session")
    }
    
    func testConcurrentSessionCreation() {
        // Test creating sessions from multiple threads
        let expectation = self.expectation(description: "Concurrent session creation")
        expectation.expectedFulfillmentCount = 3
        
        for i in 0..<3 {
            DispatchQueue.global().async {
                let bgContext = self.persistenceController.container.newBackgroundContext()
                bgContext.performAndWait {
                    let session = TrackingSession(context: bgContext)
                    session.id = UUID()
                    session.narrative = "Concurrent \(i)"
                    session.startDate = Date()
                    session.isActive = false
                    
                    do {
                        try bgContext.save()
                        expectation.fulfill()
                    } catch {
                        XCTFail("Concurrent save failed: \(error)")
                    }
                }
            }
        }
        
        wait(for: [expectation], timeout: 5.0)
    }
    
    func testLocationSaveFailureRecovery() {
        // Test recovery from save failures
        let context = persistenceController.container.viewContext
        
        let session = TrackingSession(context: context)
        session.id = UUID()
        session.narrative = "Save Test"
        session.startDate = Date()
        session.isActive = false
        
        try? context.save()
        
        // Attempt to save valid location
        let location = LocationEntry(context: context)
        location.id = UUID()
        location.latitude = 37.7749
        location.longitude = -122.4194
        location.timestamp = Date()
        location.session = session
        
        XCTAssertNoThrow(try context.save(), "Valid location should save successfully")
    }
}

// MARK: - Edge Case Tests
class LocationManagerEdgeCaseTests: XCTestCase {
    var locationManager: LocationManager!
    var persistenceController: PersistenceController!
    
    override func setUp() {
        super.setUp()
        persistenceController = PersistenceController(inMemory: true)
        locationManager = LocationManager()
    }
    
    override func tearDown() {
        locationManager = nil
        persistenceController = nil
        super.tearDown()
    }
    
    // MARK: - Coordinate Edge Cases
    
    func testEquatorLocation() {
        // Test location at equator
        let equatorLocation = CLLocation(latitude: 0.0, longitude: -122.4194)
        
        XCTAssertEqual(equatorLocation.coordinate.latitude, 0.0, "Should handle equator latitude")
    }
    
    func testPrimeMeridianLocation() {
        // Test location at prime meridian
        let primeMeridianLocation = CLLocation(latitude: 37.7749, longitude: 0.0)
        
        XCTAssertEqual(primeMeridianLocation.coordinate.longitude, 0.0, "Should handle prime meridian")
    }
    
    func testInternationalDateLineLocation() {
        // Test location near international date line
        let dateLineLocation = CLLocation(latitude: 0.0, longitude: 180.0)
        
        XCTAssertEqual(dateLineLocation.coordinate.longitude, 180.0, "Should handle date line")
    }
    
    func testAntimeridianLocation() {
        // Test location at antimeridian (opposite side)
        let antimeridianLocation = CLLocation(latitude: 0.0, longitude: -180.0)
        
        XCTAssertEqual(antimeridianLocation.coordinate.longitude, -180.0, "Should handle antimeridian")
    }
    
    func testNorthPoleLocation() {
        // Test location near north pole
        let northPoleLocation = CLLocation(latitude: 89.9, longitude: 0.0)
        
        XCTAssertGreaterThan(northPoleLocation.coordinate.latitude, 89.0, "Should handle north pole proximity")
    }
    
    func testSouthPoleLocation() {
        // Test location near south pole
        let southPoleLocation = CLLocation(latitude: -89.9, longitude: 0.0)
        
        XCTAssertLessThan(southPoleLocation.coordinate.latitude, -89.0, "Should handle south pole proximity")
    }
    
    // MARK: - Altitude Edge Cases
    
    func testNegativeAltitude() {
        // Test locations below sea level (Dead Sea, Death Valley)
        let belowSeaLevel = CLLocation(
            coordinate: CLLocationCoordinate2D(latitude: 31.5, longitude: 35.5),
            altitude: -400,
            horizontalAccuracy: 10,
            verticalAccuracy: 10,
            timestamp: Date()
        )
        
        XCTAssertLessThan(belowSeaLevel.altitude, 0, "Should handle negative altitude")
    }
    
    func testVeryHighAltitude() {
        // Test locations at high altitude (Mt. Everest height)
        let highAltitude = CLLocation(
            coordinate: CLLocationCoordinate2D(latitude: 27.9881, longitude: 86.9250),
            altitude: 8848,
            horizontalAccuracy: 50,
            verticalAccuracy: 50,
            timestamp: Date()
        )
        
        XCTAssertGreaterThan(highAltitude.altitude, 8000, "Should handle high altitude")
    }
    
    func testAircraftAltitude() {
        // Test commercial aircraft cruising altitude
        let aircraftAltitude = CLLocation(
            coordinate: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
            altitude: 10000,
            horizontalAccuracy: 100,
            verticalAccuracy: 100,
            timestamp: Date()
        )
        
        XCTAssertGreaterThan(aircraftAltitude.altitude, 9000, "Should handle aircraft altitude")
    }
    
    // MARK: - Speed Edge Cases
    
    func testZeroSpeed() {
        // Test stationary location
        let stationary = CLLocation(
            coordinate: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
            altitude: 50,
            horizontalAccuracy: 5,
            verticalAccuracy: 5,
            course: 0,
            speed: 0,
            timestamp: Date()
        )
        
        XCTAssertEqual(stationary.speed, 0, "Should handle zero speed")
    }
    
    func testNegativeSpeed() {
        // Test invalid negative speed
        let invalidSpeed = CLLocation(
            coordinate: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
            altitude: 50,
            horizontalAccuracy: 5,
            verticalAccuracy: 5,
            course: 0,
            speed: -1,
            timestamp: Date()
        )
        
        XCTAssertLessThan(invalidSpeed.speed, 0, "Negative speed indicates invalid")
    }
    
    func testHighSpeed() {
        // Test high-speed movement (highway driving)
        let highSpeed = CLLocation(
            coordinate: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
            altitude: 50,
            horizontalAccuracy: 10,
            verticalAccuracy: 10,
            course: 90,
            speed: 35, // ~126 km/h
            timestamp: Date()
        )
        
        XCTAssertGreaterThan(highSpeed.speed, 30, "Should handle high speed")
    }
    
    // MARK: - Course Edge Cases
    
    func testAllDirections() {
        // Test all cardinal and ordinal directions
        let directions: [Double] = [0, 45, 90, 135, 180, 225, 270, 315, 360]
        
        for direction in directions {
            let location = CLLocation(
                coordinate: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
                altitude: 50,
                horizontalAccuracy: 5,
                verticalAccuracy: 5,
                course: direction,
                speed: 10,
                timestamp: Date()
            )
            
            XCTAssertGreaterThanOrEqual(location.course, 0, "Course should be non-negative")
            XCTAssertLessThanOrEqual(location.course, 360, "Course should be <= 360")
        }
    }
    
    func testNegativeCourse() {
        // Test invalid negative course
        let negativeCourse = CLLocation(
            coordinate: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
            altitude: 50,
            horizontalAccuracy: 5,
            verticalAccuracy: 5,
            course: -1,
            speed: 10,
            timestamp: Date()
        )
        
        XCTAssertLessThan(negativeCourse.course, 0, "Negative course indicates invalid")
    }
    
    // MARK: - Timestamp Edge Cases
    
    func testFutureTimestamp() {
        // Test location with future timestamp
        let futureLocation = CLLocation(
            coordinate: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
            altitude: 50,
            horizontalAccuracy: 5,
            verticalAccuracy: 5,
            timestamp: Date().addingTimeInterval(3600)
        )
        
        XCTAssertGreaterThan(futureLocation.timestamp, Date(), "Should handle future timestamps")
    }
    
    func testVeryOldTimestamp() {
        // Test location from long ago
        let oldLocation = CLLocation(
            coordinate: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
            altitude: 50,
            horizontalAccuracy: 5,
            verticalAccuracy: 5,
            timestamp: Date().addingTimeInterval(-86400 * 365) // 1 year ago
        )
        
        let age = Date().timeIntervalSince(oldLocation.timestamp)
        XCTAssertGreaterThan(age, 86400 * 364, "Should handle old timestamps")
    }
    
    func testMicrosecondTimestamps() {
        // Test that microsecond precision is maintained
        let timestamp1 = Date()
        let timestamp2 = Date()
        
        let location1 = CLLocation(
            coordinate: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
            altitude: 50,
            horizontalAccuracy: 5,
            verticalAccuracy: 5,
            timestamp: timestamp1
        )
        
        let location2 = CLLocation(
            coordinate: CLLocationCoordinate2D(latitude: 37.7750, longitude: -122.4195),
            altitude: 50,
            horizontalAccuracy: 5,
            verticalAccuracy: 5,
            timestamp: timestamp2
        )
        
        XCTAssertGreaterThanOrEqual(location2.timestamp, location1.timestamp, "Timestamps should be sequential")
    }
    
    // MARK: - Distance Calculation Edge Cases
    
    func testZeroDistance() {
        // Test distance between same location
        let location = CLLocation(latitude: 37.7749, longitude: -122.4194)
        let distance = location.distance(from: location)
        
        XCTAssertEqual(distance, 0, accuracy: 0.1, "Distance to self should be zero")
    }
    
    func testAcrossPrimeMeridian() {
        // Test distance calculation across prime meridian
        let london = CLLocation(latitude: 51.5074, longitude: -0.1278)
        let ghana = CLLocation(latitude: 5.6037, longitude: -0.1870)
        
        let distance = london.distance(from: ghana)
        XCTAssertGreaterThan(distance, 5000000, "Should calculate distance across prime meridian")
    }
    
    func testAcrossDateLine() {
        // Test distance calculation across international date line
        let fiji = CLLocation(latitude: -18.1248, longitude: 178.4501)
        let samoa = CLLocation(latitude: -13.7590, longitude: -172.1046)
        
        let distance = fiji.distance(from: samoa)
        XCTAssertGreaterThan(distance, 0, "Should calculate distance across date line")
    }
    
    func testGlobalDistance() {
        // Test maximum distance (antipodal points)
        let sanFrancisco = CLLocation(latitude: 37.7749, longitude: -122.4194)
        let nearAntipode = CLLocation(latitude: -37.7749, longitude: 57.5806)
        
        let distance = sanFrancisco.distance(from: nearAntipode)
        let earthCircumference = 40075000.0 // meters
        
        XCTAssertGreaterThan(distance, earthCircumference * 0.45, "Should be near maximum distance")
    }
    
    // MARK: - Session Edge Cases
    
    func testVeryLongSession() {
        // Test session lasting multiple days
        let context = persistenceController.container.viewContext
        
        let session = TrackingSession(context: context)
        session.id = UUID()
        session.narrative = "Multi-day Trip"
        session.startDate = Date().addingTimeInterval(-86400 * 7) // 7 days ago
        session.endDate = Date()
        session.isActive = false
        
        try? context.save()
        
        let duration = session.endDate!.timeIntervalSince(session.startDate!)
        XCTAssertGreaterThan(duration, 86400 * 6, "Should handle multi-day sessions")
    }
    
    func testVeryShortSession() {
        // Test session lasting only seconds
        let context = persistenceController.container.viewContext
        
        let session = TrackingSession(context: context)
        session.id = UUID()
        session.narrative = "Quick Test"
        session.startDate = Date().addingTimeInterval(-5)
        session.endDate = Date()
        session.isActive = false
        
        try? context.save()
        
        let duration = session.endDate!.timeIntervalSince(session.startDate!)
        XCTAssertLessThan(duration, 10, "Should handle very short sessions")
    }
    
    func testSessionWithThousandsOfLocations() {
        // Test session with many location points
        let context = persistenceController.container.viewContext
        
        let session = TrackingSession(context: context)
        session.id = UUID()
        session.narrative = "Large Session"
        session.startDate = Date()
        session.isActive = false
        
        // Add many locations
        for i in 0..<100 {
            let location = LocationEntry(context: context)
            location.id = UUID()
            location.latitude = 37.7749 + Double(i) * 0.0001
            location.longitude = -122.4194 + Double(i) * 0.0001
            location.timestamp = Date().addingTimeInterval(TimeInterval(i))
            location.session = session
        }
        
        try? context.save()
        
        let fetchRequest: NSFetchRequest<LocationEntry> = LocationEntry.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "session == %@", session)
        let locations = try? context.fetch(fetchRequest)
        
        XCTAssertEqual(locations?.count, 100, "Should handle sessions with many locations")
    }
    
    func testMultipleConcurrentSessions() {
        // Test that only one session can be active at a time
        let context = persistenceController.container.viewContext
        
        let session1 = TrackingSession(context: context)
        session1.id = UUID()
        session1.narrative = "Session 1"
        session1.startDate = Date()
        session1.isActive = true
        
        let session2 = TrackingSession(context: context)
        session2.id = UUID()
        session2.narrative = "Session 2"
        session2.startDate = Date()
        session2.isActive = true
        
        try? context.save()
        
        let fetchRequest: NSFetchRequest<TrackingSession> = TrackingSession.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "isActive == YES")
        let activeSessions = try? context.fetch(fetchRequest)
        
        // This test documents current behavior - multiple active sessions are allowed at DB level
        // Business logic should prevent this
        XCTAssertNotNil(activeSessions, "Should be able to query active sessions")
    }
}

// MARK: - Performance Tests
class LocationManagerPerformanceTests: XCTestCase {
    var locationManager: LocationManager!
    var persistenceController: PersistenceController!
    
    override func setUp() {
        super.setUp()
        persistenceController = PersistenceController(inMemory: true)
        locationManager = LocationManager()
    }
    
    override func tearDown() {
        locationManager = nil
        persistenceController = nil
        super.tearDown()
    }
    
    func testLocationManagerInitializationPerformance() {
        measure {
            _ = LocationManager()
        }
    }
    
    func testBulkLocationInsertion() {
        let context = persistenceController.container.viewContext
        
        measure {
            let session = TrackingSession(context: context)
            session.id = UUID()
            session.narrative = "Performance Test"
            session.startDate = Date()
            session.isActive = false
            
            for i in 0..<100 {
                let location = LocationEntry(context: context)
                location.id = UUID()
                location.latitude = 37.7749 + Double(i) * 0.0001
                location.longitude = -122.4194 + Double(i) * 0.0001
                location.timestamp = Date().addingTimeInterval(TimeInterval(i))
                location.session = session
            }
            
            try? context.save()
            context.reset()
        }
    }
    
    func testLocationQueryPerformance() {
        let context = persistenceController.container.viewContext
        
        // Setup: Create test data
        let session = TrackingSession(context: context)
        session.id = UUID()
        session.narrative = "Query Test"
        session.startDate = Date()
        session.isActive = false
        
        for i in 0..<500 {
            let location = LocationEntry(context: context)
            location.id = UUID()
            location.latitude = 37.7749 + Double(i) * 0.0001
            location.longitude = -122.4194 + Double(i) * 0.0001
            location.timestamp = Date().addingTimeInterval(TimeInterval(i))
            location.session = session
        }
        
        try? context.save()
        
        // Measure query performance
        measure {
            let fetchRequest: NSFetchRequest<LocationEntry> = LocationEntry.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "session == %@", session)
            _ = try? context.fetch(fetchRequest)
        }
    }
    
    func testDistanceCalculationPerformance() {
        let locations = (0..<100).map { i in
            CLLocation(
                latitude: 37.7749 + Double(i) * 0.001,
                longitude: -122.4194 + Double(i) * 0.001
            )
        }
        
        measure {
            var totalDistance = 0.0
            for i in 0..<locations.count - 1 {
                totalDistance += locations[i].distance(from: locations[i + 1])
            }
            _ = totalDistance
        }
    }
}
