import SwiftUI
import CoreLocation

/// Small reusable components for history views

/// Simple detail row showing title and value
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

/// Row view for a single location entry
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

/// Small statistic item with icon
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
