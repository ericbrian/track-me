import SwiftUI
import WatchConnectivity

@main
struct TrackMe_Watch_AppApp: App {
    @StateObject private var watchConnectivity = WatchConnectivityManager()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(watchConnectivity)
        }
    }
}