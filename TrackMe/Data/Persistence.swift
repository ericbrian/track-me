import CoreData

struct PersistenceController {
    static let shared = PersistenceController()

    static var preview: PersistenceController = {
        let result = PersistenceController(inMemory: true)
        let viewContext = result.container.viewContext
        
        // Create sample data for previews
        let sampleSession = TrackingSession(context: viewContext)
        sampleSession.id = UUID()
        sampleSession.narrative = "Sample tracking session"
        sampleSession.startDate = Date().addingTimeInterval(-3600) // 1 hour ago
        sampleSession.endDate = Date()
        sampleSession.isActive = false
        
        let sampleLocation = LocationEntry(context: viewContext)
        sampleLocation.id = UUID()
        sampleLocation.latitude = 37.7749
        sampleLocation.longitude = -122.4194
        sampleLocation.timestamp = Date()
        sampleLocation.session = sampleSession
        
        do {
            try viewContext.save()
        } catch {
            // Replace this implementation with code to handle the error appropriately.
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
        return result
    }()

    let container: NSPersistentContainer

    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "TrackMe")
        if inMemory {
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        }
        
        let semaphore = DispatchSemaphore(value: 0)
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                // Replace this implementation with code to handle the error appropriately.
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
            semaphore.signal()
        })
        semaphore.wait()
        
        container.viewContext.automaticallyMergesChangesFromParent = true
    }
}

// MARK: - Core Data Convenience Methods
extension PersistenceController {
    func save() {
        let context = container.viewContext
        
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
    }
}