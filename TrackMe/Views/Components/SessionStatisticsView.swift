import SwiftUI

/// Display current session statistics
struct SessionStatisticsView: View {
    let locationCount: Int
    let currentSession: TrackingSession?

    var body: some View {
        VStack(spacing: 16) {
            HStack(spacing: 16) {
                StatCard(
                    icon: "number.circle.fill",
                    title: "Locations",
                    value: "\(locationCount)",
                    color: .blue
                )

                if let session = currentSession,
                   let startDate = session.startDate {
                    StatCard(
                        icon: "clock.fill",
                        title: "Started",
                        value: startDate.formatted(date: .omitted, time: .shortened),
                        color: .purple
                    )
                }
            }

            if let session = currentSession,
               let narrative = session.narrative {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "quote.bubble.fill")
                            .foregroundColor(.mint)
                        Text("Current Session")
                            .font(.headline)
                            .fontWeight(.semibold)
                        Spacer()
                    }

                    Text(narrative)
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.leading)
                }
                .padding(20)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(.systemGray6))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.mint.opacity(0.3), lineWidth: 1)
                        )
                )
            }
        }
    }
}
