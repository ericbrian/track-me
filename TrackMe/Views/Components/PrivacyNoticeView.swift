import SwiftUI

/// A view that displays the app's privacy policy and data handling practices
struct PrivacyNoticeView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        Image(systemName: "lock.shield.fill")
                            .font(.system(size: 48))
                            .foregroundColor(.blue)
                        
                        Text("Your Privacy Matters")
                            .font(.title)
                            .fontWeight(.bold)
                        
                        Text("TrackMe is designed with privacy at its core")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.bottom, 8)
                    
                    Divider()
                    
                    // Why we need location
                    PrivacySection(
                        icon: "location.fill",
                        title: "Why We Need Your Location",
                        description: "TrackMe is a GPS tracking app that records your location to create a detailed history of your movements. This allows you to:",
                        points: [
                            "Track your trips and journeys",
                            "Review where you've been with timestamps",
                            "Export your location data for personal use",
                            "View your routes on a map"
                        ]
                    )
                    
                    Divider()
                    
                    // Local storage
                    PrivacySection(
                        icon: "internaldrive.fill",
                        title: "100% Local Storage",
                        description: "All your location data is stored exclusively on your device:",
                        points: [
                            "No cloud sync or remote servers",
                            "No data transmission over the internet",
                            "No third-party analytics or tracking",
                            "Complete control over your data"
                        ]
                    )
                    
                    Divider()
                    
                    // Background tracking
                    PrivacySection(
                        icon: "clock.arrow.circlepath",
                        title: "Background Tracking",
                        description: "For continuous tracking, we request 'Always Allow' permission:",
                        points: [
                            "Records location even when app is closed",
                            "Essential for long trips and journeys",
                            "You can disable anytime in Settings",
                            "Optimized to preserve battery life"
                        ]
                    )
                    
                    Divider()
                    
                    // Your control
                    PrivacySection(
                        icon: "hand.raised.fill",
                        title: "You're In Control",
                        description: "Your data, your choice:",
                        points: [
                            "Start and stop tracking whenever you want",
                            "Delete any session or location data",
                            "Export your data to CSV or GeoJSON",
                            "No account required—ever"
                        ]
                    )
                    
                    Divider()
                    
                    // Data deletion
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(spacing: 12) {
                            Image(systemName: "trash.fill")
                                .font(.title2)
                                .foregroundColor(.red)
                            
                            Text("Data Deletion")
                                .font(.headline)
                        }
                        
                        Text("To completely remove all tracking data, simply delete the app from your device. All location history will be permanently erased as it's stored only on your device.")
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer(minLength: 40)
                }
                .padding(20)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Privacy & Data")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Supporting Views

/// A reusable section for displaying privacy information
struct PrivacySection: View {
    let icon: String
    let title: String
    let description: String
    let points: [String]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(.blue)
                
                Text(title)
                    .font(.headline)
            }
            
            Text(description)
                .font(.body)
                .foregroundColor(.secondary)
            
            VStack(alignment: .leading, spacing: 8) {
                ForEach(points, id: \.self) { point in
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.caption)
                            .foregroundColor(.green)
                            .padding(.top, 4)
                        
                        Text(point)
                            .font(.subheadline)
                    }
                }
            }
            .padding(.leading, 8)
        }
    }
}

// MARK: - Preview

#Preview {
    PrivacyNoticeView()
}
