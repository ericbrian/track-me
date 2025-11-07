import SwiftUI

/// Small reusable components for tracking views

/// Card displaying a single statistic
struct StatCard: View {
    let icon: String
    let title: String
    let value: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)

            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)

            Text(value)
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(color.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

/// Card displaying location data (lat, lon, accuracy, etc.)
struct LocationDataCard: View {
    let title: String
    let value: String
    let icon: String

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.blue)

            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)

            Text(value)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.primary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
        )
    }
}

/// Bullet point for feature lists
struct FeatureBullet: View {
    let text: String

    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(Color.mint)
                .frame(width: 4, height: 4)

            Text(text)
                .font(.caption)
                .foregroundColor(.secondary)

            Spacer()
        }
    }
}
