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
            let nsError = error as NSError
            print("⚠️ Preview data creation error: \(nsError), \(nsError.userInfo)")
            #if DEBUG
            // Only crash in DEBUG when running tests
            if ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil {
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }
            #endif
        }
        return result
    }()

    let container: NSPersistentContainer

    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "TrackMe")
        if inMemory {
            if let storeDescription = container.persistentStoreDescriptions.first {
                storeDescription.url = URL(fileURLWithPath: "/dev/null")
            }
        }
        
        // For in-memory stores (tests), load synchronously
        // For production, load synchronously to ensure container is ready
        // but we move the entire initialization off the main thread in TrackMeApp
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                // Log error but don't crash in production
                print("⚠️ Core Data error: \(error), \(error.userInfo)")
                #if DEBUG
                fatalError("Unresolved error \(error), \(error.userInfo)")
                #endif
            }
        })
        
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
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
                print("⚠️ Core Data save error: \(nsError), \(nsError.userInfo)")
                // Don't crash in production - log error and continue
                #if DEBUG
                // Only crash in DEBUG when running tests
                if ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil {
                    fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
                }
                #endif
            }
        }
    }
}