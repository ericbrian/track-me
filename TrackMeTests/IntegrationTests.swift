// TrackMeTests/IntegrationTests.swift
// Integration tests for TrackMe components

import XCTest
import CoreLocation
import CoreData
@testable import TrackMe

class IntegrationTests: XCTestCase {
    var persistenceController: PersistenceController!
    var locationManager: LocationManager!
    
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
    
    func testCompleteTrackingFlow() {
        // This test simulates a complete tracking session lifecycle
        let context = persistenceController.container.viewContext
        
        // 1. Create a session
        let session = TrackingSession(context: context)
        session.id = UUID()
        session.narrative = "Integration Test Session"
        session.startDate = Date()
        session.isActive = true
        
        XCTAssertNoThrow(try context.save(), "Session should be created successfully.")
        
        // 2. Add multiple location entries
        for i in 0..<10 {
            let location = LocationEntry(context: context)
            location.id = UUID()
            location.latitude = 37.7749 + Double(i) * 0.001
            location.longitude = -122.4194 + Double(i) * 0.001
            location.timestamp = Date().addingTimeInterval(TimeInterval(i * 60))
            location.accuracy = 10.0
            location.session = session
        }
        
        XCTAssertNoThrow(try context.save(), "Locations should be added successfully.")
        XCTAssertEqual(session.locations?.count, 10, "Session should have 10 locations.")
        
        // 3. End the session
        session.endDate = Date()
        session.isActive = false
        
        XCTAssertNoThrow(try context.save(), "Session should be ended successfully.")
        XCTAssertFalse(session.isActive, "Session should be inactive.")
        XCTAssertNotNil(session.endDate, "Session should have end date.")
    }
    
    func testMultipleSessionsManagement() {
        let context = persistenceController.container.viewContext
        
        // Create 5 sessions with different states
        for i in 0..<5 {
            let session = TrackingSession(context: context)
            session.id = UUID()
            session.narrative = "Session \(i + 1)"
            session.startDate = Date().addingTimeInterval(TimeInterval(-i * 3600))
            
            // Make the first session active, others inactive
            session.isActive = (i == 0)
            if i > 0 {
                session.endDate = Date().addingTimeInterval(TimeInterval(-i * 3600 + 1800))
            }
            
            // Add a few locations to each session
            for j in 0..<3 {
                let location = LocationEntry(context: context)
                location.id = UUID()
                location.latitude = 37.7749 + Double(i) * 0.01 + Double(j) * 0.001
                location.longitude = -122.4194 + Double(i) * 0.01 + Double(j) * 0.001
                location.timestamp = Date().addingTimeInterval(TimeInterval(-i * 3600 + j * 300))
                location.session = session
            }
        }
        
        XCTAssertNoThrow(try context.save(), "Multiple sessions should be saved.")
        
        // Fetch all sessions
        let allSessionsFetch: NSFetchRequest<TrackingSession> = TrackingSession.fetchRequest()
        let allSessions = try? context.fetch(allSessionsFetch)
        XCTAssertEqual(allSessions?.count, 5, "Should have 5 sessions.")
        
        // Fetch only active session
        let activeFetch: NSFetchRequest<TrackingSession> = TrackingSession.fetchRequest()
        activeFetch.predicate = NSPredicate(format: "isActive == YES")
        let activeSessions = try? context.fetch(activeFetch)
        XCTAssertEqual(activeSessions?.count, 1, "Should have 1 active session.")
        
        // Fetch only inactive sessions
        let inactiveFetch: NSFetchRequest<TrackingSession> = TrackingSession.fetchRequest()
        inactiveFetch.predicate = NSPredicate(format: "isActive == NO")
        let inactiveSessions = try? context.fetch(inactiveFetch)
        XCTAssertEqual(inactiveSessions?.count, 4, "Should have 4 inactive sessions.")
    }
    
    func testLocationQueryPerformance() {
        let context = persistenceController.container.viewContext
        
        // Create a session with many locations
        let session = TrackingSession(context: context)
        session.id = UUID()
        session.narrative = "Performance Test Session"
        session.startDate = Date()
        session.isActive = false
        
        // Add 100 locations
        for i in 0..<100 {
            let location = LocationEntry(context: context)
            location.id = UUID()
            location.latitude = 37.7749 + Double(i) * 0.0001
            location.longitude = -122.4194 + Double(i) * 0.0001
            location.timestamp = Date().addingTimeInterval(TimeInterval(i * 30))
            location.session = session
        }
        
        XCTAssertNoThrow(try context.save(), "Session with 100 locations should be saved.")
        
        // Measure fetch performance
        measure {
            let fetchRequest: NSFetchRequest<LocationEntry> = LocationEntry.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "session == %@", session)
            fetchRequest.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: true)]
            
            let locations = try? context.fetch(fetchRequest)
            XCTAssertEqual(locations?.count, 100, "Should fetch all 100 locations.")
        }
    }
    
    func testDataConsistencyAfterUpdates() {
        let context = persistenceController.container.viewContext
        
        // Create initial session
        let session = TrackingSession(context: context)
        session.id = UUID()
        session.narrative = "Original Narrative"
        session.startDate = Date()
        session.isActive = true
        
        XCTAssertNoThrow(try context.save(), "Initial session should be saved.")
        
        // Update narrative
        session.narrative = "Updated Narrative"
        XCTAssertNoThrow(try context.save(), "Updated narrative should be saved.")
        
        // Fetch and verify
        let fetchRequest: NSFetchRequest<TrackingSession> = TrackingSession.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", session.id! as CVarArg)
        let fetchedSessions = try? context.fetch(fetchRequest)
        
        XCTAssertEqual(fetchedSessions?.count, 1, "Should fetch exactly one session.")
        XCTAssertEqual(fetchedSessions?.first?.narrative, "Updated Narrative", "Narrative should be updated.")
    }
    
    func testOrphanedLocationsPrevention() {
        let context = persistenceController.container.viewContext
        
        // Create locations without a session (should be prevented in real app)
        let location = LocationEntry(context: context)
        location.id = UUID()
        location.latitude = 37.7749
        location.longitude = -122.4194
        location.timestamp = Date()
        location.session = nil // Orphaned
        
        XCTAssertNoThrow(try context.save(), "Location can be saved without session.")
        
        // Query orphaned locations
        let orphanedFetch: NSFetchRequest<LocationEntry> = LocationEntry.fetchRequest()
        orphanedFetch.predicate = NSPredicate(format: "session == nil")
        let orphanedLocations = try? context.fetch(orphanedFetch)
        
        XCTAssertGreaterThan(orphanedLocations?.count ?? 0, 0, "Should find orphaned location.")
        
        // Clean up orphaned locations
        if let orphaned = orphanedLocations {
            for location in orphaned {
                context.delete(location)
            }
            XCTAssertNoThrow(try context.save(), "Orphaned locations should be deleted.")
        }
    }
    
    func testSessionSortingByDate() {
        let context = persistenceController.container.viewContext
        
        // Create sessions with different start dates
        let dates = [
            Date().addingTimeInterval(-7200), // 2 hours ago
            Date().addingTimeInterval(-3600), // 1 hour ago
            Date().addingTimeInterval(-1800), // 30 minutes ago
        ]
        
        for (index, date) in dates.enumerated() {
            let session = TrackingSession(context: context)
            session.id = UUID()
            session.narrative = "Session \(index + 1)"
            session.startDate = date
            session.isActive = false
            session.endDate = date.addingTimeInterval(600) // 10 minutes later
        }
        
        XCTAssertNoThrow(try context.save(), "Sessions should be saved.")
        
        // Fetch sorted by start date (most recent first)
        let fetchRequest: NSFetchRequest<TrackingSession> = TrackingSession.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "startDate", ascending: false)]
        let sessions = try? context.fetch(fetchRequest)
        
        XCTAssertEqual(sessions?.count, 3, "Should have 3 sessions.")
        
        // Verify sorting
        if let sessions = sessions, sessions.count == 3 {
            XCTAssertGreaterThan(sessions[0].startDate!, sessions[1].startDate!, "Sessions should be sorted descending.")
            XCTAssertGreaterThan(sessions[1].startDate!, sessions[2].startDate!, "Sessions should be sorted descending.")
        }
    }
}

// MARK: - Core Data Performance Tests
class CoreDataPerformanceTests: XCTestCase {
    var persistenceController: PersistenceController!
    
    override func setUp() {
        super.setUp()
        persistenceController = PersistenceController(inMemory: true)
    }
    
    override func tearDown() {
        persistenceController = nil
        super.tearDown()
    }
    
    func testBatchInsertPerformance() {
        let context = persistenceController.container.viewContext
        
        measure {
            let session = TrackingSession(context: context)
            session.id = UUID()
            session.narrative = "Batch Insert Test"
            session.startDate = Date()
            session.isActive = false
            
            // Insert 50 locations
            for i in 0..<50 {
                let location = LocationEntry(context: context)
                location.id = UUID()
                location.latitude = 37.7749 + Double(i) * 0.0001
                location.longitude = -122.4194 + Double(i) * 0.0001
                location.timestamp = Date().addingTimeInterval(TimeInterval(i * 10))
                location.session = session
            }
            
            try? context.save()
            
            // Clean up for next iteration
            context.delete(session)
            try? context.save()
        }
    }
    
    func testComplexQueryPerformance() {
        let context = persistenceController.container.viewContext
        
        // Setup: Create multiple sessions with locations
        for i in 0..<10 {
            let session = TrackingSession(context: context)
            session.id = UUID()
            session.narrative = "Session \(i)"
            session.startDate = Date().addingTimeInterval(TimeInterval(-i * 3600))
            session.isActive = false
            
            for j in 0..<20 {
                let location = LocationEntry(context: context)
                location.id = UUID()
                location.latitude = 37.7749 + Double(i) * 0.01
                location.longitude = -122.4194 + Double(i) * 0.01
                location.timestamp = Date().addingTimeInterval(TimeInterval(-i * 3600 + j * 60))
                location.session = session
            }
        }
        
        try? context.save()
        
        // Measure complex query
        measure {
            let fetchRequest: NSFetchRequest<TrackingSession> = TrackingSession.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "isActive == NO")
            fetchRequest.sortDescriptors = [NSSortDescriptor(key: "startDate", ascending: false)]
            
            if let sessions = try? context.fetch(fetchRequest) {
                for session in sessions {
                    _ = session.locations?.count // Access relationship
                }
            }
        }
    }
}
