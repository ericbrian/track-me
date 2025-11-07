import SwiftUI

/// Empty state view for history when no sessions exist
struct EmptyHistoryView: View {
    var body: some View {
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
                    .padding(.horizontal, 32)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 80)
        .listRowBackground(Color.clear)
        .listRowSeparator(.hidden)
    }
}
