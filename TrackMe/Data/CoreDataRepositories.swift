import Foundation
import CoreData
import CoreLocation

// MARK: - Core Data Session Repository

/// Core Data implementation of SessionRepositoryProtocol
class CoreDataSessionRepository: SessionRepositoryProtocol {
    private let context: NSManagedObjectContext
    
    init(context: NSManagedObjectContext) {
        self.context = context
    }
    
    func fetchActiveSessions() throws -> [TrackingSession] {
        let predicate = NSPredicate(format: "isActive == YES")
        return try fetchSessions(predicate: predicate, sortDescriptors: nil)
    }
    
    func fetchAllSessions() throws -> [TrackingSession] {
        let sortDescriptors = [NSSortDescriptor(key: "startDate", ascending: false)]
        return try fetchSessions(predicate: nil, sortDescriptors: sortDescriptors)
    }
    
    func fetchSessions(predicate: NSPredicate?, sortDescriptors: [NSSortDescriptor]?) throws -> [TrackingSession] {
        let fetchRequest: NSFetchRequest<TrackingSession> = TrackingSession.fetchRequest()
        fetchRequest.predicate = predicate
        fetchRequest.sortDescriptors = sortDescriptors
        
        return try context.fetch(fetchRequest)
    }
    
    func createSession(narrative: String, startDate: Date) throws -> TrackingSession {
        let session = TrackingSession(context: context)
        session.id = UUID()
        session.narrative = narrative
        session.startDate = startDate
        session.isActive = true
        
        try context.save()
        return session
    }
    
    func endSession(_ session: TrackingSession, endDate: Date) throws {
        session.endDate = endDate
        session.isActive = false
        try context.save()
    }
    
    func deleteSession(_ session: TrackingSession) throws {
        context.delete(session)
        try context.save()
    }
    
    func locationCount(for session: TrackingSession) throws -> Int {
        guard let locations = session.locations as? Set<LocationEntry> else {
            return 0
        }
        return locations.count
    }
    
    func recoverOrphanedSessions() throws -> Int {
        let predicate = NSPredicate(format: "isActive == YES")
        let orphanedSessions = try fetchSessions(predicate: predicate, sortDescriptors: nil)
        
        if orphanedSessions.isEmpty {
            return 0
        }
        
        let endDate = Date()
        for session in orphanedSessions {
            session.isActive = false
            session.endDate = endDate
        }
        
        try context.save()
        return orphanedSessions.count
    }
}

// MARK: - Core Data Location Repository

/// Core Data implementation of LocationRepositoryProtocol
class CoreDataLocationRepository: LocationRepositoryProtocol {
    private let context: NSManagedObjectContext
    
    init(context: NSManagedObjectContext) {
        self.context = context
    }
    
    func saveLocation(_ location: CLLocation, for session: TrackingSession) throws -> LocationEntry {
        let locationEntry = LocationEntry(context: context)
        locationEntry.id = UUID()
        locationEntry.latitude = location.coordinate.latitude
        locationEntry.longitude = location.coordinate.longitude
        locationEntry.timestamp = location.timestamp
        locationEntry.accuracy = location.horizontalAccuracy
        locationEntry.altitude = location.altitude
        locationEntry.speed = location.speed >= 0 ? location.speed : 0
        locationEntry.course = location.course >= 0 ? location.course : 0
        locationEntry.session = session
        
        try context.save()
        return locationEntry
    }
    
    func fetchLocations(for session: TrackingSession) throws -> [LocationEntry] {
        let sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: true)]
        return try fetchLocations(for: session, sortDescriptors: sortDescriptors, batchSize: nil)
    }
    
    func fetchLocations(for session: TrackingSession, sortDescriptors: [NSSortDescriptor]?, batchSize: Int?) throws -> [LocationEntry] {
        let fetchRequest: NSFetchRequest<LocationEntry> = LocationEntry.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "session == %@", session)
        fetchRequest.sortDescriptors = sortDescriptors
        
        if let batchSize = batchSize {
            fetchRequest.fetchBatchSize = batchSize
        }
        
        return try context.fetch(fetchRequest)
    }
    
    func deleteLocations(for session: TrackingSession) throws {
        let locations = try fetchLocations(for: session)
        for location in locations {
            context.delete(location)
        }
        try context.save()
    }
    
    func locationCount(for session: TrackingSession) throws -> Int {
        let fetchRequest: NSFetchRequest<LocationEntry> = LocationEntry.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "session == %@", session)
        return try context.count(for: fetchRequest)
    }
}

// MARK: - Data Context Wrapper

/// Wrapper for NSPersistentContainer providing protocol-based access
class CoreDataContext: DataContextProtocol {
    private let container: NSPersistentContainer
    
    var viewContext: NSManagedObjectContext {
        container.viewContext
    }
    
    init(container: NSPersistentContainer) {
        self.container = container
    }
    
    func newBackgroundContext() -> NSManagedObjectContext {
        container.newBackgroundContext()
    }
    
    func performAndWait<T>(_ block: () throws -> T) rethrows -> T {
        try viewContext.performAndWait {
            try block()
        }
    }
    
    func performAsync(_ block: @escaping () -> Void) {
        viewContext.perform(block)
    }
}
