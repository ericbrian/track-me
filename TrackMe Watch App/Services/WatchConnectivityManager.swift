import Foundation
import WatchConnectivity
import Combine

class WatchConnectivityManager: NSObject, ObservableObject {
    @Published var isTracking = false
    @Published var locationCount = 0
    @Published var sessionNarrative: String?
    @Published var sessionStartTime: Date?
    @Published var isConnectedToPhone = false
    @Published var lastUpdateTime: Date?
    
    private var session: WCSession?
    
    override init() {
        super.init()
        setupWatchConnectivity()
    }
    
    private func setupWatchConnectivity() {
        if WCSession.isSupported() {
            session = WCSession.default
            session?.delegate = self
            session?.activate()
        }
    }
    
    // MARK: - Actions to send to iPhone
    
    func startTracking(with narrative: String) {
        guard let session = session, session.isReachable else {
            print("iPhone not reachable")
            return
        }
        
        let message = [
            "action": "startTracking",
            "narrative": narrative
        ]
        
        session.sendMessage(message, replyHandler: { response in
            DispatchQueue.main.async {
                if let success = response["success"] as? Bool, success {
                    self.isTracking = true
                    self.sessionNarrative = narrative
                    self.sessionStartTime = Date()
                    self.locationCount = 0
                }
            }
        }) { error in
            print("Error starting tracking: \(error.localizedDescription)")
        }
    }
    
    func stopTracking() {
        guard let session = session, session.isReachable else {
            print("iPhone not reachable")
            return
        }
        
        let message = ["action": "stopTracking"]
        
        session.sendMessage(message, replyHandler: { response in
            DispatchQueue.main.async {
                if let success = response["success"] as? Bool, success {
                    self.isTracking = false
                    self.sessionNarrative = nil
                    self.sessionStartTime = nil
                    self.locationCount = 0
                }
            }
        }) { error in
            print("Error stopping tracking: \(error.localizedDescription)")
        }
    }
    
    func requestStatusUpdate() {
        guard let session = session, session.isReachable else {
            print("iPhone not reachable")
            return
        }
        
        let message = ["action": "getStatus"]
        
        session.sendMessage(message, replyHandler: { response in
            DispatchQueue.main.async {
                self.updateFromResponse(response)
            }
        }) { error in
            print("Error requesting status: \(error.localizedDescription)")
        }
    }
    
    private func updateFromResponse(_ response: [String: Any]) {
        if let tracking = response["isTracking"] as? Bool {
            self.isTracking = tracking
        }
        
        if let count = response["locationCount"] as? Int {
            self.locationCount = count
        }
        
        if let narrative = response["narrative"] as? String {
            self.sessionNarrative = narrative
        }
        
        if let startTimeInterval = response["startTime"] as? TimeInterval {
            self.sessionStartTime = Date(timeIntervalSince1970: startTimeInterval)
        }
        
        self.lastUpdateTime = Date()
    }
}

// MARK: - WCSessionDelegate

extension WatchConnectivityManager: WCSessionDelegate {
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        DispatchQueue.main.async {
            self.isConnectedToPhone = (activationState == .activated && session.isReachable)
            
            if self.isConnectedToPhone {
                // Request initial status when connected
                self.requestStatusUpdate()
            }
        }
    }
    
    func sessionReachabilityDidChange(_ session: WCSession) {
        DispatchQueue.main.async {
            self.isConnectedToPhone = session.isReachable
            
            if session.isReachable {
                // Request status update when connection is restored
                self.requestStatusUpdate()
            }
        }
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        DispatchQueue.main.async {
            // Handle updates from iPhone
            if message["type"] as? String == "statusUpdate" {
                self.updateFromResponse(message)
            }
        }
    }
    
    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String : Any]) {
        DispatchQueue.main.async {
            // Handle context updates from iPhone
            self.updateFromResponse(applicationContext)
        }
    }
}