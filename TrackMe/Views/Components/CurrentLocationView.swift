import SwiftUI
import CoreLocation

/// Display current GPS location information
struct CurrentLocationView: View {
    let location: CLLocation

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "location.north.circle.fill")
                    .foregroundColor(.blue)
                    .font(.title2)
                Text("Current Location")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
            }

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                LocationDataCard(
                    title: "Latitude",
                    value: String(format: "%.6f", location.coordinate.latitude),
                    icon: "globe.americas"
                )

                LocationDataCard(
                    title: "Longitude",
                    value: String(format: "%.6f", location.coordinate.longitude),
                    icon: "globe.asia.australia"
                )

                LocationDataCard(
                    title: "Accuracy",
                    value: "±\(Int(location.horizontalAccuracy))m",
                    icon: "target"
                )

                LocationDataCard(
                    title: "Updated",
                    value: location.timestamp.formatted(date: .omitted, time: .shortened),
                    icon: "clock"
                )
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [Color(.systemGray6), Color(.systemGray5)]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.blue.opacity(0.2), lineWidth: 1)
                )
        )
    }
}
