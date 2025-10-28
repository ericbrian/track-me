import SwiftUI

struct SessionStatusView: View {
    @EnvironmentObject var watchConnectivity: WatchConnectivityManager
    @State private var showingRefresh = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Header
                VStack(spacing: 8) {
                    Image(systemName: "info.circle.fill")
                        .font(.title2)
                        .foregroundColor(.blue)
                    
                    Text("Session Status")
                        .font(.headline)
                        .fontWeight(.semibold)
                }
                
                // Current Session Info
                if watchConnectivity.isTracking {
                    currentSessionView
                } else {
                    noActiveSessionView
                }
                
                // Connection Info
                connectionInfoView
                
                // Refresh Button
                Button(action: {
                    showingRefresh = true
                    watchConnectivity.requestStatusUpdate()
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        showingRefresh = false
                    }
                }) {
                    HStack {
                        if showingRefresh {
                            ProgressView()
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: "arrow.clockwise")
                        }
                        Text("Refresh")
                            .fontWeight(.medium)
                    }
                    .foregroundColor(.blue)
                    .frame(maxWidth: .infinity)
                    .frame(height: 40)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(20)
                }
                .disabled(showingRefresh || !watchConnectivity.isConnectedToPhone)
            }
            .padding(.horizontal, 8)
        }
        .navigationTitle("Status")
        .onAppear {
            watchConnectivity.requestStatusUpdate()
        }
    }
    
    @ViewBuilder
    private var currentSessionView: some View {
        VStack(spacing: 12) {
            // Session header
            HStack {
                Circle()
                    .fill(Color.green)
                    .frame(width: 8, height: 8)
                
                Text("Active Session")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.green)
                
                Spacer()
            }
            
            // Session details
            VStack(spacing: 8) {
                if let narrative = watchConnectivity.sessionNarrative {
                    HStack {
                        Text("Activity:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(narrative)
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                }
                
                if let startTime = watchConnectivity.sessionStartTime {
                    HStack {
                        Text("Started:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(startTime, style: .time)
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                }
                
                HStack {
                    Text("Duration:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(durationString)
                        .font(.caption)
                        .fontWeight(.medium)
                }
                
                HStack {
                    Text("Locations:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("\(watchConnectivity.locationCount)")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.blue)
                }
            }
        }
        .padding(12)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    @ViewBuilder
    private var noActiveSessionView: some View {
        VStack(spacing: 12) {
            Image(systemName: "location.slash")
                .font(.title2)
                .foregroundColor(.gray)
            
            Text("No Active Session")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)
            
            Text("Start tracking from the Track tab to see session details.")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(20)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    @ViewBuilder
    private var connectionInfoView: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: watchConnectivity.isConnectedToPhone ? "iphone" : "iphone.slash")
                    .font(.title3)
                    .foregroundColor(watchConnectivity.isConnectedToPhone ? .green : .red)
                
                Text("iPhone Connection")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                Spacer()
            }
            
            HStack {
                Text("Status:")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                Text(watchConnectivity.isConnectedToPhone ? "Connected" : "Disconnected")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(watchConnectivity.isConnectedToPhone ? .green : .red)
            }
            
            if let lastUpdate = watchConnectivity.lastUpdateTime {
                HStack {
                    Text("Last Update:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(lastUpdate, style: .time)
                        .font(.caption)
                        .fontWeight(.medium)
                }
            }
        }
        .padding(12)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private var durationString: String {
        guard let startTime = watchConnectivity.sessionStartTime else { return "0m" }
        
        let duration = Date().timeIntervalSince(startTime)
        let hours = Int(duration) / 3600
        let minutes = Int(duration) % 3600 / 60
        let seconds = Int(duration) % 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else if minutes > 0 {
            return "\(minutes)m \(seconds)s"
        } else {
            return "\(seconds)s"
        }
    }
}

#Preview {
    SessionStatusView()
        .environmentObject(WatchConnectivityManager())
}