import SwiftUI
import MapKit
import CoreData

// MARK: - Map Display View

/// Sub-view for rendering the map with annotations and route polylines
struct MapDisplayView: View {
    @ObservedObject var viewModel: MapViewModel
    
    var body: some View {
        Map(position: $viewModel.mapPosition) {
            // Add annotations for each location point
            ForEach(viewModel.locations, id: \.objectID) { location in
                Annotation(
                    "",
                    coordinate: CLLocationCoordinate2D(
                        latitude: location.latitude,
                        longitude: location.longitude
                    ),
                    anchor: .center
                ) {
                    LocationPin(
                        location: location,
                        isSelected: viewModel.selectedLocation?.id == location.id,
                        isStart: viewModel.isStartLocation(location),
                        isEnd: viewModel.isEndLocation(location)
                    )
                    .onTapGesture {
                        withAnimation {
                            viewModel.selectLocation(location)
                        }
                    }
                }
            }
            
            // Add the route polyline(s) if enabled
            if viewModel.showRoute {
                ForEach(Array(viewModel.routePolylines.enumerated()), id: \.offset) { _, poly in
                    MapPolyline(poly)
                        .stroke(.blue, lineWidth: 4)
                }
            }
        }
        .overlay {
            if !viewModel.hasLocations {
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
        .mapControls {
            MapUserLocationButton()
            MapCompass()
            MapScaleView()
        }
    }
}

// MARK: - Map Controls View Model

@MainActor
final class MapControlsViewModel: ObservableObject {
    private let mapViewModel: MapViewModel
    
    var showRoute: Bool {
        mapViewModel.showRoute
    }
    
    init(mapViewModel: MapViewModel) {
        self.mapViewModel = mapViewModel
    }
    
    func toggleRoute() {
        mapViewModel.toggleRoute()
    }
    
    func share() {
        mapViewModel.shareSession()
    }
}

// MARK: - Map Controls View

/// Sub-view for map toolbar controls (route toggle, share)
struct MapControlsView: View {
    @StateObject private var viewModel: MapControlsViewModel
    @ObservedObject var mapViewModel: MapViewModel
    
    init(mapViewModel: MapViewModel) {
        self.mapViewModel = mapViewModel
        _viewModel = StateObject(wrappedValue: MapControlsViewModel(mapViewModel: mapViewModel))
    }
    
    var body: some View {
        HStack {
            Button(action: viewModel.toggleRoute) {
                Image(systemName: viewModel.showRoute ? "eye.slash.fill" : "eye.fill")
            }
            Button(action: viewModel.share) {
                Image(systemName: "square.and.arrow.up")
            }
        }
    }
}

// MARK: - Location Detail View Model

@MainActor
final class LocationDetailViewModel: ObservableObject {
    let location: LocationEntry
    let onDismiss: () -> Void
    
    var timestamp: String {
        guard let timestamp = location.timestamp else { return "Unknown" }
        return timestamp.formatted(date: .abbreviated, time: .shortened)
    }
    
    var latitude: String {
        String(format: "%.6f", location.latitude)
    }
    
    var longitude: String {
        String(format: "%.6f", location.longitude)
    }
    
    var accuracy: String {
        "±\(Int(location.accuracy))m"
    }
    
    var speed: String? {
        guard location.speed > 0 else { return nil }
        return String(format: "%.1f km/h", location.speed * 3.6)
    }
    
    var altitude: String? {
        guard location.altitude != 0 else { return nil }
        return String(format: "%.1f m", location.altitude)
    }
    
    var course: String? {
        guard location.course >= 0 else { return nil }
        return String(format: "%.0f°", location.course)
    }
    
    init(location: LocationEntry, onDismiss: @escaping () -> Void) {
        self.location = location
        self.onDismiss = onDismiss
    }
}

// MARK: - Location Detail Panel View

/// Sub-view for displaying detailed information about a selected location
struct LocationDetailPanelView: View {
    @StateObject private var viewModel: LocationDetailViewModel
    
    init(location: LocationEntry, onDismiss: @escaping () -> Void) {
        _viewModel = StateObject(
            wrappedValue: LocationDetailViewModel(location: location, onDismiss: onDismiss)
        )
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Location Details")
                        .font(.title3)
                        .fontWeight(.bold)
                    
                    Text(viewModel.timestamp)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button(action: viewModel.onDismiss) {
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
                    value: viewModel.latitude,
                    icon: "globe.americas.fill"
                )
                
                DetailDataCard(
                    title: "Longitude",
                    value: viewModel.longitude,
                    icon: "globe.asia.australia.fill"
                )
                
                DetailDataCard(
                    title: "Accuracy",
                    value: viewModel.accuracy,
                    icon: "target"
                )
                
                if let speed = viewModel.speed {
                    DetailDataCard(
                        title: "Speed",
                        value: speed,
                        icon: "speedometer"
                    )
                }
                
                if let altitude = viewModel.altitude {
                    DetailDataCard(
                        title: "Altitude",
                        value: altitude,
                        icon: "mountain.2.fill"
                    )
                }
                
                if let course = viewModel.course {
                    DetailDataCard(
                        title: "Course",
                        value: course,
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

// MARK: - Previews

#Preview("Map Display") {
    let context = PersistenceController.preview.container.viewContext
    let session = TrackingSession(context: context)
    session.id = UUID()
    
    return MapDisplayView(
        viewModel: MapViewModel(session: session, viewContext: context)
    )
}

#Preview("Map Controls") {
    let context = PersistenceController.preview.container.viewContext
    let session = TrackingSession(context: context)
    session.id = UUID()
    
    let viewModel = MapViewModel(session: session, viewContext: context)
    return MapControlsView(mapViewModel: viewModel)
}
