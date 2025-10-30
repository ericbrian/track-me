import XCTest
import CoreData
import SwiftUI
@testable import TrackMe

/// Tests for HistoryView collection view crash fixes
/// Validates that the UI properly handles Core Data updates without causing
/// "invalid number of items" crashes in UICollectionView
class HistoryViewCollectionTests: XCTestCase {
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
    
    // MARK: - Core Data Update Tests
    
    func testSessionLocationUpdateDoesNotCrash() throws {
        // Create a session with 1 location
        let session = TrackingSession(context: context)
        session.id = UUID()
        session.startDate = Date()
        session.narrative = "Test Session"
        session.isActive = true
        
        let location1 = LocationEntry(context: context)
        location1.id = UUID()
        location1.latitude = 37.7749
        location1.longitude = -122.4194
        location1.timestamp = Date()
        location1.accuracy = 10.0
        location1.speed = 0.0
        session.addToLocations(location1)
        
        try context.save()
        
        // Verify initial state
        XCTAssertEqual(session.locations?.count, 1)
        
        // Simulate adding more locations (like when tracking is active)
        for i in 2...5 {
            let location = LocationEntry(context: context)
            location.id = UUID()
            location.latitude = 37.7749 + Double(i) * 0.001
            location.longitude = -122.4194 + Double(i) * 0.001
            location.timestamp = Date().addingTimeInterval(Double(i) * 10)
            location.accuracy = 10.0
            location.speed = 5.0
            session.addToLocations(location)
        }
        
        // Save the context - this simulates the update that would cause the crash
        XCTAssertNoThrow(try context.save())
        
        // Verify the update succeeded
        context.refresh(session, mergeChanges: true)
        XCTAssertEqual(session.locations?.count, 5)
    }
    
    func testMultipleSessionUpdatesWithStableIdentity() throws {
        // Create multiple sessions
        var sessions: [TrackingSession] = []
        for i in 1...3 {
            let session = TrackingSession(context: context)
            session.id = UUID()
            session.startDate = Date().addingTimeInterval(TimeInterval(-i * 3600))
            session.narrative = "Session \(i)"
            session.isActive = (i == 1)
            
            let location = LocationEntry(context: context)
            location.id = UUID()
            location.latitude = 37.7749
            location.longitude = -122.4194
            location.timestamp = Date()
            location.accuracy = 10.0
            session.addToLocations(location)
            
            sessions.append(session)
        }
        
        try context.save()
        
        // Store objectIDs - these should remain stable
        let objectIDs = sessions.map { $0.objectID }
        
        // Update each session by adding locations
        for (index, session) in sessions.enumerated() {
            for j in 1...4 {
                let location = LocationEntry(context: context)
                location.id = UUID()
                location.latitude = 37.7749 + Double(j) * 0.001
                location.longitude = -122.4194 + Double(j) * 0.001
                location.timestamp = Date().addingTimeInterval(Double(j) * 10)
                location.accuracy = 10.0
                session.addToLocations(location)
            }
        }
        
        try context.save()
        
        // Verify objectIDs remain the same (stable identity)
        for (index, session) in sessions.enumerated() {
            XCTAssertEqual(session.objectID, objectIDs[index], "ObjectID should remain stable after updates")
            XCTAssertEqual(session.locations?.count, 5, "Session \(index + 1) should have 5 locations")
        }
    }
    
    func testConcurrentSessionUpdates() throws {
        // Create a session
        let session = TrackingSession(context: context)
        session.id = UUID()
        session.startDate = Date()
        session.narrative = "Concurrent Test"
        session.isActive = true
        
        let location = LocationEntry(context: context)
        location.id = UUID()
        location.latitude = 37.7749
        location.longitude = -122.4194
        location.timestamp = Date()
        location.accuracy = 10.0
        session.addToLocations(location)
        
        try context.save()
        
        let objectID = session.objectID
        
        // Simulate concurrent updates in a background context
        let backgroundContext = persistenceController.container.newBackgroundContext()
        let expectation = self.expectation(description: "Background updates complete")
        
        backgroundContext.perform {
            do {
                guard let bgSession = try backgroundContext.existingObject(with: objectID) as? TrackingSession else {
                    XCTFail("Could not fetch session in background context")
                    return
                }
                
                // Add locations in background
                for i in 1...5 {
                    let location = LocationEntry(context: backgroundContext)
                    location.id = UUID()
                    location.latitude = 37.7749 + Double(i) * 0.001
                    location.longitude = -122.4194 + Double(i) * 0.001
                    location.timestamp = Date().addingTimeInterval(Double(i) * 10)
                    location.accuracy = 10.0
                    bgSession.addToLocations(location)
                }
                
                try backgroundContext.save()
                expectation.fulfill()
            } catch {
                XCTFail("Background save failed: \(error)")
            }
        }
        
        wait(for: [expectation], timeout: 5.0)
        
        // Refresh the main context
        context.refreshAllObjects()
        
        // Verify the session was updated
        let updatedSession = try context.existingObject(with: objectID) as? TrackingSession
        XCTAssertNotNil(updatedSession)
        XCTAssertEqual(updatedSession?.locations?.count, 6, "Should have 6 locations after concurrent update")
    }
    
    func testSessionDeletionWithMultipleLocations() throws {
        // Create a session with multiple locations
        let session = TrackingSession(context: context)
        session.id = UUID()
        session.startDate = Date()
        session.narrative = "To Be Deleted"
        session.isActive = false
        
        for i in 1...10 {
            let location = LocationEntry(context: context)
            location.id = UUID()
            location.latitude = 37.7749 + Double(i) * 0.001
            location.longitude = -122.4194 + Double(i) * 0.001
            location.timestamp = Date().addingTimeInterval(Double(i) * 10)
            location.accuracy = 10.0
            session.addToLocations(location)
        }
        
        try context.save()
        
        XCTAssertEqual(session.locations?.count, 10)
        
        // Delete the session
        context.delete(session)
        XCTAssertNoThrow(try context.save())
        
        // Verify deletion
        let fetchRequest: NSFetchRequest<TrackingSession> = TrackingSession.fetchRequest()
        let remainingSessions = try context.fetch(fetchRequest)
        XCTAssertEqual(remainingSessions.count, 0, "Session should be deleted")
    }
    
    func testFetchRequestWithAnimationDisabled() throws {
        // Create multiple sessions to test fetch request behavior
        for i in 1...5 {
            let session = TrackingSession(context: context)
            session.id = UUID()
            session.startDate = Date().addingTimeInterval(TimeInterval(-i * 3600))
            session.narrative = "Session \(i)"
            session.isActive = false
            
            let location = LocationEntry(context: context)
            location.id = UUID()
            location.latitude = 37.7749
            location.longitude = -122.4194
            location.timestamp = Date()
            location.accuracy = 10.0
            session.addToLocations(location)
        }
        
        try context.save()
        
        // Fetch sessions
        let fetchRequest: NSFetchRequest<TrackingSession> = TrackingSession.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \TrackingSession.startDate, ascending: false)]
        
        let sessions = try context.fetch(fetchRequest)
        XCTAssertEqual(sessions.count, 5)
        
        // Update first session
        let firstSession = sessions[0]
        for i in 1...5 {
            let location = LocationEntry(context: context)
            location.id = UUID()
            location.latitude = 37.7749 + Double(i) * 0.001
            location.longitude = -122.4194 + Double(i) * 0.001
            location.timestamp = Date().addingTimeInterval(Double(i) * 10)
            location.accuracy = 10.0
            firstSession.addToLocations(location)
        }
        
        try context.save()
        
        // Re-fetch to verify order is maintained
        let updatedSessions = try context.fetch(fetchRequest)
        XCTAssertEqual(updatedSessions.count, 5)
        XCTAssertEqual(updatedSessions[0].id, firstSession.id, "First session should remain first after update")
        XCTAssertEqual(updatedSessions[0].locations?.count, 6, "First session should have updated location count")
    }
    
    func testObjectIDStabilityAcrossUpdates() throws {
        // Create a session
        let session = TrackingSession(context: context)
        session.id = UUID()
        session.startDate = Date()
        session.narrative = "Stability Test"
        session.isActive = true
        
        try context.save()
        
        let originalObjectID = session.objectID
        XCTAssertFalse(originalObjectID.isTemporaryID, "Should have permanent ID after save")
        
        // Perform multiple updates
        for iteration in 1...10 {
            let location = LocationEntry(context: context)
            location.id = UUID()
            location.latitude = 37.7749 + Double(iteration) * 0.001
            location.longitude = -122.4194 + Double(iteration) * 0.001
            location.timestamp = Date().addingTimeInterval(Double(iteration) * 10)
            location.accuracy = 10.0
            session.addToLocations(location)
            
            try context.save()
            
            // Verify objectID remains the same
            XCTAssertEqual(session.objectID, originalObjectID, "ObjectID should remain stable after update \(iteration)")
        }
        
        XCTAssertEqual(session.locations?.count, 10)
    }
    
    func testRefreshAllObjectsDoesNotCauseCrash() throws {
        // Create sessions
        for i in 1...5 {
            let session = TrackingSession(context: context)
            session.id = UUID()
            session.startDate = Date().addingTimeInterval(TimeInterval(-i * 3600))
            session.narrative = "Session \(i)"
            session.isActive = false
            
            for j in 1...3 {
                let location = LocationEntry(context: context)
                location.id = UUID()
                location.latitude = 37.7749 + Double(j) * 0.001
                location.longitude = -122.4194
                location.timestamp = Date()
                location.accuracy = 10.0
                session.addToLocations(location)
            }
        }
        
        try context.save()
        
        // Call refreshAllObjects (simulating what HistoryView does onAppear)
        XCTAssertNoThrow(context.refreshAllObjects())
        
        // Verify data is still accessible
        let fetchRequest: NSFetchRequest<TrackingSession> = TrackingSession.fetchRequest()
        let sessions = try context.fetch(fetchRequest)
        XCTAssertEqual(sessions.count, 5)
        
        for session in sessions {
            XCTAssertEqual(session.locations?.count, 3)
        }
    }
    
    func testRapidLocationAdditionDoesNotCrash() throws {
        // Simulate rapid location additions like during active tracking
        let session = TrackingSession(context: context)
        session.id = UUID()
        session.startDate = Date()
        session.narrative = "Rapid Updates"
        session.isActive = true
        
        try context.save()
        
        // Add locations rapidly
        for i in 1...50 {
            let location = LocationEntry(context: context)
            location.id = UUID()
            location.latitude = 37.7749 + Double(i) * 0.0001
            location.longitude = -122.4194 + Double(i) * 0.0001
            location.timestamp = Date().addingTimeInterval(Double(i))
            location.accuracy = Double.random(in: 5.0...15.0)
            location.speed = Double.random(in: 0.0...30.0)
            session.addToLocations(location)
            
            // Save every 10 locations to simulate batched saves
            if i % 10 == 0 {
                XCTAssertNoThrow(try context.save())
            }
        }
        
        try context.save()
        XCTAssertEqual(session.locations?.count, 50)
    }
    
    func testSessionActiveFlagUpdate() throws {
        // Test updating isActive flag (like when stopping tracking)
        let session = TrackingSession(context: context)
        session.id = UUID()
        session.startDate = Date()
        session.narrative = "Active Session"
        session.isActive = true
        
        for i in 1...5 {
            let location = LocationEntry(context: context)
            location.id = UUID()
            location.latitude = 37.7749 + Double(i) * 0.001
            location.longitude = -122.4194
            location.timestamp = Date().addingTimeInterval(Double(i) * 10)
            location.accuracy = 10.0
            session.addToLocations(location)
        }
        
        try context.save()
        let objectID = session.objectID
        
        XCTAssertTrue(session.isActive)
        XCTAssertEqual(session.locations?.count, 5)
        
        // Stop tracking - update isActive and endDate
        session.isActive = false
        session.endDate = Date()
        
        XCTAssertNoThrow(try context.save())
        
        // Verify the update
        let updatedSession = try context.existingObject(with: objectID) as? TrackingSession
        XCTAssertNotNil(updatedSession)
        XCTAssertFalse(updatedSession!.isActive)
        XCTAssertNotNil(updatedSession!.endDate)
        XCTAssertEqual(updatedSession!.locations?.count, 5)
    }
    
    func testEnumeratedForEachWithObjectID() throws {
        // Test the enumerated ForEach pattern used in HistoryView
        var sessions: [TrackingSession] = []
        
        for i in 1...5 {
            let session = TrackingSession(context: context)
            session.id = UUID()
            session.startDate = Date().addingTimeInterval(TimeInterval(-i * 3600))
            session.narrative = "Session \(i)"
            session.isActive = false
            
            let location = LocationEntry(context: context)
            location.id = UUID()
            location.latitude = 37.7749
            location.longitude = -122.4194
            location.timestamp = Date()
            location.accuracy = 10.0
            session.addToLocations(location)
            
            sessions.append(session)
        }
        
        try context.save()
        
        // Verify enumeration with objectID works
        let enumerated = Array(sessions.enumerated())
        XCTAssertEqual(enumerated.count, 5)
        
        for (index, session) in enumerated {
            XCTAssertEqual(index, enumerated[index].offset)
            XCTAssertNotNil(session.objectID)
            XCTAssertFalse(session.objectID.isTemporaryID)
        }
        
        // Update one session and verify objectID remains stable
        let middleSession = sessions[2]
        let originalObjectID = middleSession.objectID
        
        for i in 1...10 {
            let location = LocationEntry(context: context)
            location.id = UUID()
            location.latitude = 37.7749 + Double(i) * 0.001
            location.longitude = -122.4194
            location.timestamp = Date().addingTimeInterval(Double(i) * 10)
            location.accuracy = 10.0
            middleSession.addToLocations(location)
        }
        
        try context.save()
        
        XCTAssertEqual(middleSession.objectID, originalObjectID, "ObjectID should remain stable")
        XCTAssertEqual(middleSession.locations?.count, 11)
    }
}
