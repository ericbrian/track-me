import SwiftUI

struct ContentView: View {
    @StateObject private var locationManager = LocationManager()
    @StateObject private var phoneConnectivity = PhoneConnectivityManager()
    
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
        }
    }
}

#Preview {
    ContentView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}