import SwiftUI
import BackgroundTasks

@main
struct TrackMeApp: App {
    let persistenceController = PersistenceController.shared
    @StateObject private var phoneConnectivityManager = PhoneConnectivityManager.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .environmentObject(phoneConnectivityManager)
                .onReceive(NotificationCenter.default.publisher(for: UIApplication.didFinishLaunchingNotification)) { _ in
                    registerBackgroundTasks()
                }
        }
    }
    
    private func registerBackgroundTasks() {
        print("Registering background tasks...")
        
        BGTaskScheduler.shared.register(forTaskWithIdentifier: "com.ericbrian.TrackMe.background-location", using: nil) { task in
            print("Background location task triggered")
            handleBackgroundLocationRefresh(task: task as! BGAppRefreshTask)
        }
        
        BGTaskScheduler.shared.register(forTaskWithIdentifier: "com.ericbrian.TrackMe.data-sync", using: nil) { task in
            print("Background data sync task triggered")
            handleBackgroundDataSync(task: task as! BGProcessingTask)
        }
    }
    
    private func handleBackgroundLocationRefresh(task: BGAppRefreshTask) {
        task.expirationHandler = {
            print("Background location task expired")
            task.setTaskCompleted(success: false)
        }
        
        // Schedule next background task
        let request = BGAppRefreshTaskRequest(identifier: "com.ericbrian.TrackMe.background-location")
        request.earliestBeginDate = Date(timeIntervalSinceNow: 15 * 60) // 15 minutes
        
        do {
            try BGTaskScheduler.shared.submit(request)
            print("Next background task scheduled")
        } catch {
            print("Failed to schedule background task: \(error)")
        }
        
        task.setTaskCompleted(success: true)
    }
    
    private func handleBackgroundDataSync(task: BGProcessingTask) {
        task.expirationHandler = {
            print("Background data sync task expired")
            task.setTaskCompleted(success: false)
        }
        
        // Perform any data cleanup or optimization
        persistenceController.save()
        
        task.setTaskCompleted(success: true)
    }
}