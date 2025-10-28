
import SwiftUI
import BackgroundTasks


@main
struct TrackMeApp: App {
    @StateObject private var phoneConnectivityManager = PhoneConnectivityManager.shared
    @State private var persistenceController: PersistenceController? = nil
    @State private var isLoading = true

    var body: some Scene {
        WindowGroup {
            Group {
                if isLoading {
                    SplashView()
                } else if let persistenceController = persistenceController {
                    ContentView()
                        .environment(\.managedObjectContext, persistenceController.container.viewContext)
                        .environmentObject(phoneConnectivityManager)
                        .onReceive(NotificationCenter.default.publisher(for: UIApplication.didFinishLaunchingNotification)) { _ in
                            registerBackgroundTasks()
                        }
                }
            }
            .onAppear {
                if persistenceController == nil {
                    DispatchQueue.global(qos: .userInitiated).async {
                        let controller = PersistenceController()
                        DispatchQueue.main.async {
                            self.persistenceController = controller
                            self.isLoading = false
                        }
                    }
                }
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
        let request = BGAppRefreshTaskRequest(identifier: "com.ericbrian.TrackMe.background-location")
        request.earliestBeginDate = Date(timeIntervalSinceNow: 15 * 60)
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
        persistenceController?.save()
        task.setTaskCompleted(success: true)
    }
}

struct SplashView: View {
    var body: some View {
        ZStack {
            Color(.systemBackground).ignoresSafeArea()
            VStack(spacing: 24) {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                    .scaleEffect(1.5)
                Text("Loading TrackMe...")
                    .font(.headline)
                    .foregroundColor(.secondary)
            }
        }
    }
}