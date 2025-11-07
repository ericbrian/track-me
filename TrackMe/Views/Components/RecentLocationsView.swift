import SwiftUI

/// View displaying recent location entries
struct RecentLocationsView: View {
    let sortedLocations: [LocationEntry]

    var body: some View {
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
}
