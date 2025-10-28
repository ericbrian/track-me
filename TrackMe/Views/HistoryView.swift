import SwiftUI
import CoreData
import CoreLocation

struct HistoryView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \TrackingSession.startDate, ascending: false)],
        predicate: nil,
        animation: .default
    )
    private var sessions: FetchedResults<TrackingSession>

    init() {
        let request = TrackingSession.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \TrackingSession.startDate, ascending: false)]
        request.fetchLimit = 20
        _sessions = FetchRequest(fetchRequest: request, animation: .default)
    }
    
    @State private var selectedSession: TrackingSession?
    @State private var showingSessionDetail = false
    @State private var showingMapView = false
    @State private var refreshID = UUID()
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background gradient
                LinearGradient(
                    gradient: Gradient(colors: [Color(.systemBackground), Color(.systemGray6).opacity(0.3)]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                List {
                    if sessions.isEmpty {
                        VStack(spacing: 20) {
                            Image(systemName: "clock.arrow.circlepath")
                                .font(.system(size: 60))
                                .foregroundStyle(
                                    LinearGradient(
                                        gradient: Gradient(colors: [.blue, .purple]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                            
                            VStack(spacing: 8) {
                                Text("No tracking sessions yet")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.primary)
                                
                                Text("Start tracking from the Track tab to see your location history here.")
                                    .font(.body)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 80)
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                    } else {
                        ForEach(sessions, id: \.id) { session in
                            ModernSessionRowView(
                                session: session,
                                onTapSession: {
                                    selectedSession = session
                                    showingSessionDetail = true
                                },
                                onTapMap: {
                                    selectedSession = session
                                    showingMapView = true
                                }
                            )
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                        }
                        .onDelete(perform: deleteSessions)
                    }
                }
                .listStyle(PlainListStyle())
            }
            .navigationTitle("Tracking History")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    EditButton()
                }
            }
            .sheet(isPresented: $showingSessionDetail) {
                if let session = selectedSession {
                    SessionDetailView(session: session)
                }
            }
            .sheet(isPresented: $showingMapView) {
                if let session = selectedSession {
                    TripMapView(session: session)
                }
            }
            .id(refreshID) // Force view reload when refreshID changes
            .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("HistoryShouldRefresh"))) { _ in
                refreshID = UUID()
            }
        }
    }
    
    private func deleteSessions(offsets: IndexSet) {
        withAnimation {
            offsets.map { sessions[$0] }.forEach(viewContext.delete)
            
            do {
                try viewContext.save()
            } catch {
                // Handle the error appropriately
                print("Error deleting sessions: \(error)")
            }
        }
    }
}

struct SessionRowView: View {
    let session: TrackingSession
    let onTapSession: () -> Void
    let onTapMap: () -> Void
    
    private var hasLocations: Bool {
        (session.locations?.count ?? 0) > 0
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(session.narrative ?? "Unnamed Session")
                        .font(.headline)
                        .lineLimit(1)
                    
                    if let startDate = session.startDate {
                        Text(startDate, style: .date)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                // Action buttons
                HStack(spacing: 12) {
                    if hasLocations {
                        Button(action: onTapMap) {
                            Image(systemName: "map")
                                .font(.title3)
                                .foregroundColor(.blue)
                                .frame(width: 32, height: 32)
                                .background(Color.blue.opacity(0.1))
                                .clipShape(Circle())
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        if session.isActive {
                            Label("Active", systemImage: "location.fill")
                                .font(.caption)
                                .foregroundColor(.green)
                        } else {
                            Text("\(session.locations?.count ?? 0) locations")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        if let duration = sessionDuration {
                            Text(duration)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            
            if let startDate = session.startDate {
                HStack {
                    Text("Started: \(startDate, style: .time)")
                    
                    if let endDate = session.endDate {
                        Text("• Ended: \(endDate, style: .time)")
                    }
                }
                .font(.caption)
                .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .onTapGesture {
            onTapSession()
        }
    }
    
    private var sessionDuration: String? {
        guard let startDate = session.startDate else { return nil }
        
        let endDate = session.endDate ?? Date()
        let duration = endDate.timeIntervalSince(startDate)
        
        let hours = Int(duration) / 3600
        let minutes = Int(duration) % 3600 / 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
}

struct SessionDetailView: View {
    let session: TrackingSession
    @Environment(\.presentationMode) var presentationMode
    
    private var locations: [LocationEntry] {
        session.locations?.allObjects as? [LocationEntry] ?? []
    }
    
    private var sortedLocations: [LocationEntry] {
        locations.sorted { ($0.timestamp ?? Date.distantPast) < ($1.timestamp ?? Date.distantPast) }
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Session Info
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Session Details")
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            DetailRow(title: "Description", value: session.narrative ?? "No description")
                            
                            if let startDate = session.startDate {
                                DetailRow(title: "Start Time", value: DateFormatter.detailed.string(from: startDate))
                            }
                            
                            if let endDate = session.endDate {
                                DetailRow(title: "End Time", value: DateFormatter.detailed.string(from: endDate))
                            }
                            
                            DetailRow(title: "Duration", value: sessionDuration)
                            DetailRow(title: "Total Locations", value: "\(locations.count)")
                            DetailRow(title: "Status", value: session.isActive ? "Active" : "Completed")
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                    
                    // Statistics
                    if !locations.isEmpty {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Statistics")
                                .font(.title2)
                                .fontWeight(.semibold)
                            
                            VStack(alignment: .leading, spacing: 8) {
                                if let firstLocation = sortedLocations.first,
                                   let lastLocation = sortedLocations.last {
                                    let distance = firstLocation.distance(to: lastLocation)
                                    DetailRow(title: "Distance (straight line)", value: String(format: "%.2f km", distance / 1000))
                                }
                                
                                if let avgAccuracy = averageAccuracy {
                                    DetailRow(title: "Average Accuracy", value: "±\(Int(avgAccuracy))m")
                                }
                                
                                if let maxSpeed = maxSpeed {
                                    DetailRow(title: "Max Speed", value: String(format: "%.1f km/h", maxSpeed * 3.6))
                                }
                            }
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                    }
                    
                    // Recent Locations
                    if !sortedLocations.isEmpty {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Location Data (\(min(10, sortedLocations.count)) most recent)")
                                .font(.title2)
                                .fontWeight(.semibold)
                            
                            LazyVStack(spacing: 8) {
                                ForEach(Array(sortedLocations.suffix(10).reversed().enumerated()), id: \.element.id) { index, location in
                                    LocationRowView(location: location, index: index + 1)
                                }
                            }
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                    }
                }
                .padding()
            }
            .navigationTitle("Session Details")
            .navigationBarItems(trailing: Button("Done") {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
    
    private var sessionDuration: String {
        guard let startDate = session.startDate else { return "Unknown" }
        
        let endDate = session.endDate ?? Date()
        let duration = endDate.timeIntervalSince(startDate)
        
        let hours = Int(duration) / 3600
        let minutes = Int(duration) % 3600 / 60
        let seconds = Int(duration) % 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m \(seconds)s"
        } else if minutes > 0 {
            return "\(minutes)m \(seconds)s"
        } else {
            return "\(seconds)s"
        }
    }
    
    private var averageAccuracy: Double? {
        guard !locations.isEmpty else { return nil }
        let totalAccuracy = locations.reduce(0) { $0 + $1.accuracy }
        return totalAccuracy / Double(locations.count)
    }
    
    private var maxSpeed: Double? {
        guard !locations.isEmpty else { return nil }
        return locations.map { $0.speed }.max()
    }
}

struct DetailRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
        }
    }
}

struct LocationRowView: View {
    let location: LocationEntry
    let index: Int
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("#\(index)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                if let timestamp = location.timestamp {
                    Text(timestamp, style: .time)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text("Lat: \(location.latitude, specifier: "%.6f"), Long: \(location.longitude, specifier: "%.6f")")
                    .font(.caption)
                    .monospaced()
                
                HStack {
                    Text("Accuracy: ±\(Int(location.accuracy))m")
                    Spacer()
                    if location.speed > 0 {
                        Text("Speed: \(location.speed * 3.6, specifier: "%.1f") km/h")
                    }
                }
                .font(.caption)
                .foregroundColor(.secondary)
            }
        }
        .padding(8)
        .background(Color(.systemBackground))
        .cornerRadius(8)
    }
}

// MARK: - Extensions
extension DateFormatter {
    static let detailed: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .medium
        return formatter
    }()
}

extension LocationEntry {
    func distance(to other: LocationEntry) -> Double {
        let location1 = CLLocation(latitude: self.latitude, longitude: self.longitude)
        let location2 = CLLocation(latitude: other.latitude, longitude: other.longitude)
        return location1.distance(from: location2)
    }
}

#Preview {
    HistoryView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}

// MARK: - Modern Components

struct ModernSessionRowView: View {
    let session: TrackingSession
    let onTapSession: () -> Void
    let onTapMap: () -> Void
    
    private var hasLocations: Bool {
        (session.locations?.count ?? 0) > 0
    }
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 16) {
                // Status indicator
                VStack {
                    Circle()
                        .fill(session.isActive ? Color.green : Color.blue)
                        .frame(width: 12, height: 12)
                        .overlay(
                            Circle()
                                .stroke(Color.white, lineWidth: 2)
                        )
                    
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 2)
                        .frame(maxHeight: .infinity)
                }
                .frame(height: 60)
                
                // Content
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(session.narrative ?? "Unnamed Session")
                                .font(.headline)
                                .fontWeight(.semibold)
                                .lineLimit(1)
                            
                            if let startDate = session.startDate {
                                Text(startDate.formatted(date: .abbreviated, time: .omitted))
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        Spacer()
                        
                        // Action buttons
                        HStack(spacing: 8) {
                            if hasLocations {
                                Button(action: onTapMap) {
                                    Image(systemName: "map.fill")
                                        .font(.title3)
                                        .foregroundColor(.white)
                                        .frame(width: 36, height: 36)
                                        .background(
                                            Circle()
                                                .fill(
                                                    LinearGradient(
                                                        gradient: Gradient(colors: [.blue, .blue.opacity(0.8)]),
                                                        startPoint: .topLeading,
                                                        endPoint: .bottomTrailing
                                                    )
                                                )
                                        )
                                        .shadow(color: Color.blue.opacity(0.3), radius: 4, x: 0, y: 2)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                            
                            Button(action: onTapSession) {
                                Image(systemName: "info.circle.fill")
                                    .font(.title3)
                                    .foregroundColor(.white)
                                    .frame(width: 36, height: 36)
                                    .background(
                                        Circle()
                                            .fill(
                                                LinearGradient(
                                                    gradient: Gradient(colors: [.purple, .purple.opacity(0.8)]),
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing
                                                )
                                            )
                                    )
                                    .shadow(color: Color.purple.opacity(0.3), radius: 4, x: 0, y: 2)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    
                    // Stats row
                    HStack(spacing: 16) {
                        if let startDate = session.startDate {
                            StatItem(
                                icon: "clock.fill",
                                text: startDate.formatted(date: .omitted, time: .shortened),
                                color: .orange
                            )
                        }
                        
                        StatItem(
                            icon: "location.fill",
                            text: "\(session.locations?.count ?? 0) points",
                            color: .blue
                        )
                        
                        if let duration = sessionDuration {
                            StatItem(
                                icon: "timer.circle.fill",
                                text: duration,
                                color: .green
                            )
                        }
                        
                        if session.isActive {
                            StatItem(
                                icon: "dot.radiowaves.left.and.right",
                                text: "Active",
                                color: .red
                            )
                        }
                        
                        Spacer()
                    }
                }
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.systemBackground))
                    .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color(.systemGray5), lineWidth: 0.5)
                    )
            )
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }
    
    private var sessionDuration: String? {
        guard let startDate = session.startDate else { return nil }
        
        let endDate = session.endDate ?? Date()
        let duration = endDate.timeIntervalSince(startDate)
        
        let hours = Int(duration) / 3600
        let minutes = Int(duration) % 3600 / 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
}

struct StatItem: View {
    let icon: String
    let text: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(color)
            
            Text(text)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}