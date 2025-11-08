import Foundation
import CoreData

extension TrackingSession {
    /// Efficiently fetch sorted locations for this session using Core Data fetch request
    /// This avoids loading all locations into memory and sorting them manually
    /// - Parameter context: The managed object context to use for fetching
    /// - Returns: Array of LocationEntry sorted by timestamp ascending
    func fetchSortedLocations(in context: NSManagedObjectContext) -> [LocationEntry] {
        let request: NSFetchRequest<LocationEntry> = LocationEntry.fetchRequest()

        // Filter by this session
        request.predicate = NSPredicate(format: "session == %@", self)

        // Sort by timestamp ascending (oldest first)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \LocationEntry.timestamp, ascending: true)]

        do {
            return try context.fetch(request)
        } catch {
            print("⚠️ Failed to fetch sorted locations for session: \(error)")
            return []
        }
    }

    /// Convenience method that uses the session's own managed object context
    /// - Returns: Array of LocationEntry sorted by timestamp ascending
    func fetchSortedLocations() -> [LocationEntry] {
        guard let context = managedObjectContext else {
            print("⚠️ TrackingSession has no managed object context")
            return []
        }
        return fetchSortedLocations(in: context)
    }
}
