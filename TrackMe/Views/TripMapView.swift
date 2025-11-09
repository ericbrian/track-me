import SwiftUI
import MapKit
import CoreData

/// A view that displays a map with the trip's route and location points.
struct TripMapView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @ObservedObject var session: TrackingSession
    @StateObject private var viewModel: MapViewModel

    init(session: TrackingSession) {
        self._session = ObservedObject(wrappedValue: session)
        // Initialize the view model with the session
        // Note: viewContext is accessed in onAppear since it's not available during init
        _viewModel = StateObject(wrappedValue: MapViewModel(
            session: session,
            viewContext: PersistenceController.shared.container.viewContext
        ))
    }

    var body: some View {
        ZStack {
            // Main map display
            MapDisplayView(viewModel: viewModel)
            
            // Location detail panel overlay
            VStack {
                Spacer()
                if let selectedLocation = viewModel.selectedLocation {
                    LocationDetailPanelView(location: selectedLocation) {
                        withAnimation {
                            viewModel.deselectLocation()
                        }
                    }
                    .padding()
                    .transition(.move(edge: .bottom))
                }
            }
        }
        .onAppear {
            viewModel.loadLocations()
        }
        .navigationTitle("Trip Map")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                MapControlsView(mapViewModel: viewModel)
            }
        }
        .sheet(isPresented: $viewModel.isPresentingShare) {
            if let url = viewModel.shareURL {
                ShareSheet(activityItems: [url])
            }
        }
    }
}

// MARK: - Supporting Views (kept for backwards compatibility)

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