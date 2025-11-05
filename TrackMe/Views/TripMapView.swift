import SwiftUI
import MapKit
import CoreData

/// A view that displays a map with the trip's route and location points.
struct TripMapView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @ObservedObject var session: TrackingSession

    // Map camera state and UI selections
    @State private var mapPosition: MapCameraPosition = .automatic
    @State private var didSetInitialRegion = false
    @State private var selectedLocation: LocationEntry?
    @State private var showRoute = true
    @State private var isPresentingShare = false
    @State private var shareURL: URL?

    // Fetch request for the session's locations, sorted by timestamp
    @FetchRequest private var locations: FetchedResults<LocationEntry>

    init(session: TrackingSession) {
        self._session = ObservedObject(wrappedValue: session)
        // Build an explicit fetch request with an entity to avoid runtime crashes like
        // "executeFetchRequest:error: A fetch request must have an entity."
        let request = NSFetchRequest<LocationEntry>(entityName: "LocationEntry")
        request.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: true)]
        request.predicate = NSPredicate(format: "session == %@", session)
        self._locations = FetchRequest(fetchRequest: request, animation: .default)
    }

    var body: some View {
        Map(position: $mapPosition) {
            // Add annotations for each location point
            ForEach(locations, id: \.objectID) { location in
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
            
            // Add the route polyline(s) if enabled
            if showRoute {
                ForEach(Array(routePolylines.enumerated()), id: \.offset) { _, poly in
                    MapPolyline(poly)
                        .stroke(.blue, lineWidth: 4)
                }
            }
        }
        .overlay {
            if locations.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "map")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary)
                    Text("No location data")
                        .font(.headline)
                        .foregroundColor(.primary)
                    Text("This session has no recorded locations")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding()
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
        .onAppear {
            // Refresh the session to ensure relationships are loaded in this context
            viewContext.refresh(session, mergeChanges: true)
            setInitialCameraPositionIfNeeded()
        }
        .onChange(of: locations.count) { _, _ in
            // Recompute only the first time locations appear
            setInitialCameraPositionIfNeeded()
        }
        .navigationTitle("Trip Map")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            // Toolbar items for sharing and toggling the route
            ToolbarItem(placement: .navigationBarTrailing) {
                HStack {
                    Button(action: { showRoute.toggle() }) {
                        Image(systemName: showRoute ? "eye.slash.fill" : "eye.fill")
                    }
                    Button(action: shareSession) {
                        Image(systemName: "square.and.arrow.up")
                    }
                }
            }
        }
        .sheet(isPresented: $isPresentingShare) {
            if let url = shareURL {
                ActivityShareSheet(activityItems: [url])
            }
        }
    }

    /// Calculates and sets the initial camera position to fit the entire route.
    private func setInitialCameraPositionIfNeeded() {
        guard !didSetInitialRegion else { return }

        if locations.isEmpty {
            // Default to a neutral world view
            mapPosition = .automatic
            didSetInitialRegion = true
            return
        }

        let coords = Array(locations).map { CLLocationCoordinate2D(latitude: $0.latitude, longitude: $0.longitude) }
        let region = MapMath.computeRegion(for: coords, minSpan: 0.01, paddingScale: 1.4)
        mapPosition = .region(region)
        didSetInitialRegion = true
    }
    
    /// Computed polylines split across antimeridian if needed to avoid long wrap-around lines.
    private var routePolylines: [MKPolyline] {
        guard locations.count > 1 else { return [] }
        let coordinates = locations.map { CLLocationCoordinate2D(latitude: $0.latitude, longitude: $0.longitude) }
        let segments = MapMath.splitSegmentsAcrossAntimeridian(coordinates)
        return segments.map { segment in
            MKPolyline(coordinates: segment, count: segment.count)
        }
    }
    
    /// Checks if a location is the first in the session.
    private func isStartLocation(_ location: LocationEntry) -> Bool {
        return locations.first?.id == location.id
    }
    
    /// Checks if a location is the last in the session.
    private func isEndLocation(_ location: LocationEntry) -> Bool {
        return locations.last?.id == location.id
    }

    /// Lazily generate the export on demand to avoid heavy work in the view body.
    private func shareSession() {
        let currentLocations = Array(locations)
        guard !currentLocations.isEmpty else {
            // Nothing to share
            return
        }
        // Perform export off the main thread to keep UI responsive
        DispatchQueue.global(qos: .userInitiated).async {
            let csv = ExportService.shared.exportToCSV(session: session, locations: currentLocations)
            let filename = ExportService.shared.generateFilename(session: session, format: .csv)
            let fileURL = ExportService.shared.saveToTemporaryFile(content: csv, filename: filename)
            DispatchQueue.main.async {
                self.shareURL = fileURL
                self.isPresentingShare = (fileURL != nil)
            }
        }
    }
}

// Simple wrapper for UIActivityViewController to present shares from SwiftUI
private struct ActivityShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]
    let applicationActivities: [UIActivity]? = nil

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: applicationActivities)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) { }
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