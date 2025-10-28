import SwiftUI

struct ContentView: View {
    @EnvironmentObject var watchConnectivity: WatchConnectivityManager
    
    var body: some View {
        TabView {
            TrackingControlView()
                .environmentObject(watchConnectivity)
                .tabItem {
                    Image(systemName: "location")
                    Text("Track")
                }
            
            SessionStatusView()
                .environmentObject(watchConnectivity)
                .tabItem {
                    Image(systemName: "info.circle")
                    Text("Status")
                }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(WatchConnectivityManager())
}