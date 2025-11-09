import Foundation
import CoreData
import CoreLocation

// MARK: - Repository Protocols

/// Protocol for managing tracking sessions
protocol SessionRepositoryProtocol {
    /// Fetch all active tracking sessions
    func fetchActiveSessions() throws -> [TrackingSession]
    
    /// Fetch all sessions (active and inactive)
    func fetchAllSessions() throws -> [TrackingSession]
    
    /// Fetch sessions with a predicate
    func fetchSessions(predicate: NSPredicate?, sortDescriptors: [NSSortDescriptor]?) throws -> [TrackingSession]
    
    /// Create a new tracking session
    func createSession(narrative: String, startDate: Date) throws -> TrackingSession
    
    /// End a tracking session
    func endSession(_ session: TrackingSession, endDate: Date) throws
    
    /// Delete a session and all its location entries
    func deleteSession(_ session: TrackingSession) throws
    
    /// Get the count of location entries for a session
    func locationCount(for session: TrackingSession) throws -> Int
    
    /// Mark orphaned sessions as inactive (recovery on app launch)
    func recoverOrphanedSessions() throws -> Int
}

/// Protocol for managing location entries
protocol LocationRepositoryProtocol {
    /// Save a new location entry for a session
    func saveLocation(_ location: CLLocation, for session: TrackingSession) throws -> LocationEntry
    
    /// Fetch all location entries for a session
    func fetchLocations(for session: TrackingSession) throws -> [LocationEntry]
    
    /// Fetch locations with sorting and batching
    func fetchLocations(for session: TrackingSession, sortDescriptors: [NSSortDescriptor]?, batchSize: Int?) throws -> [LocationEntry]
    
    /// Delete all location entries for a session
    func deleteLocations(for session: TrackingSession) throws
    
    /// Get the total count of location entries for a session
    func locationCount(for session: TrackingSession) throws -> Int
}

/// Protocol for exporting session data
protocol ExportRepositoryProtocol {
    /// Export session to GPX format
    func exportToGPX(session: TrackingSession) throws -> Data
    
    /// Export session to CSV format
    func exportToCSV(session: TrackingSession) throws -> Data
    
    /// Export session to JSON format
    func exportToJSON(session: TrackingSession) throws -> Data
}

/// Protocol for accessing Core Data context
protocol DataContextProtocol {
    var viewContext: NSManagedObjectContext { get }
    func newBackgroundContext() -> NSManagedObjectContext
    func performAndWait<T>(_ block: () throws -> T) rethrows -> T
    func performAsync(_ block: @escaping () -> Void)
}
