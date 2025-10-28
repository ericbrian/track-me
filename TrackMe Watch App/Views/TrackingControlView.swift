import SwiftUI

struct TrackingControlView: View {
    @EnvironmentObject var watchConnectivity: WatchConnectivityManager
    @State private var showingNarrativeInput = false
    @State private var hapticFeedback = WKHapticType.success
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Status Indicator
                VStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(watchConnectivity.isTracking ? Color.green.opacity(0.2) : Color.gray.opacity(0.2))
                            .frame(width: 80, height: 80)
                        
                        Circle()
                            .stroke(watchConnectivity.isTracking ? Color.green : Color.gray, lineWidth: 3)
                            .frame(width: 80, height: 80)
                        
                        Image(systemName: watchConnectivity.isTracking ? "location.fill" : "location")
                            .font(.system(size: 24, weight: .medium))
                            .foregroundColor(watchConnectivity.isTracking ? .green : .gray)
                    }
                    .scaleEffect(watchConnectivity.isTracking ? 1.0 : 0.9)
                    .animation(.easeInOut(duration: 0.3), value: watchConnectivity.isTracking)
                    
                    Text(watchConnectivity.isTracking ? "TRACKING" : "STOPPED")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(watchConnectivity.isTracking ? .green : .gray)
                }
                
                // Stats (when tracking)
                if watchConnectivity.isTracking {
                    VStack(spacing: 8) {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Locations")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                                Text("\(watchConnectivity.locationCount)")
                                    .font(.title3)
                                    .fontWeight(.semibold)
                            }
                            
                            Spacer()
                            
                            VStack(alignment: .trailing, spacing: 2) {
                                Text("Duration")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                                Text(durationString)
                                    .font(.title3)
                                    .fontWeight(.semibold)
                            }
                        }
                        .padding(.horizontal, 4)
                        
                        if let narrative = watchConnectivity.sessionNarrative {
                            Text(narrative)
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .lineLimit(2)
                        }
                    }
                    .padding(12)
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                }
                
                // Control Button
                VStack(spacing: 12) {
                    if !watchConnectivity.isTracking {
                        Button(action: {
                            showingNarrativeInput = true
                        }) {
                            HStack {
                                Image(systemName: "play.fill")
                                    .font(.system(size: 16, weight: .medium))
                                Text("Start")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 44)
                            .background(Color.green)
                            .cornerRadius(22)
                        }
                        .disabled(!watchConnectivity.isConnectedToPhone)
                        .opacity(watchConnectivity.isConnectedToPhone ? 1.0 : 0.5)
                    } else {
                        Button(action: {
                            WKInterfaceDevice.current().play(hapticFeedback)
                            watchConnectivity.stopTracking()
                        }) {
                            HStack {
                                Image(systemName: "stop.fill")
                                    .font(.system(size: 16, weight: .medium))
                                Text("Stop")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 44)
                            .background(Color.red)
                            .cornerRadius(22)
                        }
                    }
                    
                    // Connection status
                    connectionStatusView
                }
            }
            .padding(.horizontal, 8)
        }
        .navigationTitle("GPS Tracker")
        .onAppear {
            watchConnectivity.requestStatusUpdate()
        }
        .sheet(isPresented: $showingNarrativeInput) {
            NarrativeInputView { narrative in
                WKInterfaceDevice.current().play(.success)
                watchConnectivity.startTracking(with: narrative)
            }
        }
    }
    
    @ViewBuilder
    private var connectionStatusView: some View {
        HStack {
            Circle()
                .fill(watchConnectivity.isConnectedToPhone ? Color.green : Color.red)
                .frame(width: 6, height: 6)
            
            Text(watchConnectivity.isConnectedToPhone ? "Connected to iPhone" : "iPhone not reachable")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }
    
    private var durationString: String {
        guard let startTime = watchConnectivity.sessionStartTime else { return "0m" }
        
        let duration = Date().timeIntervalSince(startTime)
        let minutes = Int(duration) / 60
        let hours = minutes / 60
        
        if hours > 0 {
            return "\(hours)h \(minutes % 60)m"
        } else {
            return "\(minutes)m"
        }
    }
}

struct NarrativeInputView: View {
    let onStart: (String) -> Void
    @Environment(\.presentationMode) var presentationMode
    @State private var selectedNarrative = "Quick Track"
    
    private let suggestions = [
        "Quick Track",
        "Morning Jog",
        "Walk",
        "Drive to Work",
        "Bike Ride",
        "Hiking"
    ]
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 16) {
                    Text("Choose Activity")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .padding(.top, 8)
                    
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 12) {
                        ForEach(suggestions, id: \.self) { suggestion in
                            Button(action: {
                                selectedNarrative = suggestion
                            }) {
                                VStack(spacing: 6) {
                                    Image(systemName: iconForSuggestion(suggestion))
                                        .font(.title2)
                                        .foregroundColor(selectedNarrative == suggestion ? .white : .blue)
                                    
                                    Text(suggestion)
                                        .font(.caption)
                                        .fontWeight(.medium)
                                        .foregroundColor(selectedNarrative == suggestion ? .white : .primary)
                                        .multilineTextAlignment(.center)
                                }
                                .frame(maxWidth: .infinity)
                                .frame(height: 60)
                                .background(selectedNarrative == suggestion ? Color.blue : Color(.systemGray6))
                                .cornerRadius(12)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    
                    Button(action: {
                        onStart(selectedNarrative)
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        HStack {
                            Image(systemName: "location.fill")
                            Text("Start Tracking")
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 40)
                        .background(Color.green)
                        .cornerRadius(20)
                    }
                    .padding(.top, 8)
                }
                .padding(.horizontal, 8)
            }
            .navigationTitle("New Session")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }
    
    private func iconForSuggestion(_ suggestion: String) -> String {
        switch suggestion {
        case "Morning Jog": return "figure.run"
        case "Walk": return "figure.walk"
        case "Drive to Work": return "car.fill"
        case "Bike Ride": return "bicycle"
        case "Hiking": return "mountain.2.fill"
        default: return "location.fill"
        }
    }
}

#Preview {
    TrackingControlView()
        .environmentObject(WatchConnectivityManager())
}