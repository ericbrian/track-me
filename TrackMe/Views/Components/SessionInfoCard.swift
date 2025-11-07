import SwiftUI

/// Card displaying session detail information
struct SessionInfoCard: View {
    let session: TrackingSession
    let locationCount: Int
    let sessionDuration: String

    var body: some View {
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
                DetailRow(title: "Total Locations", value: "\(locationCount)")
                DetailRow(title: "Status", value: session.isActive ? "Active" : "Completed")
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
}
