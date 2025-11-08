import SwiftUI

/// Settings view for selecting tracking mode with detailed information and warnings
struct TrackingModeSettingsView: View {
    @AppStorage("selectedTrackingMode") private var selectedMode: String = TrackingMode.balanced.rawValue
    @Environment(\.dismiss) private var dismiss

    @State private var showingDetailSheet = false
    @State private var detailMode: TrackingMode?

    private var currentMode: TrackingMode {
        TrackingMode(rawValue: selectedMode) ?? .balanced
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 8) {
                        Image(systemName: "location.circle.fill")
                            .font(.system(size: 50))
                            .foregroundColor(.blue)

                        Text("Tracking Quality")
                            .font(.title2)
                            .fontWeight(.bold)

                        Text("Choose how detailed you want your tracking to be")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .padding(.top)

                    // Mode Selection Cards
                    VStack(spacing: 16) {
                        ForEach(TrackingMode.allCases) { mode in
                            TrackingModeCard(
                                mode: mode,
                                isSelected: currentMode == mode,
                                onSelect: {
                                    withAnimation {
                                        selectedMode = mode.rawValue
                                    }
                                },
                                onShowDetails: {
                                    detailMode = mode
                                    showingDetailSheet = true
                                }
                            )
                        }
                    }
                    .padding(.horizontal)

                    // Current Selection Summary
                    CurrentSelectionSummary(mode: currentMode)
                        .padding(.horizontal)

                    // Important Note
                    VStack(alignment: .leading, spacing: 12) {
                        Label("Important", systemImage: "info.circle.fill")
                            .font(.headline)
                            .foregroundColor(.blue)

                        Text("The tracking mode can only be changed before starting a new tracking session. Active sessions will continue using their original settings.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.blue.opacity(0.1))
                    )
                    .padding(.horizontal)
                }
                .padding(.bottom, 32)
            }
            .navigationTitle("Tracking Mode")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingDetailSheet) {
                if let mode = detailMode {
                    TrackingModeDetailSheet(mode: mode)
                }
            }
        }
    }
}

// MARK: - Tracking Mode Card

struct TrackingModeCard: View {
    let mode: TrackingMode
    let isSelected: Bool
    let onSelect: () -> Void
    let onShowDetails: () -> Void

    var body: some View {
        Button(action: onSelect) {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    // Icon
                    Image(systemName: mode.iconName)
                        .font(.title)
                        .foregroundColor(isSelected ? .white : .blue)
                        .frame(width: 44, height: 44)
                        .background(
                            Circle()
                                .fill(isSelected ? Color.blue : Color.blue.opacity(0.1))
                        )

                    VStack(alignment: .leading, spacing: 4) {
                        Text(mode.displayName)
                            .font(.headline)
                            .foregroundColor(.primary)

                        Text(mode.description)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(.green)
                    }
                }

                // Quick stats
                HStack(spacing: 16) {
                    StatBadge(icon: "ruler", text: mode.technicalSpecs.components(separatedBy: " | ").first ?? "")
                    StatBadge(icon: "target", text: mode.technicalSpecs.components(separatedBy: " | ")[1])
                }

                // Show details button
                Button(action: onShowDetails) {
                    HStack {
                        Text("View Details & Warnings")
                            .font(.caption)
                            .fontWeight(.medium)
                        Image(systemName: "chevron.right")
                            .font(.caption2)
                    }
                    .foregroundColor(.blue)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.systemBackground))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(isSelected ? Color.blue : Color(.systemGray4), lineWidth: isSelected ? 2 : 1)
                    )
                    .shadow(color: Color.black.opacity(isSelected ? 0.1 : 0.05), radius: 8, x: 0, y: 4)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct StatBadge: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption2)
            Text(text)
                .font(.caption2)
        }
        .foregroundColor(.secondary)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(Color(.systemGray6))
        )
    }
}

// MARK: - Current Selection Summary

struct CurrentSelectionSummary: View {
    let mode: TrackingMode

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Current Selection", systemImage: "checkmark.circle.fill")
                .font(.headline)
                .foregroundColor(.green)

            VStack(alignment: .leading, spacing: 8) {
                Text(mode.displayName)
                    .font(.title3)
                    .fontWeight(.semibold)

                Text(mode.details)
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                Divider()

                Text("Example data usage:")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)

                Text(mode.dataVolumeExamples)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.green.opacity(0.1))
        )
    }
}

// MARK: - Detail Sheet

struct TrackingModeDetailSheet: View {
    let mode: TrackingMode
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Header
                    VStack(spacing: 12) {
                        Image(systemName: mode.iconName)
                            .font(.system(size: 60))
                            .foregroundColor(.blue)

                        Text(mode.displayName)
                            .font(.title)
                            .fontWeight(.bold)

                        Text(mode.description)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()

                    // Details
                    DetailSection(title: "How It Works", icon: "gear") {
                        Text(mode.details)
                            .font(.subheadline)
                    }

                    DetailSection(title: "Technical Specifications", icon: "chart.bar") {
                        Text(mode.technicalSpecs)
                            .font(.subheadline)
                            .fontDesign(.monospaced)
                    }

                    DetailSection(title: "Data Usage Examples", icon: "doc.text") {
                        Text(mode.dataVolumeExamples)
                            .font(.subheadline)
                    }

                    // Warnings Section
                    VStack(alignment: .leading, spacing: 12) {
                        Label("Important Considerations", systemImage: "exclamationmark.triangle.fill")
                            .font(.headline)
                            .foregroundColor(.orange)

                        ForEach(mode.warnings, id: \.self) { warning in
                            HStack(alignment: .top, spacing: 8) {
                                Text("•")
                                    .font(.caption)
                                Text(warning)
                                    .font(.caption)
                            }
                            .foregroundColor(.primary)
                        }
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.orange.opacity(0.1))
                    )
                    .padding(.horizontal)
                }
                .padding(.bottom, 32)
            }
            .navigationTitle("Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct DetailSection<Content: View>: View {
    let title: String
    let icon: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(title, systemImage: icon)
                .font(.headline)
                .foregroundColor(.primary)

            content
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6))
        )
        .padding(.horizontal)
    }
}

#Preview {
    TrackingModeSettingsView()
}
