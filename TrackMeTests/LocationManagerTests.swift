// TrackMeTests/LocationManagerTests.swift
// Unit tests for LocationManager

import XCTest
import CoreLocation
import CoreData
@testable import TrackMe

class LocationManagerTests: XCTestCase {
    var locationManager: LocationManager!

    override func setUp() {
        super.setUp()
        locationManager = LocationManager()
    }

    override func tearDown() {
        locationManager = nil
        super.tearDown()
    }

    func testInitialState() {
        XCTAssertFalse(locationManager.isTracking, "LocationManager should not be tracking initially.")
        XCTAssertNil(locationManager.currentSession, "No session should exist initially.")
        XCTAssertEqual(locationManager.locationCount, 0, "Location count should be 0 initially.")
        XCTAssertNil(locationManager.currentLocation, "Current location should be nil initially.")
    }
    
    func testPublishedPropertiesExist() {
        // Verify all published properties are accessible
        _ = locationManager.isTracking
        _ = locationManager.authorizationStatus
        _ = locationManager.currentLocation
        _ = locationManager.currentSession
        _ = locationManager.locationCount
        _ = locationManager.trackingStartError
        _ = locationManager.trackingStopError
        _ = locationManager.showSettingsSuggestion
    }
    
    func testAuthorizationStatusInitialValue() {
        // Authorization status should be set to notDetermined or the actual system status
        XCTAssertNotNil(locationManager.authorizationStatus, "Authorization status should be set.")
    }
}

// MARK: - PersistenceController Tests
class PersistenceControllerTests: XCTestCase {
    var persistenceController: PersistenceController!
    
    override func setUp() {
        super.setUp()
        persistenceController = PersistenceController(inMemory: true)
    }
    
    override func tearDown() {
        persistenceController = nil
        super.tearDown()
    }
    
    func testInMemoryStoreCreation() {
        XCTAssertNotNil(persistenceController.container, "Container should be created.")
        XCTAssertNotNil(persistenceController.container.viewContext, "View context should exist.")
    }
    
    func testCreateTrackingSession() {
        let context = persistenceController.container.viewContext
        let session = TrackingSession(context: context)
        session.id = UUID()
        session.narrative = "Test Session"
        session.startDate = Date()
        session.isActive = true
        
        XCTAssertNoThrow(try context.save(), "Should save tracking session without error.")
        XCTAssertNotNil(session.id, "Session ID should be set.")
        XCTAssertEqual(session.narrative, "Test Session", "Narrative should match.")
        XCTAssertTrue(session.isActive, "Session should be active.")
    }
    
    func testCreateLocationEntry() {
        let context = persistenceController.container.viewContext
        let location = LocationEntry(context: context)
        location.id = UUID()
        location.latitude = 37.7749
        location.longitude = -122.4194
        location.timestamp = Date()
        location.accuracy = 10.0
        location.altitude = 50.0
        location.speed = 5.0
        location.course = 180.0
        
        XCTAssertNoThrow(try context.save(), "Should save location entry without error.")
        XCTAssertNotNil(location.id, "Location ID should be set.")
        XCTAssertEqual(location.latitude, 37.7749, "Latitude should match.")
        XCTAssertEqual(location.longitude, -122.4194, "Longitude should match.")
    }
    
    func testSessionLocationRelationship() {
        let context = persistenceController.container.viewContext
        
        let session = TrackingSession(context: context)
        session.id = UUID()
        session.narrative = "Test Session with Locations"
        session.startDate = Date()
        session.isActive = true
        
        let location1 = LocationEntry(context: context)
        location1.id = UUID()
        location1.latitude = 37.7749
        location1.longitude = -122.4194
        location1.timestamp = Date()
        location1.session = session
        
        let location2 = LocationEntry(context: context)
        location2.id = UUID()
        location2.latitude = 37.7750
        location2.longitude = -122.4195
        location2.timestamp = Date()
        location2.session = session
        
        XCTAssertNoThrow(try context.save(), "Should save session with locations.")
        XCTAssertEqual(session.locations?.count, 2, "Session should have 2 locations.")
        XCTAssertEqual(location1.session, session, "Location should reference session.")
        XCTAssertEqual(location2.session, session, "Location should reference session.")
    }
    
    func testFetchTrackingSessions() {
        let context = persistenceController.container.viewContext
        
        // Create multiple sessions
        for i in 0..<3 {
            let session = TrackingSession(context: context)
            session.id = UUID()
            session.narrative = "Session \(i)"
            session.startDate = Date().addingTimeInterval(TimeInterval(-i * 3600))
            session.isActive = i == 0
        }
        
        XCTAssertNoThrow(try context.save(), "Should save multiple sessions.")
        
        let fetchRequest: NSFetchRequest<TrackingSession> = TrackingSession.fetchRequest()
        let sessions = try? context.fetch(fetchRequest)
        
        XCTAssertNotNil(sessions, "Should fetch sessions.")
        XCTAssertEqual(sessions?.count, 3, "Should have 3 sessions.")
    }
    
    func testFetchActiveSession() {
        let context = persistenceController.container.viewContext
        
        let activeSession = TrackingSession(context: context)
        activeSession.id = UUID()
        activeSession.narrative = "Active Session"
        activeSession.startDate = Date()
        activeSession.isActive = true
        
        let inactiveSession = TrackingSession(context: context)
        inactiveSession.id = UUID()
        inactiveSession.narrative = "Inactive Session"
        inactiveSession.startDate = Date().addingTimeInterval(-3600)
        inactiveSession.endDate = Date()
        inactiveSession.isActive = false
        
        XCTAssertNoThrow(try context.save(), "Should save sessions.")
        
        let fetchRequest: NSFetchRequest<TrackingSession> = TrackingSession.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "isActive == YES")
        let activeSessions = try? context.fetch(fetchRequest)
        
        XCTAssertNotNil(activeSessions, "Should fetch active sessions.")
        XCTAssertEqual(activeSessions?.count, 1, "Should have 1 active session.")
        XCTAssertEqual(activeSessions?.first?.narrative, "Active Session", "Should be the active session.")
    }
    
    func testDeleteSession() {
        let context = persistenceController.container.viewContext
        
        let session = TrackingSession(context: context)
        session.id = UUID()
        session.narrative = "Session to Delete"
        session.startDate = Date()
        session.isActive = false
        
        XCTAssertNoThrow(try context.save(), "Should save session.")
        
        context.delete(session)
        XCTAssertNoThrow(try context.save(), "Should delete session.")
        
        let fetchRequest: NSFetchRequest<TrackingSession> = TrackingSession.fetchRequest()
        let sessions = try? context.fetch(fetchRequest)
        
        XCTAssertEqual(sessions?.count, 0, "Should have no sessions after deletion.")
    }
    
    func testCascadeDeleteLocationsWithSession() {
        let context = persistenceController.container.viewContext
        
        let session = TrackingSession(context: context)
        session.id = UUID()
        session.narrative = "Session with Cascade Delete"
        session.startDate = Date()
        session.isActive = false
        
        let location = LocationEntry(context: context)
        location.id = UUID()
        location.latitude = 37.7749
        location.longitude = -122.4194
        location.timestamp = Date()
        location.session = session
        
        XCTAssertNoThrow(try context.save(), "Should save session and location.")
        
        context.delete(session)
        XCTAssertNoThrow(try context.save(), "Should delete session.")
        
        let locationFetch: NSFetchRequest<LocationEntry> = LocationEntry.fetchRequest()
        let locations = try? context.fetch(locationFetch)
        
        XCTAssertEqual(locations?.count, 0, "Locations should be cascade deleted with session.")
    }
    
    func testPreviewPersistenceController() {
        let previewController = PersistenceController.preview
        let context = previewController.container.viewContext
        
        let fetchRequest: NSFetchRequest<TrackingSession> = TrackingSession.fetchRequest()
        let sessions = try? context.fetch(fetchRequest)
        
        XCTAssertNotNil(sessions, "Preview should have sample sessions.")
        XCTAssertGreaterThan(sessions?.count ?? 0, 0, "Preview should contain at least one session.")
    }
}

// MARK: - Core Data Entity Tests
class TrackingSessionTests: XCTestCase {
    var persistenceController: PersistenceController!
    
    override func setUp() {
        super.setUp()
        persistenceController = PersistenceController(inMemory: true)
    }
    
    override func tearDown() {
        persistenceController = nil
        super.tearDown()
    }
    
    func testSessionDuration() {
        let context = persistenceController.container.viewContext
        let session = TrackingSession(context: context)
        session.id = UUID()
        session.narrative = "Duration Test"
        session.startDate = Date().addingTimeInterval(-3600) // 1 hour ago
        session.endDate = Date()
        session.isActive = false
        
        XCTAssertNoThrow(try context.save(), "Should save session.")
        
        let duration = session.endDate!.timeIntervalSince(session.startDate!)
        XCTAssertGreaterThan(duration, 3500, "Duration should be approximately 1 hour.")
        XCTAssertLessThan(duration, 3700, "Duration should be approximately 1 hour.")
    }
    
    func testActiveSessionWithoutEndDate() {
        let context = persistenceController.container.viewContext
        let session = TrackingSession(context: context)
        session.id = UUID()
        session.narrative = "Active Session"
        session.startDate = Date()
        session.isActive = true
        session.endDate = nil
        
        XCTAssertNoThrow(try context.save(), "Should save active session without end date.")
        XCTAssertNil(session.endDate, "Active session should not have end date.")
    }
}

// MARK: - Location Entry Tests
class LocationEntryTests: XCTestCase {
    var persistenceController: PersistenceController!
    
    override func setUp() {
        super.setUp()
        persistenceController = PersistenceController(inMemory: true)
    }
    
    override func tearDown() {
        persistenceController = nil
        super.tearDown()
    }
    
    func testLocationDataIntegrity() {
        let context = persistenceController.container.viewContext
        let location = LocationEntry(context: context)
        
        let testLat = 37.7749295
        let testLon = -122.4194155
        let testAccuracy = 15.5
        let testAltitude = 100.0
        let testSpeed = 10.5
        let testCourse = 90.0
        let testTimestamp = Date()
        
        location.id = UUID()
        location.latitude = testLat
        location.longitude = testLon
        location.accuracy = testAccuracy
        location.altitude = testAltitude
        location.speed = testSpeed
        location.course = testCourse
        location.timestamp = testTimestamp
        
        XCTAssertNoThrow(try context.save(), "Should save location with all data.")
        XCTAssertEqual(location.latitude, testLat, accuracy: 0.0000001, "Latitude should match.")
        XCTAssertEqual(location.longitude, testLon, accuracy: 0.0000001, "Longitude should match.")
        XCTAssertEqual(location.accuracy, testAccuracy, "Accuracy should match.")
        XCTAssertEqual(location.altitude, testAltitude, "Altitude should match.")
        XCTAssertEqual(location.speed, testSpeed, "Speed should match.")
        XCTAssertEqual(location.course, testCourse, "Course should match.")
        XCTAssertEqual(location.timestamp, testTimestamp, "Timestamp should match.")
    }
    
    func testFetchLocationsForSession() {
        let context = persistenceController.container.viewContext
        
        let session = TrackingSession(context: context)
        session.id = UUID()
        session.narrative = "Session for Location Fetch"
        session.startDate = Date()
        session.isActive = false
        
        for i in 0..<5 {
            let location = LocationEntry(context: context)
            location.id = UUID()
            location.latitude = 37.7749 + Double(i) * 0.001
            location.longitude = -122.4194 + Double(i) * 0.001
            location.timestamp = Date().addingTimeInterval(TimeInterval(i * 60))
            location.session = session
        }
        
        XCTAssertNoThrow(try context.save(), "Should save session with locations.")
        
        let fetchRequest: NSFetchRequest<LocationEntry> = LocationEntry.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "session == %@", session)
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: true)]
        
        let locations = try? context.fetch(fetchRequest)
        
        XCTAssertNotNil(locations, "Should fetch locations.")
        XCTAssertEqual(locations?.count, 5, "Should have 5 locations.")
        
        // Verify they are sorted by timestamp
        if let locations = locations, locations.count == 5 {
            for i in 0..<4 {
                XCTAssertLessThan(locations[i].timestamp!, locations[i+1].timestamp!, "Locations should be sorted by timestamp.")
            }
        }
    }
}
