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

// MARK: - Supporting Views

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