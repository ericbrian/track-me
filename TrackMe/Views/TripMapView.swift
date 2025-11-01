import SwiftUI
import MapKit
import CoreData

/// A view that displays a map with the trip's route and location points.
struct TripMapView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @ObservedObject var session: TrackingSession
    
    // State for the map's region and selected location
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 0, longitude: 0),
        span: MKCoordinateSpan(latitudeDelta: 100, longitudeDelta: 100)
    )
    @State private var selectedLocation: LocationEntry?
    @State private var showRoute = true
    
    // Location manager to get the user's current location for default region
    private let locationManager = CLLocationManager()
    
    // Fetch request for the session's locations, sorted by timestamp
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \LocationEntry.timestamp, ascending: true)],
        animation: .default)
    private var locations: FetchedResults<LocationEntry>
    
    var body: some View {
        Map(coordinateRegion: $region, interactionModes: .all, showsUserLocation: true) {
            // Add annotations for each location point
            ForEach(locations) { location in
                Annotation(
                    "",
                    coordinate: CLLocationCoordinate2D(latitude: location.latitude, longitude: location.longitude),
                    anchor: .center
                ) {
                    LocationPin(
                        location: location,
                        isSelected: selectedLocation?.id == location.id,
                        isStart: isStartLocation(location),
                        isEnd: isEndLocation(location)
                    )
                    .onTapGesture {
                        withAnimation {
                            selectedLocation = (selectedLocation?.id == location.id) ? nil : location
                        }
                    }
                }
            }
            
            // Add the route polyline if enabled
            if showRoute, let polyline = routePolyline {
                MapPolyline(polyline)
                    .stroke(.blue, lineWidth: 4)
            }
        }
        .overlay(alignment: .bottom) {
            // Show detail panel for selected location
            if let selectedLocation = selectedLocation {
                LocationDetailPanel(location: selectedLocation) {
                    withAnimation {
                        self.selectedLocation = nil
                    }
                }
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(16)
                .shadow(radius: 5)
                .transition(.move(edge: .bottom))
            }
        }
        .mapControls {
            MapUserLocationButton()
            MapCompass()
            MapScaleView()
        }
        .onAppear(perform: setupView)
        .navigationTitle("Trip Map")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            // Toolbar items for sharing and toggling the route
            ToolbarItem(placement: .navigationBarTrailing) {
                HStack {
                    Button(action: { showRoute.toggle() }) {
                        Image(systemName: showRoute ? "eye.slash.fill" : "eye.fill")
                    }
                    ShareLink(item: ExportService.shared.exportToCSV(session: session, locations: Array(locations)),
                              subject: Text("TrackMe Session Data"),
                              message: Text("Here is the data for my tracking session."),
                              preview: SharePreview("Session Data",
                                                    image: Image(systemName: "doc.text"),
                                                    icon: Image(systemName: "plus")))
                }
            }
        }
    }
    
    /// Sets up the view by configuring the fetch request and initial map region.
    private func setupView() {
        locations.nsPredicate = NSPredicate(format: "session == %@", session)
        setupInitialRegion()
    }
    
    /// Calculates and sets the initial map region to fit the entire route.
    private func setupInitialRegion() {
        guard !locations.isEmpty else {
            // If no locations, center on user's current location or a default
            if let userLocation = locationManager.location?.coordinate {
                region = MKCoordinateRegion(
                    center: userLocation,
                    span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
                )
            }
            // The default region is already set in the @State property
            return
        }
        
        // Calculate bounding box
        let latitudes = locations.map { $0.latitude }
        let longitudes = locations.map { $0.longitude }
        
        let minLat = latitudes.min()!
        let maxLat = latitudes.max()!
        let minLon = longitudes.min()!
        let maxLon = longitudes.max()!
        
        // Set region with padding
        let center = CLLocationCoordinate2D(latitude: (minLat + maxLat) / 2, longitude: (minLon + maxLon) / 2)
        let span = MKCoordinateSpan(latitudeDelta: max(maxLat - minLat, 0.01) * 1.4, longitudeDelta: max(maxLon - minLon, 0.01) * 1.4)
        
        region = MKCoordinateRegion(center: center, span: span)
    }
    
    /// A computed property that creates an `MKPolyline` from the session's locations.
    private var routePolyline: MKPolyline? {
        guard locations.count > 1 else { return nil }
        let coordinates = locations.map { CLLocationCoordinate2D(latitude: $0.latitude, longitude: $0.longitude) }
        return MKPolyline(coordinates: coordinates, count: coordinates.count)
    }
    
    /// Checks if a location is the first in the session.
    private func isStartLocation(_ location: LocationEntry) -> Bool {
        return locations.first?.id == location.id
    }
    
    /// Checks if a location is the last in the session.
    private func isEndLocation(_ location: LocationEntry) -> Bool {
        return locations.last?.id == location.id
    }
}

// MARK: - Subviews for TripMapView

/// A view for the map annotation pin.
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