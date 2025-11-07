import SwiftUI
import CoreLocation

/// Card displaying session statistics
struct SessionStatisticsCard: View {
    let sortedLocations: [LocationEntry]

    private var averageAccuracy: Double? {
        guard !sortedLocations.isEmpty else { return nil }
        let totalAccuracy = sortedLocations.reduce(0) { $0 + $1.accuracy }
        return totalAccuracy / Double(sortedLocations.count)
    }

    private var maxSpeed: Double? {
        guard !sortedLocations.isEmpty else { return nil }
        return sortedLocations.map { $0.speed }.max()
    }

    var body: some View {
        if !sortedLocations.isEmpty {
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
    }
}
