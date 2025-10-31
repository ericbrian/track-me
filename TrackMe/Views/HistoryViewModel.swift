import Foundation
import CoreData

final class HistoryViewModel: NSObject, ObservableObject {
    @Published var sessions: [TrackingSession] = []

    private var fetchedResultsController: NSFetchedResultsController<TrackingSession>?
    private var isConfigured = false

    func attach(context: NSManagedObjectContext) {
        guard !isConfigured else { return }
        isConfigured = true

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
            print("HistoryViewModel: Failed to perform fetch: \(error)")
            sessions = []
        }
    }
}

extension HistoryViewModel: NSFetchedResultsControllerDelegate {
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        guard let frc = fetchedResultsController else { return }
        sessions = frc.fetchedObjects ?? []
    }
}
