import XCTest
import CoreData
@testable import TrackMe

/// Unit tests for CoreDataSessionRepository
/// Tests all CRUD operations, error handling, and data integrity with real Core Data
final class CoreDataSessionRepositoryTests: XCTestCase {
    
    var repository: CoreDataSessionRepository!
    var testContext: NSManagedObjectContext!
    var testContainer: NSPersistentContainer!
    
    override func setUp() {
        super.setUp()
        
        // Setup - create Core Data stack manually (bypassing TrackMeTestCase)
        let bundle = Bundle(for: TrackingSession.self)
        guard let modelURL = bundle.url(forResource: "TrackMe", withExtension: "momd"),
              let model = NSManagedObjectModel(contentsOf: modelURL) else {
            fatalError("Could not load Core Data model")
        }
        
        testContainer = NSPersistentContainer(name: "TrackMe", managedObjectModel: model)
        let description = NSPersistentStoreDescription()
        description.type = NSInMemoryStoreType
        description.shouldAddStoreAsynchronously = false
        testContainer.persistentStoreDescriptions = [description]
        
        var loadError: Error?
        testContainer.loadPersistentStores { _, error in
            loadError = error
        }
        
        if let loadError = loadError {
            fatalError("Failed to load stores: \(loadError)")
        }
        
        testContext = testContainer.viewContext
        repository = CoreDataSessionRepository(context: testContext)
    }
    
    override func tearDown() {
        repository = nil
        testContext = nil
        testContainer = nil
        super.tearDown()
    }
    
    // MARK: - Create Session Tests
    
    func testCreateSession() throws {
        // Given
        let narrative = "Morning commute to work"
        let startDate = Date()
        
        print("DEBUG: testContext = \(String(describing: testContext))")
        print("DEBUG: repository = \(String(describing: repository))")
        
        // When
        do {
            let session = try repository.createSession(narrative: narrative, startDate: startDate)
            
            // Then
            XCTAssertNotNil(session.id, "Session should have an ID")
            XCTAssertEqual(session.narrative, narrative)
            XCTAssertEqual(session.startDate, startDate)
            XCTAssertTrue(session.isActive, "New session should be active")
            XCTAssertNil(session.endDate, "New session should not have end date")
        } catch {
            XCTFail("Failed to create session: \(error)")
        }
    }
    
    func testCreateSessionPersistsToDatabase() throws {
        // Given
        let narrative = "Weekend hiking trip"
        let startDate = Date()
        
        // When
        let session = try repository.createSession(narrative: narrative, startDate: startDate)
        let sessionId = session.id
        
        // Then - Verify it's persisted by fetching all sessions
        let allSessions = try repository.fetchAllSessions()
        XCTAssertEqual(allSessions.count, 1)
        XCTAssertEqual(allSessions.first?.id, sessionId)
        XCTAssertEqual(allSessions.first?.narrative, narrative)
    }
    
    func testCreateMultipleSessions() throws {
        // Given
        let narratives = ["Session 1", "Session 2", "Session 3"]
        var createdSessions: [TrackingSession] = []
        
        // When
        for narrative in narratives {
            let session = try repository.createSession(narrative: narrative, startDate: Date())
            createdSessions.append(session)
        }
        
        // Then
        let allSessions = try repository.fetchAllSessions()
        XCTAssertEqual(allSessions.count, narratives.count)
        
        // Verify all sessions are present
        let allIds = Set(allSessions.compactMap { $0.id })
        let createdIds = Set(createdSessions.compactMap { $0.id })
        XCTAssertEqual(allIds, createdIds)
    }
    
    func testCreateSessionWithEmptyNarrative() throws {
        // Given
        let narrative = ""
        let startDate = Date()
        
        // When
        let session = try repository.createSession(narrative: narrative, startDate: startDate)
        
        // Then - Should allow empty narrative
        XCTAssertEqual(session.narrative, "")
        XCTAssertTrue(session.isActive)
    }
    
    // MARK: - Fetch Active Sessions Tests
    
    func testFetchActiveSessionsReturnsOnlyActiveSessions() throws {
        // Given - Create mix of active and inactive sessions
        let activeSession1 = try repository.createSession(narrative: "Active 1", startDate: Date())
        let activeSession2 = try repository.createSession(narrative: "Active 2", startDate: Date())
        
        let inactiveSession = try repository.createSession(narrative: "Inactive", startDate: Date())
        try repository.endSession(inactiveSession, endDate: Date())
        
        // When
        let activeSessions = try repository.fetchActiveSessions()
        
        // Then
        XCTAssertEqual(activeSessions.count, 2)
        
        let activeIds = Set(activeSessions.compactMap { $0.id })
        XCTAssertTrue(activeIds.contains(activeSession1.id!))
        XCTAssertTrue(activeIds.contains(activeSession2.id!))
        XCTAssertFalse(activeIds.contains(inactiveSession.id!))
    }
    
    func testFetchActiveSessionsReturnsEmptyWhenNoneActive() throws {
        // Given - Create only inactive sessions
        let session1 = try repository.createSession(narrative: "Session 1", startDate: Date())
        let session2 = try repository.createSession(narrative: "Session 2", startDate: Date())
        
        try repository.endSession(session1, endDate: Date())
        try repository.endSession(session2, endDate: Date())
        
        // When
        let activeSessions = try repository.fetchActiveSessions()
        
        // Then
        XCTAssertTrue(activeSessions.isEmpty)
    }
    
    func testFetchActiveSessionsWhenNone() throws {
        // Given - No sessions created
        
        // When
        let activeSessions = try repository.fetchActiveSessions()
        
        // Then
        XCTAssertTrue(activeSessions.isEmpty)
    }
    
    // MARK: - Fetch All Sessions Tests
    
    func testFetchAllSessionsReturnsBothActiveAndInactive() throws {
        // Given
        let activeSession = try repository.createSession(narrative: "Active", startDate: Date())
        let inactiveSession = try repository.createSession(narrative: "Inactive", startDate: Date())
        try repository.endSession(inactiveSession, endDate: Date())
        
        // When
        let allSessions = try repository.fetchAllSessions()
        
        // Then
        XCTAssertEqual(allSessions.count, 2)
        
        let ids = Set(allSessions.compactMap { $0.id })
        XCTAssertTrue(ids.contains(activeSession.id!))
        XCTAssertTrue(ids.contains(inactiveSession.id!))
    }
    
    func testFetchAllSessionsSortedByStartDateDescending() throws {
        // Given - Create sessions with different start dates
        let date1 = Date(timeIntervalSince1970: 1000)
        let date2 = Date(timeIntervalSince1970: 2000)
        let date3 = Date(timeIntervalSince1970: 3000)
        
        let session1 = try repository.createSession(narrative: "First", startDate: date1)
        let session2 = try repository.createSession(narrative: "Second", startDate: date2)
        let session3 = try repository.createSession(narrative: "Third", startDate: date3)
        
        // When
        let allSessions = try repository.fetchAllSessions()
        
        // Then - Should be sorted newest first
        XCTAssertEqual(allSessions.count, 3)
        XCTAssertEqual(allSessions[0].id, session3.id) // Newest
        XCTAssertEqual(allSessions[1].id, session2.id)
        XCTAssertEqual(allSessions[2].id, session1.id) // Oldest
    }
    
    func testFetchAllSessionsWhenEmpty() throws {
        // Given - No sessions
        
        // When
        let allSessions = try repository.fetchAllSessions()
        
        // Then
        XCTAssertTrue(allSessions.isEmpty)
    }
    
    // MARK: - Fetch Sessions with Predicate Tests
    
    func testFetchSessionsWithNarrativePredicate() throws {
        // Given
        let targetNarrative = "Morning commute"
        _ = try repository.createSession(narrative: targetNarrative, startDate: Date())
        _ = try repository.createSession(narrative: "Evening run", startDate: Date())
        _ = try repository.createSession(narrative: "Weekend trip", startDate: Date())
        
        // When
        let predicate = NSPredicate(format: "narrative CONTAINS[c] %@", "commute")
        let matchingSessions = try repository.fetchSessions(predicate: predicate, sortDescriptors: nil)
        
        // Then
        XCTAssertEqual(matchingSessions.count, 1)
        XCTAssertEqual(matchingSessions.first?.narrative, targetNarrative)
    }
    
    func testFetchSessionsWithDateRangePredicate() throws {
        // Given
        let startDate1 = Date(timeIntervalSince1970: 1000)
        let startDate2 = Date(timeIntervalSince1970: 2000)
        let startDate3 = Date(timeIntervalSince1970: 3000)
        
        _ = try repository.createSession(narrative: "Old", startDate: startDate1)
        let middleSession = try repository.createSession(narrative: "Middle", startDate: startDate2)
        _ = try repository.createSession(narrative: "New", startDate: startDate3)
        
        // When - Fetch sessions between dates
        let predicate = NSPredicate(format: "startDate >= %@ AND startDate <= %@",
                                   startDate2 as NSDate,
                                   startDate2 as NSDate)
        let matchingSessions = try repository.fetchSessions(predicate: predicate, sortDescriptors: nil)
        
        // Then
        XCTAssertEqual(matchingSessions.count, 1)
        XCTAssertEqual(matchingSessions.first?.id, middleSession.id)
    }
    
    func testFetchSessionsWithSortDescriptor() throws {
        // Given
        _ = try repository.createSession(narrative: "Zebra", startDate: Date())
        _ = try repository.createSession(narrative: "Alpha", startDate: Date())
        _ = try repository.createSession(narrative: "Beta", startDate: Date())
        
        // When - Sort alphabetically by narrative
        let sortDescriptor = NSSortDescriptor(key: "narrative", ascending: true)
        let sortedSessions = try repository.fetchSessions(predicate: nil, sortDescriptors: [sortDescriptor])
        
        // Then
        XCTAssertEqual(sortedSessions.count, 3)
        XCTAssertEqual(sortedSessions[0].narrative, "Alpha")
        XCTAssertEqual(sortedSessions[1].narrative, "Beta")
        XCTAssertEqual(sortedSessions[2].narrative, "Zebra")
    }
    
    // MARK: - End Session Tests
    
    func testEndSession() throws {
        // Given
        let session = try repository.createSession(narrative: "Test Session", startDate: Date())
        XCTAssertTrue(session.isActive)
        XCTAssertNil(session.endDate)
        
        // When
        let endDate = Date()
        try repository.endSession(session, endDate: endDate)
        
        // Then
        XCTAssertFalse(session.isActive)
        XCTAssertEqual(session.endDate, endDate)
    }
    
    func testEndSessionPersistsChanges() throws {
        // Given
        let session = try repository.createSession(narrative: "Test Session", startDate: Date())
        let sessionId = session.id
        
        // When
        let endDate = Date()
        try repository.endSession(session, endDate: endDate)
        
        // Then - Verify changes persisted by refetching
        let allSessions = try repository.fetchAllSessions()
        let endedSession = allSessions.first { $0.id == sessionId }
        
        XCTAssertNotNil(endedSession)
        XCTAssertFalse(endedSession!.isActive)
        XCTAssertEqual(endedSession!.endDate, endDate)
    }
    
    func testEndSessionRemovesFromActiveList() throws {
        // Given
        let session = try repository.createSession(narrative: "Test Session", startDate: Date())
        
        // When
        try repository.endSession(session, endDate: Date())
        
        // Then
        let activeSessions = try repository.fetchActiveSessions()
        XCTAssertTrue(activeSessions.isEmpty)
    }
    
    func testEndMultipleSessions() throws {
        // Given
        let session1 = try repository.createSession(narrative: "Session 1", startDate: Date())
        let session2 = try repository.createSession(narrative: "Session 2", startDate: Date())
        let session3 = try repository.createSession(narrative: "Session 3", startDate: Date())
        
        // When - End first two sessions
        try repository.endSession(session1, endDate: Date())
        try repository.endSession(session2, endDate: Date())
        
        // Then
        let activeSessions = try repository.fetchActiveSessions()
        XCTAssertEqual(activeSessions.count, 1)
        XCTAssertEqual(activeSessions.first?.id, session3.id)
    }
    
    // MARK: - Delete Session Tests
    
    func testDeleteSession() throws {
        // Given
        let session = try repository.createSession(narrative: "To Delete", startDate: Date())
        let sessionId = session.id
        
        // Verify it exists
        var allSessions = try repository.fetchAllSessions()
        XCTAssertEqual(allSessions.count, 1)
        
        // When
        try repository.deleteSession(session)
        
        // Then
        allSessions = try repository.fetchAllSessions()
        XCTAssertTrue(allSessions.isEmpty)
    }
    
    func testDeleteSessionRemovesFromDatabase() throws {
        // Given
        let session1 = try repository.createSession(narrative: "Keep", startDate: Date())
        let session2 = try repository.createSession(narrative: "Delete", startDate: Date())
        let session1Id = session1.id
        
        // When
        try repository.deleteSession(session2)
        
        // Then
        let remainingSessions = try repository.fetchAllSessions()
        XCTAssertEqual(remainingSessions.count, 1)
        XCTAssertEqual(remainingSessions.first?.id, session1Id)
    }
    
    func testDeleteMultipleSessions() throws {
        // Given
        let sessions = try (1...5).map {
            try repository.createSession(narrative: "Session \($0)", startDate: Date())
        }
        
        // When - Delete first 3
        for session in sessions.prefix(3) {
            try repository.deleteSession(session)
        }
        
        // Then
        let remainingSessions = try repository.fetchAllSessions()
        XCTAssertEqual(remainingSessions.count, 2)
    }
    
    // MARK: - Location Count Tests
    
    func testLocationCountForSessionWithNoLocations() throws {
        // Given
        let session = try repository.createSession(narrative: "Empty Session", startDate: Date())
        
        // When
        let count = try repository.locationCount(for: session)
        
        // Then
        XCTAssertEqual(count, 0)
    }
    
    func testLocationCountForSessionWithLocations() throws {
        // Given
        let session = createTestSession()
        
        // Add some location entries using TestFixtures
        _ = TestFixtures.createLocationEntries(count: 5, in: testContext, for: session)
        saveContext()
        
        // When
        let count = try repository.locationCount(for: session)
        
        // Then
        XCTAssertEqual(count, 5)
    }
    
    // MARK: - Recover Orphaned Sessions Tests
    
    func testRecoverOrphanedSessionsWithNoOrphans() throws {
        // Given - Create only inactive sessions
        let session = try repository.createSession(narrative: "Session", startDate: Date())
        try repository.endSession(session, endDate: Date())
        
        // When
        let recoveredCount = try repository.recoverOrphanedSessions()
        
        // Then
        XCTAssertEqual(recoveredCount, 0)
    }
    
    func testRecoverOrphanedSessionsWithSingleOrphan() throws {
        // Given - Create an active session (simulating orphaned state)
        let session = try repository.createSession(narrative: "Orphaned", startDate: Date())
        XCTAssertTrue(session.isActive)
        
        // When
        let recoveredCount = try repository.recoverOrphanedSessions()
        
        // Then
        XCTAssertEqual(recoveredCount, 1)
        XCTAssertFalse(session.isActive)
        XCTAssertNotNil(session.endDate)
    }
    
    func testRecoverOrphanedSessionsWithMultipleOrphans() throws {
        // Given - Create multiple active sessions
        let session1 = try repository.createSession(narrative: "Orphan 1", startDate: Date())
        let session2 = try repository.createSession(narrative: "Orphan 2", startDate: Date())
        let session3 = try repository.createSession(narrative: "Orphan 3", startDate: Date())
        
        // When
        let recoveredCount = try repository.recoverOrphanedSessions()
        
        // Then
        XCTAssertEqual(recoveredCount, 3)
        
        // Verify all are now inactive
        let activeSessions = try repository.fetchActiveSessions()
        XCTAssertTrue(activeSessions.isEmpty)
        
        XCTAssertFalse(session1.isActive)
        XCTAssertFalse(session2.isActive)
        XCTAssertFalse(session3.isActive)
        
        XCTAssertNotNil(session1.endDate)
        XCTAssertNotNil(session2.endDate)
        XCTAssertNotNil(session3.endDate)
    }
    
    func testRecoverOrphanedSessionsSetsEndDate() throws {
        // Given
        let session = try repository.createSession(narrative: "Orphaned", startDate: Date())
        let beforeRecovery = Date()
        
        // When
        _ = try repository.recoverOrphanedSessions()
        let afterRecovery = Date()
        
        // Then
        XCTAssertNotNil(session.endDate)
        XCTAssertGreaterThanOrEqual(session.endDate!, beforeRecovery)
        XCTAssertLessThanOrEqual(session.endDate!, afterRecovery)
    }
    
    func testRecoverOrphanedSessionsWithMixedSessions() throws {
        // Given - Mix of active and inactive
        let activeSession1 = try repository.createSession(narrative: "Active 1", startDate: Date())
        
        let inactiveSession = try repository.createSession(narrative: "Inactive", startDate: Date())
        try repository.endSession(inactiveSession, endDate: Date())
        
        let activeSession2 = try repository.createSession(narrative: "Active 2", startDate: Date())
        
        // When
        let recoveredCount = try repository.recoverOrphanedSessions()
        
        // Then - Should only recover the 2 active sessions
        XCTAssertEqual(recoveredCount, 2)
        
        // All should now be inactive
        let activeSessions = try repository.fetchActiveSessions()
        XCTAssertTrue(activeSessions.isEmpty)
        
        XCTAssertFalse(activeSession1.isActive)
        XCTAssertFalse(activeSession2.isActive)
        XCTAssertFalse(inactiveSession.isActive) // Still inactive
    }
    
    // MARK: - Data Integrity Tests
    
    func testSessionIDsAreUnique() throws {
        // Given/When
        let session1 = try repository.createSession(narrative: "Session 1", startDate: Date())
        let session2 = try repository.createSession(narrative: "Session 2", startDate: Date())
        let session3 = try repository.createSession(narrative: "Session 3", startDate: Date())
        
        // Then
        let ids = [session1.id, session2.id, session3.id].compactMap { $0 }
        let uniqueIds = Set(ids)
        
        XCTAssertEqual(ids.count, uniqueIds.count, "All session IDs should be unique")
    }
    
    func testSessionDatesArePreserved() throws {
        // Given
        let startDate = Date(timeIntervalSince1970: 1609459200) // Jan 1, 2021
        let endDate = Date(timeIntervalSince1970: 1609545600)   // Jan 2, 2021
        
        // When
        let session = try repository.createSession(narrative: "Test", startDate: startDate)
        try repository.endSession(session, endDate: endDate)
        
        // Then - Refetch and verify dates are preserved
        let allSessions = try repository.fetchAllSessions()
        let refetchedSession = allSessions.first!
        
        XCTAssertEqual(refetchedSession.startDate, startDate)
        XCTAssertEqual(refetchedSession.endDate, endDate)
    }
    
    func testSessionNarrativeIsPreserved() throws {
        // Given
        let narratives = [
            "Simple narrative",
            "Narrative with special chars: !@#$%^&*()",
            "Multi-line\nnarrative\nwith\nbreaks",
            "UTF-8: 你好世界 🌍 Здравствуй мир",
            ""
        ]
        
        // When/Then
        for narrative in narratives {
            let session = try repository.createSession(narrative: narrative, startDate: Date())
            let refetched = try repository.fetchAllSessions().first { $0.id == session.id }
            
            XCTAssertEqual(refetched?.narrative, narrative,
                          "Narrative should be preserved: \(narrative)")
            
            try repository.deleteSession(session)
        }
    }
    
    // MARK: - Error Handling Tests
    
    func testFetchSessionsDoesNotThrowOnEmptyDatabase() throws {
        // Given - Empty database
        
        // When/Then - Should not throw
        XCTAssertNoThrow(try repository.fetchAllSessions())
        XCTAssertNoThrow(try repository.fetchActiveSessions())
    }
    
    // MARK: - Performance Tests
    
    func testCreateManySessionsPerformance() {
        measure {
            // Create 100 sessions
            for i in 1...100 {
                _ = try? repository.createSession(
                    narrative: "Performance Test \(i)",
                    startDate: Date()
                )
            }
        }
    }
    
    func testFetchManySessionsPerformance() throws {
        // Given - Create 100 sessions
        for i in 1...100 {
            _ = try repository.createSession(
                narrative: "Session \(i)",
                startDate: Date(timeIntervalSince1970: Double(i * 1000))
            )
        }
        
        // When/Then
        measure {
            _ = try? repository.fetchAllSessions()
        }
    }
    
    // MARK: - Helper Methods
    
    func createTestSession(
        narrative: String = "Test Session",
        isActive: Bool = true,
        startDate: Date = Date(),
        endDate: Date? = nil
    ) -> TrackingSession {
        let session = TrackingSession(context: testContext)
        session.id = UUID()
        session.narrative = narrative
        session.isActive = isActive
        session.startDate = startDate
        session.endDate = endDate
        return session
    }
    
    func saveContext() {
        do {
            if testContext.hasChanges {
                try testContext.save()
            }
        } catch {
            XCTFail("Failed to save test context: \(error)")
        }
    }
}
