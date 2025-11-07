import SwiftUI

/// Modern card-style row view for a tracking session
struct ModernSessionRowView: View {
    let session: TrackingSession

    @State private var showingExportMenu = false
    @State private var showingExportSheet = false
    @State private var exportFileURL: URL?

    private var hasLocations: Bool {
        (session.locations?.count ?? 0) > 0
    }

    private func getSortedLocations() -> [LocationEntry] {
        let locations = session.locations?.allObjects as? [LocationEntry] ?? []
        return locations.sorted { ($0.timestamp ?? Date.distantPast) < ($1.timestamp ?? Date.distantPast) }
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

                    // Action buttons row at bottom
                    HStack(spacing: 12) {
                        if hasLocations {
                            NavigationLink(destination: TripMapView(session: session)) {
                                ActionButton(
                                    icon: "map.fill",
                                    text: "Map",
                                    colors: [.blue, .blue.opacity(0.8)]
                                )
                            }
                            .buttonStyle(PlainButtonStyle())
                        }

                        NavigationLink(destination: SessionDetailView(session: session)) {
                            ActionButton(
                                icon: "info.circle.fill",
                                text: "Details",
                                colors: [.purple, .purple.opacity(0.8)]
                            )
                        }
                        .buttonStyle(PlainButtonStyle())

                        if hasLocations {
                            Button(action: { showingExportMenu = true }) {
                                ActionButton(
                                    icon: "square.and.arrow.down.fill",
                                    text: "Export",
                                    colors: [.green, .green.opacity(0.8)]
                                )
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
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
        let sortedLocations = getSortedLocations()
        let content: String

        switch format {
        case .gpx:
            content = exportService.exportToGPX(session: session, locations: sortedLocations)
        case .kml:
            content = exportService.exportToKML(session: session, locations: sortedLocations)
        case .csv:
            content = exportService.exportToCSV(session: session, locations: sortedLocations)
        case .geojson:
            content = exportService.exportToGeoJSON(session: session, locations: sortedLocations)
        }

        let filename = exportService.generateFilename(session: session, format: format)

        if let fileURL = exportService.saveToTemporaryFile(content: content, filename: filename) {
            exportFileURL = fileURL
            showingExportSheet = true
        }
    }
}

// MARK: - Action Button Component

private struct ActionButton: View {
    let icon: String
    let text: String
    let colors: [Color]

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.body)
            Text(text)
                .font(.subheadline)
                .fontWeight(.medium)
        }
        .foregroundColor(.white)
        .frame(maxWidth: .infinity)
        .frame(height: 44)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: colors),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        .shadow(color: colors.first?.opacity(0.3) ?? Color.clear, radius: 4, x: 0, y: 2)
    }
}
