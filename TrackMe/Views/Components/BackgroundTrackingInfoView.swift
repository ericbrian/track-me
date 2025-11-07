import SwiftUI

/// Information card showing background tracking capabilities
struct BackgroundTrackingInfoView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "shield.checkered")
                    .foregroundColor(.mint)
                Text("Background Tracking Active")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.mint)
            }

            Text("This app continues tracking your location when:")
                .font(.subheadline)
                .foregroundColor(.secondary)

            VStack(alignment: .leading, spacing: 6) {
                FeatureBullet(text: "App is minimized or closed")
                FeatureBullet(text: "Device screen is locked")
                FeatureBullet(text: "You switch to other apps")
            }
            .padding(.leading, 8)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.mint.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.mint.opacity(0.3), lineWidth: 1)
                )
        )
    }
}
