import SwiftUI
import MapKit
import CoreData

struct TripMapView: View {
    let session: TrackingSession
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.managedObjectContext) private var viewContext
    @State private var region = MKCoordinateRegion()
    @State private var mapPosition: MapCameraPosition = .automatic
    @State private var showingRoute = true
    @State private var selectedLocation: LocationEntry?
    @State private var locations: [LocationEntry] = []
    
    private var coordinates: [CLLocationCoordinate2D] {
        locations.map { CLLocationCoordinate2D(latitude: $0.latitude, longitude: $0.longitude) }
    }
    
    var body: some View {
        ZStack {
            if locations.isEmpty {
                // Empty state view
                VStack(spacing: 20) {
                    Image(systemName: "map.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.gray)
                    
                    Text(NSLocalizedString("No Location Data", comment: "Empty map state title"))
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text(NSLocalizedString("This session has no recorded locations.", comment: "Empty map state description"))
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding()
            } else {
                // Map View - Modern iOS 17+ API
                Map(position: $mapPosition) {
                    ForEach(locations, id: \.id) { location in
                        Annotation(
                            "",
                            coordinate: CLLocationCoordinate2D(latitude: location.latitude, longitude: location.longitude)
                        ) {
                            LocationPin(
                                location: location,
                                isSelected: selectedLocation?.id == location.id,
                                isStart: isStartLocation(location),
                                isEnd: isEndLocation(location)
                            )
                            .onTapGesture {
                                selectedLocation = location
                            }
                        }
                    }
                }
                .overlay(
                    // Route overlay
                    RouteOverlay(coordinates: coordinates, showRoute: showingRoute)
                )
            }
            
            // Fetch locations when view appears
            Color.clear.onAppear {
                fetchLocations()
            }
            
            // Control panel
            VStack {
                Spacer()
                
                HStack {
                    Spacer()
                    
                    VStack(spacing: 16) {
                        // Route toggle
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                showingRoute.toggle()
                            }
                        }) {
                            Image(systemName: showingRoute ? "location.fill" : "location")
                                .font(.title2)
                                .foregroundColor(.white)
                                .frame(width: 50, height: 50)
                                .background(
                                    Circle()
                                        .fill(
                                            LinearGradient(
                                                gradient: Gradient(colors: showingRoute ? 
                                                    [Color.blue, Color.blue.opacity(0.8)] : 
                                                    [Color.gray, Color.gray.opacity(0.8)]
                                                ),
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                )
                                .shadow(color: (showingRoute ? Color.blue : Color.gray).opacity(0.3), radius: 8, x: 0, y: 4)
                        }
                        .scaleEffect(showingRoute ? 1.0 : 0.9)
                        .animation(.easeInOut(duration: 0.2), value: showingRoute)
                        
                        // Fit to route button
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                fitToRoute()
                            }
                        }) {
                            Image(systemName: "arrow.up.left.and.arrow.down.right")
                                .font(.title2)
                                .foregroundColor(.white)
                                .frame(width: 50, height: 50)
                                .background(
                                    Circle()
                                        .fill(
                                            LinearGradient(
                                                gradient: Gradient(colors: [Color.green, Color.green.opacity(0.8)]),
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                )
                                .shadow(color: Color.green.opacity(0.3), radius: 8, x: 0, y: 4)
                        }
                    }
                    .padding(.trailing, 20)
                }
                .padding(.bottom, 100)
            }
            
            // Location details panel
            if let selectedLocation = selectedLocation {
                VStack {
                    Spacer()
                    LocationDetailPanel(location: selectedLocation) {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            self.selectedLocation = nil
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 30)
                }
            }
        }
        .navigationTitle("Trip Map")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: {
                    presentationMode.wrappedValue.dismiss()
                }) {
                    HStack {
                        Image(systemName: "chevron.left")
                        Text("Done")
                    }
                    .foregroundColor(.blue)
                }
            }
            
            ToolbarItem(placement: .navigationBarTrailing) {
                HStack(spacing: 12) {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("\(locations.count)")
                            .font(.headline)
                            .fontWeight(.bold)
                        Text("points")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    
                    Image(systemName: "location.circle.fill")
                        .foregroundColor(.blue)
                        .font(.title3)
                }
            }
        }
    }

    private func fetchLocations() {
        // Refresh the session in the current context to ensure it's not faulted
        viewContext.refresh(session, mergeChanges: true)
        
        let fetchRequest: NSFetchRequest<LocationEntry> = LocationEntry.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "session == %@", session)
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: true)]
        do {
            let fetched = try viewContext.fetch(fetchRequest)
            print("TripMapView: Fetched \(fetched.count) locations for session")
            self.locations = fetched
            setupInitialRegion()
        } catch {
            print("Failed to fetch locations for session: \(error)")
            self.locations = []
        }
    }
    
    private func setupInitialRegion() {
        guard !locations.isEmpty else {
            print("TripMapView: No locations to display on map")
            return
        }
        
        let latitudes = locations.map { $0.latitude }
        let longitudes = locations.map { $0.longitude }
        let minLat = latitudes.min() ?? 0
        let maxLat = latitudes.max() ?? 0
        let minLon = longitudes.min() ?? 0
        let maxLon = longitudes.max() ?? 0
        let centerLat = (minLat + maxLat) / 2
        let centerLon = (minLon + maxLon) / 2
        let spanLat = max(maxLat - minLat, 0.01) * 1.2
        let spanLon = max(maxLon - minLon, 0.01) * 1.2
        
        region = MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: centerLat, longitude: centerLon),
            span: MKCoordinateSpan(latitudeDelta: spanLat, longitudeDelta: spanLon)
        )
        
        // Update the map position binding
        mapPosition = .region(region)
        print("TripMapView: Set map region to center: \(centerLat), \(centerLon)")
    }
    
    private func fitToRoute() {
        setupInitialRegion()
    }
    
    private func isStartLocation(_ location: LocationEntry) -> Bool {
        return location.id == locations.first?.id
    }
    
    private func isEndLocation(_ location: LocationEntry) -> Bool {
        return location.id == locations.last?.id
    }
}

struct LocationPin: View {
    let location: LocationEntry
    let isSelected: Bool
    let isStart: Bool
    let isEnd: Bool
    
    var body: some View {
        ZStack {
            Circle()
                .fill(pinColor)
                .frame(width: isSelected ? 20 : 12, height: isSelected ? 20 : 12)
                .overlay(
                    Circle()
                        .stroke(Color.white, lineWidth: isSelected ? 3 : 2)
                )
                .shadow(radius: 2)
            
            if isStart || isEnd {
                Image(systemName: isStart ? "play.fill" : "stop.fill")
                    .font(.system(size: 8))
                    .foregroundColor(.white)
            }
        }
        .scaleEffect(isSelected ? 1.2 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }
    
    private var pinColor: Color {
        if isStart { return .green }
        if isEnd { return .red }
        if isSelected { return .blue }
        return .orange
    }
}

struct RouteOverlay: UIViewRepresentable {
    let coordinates: [CLLocationCoordinate2D]
    let showRoute: Bool
    
    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.isUserInteractionEnabled = false
        mapView.delegate = context.coordinator
        return mapView
    }
    
    func updateUIView(_ mapView: MKMapView, context: Context) {
        mapView.removeOverlays(mapView.overlays)
        
        if showRoute && coordinates.count > 1 {
            let polyline = MKPolyline(coordinates: coordinates, count: coordinates.count)
            mapView.addOverlay(polyline)
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    class Coordinator: NSObject, MKMapViewDelegate {
        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            if let polyline = overlay as? MKPolyline {
                let renderer = MKPolylineRenderer(polyline: polyline)
                renderer.strokeColor = UIColor.systemBlue
                renderer.lineWidth = 4
                renderer.lineCap = .round
                renderer.lineJoin = .round
                return renderer
            }
            return MKOverlayRenderer()
        }
    }
}

struct LocationDetailPanel: View {
    let location: LocationEntry
    let onDismiss: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Location Details")
                        .font(.title3)
                        .fontWeight(.bold)
                    
                    if let timestamp = location.timestamp {
                        Text(timestamp.formatted(date: .abbreviated, time: .shortened))
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                Button(action: onDismiss) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.gray)
                        .background(Color.white)
                        .clipShape(Circle())
                }
            }
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                DetailDataCard(
                    title: "Latitude",
                    value: String(format: "%.6f", location.latitude),
                    icon: "globe.americas.fill"
                )
                
                DetailDataCard(
                    title: "Longitude", 
                    value: String(format: "%.6f", location.longitude),
                    icon: "globe.asia.australia.fill"
                )
                
                DetailDataCard(
                    title: "Accuracy",
                    value: "±\(Int(location.accuracy))m",
                    icon: "target"
                )
                
                if location.speed > 0 {
                    DetailDataCard(
                        title: "Speed",
                        value: String(format: "%.1f km/h", location.speed * 3.6),
                        icon: "speedometer"
                    )
                }
                
                if location.altitude != 0 {
                    DetailDataCard(
                        title: "Altitude",
                        value: String(format: "%.1f m", location.altitude),
                        icon: "mountain.2.fill"
                    )
                }
                
                if location.course >= 0 {
                    DetailDataCard(
                        title: "Course",
                        value: String(format: "%.0f°", location.course),
                        icon: "location.north.fill"
                    )
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.1), radius: 16, x: 0, y: 8)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color(.systemGray4), lineWidth: 0.5)
                )
        )
    }
}

struct DetailDataCard: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.blue)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text(value)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6))
        )
    }
}

#Preview {
    // Create a preview with mock data
    let context = PersistenceController.preview.container.viewContext
    let session = TrackingSession(context: context)
    session.id = UUID()
    session.narrative = "Sample Trip"
    session.startDate = Date()
    session.endDate = Date()
    
    return TripMapView(session: session)
}