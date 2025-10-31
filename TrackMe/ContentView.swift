import SwiftUI

struct ContentView: View {
    @StateObject private var locationManager = LocationManager()
    @EnvironmentObject private var phoneConnectivity: PhoneConnectivityManager
    
    var body: some View {
        TabView {
            TrackingView()
                .environmentObject(locationManager)
                .tabItem {
                    Image(systemName: "location")
                    Text("Track")
                }
            
            HistoryView()
                .tabItem {
                    Image(systemName: "clock")
                    Text("History")
                }
        }
        .onAppear {
            phoneConnectivity.setLocationManager(locationManager)
            // Defer heavy setup until after UI appears
            DispatchQueue.main.async {
                locationManager.asyncSetup()
            }
        }
    }
}

#Preview {
    ContentView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}