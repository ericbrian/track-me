import Foundation
import CoreData
import Combine

/// ViewModel for history list - manages session list display and deletion
@MainActor
final class HistoryListViewModel: NSObject, ObservableObject {
    
    // MARK: - Dependencies
    
    private weak var viewContext: NSManagedObjectContext?
    
    // MARK: - Published State
    
    @Published var sessions: [TrackingSession] = []
    @Published var searchText = ""
    @Published var isConfigured = false
    
    // MARK: - Computed Properties
    
    var filteredSessions: [TrackingSession] {
        if searchText.isEmpty {
            return sessions
        }
        return sessions.filter { session in
            session.narrative?.localizedCaseInsensitiveContains(searchText) ?? false
        }
    }
    
    var isEmpty: Bool {
        sessions.isEmpty
    }
    
    // MARK: - Private State
    
    private var fetchedResultsController: NSFetchedResultsController<TrackingSession>?
    
    // MARK: - Initialization
    
    override init() {
        super.init()
    }
    
    // MARK: - Lifecycle
    
    func attach(context: NSManagedObjectContext) {
        guard !isConfigured else { return }
        isConfigured = true
        viewContext = context
        
        let request: NSFetchRequest<TrackingSession> = TrackingSession.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \TrackingSession.startDate, ascending: false)]
        
        let frc = NSFetchedResultsController(
            fetchRequest: request,
            managedObjectContext: context,
            sectionNameKeyPath: nil,
            cacheName: nil
        )
        frc.delegate = self
        fetchedResultsController = frc
        
        do {
            try frc.performFetch()
            sessions = frc.fetchedObjects ?? []
        } catch {
            print("HistoryListViewModel: Failed to perform fetch: \(error)")
            sessions = []
        }
    }
    
    func detach() {
        fetchedResultsController?.delegate = nil
        fetchedResultsController = nil
        isConfigured = false
        viewContext = nil
    }
    
    // MARK: - Actions
    
    func deleteSessions(offsets: IndexSet) {
        guard let context = viewContext else { return }
        
        // Get object IDs for the sessions to delete
        let sessionsToDelete = offsets.map { filteredSessions[$0] }
        let objectIDs = sessionsToDelete.map { $0.objectID }
        
        // Perform deletion on background context for better performance
        let backgroundContext = PersistenceController.shared.container.newBackgroundContext()
        
        backgroundContext.perform {
            do {
                // Delete sessions in background context
                for objectID in objectIDs {
                    if let sessionToDelete = try? backgroundContext.existingObject(with: objectID) {
                        backgroundContext.delete(sessionToDelete)
                    }
                }
                
                // Save the background context
                try backgroundContext.save()
                
                print("Successfully deleted \(objectIDs.count) session(s)")
                
                // The FetchedResultsController will automatically update
            } catch {
                print("⚠️ Error deleting sessions: \(error.localizedDescription)")
                Task { @MainActor in
                    ErrorHandler.shared.handle(.dataDeleteFailed(error))
                }
            }
        }
    }
    
    func refresh() {
        guard let frc = fetchedResultsController else { return }
        do {
            try frc.performFetch()
            sessions = frc.fetchedObjects ?? []
        } catch {
            print("HistoryListViewModel: Failed to refresh: \(error)")
        }
    }
    
    deinit {
        detach()
    }
}

// MARK: - NSFetchedResultsControllerDelegate

extension HistoryListViewModel: NSFetchedResultsControllerDelegate {
    nonisolated func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        Task { @MainActor in
            guard let frc = fetchedResultsController else { return }
            sessions = frc.fetchedObjects ?? []
        }
    }
}
