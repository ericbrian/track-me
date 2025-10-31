// TrackMeTests/HistoryViewTests.swift
// Comprehensive unit tests for HistoryView operations and state management

import XCTest
import SwiftUI
import CoreData
import CoreLocation
@testable import TrackMe

class HistoryViewTests: XCTestCase {
    var persistenceController: PersistenceController!
    var viewContext: NSManagedObjectContext!
    
    override func setUp() {
        super.setUp()
        persistenceController = PersistenceController(inMemory: true)
        viewContext = persistenceController.container.viewContext
    }
    
    override func tearDown() {
        viewContext = nil
        persistenceController = nil
        super.tearDown()
    }
    
    // MARK: - Empty State Tests
    
    func testEmptyStateDisplay() {
        // Fetch sessions (should be empty)
        let fetchRequest: NSFetchRequest<TrackingSession> = TrackingSession.fetchRequest()
        let sessions = try? viewContext.fetch(fetchRequest)
        
        XCTAssertNotNil(sessions)
        XCTAssertTrue(sessions?.isEmpty ?? false)
    }
    
    func testEmptyStateMessage() {
        let isEmpty = true
        let message = isEmpty ? "No tracking sessions yet" : "Sessions available"
        
        XCTAssertEqual(message, "No tracking sessions yet")
    }
    
    // MARK: - Session List Tests
    
    func testSessionListWithSessions() {
        // Create test sessions
        for i in 0..<3 {
            let session = TrackingSession(context: viewContext)
            session.id = UUID()
            session.narrative = "Session \(i)"
            session.startDate = Date().addingTimeInterval(TimeInterval(-i * 3600))
            session.isActive = false
        }
        
        try? viewContext.save()
        
        let fetchRequest: NSFetchRequest<TrackingSession> = TrackingSession.fetchRequest()
        let sessions = try? viewContext.fetch(fetchRequest)
        
        XCTAssertEqual(sessions?.count, 3)
    }
    
    func testSessionListOrdering() {
        // Create sessions with different dates
        let session1 = TrackingSession(context: viewContext)
        session1.id = UUID()
        session1.narrative = "Oldest"
        session1.startDate = Date().addingTimeInterval(-7200) // 2 hours ago
        
        let session2 = TrackingSession(context: viewContext)
        session2.id = UUID()
        session2.narrative = "Middle"
        session2.startDate = Date().addingTimeInterval(-3600) // 1 hour ago
        
        let session3 = TrackingSession(context: viewContext)
        session3.id = UUID()
        session3.narrative = "Newest"
        session3.startDate = Date() // Now
        
        try? viewContext.save()
        
        let fetchRequest: NSFetchRequest<TrackingSession> = TrackingSession.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \TrackingSession.startDate, ascending: false)]
        let sessions = try? viewContext.fetch(fetchRequest)
        
        XCTAssertEqual(sessions?.count, 3)
        XCTAssertEqual(sessions?.first?.narrative, "Newest")
        XCTAssertEqual(sessions?.last?.narrative, "Oldest")
    }
    
    // MARK: - Session Deletion Tests
    
    func testDeleteSingleSession() {
        // Create session
        let session = TrackingSession(context: viewContext)
        session.id = UUID()
        session.narrative = "Test Session"
        session.startDate = Date()
        
        try? viewContext.save()
        
        // Verify it exists
        var fetchRequest: NSFetchRequest<TrackingSession> = TrackingSession.fetchRequest()
        var sessions = try? viewContext.fetch(fetchRequest)
        XCTAssertEqual(sessions?.count, 1)
        
        // Delete it
        viewContext.delete(session)
        try? viewContext.save()
        
        // Verify it's gone
        fetchRequest = TrackingSession.fetchRequest()
        sessions = try? viewContext.fetch(fetchRequest)
        XCTAssertEqual(sessions?.count, 0)
    }
    
    func testDeleteMultipleSessions() {
        // Create multiple sessions
        for i in 0..<5 {
            let session = TrackingSession(context: viewContext)
            session.id = UUID()
            session.narrative = "Session \(i)"
            session.startDate = Date()
        }
        
        try? viewContext.save()
        
        // Verify count
        var fetchRequest: NSFetchRequest<TrackingSession> = TrackingSession.fetchRequest()
        var sessions = try? viewContext.fetch(fetchRequest)
        XCTAssertEqual(sessions?.count, 5)
        
        // Delete first 2
        if let sessionsToDelete = sessions?.prefix(2) {
            for session in sessionsToDelete {
                viewContext.delete(session)
            }
            try? viewContext.save()
        }
        
        // Verify remaining count
        fetchRequest = TrackingSession.fetchRequest()
        sessions = try? viewContext.fetch(fetchRequest)
        XCTAssertEqual(sessions?.count, 3)
    }
    
    func testDeleteSessionWithLocations() {
        // Create session with locations
        let session = TrackingSession(context: viewContext)
        session.id = UUID()
        session.narrative = "Test Session"
        session.startDate = Date()
        
        for i in 0..<10 {
            let location = LocationEntry(context: viewContext)
            location.id = UUID()
            location.latitude = 37.7749 + Double(i) * 0.001
            location.longitude = -122.4194
            location.timestamp = Date()
            location.session = session
        }
        
        try? viewContext.save()
        
        // Verify locations exist
        var locationFetch: NSFetchRequest<LocationEntry> = LocationEntry.fetchRequest()
        var locations = try? viewContext.fetch(locationFetch)
        XCTAssertEqual(locations?.count, 10)
        
        // Delete session (should cascade delete locations)
        viewContext.delete(session)
        try? viewContext.save()
        
        // Verify locations are gone (cascade delete)
        locationFetch = LocationEntry.fetchRequest()
        locations = try? viewContext.fetch(locationFetch)
        XCTAssertEqual(locations?.count, 0)
    }
    
    // MARK: - Session Selection Tests
    
    func testSelectSession() {
        var selectedSession: TrackingSession? = nil
        var showingDetail = false
        
        // Create and select session
        let session = TrackingSession(context: viewContext)
        session.id = UUID()
        session.narrative = "Test Session"
        
        selectedSession = session
        showingDetail = true
        
        XCTAssertNotNil(selectedSession)
        XCTAssertTrue(showingDetail)
        XCTAssertEqual(selectedSession?.narrative, "Test Session")
    }
    
    func testDeselectSession() {
        var selectedSession: TrackingSession? = TrackingSession(context: viewContext)
        var showingDetail = true
        
        // Deselect
        selectedSession = nil
        showingDetail = false
        
        XCTAssertNil(selectedSession)
        XCTAssertFalse(showingDetail)
    }
    
    func testShowSessionDetail() {
        var showingSessionDetail = false
        
        XCTAssertFalse(showingSessionDetail)
        
        // Show detail
        showingSessionDetail = true
        XCTAssertTrue(showingSessionDetail)
        
        // Dismiss
        showingSessionDetail = false
        XCTAssertFalse(showingSessionDetail)
    }
    
    func testShowMapView() {
        var showingMapView = false
        
        XCTAssertFalse(showingMapView)
        
        // Show map
        showingMapView = true
        XCTAssertTrue(showingMapView)
        
        // Dismiss
        showingMapView = false
        XCTAssertFalse(showingMapView)
    }
    
    // MARK: - Session Detail Tests
    
    func testSessionDetailDisplay() {
        let session = TrackingSession(context: viewContext)
        session.id = UUID()
        session.narrative = "Morning Walk"
        session.startDate = Date()
        session.endDate = Date().addingTimeInterval(3600)
        session.isActive = false
        
        XCTAssertEqual(session.narrative, "Morning Walk")
        XCTAssertNotNil(session.startDate)
        XCTAssertNotNil(session.endDate)
        XCTAssertFalse(session.isActive)
    }
    
    func testSessionWithoutNarrative() {
        let session = TrackingSession(context: viewContext)
        session.id = UUID()
        session.narrative = nil
        session.startDate = Date()
        
        XCTAssertNil(session.narrative)
        
        // Display text for nil narrative
        let displayText = session.narrative ?? "Unnamed Session"
        XCTAssertEqual(displayText, "Unnamed Session")
    }
    
    func testActiveSessionDisplay() {
        let session = TrackingSession(context: viewContext)
        session.id = UUID()
        session.narrative = "Active Session"
        session.isActive = true
        
        XCTAssertTrue(session.isActive)
        
        let statusText = session.isActive ? "Active" : "Completed"
        XCTAssertEqual(statusText, "Active")
    }
    
    func testCompletedSessionDisplay() {
        let session = TrackingSession(context: viewContext)
        session.id = UUID()
        session.narrative = "Completed Session"
        session.isActive = false
        
        XCTAssertFalse(session.isActive)
        
        let statusText = session.isActive ? "Active" : "Completed"
        XCTAssertEqual(statusText, "Completed")
    }
    
    // MARK: - Duration Calculation Tests
    
    func testSessionDuration() {
        let session = TrackingSession(context: viewContext)
        session.startDate = Date().addingTimeInterval(-3600) // 1 hour ago
        session.endDate = Date()
        
        guard let startDate = session.startDate,
              let endDate = session.endDate else {
            XCTFail("Dates should be set")
            return
        }
        
        let duration = endDate.timeIntervalSince(startDate)
        let hours = Int(duration) / 3600
        let minutes = Int(duration) % 3600 / 60
        
        XCTAssertEqual(hours, 1)
        XCTAssertEqual(minutes, 0)
    }
    
    func testSessionDurationFormatting() {
        let duration: TimeInterval = 5430 // 1 hour 30 minutes 30 seconds
        
        let hours = Int(duration) / 3600
        let minutes = Int(duration) % 3600 / 60
        let seconds = Int(duration) % 60
        
        XCTAssertEqual(hours, 1)
        XCTAssertEqual(minutes, 30)
        XCTAssertEqual(seconds, 30)
    }
    
    func testShortDurationFormatting() {
        let duration: TimeInterval = 90 // 1 minute 30 seconds
        
        let hours = Int(duration) / 3600
        let minutes = Int(duration) % 3600 / 60
        let seconds = Int(duration) % 60
        
        XCTAssertEqual(hours, 0)
        XCTAssertEqual(minutes, 1)
        XCTAssertEqual(seconds, 30)
    }
    
    // MARK: - Refresh Tests
    
    func testRefreshIDUpdate() {
        var refreshID = UUID()
        let initialID = refreshID
        
        // Simulate refresh
        refreshID = UUID()
        
        XCTAssertNotEqual(refreshID, initialID)
    }
    
    func testRefreshOnNotification() {
        var refreshID = UUID()
        let initialID = refreshID
        
        // Simulate notification received
        refreshID = UUID()
        
        XCTAssertNotEqual(refreshID, initialID)
    }
    
    // MARK: - Session Row Tests
    
    func testSessionHasLocations() {
        let session = TrackingSession(context: viewContext)
        session.id = UUID()
        
        // Add locations
        for i in 0..<5 {
            let location = LocationEntry(context: viewContext)
            location.id = UUID()
            location.latitude = 37.7749 + Double(i) * 0.001
            location.longitude = -122.4194
            location.session = session
        }
        
        let locationCount = session.locations?.count ?? 0
        XCTAssertEqual(locationCount, 5)
        
        let hasLocations = locationCount > 0
        XCTAssertTrue(hasLocations)
    }
    
    func testSessionWithoutLocations() {
        let session = TrackingSession(context: viewContext)
        session.id = UUID()
        
        let locationCount = session.locations?.count ?? 0
        XCTAssertEqual(locationCount, 0)
        
        let hasLocations = locationCount > 0
        XCTAssertFalse(hasLocations)
    }
    
    func testLocationCountDisplay() {
        let session = TrackingSession(context: viewContext)
        session.id = UUID()
        
        for _ in 0..<10 {
            let location = LocationEntry(context: viewContext)
            location.id = UUID()
            location.latitude = 37.7749
            location.longitude = -122.4194
            location.session = session
        }
        
        let count = session.locations?.count ?? 0
        let displayText = "\(count) points"
        
        XCTAssertEqual(displayText, "10 points")
    }
    
    // MARK: - Statistics Tests
    
    func testCalculateDistanceBetweenLocations() {
        let location1 = LocationEntry(context: viewContext)
        location1.latitude = 37.7749
        location1.longitude = -122.4194
        
        let location2 = LocationEntry(context: viewContext)
        location2.latitude = 37.7849
        location2.longitude = -122.4294
        
        let loc1 = CLLocation(latitude: location1.latitude, longitude: location1.longitude)
        let loc2 = CLLocation(latitude: location2.latitude, longitude: location2.longitude)
        
        let distance = loc1.distance(from: loc2)
        
        XCTAssertGreaterThan(distance, 0)
        XCTAssertLessThan(distance, 2000) // Should be less than 2km
    }
    
    func testAverageAccuracy() {
        let session = TrackingSession(context: viewContext)
        session.id = UUID()
        
        let accuracies: [Double] = [10.0, 15.0, 12.0, 8.0, 20.0]
        
        for accuracy in accuracies {
            let location = LocationEntry(context: viewContext)
            location.id = UUID()
            location.latitude = 37.7749
            location.longitude = -122.4194
            location.accuracy = accuracy
            location.session = session
        }
        
        let locations = session.locations?.allObjects as? [LocationEntry] ?? []
        let totalAccuracy = locations.reduce(0.0) { $0 + $1.accuracy }
        let averageAccuracy = totalAccuracy / Double(locations.count)
        
        XCTAssertEqual(averageAccuracy, 13.0, accuracy: 0.01)
    }
    
    func testMaxSpeed() {
        let session = TrackingSession(context: viewContext)
        session.id = UUID()
        
        let speeds: [Double] = [5.0, 10.0, 8.0, 12.0, 6.0]
        
        for speed in speeds {
            let location = LocationEntry(context: viewContext)
            location.id = UUID()
            location.latitude = 37.7749
            location.longitude = -122.4194
            location.speed = speed
            location.session = session
        }
        
        let locations = session.locations?.allObjects as? [LocationEntry] ?? []
        let maxSpeed = locations.map { $0.speed }.max()
        
        XCTAssertEqual(maxSpeed, 12.0)
    }
    
    // MARK: - Export Tests
    
    func testExportMenuPresentation() {
        var showingExportMenu = false
        
        XCTAssertFalse(showingExportMenu)
        
        // Show export menu
        showingExportMenu = true
        XCTAssertTrue(showingExportMenu)
        
        // Dismiss
        showingExportMenu = false
        XCTAssertFalse(showingExportMenu)
    }
    
    func testExportSheetPresentation() {
        var showingExportSheet = false
        var exportFileURL: URL? = nil
        
        XCTAssertFalse(showingExportSheet)
        XCTAssertNil(exportFileURL)
        
        // Set export URL
        exportFileURL = URL(fileURLWithPath: "/tmp/test.gpx")
        showingExportSheet = true
        
        XCTAssertTrue(showingExportSheet)
        XCTAssertNotNil(exportFileURL)
    }
    
    // MARK: - Date Formatting Tests
    
    func testDateFormatterDetailed() {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .medium
        
        let date = Date()
        let formatted = formatter.string(from: date)
        
        XCTAssertFalse(formatted.isEmpty)
    }
    
    func testDateFormatterShort() {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .none
        
        let date = Date()
        let formatted = formatter.string(from: date)
        
        XCTAssertFalse(formatted.isEmpty)
    }
    
    // MARK: - Integration Tests
    
    func testCompleteSessionLifecycle() {
        // Create session
        let session = TrackingSession(context: viewContext)
        session.id = UUID()
        session.narrative = "Complete Test"
        session.startDate = Date()
        session.isActive = true
        
        // Add locations
        for i in 0..<5 {
            let location = LocationEntry(context: viewContext)
            location.id = UUID()
            location.latitude = 37.7749 + Double(i) * 0.001
            location.longitude = -122.4194
            location.timestamp = Date()
            location.session = session
        }
        
        try? viewContext.save()
        
        // Verify it was saved
        let fetchRequest: NSFetchRequest<TrackingSession> = TrackingSession.fetchRequest()
        let sessions = try? viewContext.fetch(fetchRequest)
        XCTAssertEqual(sessions?.count, 1)
        
        // Complete the session
        session.isActive = false
        session.endDate = Date()
        try? viewContext.save()
        
        // Verify updates
        XCTAssertFalse(session.isActive)
        XCTAssertNotNil(session.endDate)
        
        // Delete session
        viewContext.delete(session)
        try? viewContext.save()
        
        // Verify deletion
        let finalFetch: NSFetchRequest<TrackingSession> = TrackingSession.fetchRequest()
        let finalSessions = try? viewContext.fetch(finalFetch)
        XCTAssertEqual(finalSessions?.count, 0)
    }
    
    func testMultipleSessionsWithDifferentStates() {
        // Create active session
        let activeSession = TrackingSession(context: viewContext)
        activeSession.id = UUID()
        activeSession.narrative = "Active"
        activeSession.startDate = Date()
        activeSession.isActive = true
        
        // Create completed session
        let completedSession = TrackingSession(context: viewContext)
        completedSession.id = UUID()
        completedSession.narrative = "Completed"
        completedSession.startDate = Date().addingTimeInterval(-3600)
        completedSession.endDate = Date()
        completedSession.isActive = false
        
        try? viewContext.save()
        
        // Fetch all sessions
        let fetchRequest: NSFetchRequest<TrackingSession> = TrackingSession.fetchRequest()
        let sessions = try? viewContext.fetch(fetchRequest)
        
        XCTAssertEqual(sessions?.count, 2)
        
        // Filter active
        let activeSessions = sessions?.filter { $0.isActive }
        XCTAssertEqual(activeSessions?.count, 1)
        
        // Filter completed
        let completedSessions = sessions?.filter { !$0.isActive }
        XCTAssertEqual(completedSessions?.count, 1)
    }
    
    // MARK: - Sheet Context Tests
    
    func testSessionAccessibleInDifferentContext() {
        // This test simulates the sheet presentation scenario where a session
        // from one context needs to be accessed in another context (like in a sheet)
        
        // Create session in main context
        let session = TrackingSession(context: viewContext)
        session.id = UUID()
        session.narrative = "Test Session"
        session.startDate = Date()
        session.isActive = false
        
        // Add some locations
        for i in 0..<5 {
            let location = LocationEntry(context: viewContext)
            location.id = UUID()
            location.latitude = 37.7749 + Double(i) * 0.001
            location.longitude = -122.4194 + Double(i) * 0.001
            location.timestamp = Date().addingTimeInterval(TimeInterval(i * 60))
            location.accuracy = 10.0
            location.session = session
        }
        
        try? viewContext.save()
        
        // Verify locations are accessible from session
        XCTAssertEqual(session.locations?.count, 5, "Session should have 5 locations")
        
        // Simulate accessing the session in a different context (like a sheet would)
        let backgroundContext = persistenceController.container.newBackgroundContext()
        let expectation = self.expectation(description: "Background context access")
        
        backgroundContext.perform {
            // Use objectID to fetch session in different context
            let sessionID = session.objectID
            
            do {
                let sessionInBgContext = try backgroundContext.existingObject(with: sessionID) as? TrackingSession
                XCTAssertNotNil(sessionInBgContext, "Session should be accessible in background context")
                XCTAssertEqual(sessionInBgContext?.narrative, "Test Session")
                
                // Verify locations are accessible
                let locationCount = sessionInBgContext?.locations?.count ?? 0
                XCTAssertEqual(locationCount, 5, "Locations should be accessible in background context")
                
                expectation.fulfill()
            } catch {
                XCTFail("Failed to access session in background context: \(error)")
                expectation.fulfill()
            }
        }
        
        waitForExpectations(timeout: 2.0)
    }
    
    func testLocationsFetchableViaPredicateInDifferentContext() {
        // Test that locations can be fetched using a predicate even when
        // the session object is from a different context
        
        // Create session in main context
        let session = TrackingSession(context: viewContext)
        session.id = UUID()
        session.narrative = "Predicate Test Session"
        session.startDate = Date()
        
        // Add locations
        for i in 0..<10 {
            let location = LocationEntry(context: viewContext)
            location.id = UUID()
            location.latitude = 37.7749 + Double(i) * 0.001
            location.longitude = -122.4194 + Double(i) * 0.001
            location.timestamp = Date().addingTimeInterval(TimeInterval(i * 60))
            location.session = session
        }
        
        try? viewContext.save()
        
        // Now simulate fetching locations in a different context using the session
        let backgroundContext = persistenceController.container.newBackgroundContext()
        let expectation = self.expectation(description: "Fetch locations with predicate")
        
        backgroundContext.perform {
            // Get session in this context
            do {
                let sessionInBgContext = try backgroundContext.existingObject(with: session.objectID) as? TrackingSession
                XCTAssertNotNil(sessionInBgContext)
                
                // Fetch locations using predicate (this is what TripMapView does)
                let fetchRequest: NSFetchRequest<LocationEntry> = LocationEntry.fetchRequest()
                fetchRequest.predicate = NSPredicate(format: "session == %@", sessionInBgContext!)
                fetchRequest.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: true)]
                
                let locations = try backgroundContext.fetch(fetchRequest)
                XCTAssertEqual(locations.count, 10, "Should fetch all 10 locations")
                
                expectation.fulfill()
            } catch {
                XCTFail("Failed to fetch locations: \(error)")
                expectation.fulfill()
            }
        }
        
        waitForExpectations(timeout: 2.0)
    }
}
