import Foundation
import CoreData
import CoreLocation
@testable import TrackMe

// MARK: - Mock Session Repository

/// Mock implementation of SessionRepositoryProtocol for testing
class MockSessionRepository: SessionRepositoryProtocol {
    
    // MARK: - Configuration
    
    /// When true, all operations will throw errors
    var shouldFail = false
    
    /// Custom error to throw when shouldFail is true
    var errorToThrow: Error = AppError.dataStorageError(NSError(domain: "MockError", code: 1))
    
    // MARK: - Stored Data
    
    /// In-memory storage for sessions
    private(set) var sessions: [TrackingSession] = []
    
    /// Counter for tracking method calls
    private(set) var fetchActiveSessionsCallCount = 0
    private(set) var fetchAllSessionsCallCount = 0
    private(set) var createSessionCallCount = 0
    private(set) var endSessionCallCount = 0
    private(set) var deleteSessionCallCount = 0
    private(set) var recoverOrphanedSessionsCallCount = 0
    
    // MARK: - Captured Parameters
    
    private(set) var lastCreatedNarrative: String?
    private(set) var lastCreatedStartDate: Date?
    private(set) var lastEndedSession: TrackingSession?
    private(set) var lastDeletedSession: TrackingSession?
    
    // MARK: - SessionRepositoryProtocol Implementation
    
    func fetchActiveSessions() throws -> [TrackingSession] {
        fetchActiveSessionsCallCount += 1
        
        if shouldFail {
            throw errorToThrow
        }
        
        return sessions.filter { $0.isActive }
    }
    
    func fetchAllSessions() throws -> [TrackingSession] {
        fetchAllSessionsCallCount += 1
        
        if shouldFail {
            throw errorToThrow
        }
        
        return sessions.sorted { ($0.startDate ?? Date.distantPast) > ($1.startDate ?? Date.distantPast) }
    }
    
    func fetchSessions(predicate: NSPredicate?, sortDescriptors: [NSSortDescriptor]?) throws -> [TrackingSession] {
        if shouldFail {
            throw errorToThrow
        }
        
        var filtered = sessions
        
        // Apply predicate if provided
        if let predicate = predicate {
            filtered = (sessions as NSArray).filtered(using: predicate) as! [TrackingSession]
        }
        
        // Apply sort descriptors if provided
        if let sortDescriptors = sortDescriptors {
            filtered = (filtered as NSArray).sortedArray(using: sortDescriptors) as! [TrackingSession]
        }
        
        return filtered
    }
    
    func createSession(narrative: String, startDate: Date) throws -> TrackingSession {
        createSessionCallCount += 1
        lastCreatedNarrative = narrative
        lastCreatedStartDate = startDate
        
        if shouldFail {
            throw errorToThrow
        }
        
        // Create a mock session (not backed by Core Data)
        let session = MockTrackingSession()
        session.id = UUID()
        session.narrative = narrative
        session.startDate = startDate
        session.isActive = true
        
        sessions.append(session)
        return session
    }
    
    func endSession(_ session: TrackingSession, endDate: Date) throws {
        endSessionCallCount += 1
        lastEndedSession = session
        
        if shouldFail {
            throw errorToThrow
        }
        
        session.endDate = endDate
        session.isActive = false
    }
    
    func deleteSession(_ session: TrackingSession) throws {
        deleteSessionCallCount += 1
        lastDeletedSession = session
        
        if shouldFail {
            throw errorToThrow
        }
        
        sessions.removeAll { $0.id == session.id }
    }
    
    func locationCount(for session: TrackingSession) throws -> Int {
        if shouldFail {
            throw errorToThrow
        }
        
        if let locations = session.locations as? Set<LocationEntry> {
            return locations.count
        }
        return 0
    }
    
    func recoverOrphanedSessions() throws -> Int {
        recoverOrphanedSessionsCallCount += 1
        
        if shouldFail {
            throw errorToThrow
        }
        
        let orphaned = sessions.filter { $0.isActive }
        let endDate = Date()
        
        for session in orphaned {
            session.isActive = false
            session.endDate = endDate
        }
        
        return orphaned.count
    }
    
    // MARK: - Helper Methods
    
    /// Resets the mock to its initial state
    func reset() {
        sessions.removeAll()
        shouldFail = false
        fetchActiveSessionsCallCount = 0
        fetchAllSessionsCallCount = 0
        createSessionCallCount = 0
        endSessionCallCount = 0
        deleteSessionCallCount = 0
        recoverOrphanedSessionsCallCount = 0
        lastCreatedNarrative = nil
        lastCreatedStartDate = nil
        lastEndedSession = nil
        lastDeletedSession = nil
    }
    
    /// Adds a pre-configured session for testing
    func addSession(_ session: TrackingSession) {
        sessions.append(session)
    }
}

// MARK: - Mock Location Repository

/// Mock implementation of LocationRepositoryProtocol for testing
class MockLocationRepository: LocationRepositoryProtocol {
    
    // MARK: - Configuration
    
    /// When true, all operations will throw errors
    var shouldFail = false
    
    /// Custom error to throw when shouldFail is true
    var errorToThrow: Error = AppError.dataStorageError(NSError(domain: "MockError", code: 1))
    
    // MARK: - Stored Data
    
    /// In-memory storage for location entries by session ID
    private var locationsBySession: [UUID: [LocationEntry]] = [:]
    
    /// Counter for tracking method calls
    private(set) var saveLocationCallCount = 0
    private(set) var fetchLocationsCallCount = 0
    private(set) var deleteLocationsCallCount = 0
    
    // MARK: - Captured Parameters
    
    private(set) var lastSavedLocation: CLLocation?
    private(set) var lastSavedSession: TrackingSession?
    
    // MARK: - LocationRepositoryProtocol Implementation
    
    func saveLocation(_ location: CLLocation, for session: TrackingSession) throws -> LocationEntry {
        saveLocationCallCount += 1
        lastSavedLocation = location
        lastSavedSession = session
        
        if shouldFail {
            throw errorToThrow
        }
        
        // Create a mock location entry
        let entry = MockLocationEntry()
        entry.id = UUID()
        entry.latitude = location.coordinate.latitude
        entry.longitude = location.coordinate.longitude
        entry.altitude = location.altitude
        entry.accuracy = location.horizontalAccuracy
        entry.course = location.course
        entry.speed = location.speed
        entry.timestamp = location.timestamp
        entry.session = session
        
        // Store in memory
        guard let sessionId = session.id else {
            throw AppError.sessionNotFound
        }
        
        var locations = locationsBySession[sessionId] ?? []
        locations.append(entry)
        locationsBySession[sessionId] = locations
        
        return entry
    }
    
    func fetchLocations(for session: TrackingSession) throws -> [LocationEntry] {
        return try fetchLocations(for: session, sortDescriptors: nil, batchSize: nil)
    }
    
    func fetchLocations(for session: TrackingSession, sortDescriptors: [NSSortDescriptor]?, batchSize: Int?) throws -> [LocationEntry] {
        fetchLocationsCallCount += 1
        
        if shouldFail {
            throw errorToThrow
        }
        
        guard let sessionId = session.id else {
            return []
        }
        
        var locations = locationsBySession[sessionId] ?? []
        
        // Apply sort descriptors if provided
        if let sortDescriptors = sortDescriptors {
            locations = (locations as NSArray).sortedArray(using: sortDescriptors) as! [LocationEntry]
        }
        
        // Apply batch size if provided
        if let batchSize = batchSize, batchSize > 0 {
            locations = Array(locations.prefix(batchSize))
        }
        
        return locations
    }
    
    func deleteLocations(for session: TrackingSession) throws {
        deleteLocationsCallCount += 1
        
        if shouldFail {
            throw errorToThrow
        }
        
        guard let sessionId = session.id else {
            return
        }
        
        locationsBySession.removeValue(forKey: sessionId)
    }
    
    func locationCount(for session: TrackingSession) throws -> Int {
        if shouldFail {
            throw errorToThrow
        }
        
        guard let sessionId = session.id else {
            return 0
        }
        
        return locationsBySession[sessionId]?.count ?? 0
    }
    
    // MARK: - Helper Methods
    
    /// Resets the mock to its initial state
    func reset() {
        locationsBySession.removeAll()
        shouldFail = false
        saveLocationCallCount = 0
        fetchLocationsCallCount = 0
        deleteLocationsCallCount = 0
        lastSavedLocation = nil
        lastSavedSession = nil
    }
    
    /// Gets all stored locations across all sessions
    func getAllLocations() -> [LocationEntry] {
        return locationsBySession.values.flatMap { $0 }
    }
}

// MARK: - Mock Core Data Entities

/// Mock TrackingSession for testing without Core Data
/// Note: Use real Core Data entities when possible (via TestFixtures).
/// This mock is only for repository testing where Core Data isn't needed.
class MockTrackingSession: TrackingSession {
    // We don't override properties - they're inherited from the Core Data class
    // Initialize with nil context to create an unmanaged object
    init() {
        // Get the entity description from the test context
        let context = CoreDataTestStack.createTestContext()
        let entity = NSEntityDescription.entity(forEntityName: "TrackingSession", in: context)!
        super.init(entity: entity, insertInto: nil)
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

/// Mock LocationEntry for testing without Core Data
/// Note: Use real Core Data entities when possible (via TestFixtures).
/// This mock is only for repository testing where Core Data isn't needed.
class MockLocationEntry: LocationEntry {
    // We don't override properties - they're inherited from the Core Data class
    // Initialize with nil context to create an unmanaged object
    init() {
        // Get the entity description from the test context
        let context = CoreDataTestStack.createTestContext()
        let entity = NSEntityDescription.entity(forEntityName: "LocationEntry", in: context)!
        super.init(entity: entity, insertInto: nil)
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
