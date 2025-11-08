import SwiftUI
import CoreData
import UIKit

/// Detailed view of a single tracking session
struct SessionDetailView: View {
    let session: TrackingSession
    @Environment(\.managedObjectContext) private var viewContext

    @State private var showingExportMenu = false
    @State private var showingExportSheet = false
    @State private var exportFileURL: URL?
    @State private var cachedSortedLocations: [LocationEntry]?

    private var locations: [LocationEntry] {
        session.locations?.allObjects as? [LocationEntry] ?? []
    }

    private var sortedLocations: [LocationEntry] {
        if let cached = cachedSortedLocations {
            return cached
        }
        // Use Core Data fetch request with sort descriptors for efficient database-level sorting
        return session.fetchSortedLocations()
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

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Session Info
                SessionInfoCard(
                    session: session,
                    locationCount: locations.count,
                    sessionDuration: sessionDuration
                )

                // Statistics
                SessionStatisticsCard(sortedLocations: sortedLocations)

                // Recent Locations
                RecentLocationsView(sortedLocations: sortedLocations)
            }
            .padding()
        }
        .onAppear {
            viewContext.refresh(session, mergeChanges: true)
            // Use Core Data fetch request with sort descriptors for efficient database-level sorting
            cachedSortedLocations = session.fetchSortedLocations(in: viewContext)
            print("SessionDetailView: Loaded session '\(session.narrative ?? "Unnamed")' with \(locations.count) locations")
        }
        .navigationTitle("Session Details")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    showingExportMenu = true
                }) {
                    Label("Export", systemImage: "square.and.arrow.up")
                }
            }
        }
        .confirmationDialog("Export Session", isPresented: $showingExportMenu) {
            ForEach(ExportFormat.allCases, id: \.self) { format in
                Button(format.rawValue) {
                    exportSession(format: format)
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Choose a format to export this tracking session")
        }
        .sheet(isPresented: $showingExportSheet, onDismiss: {
            exportFileURL = nil
            showingExportSheet = false
        }) {
            if let fileURL = exportFileURL {
                ActivityViewController(activityItems: [fileURL])
            }
        }
    }

    private func exportSession(format: ExportFormat) {
        let exportService = ExportService.shared

        do {
            let content: String

            switch format {
            case .gpx:
                content = try exportService.exportToGPX(session: session, locations: sortedLocations)
            case .kml:
                content = try exportService.exportToKML(session: session, locations: sortedLocations)
            case .csv:
                content = try exportService.exportToCSV(session: session, locations: sortedLocations)
            case .geojson:
                content = try exportService.exportToGeoJSON(session: session, locations: sortedLocations)
            }

            let filename = exportService.generateFilename(session: session, format: format)
            let fileURL = try exportService.saveToTemporaryFile(content: content, filename: filename)

            exportFileURL = fileURL
            showingExportSheet = true
        } catch let error as AppError {
            Task { @MainActor in
                ErrorHandler.shared.handle(error)
            }
        } catch {
            Task { @MainActor in
                ErrorHandler.shared.handle(.unknown(error))
            }
        }
    }
}

// MARK: - ActivityViewController for sharing

struct ActivityViewController: UIViewControllerRepresentable {
    let activityItems: [Any]
    let applicationActivities: [UIActivity]? = nil

    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(
            activityItems: activityItems,
            applicationActivities: applicationActivities
        )
        return controller
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {
        // No update needed
    }
}
