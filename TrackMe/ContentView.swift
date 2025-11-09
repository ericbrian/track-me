import SwiftUI

struct ContentView: View {
    @StateObject private var dependencyContainer = DependencyContainer()
    @EnvironmentObject private var phoneConnectivity: PhoneConnectivityManager
    
    var body: some View {
        TabView {
            TrackingView(viewModel: dependencyContainer.makeTrackingViewModel())
                .environmentObject(dependencyContainer.locationManager)
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
        .ignoresSafeArea(.keyboard)
        .onAppear {
            phoneConnectivity.setLocationManager(dependencyContainer.locationManager)
            // Defer heavy setup until after UI appears
            DispatchQueue.main.async {
                dependencyContainer.locationManager.asyncSetup()
            }
        }
    }
}

#Preview {
    let container = DependencyContainer()
    return ContentView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
        .environmentObject(PhoneConnectivityManager.shared)
}