import Foundation
import WatchConnectivity
import UIKit

class PhoneConnectivityManager: NSObject, ObservableObject {
    @Published var isWatchConnected = false
    
    private var session: WCSession?
    private var locationManager: LocationManager?
    
    override init() {
        super.init()
        setupWatchConnectivity()
    }
    
    func setLocationManager(_ manager: LocationManager) {
        self.locationManager = manager
        
        // Setup observers for location manager changes
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(trackingStateChanged),
            name: NSNotification.Name("TrackingStateChanged"),
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(locationCountChanged),
            name: NSNotification.Name("LocationCountChanged"),
            object: nil
        )
    }
    
    private func setupWatchConnectivity() {
        if WCSession.isSupported() {
            session = WCSession.default
            session?.delegate = self
            session?.activate()
        }
    }
    
    @objc private func trackingStateChanged() {
        sendStatusUpdateToWatch()
    }
    
    @objc private func locationCountChanged() {
        sendStatusUpdateToWatch()
    }
    
    private func sendStatusUpdateToWatch() {
        guard let session = session,
              session.isPaired && session.isWatchAppInstalled,
              let locationManager = locationManager else { return }
        
        var context: [String: Any] = [
            "type": "statusUpdate",
            "isTracking": locationManager.isTracking,
            "locationCount": locationManager.locationCount
        ]
        
        if let currentSession = locationManager.currentSession {
            if let narrative = currentSession.narrative {
                context["narrative"] = narrative
            }
            
            if let startDate = currentSession.startDate {
                context["startTime"] = startDate.timeIntervalSince1970
            }
        }
        
        do {
            try session.updateApplicationContext(context)
        } catch {
            print("Error updating watch context: \(error)")
        }
        
        // Also try to send immediate message if watch is reachable
        if session.isReachable {
            session.sendMessage(context, replyHandler: nil) { error in
                print("Error sending message to watch: \(error)")
            }
        }
    }
    
    private func handleWatchMessage(_ message: [String: Any]) -> [String: Any] {
        guard let action = message["action"] as? String,
              let locationManager = locationManager else {
            return ["success": false, "error": "Invalid action or location manager not available"]
        }
        
        switch action {
        case "startTracking":
            let narrative = message["narrative"] as? String ?? "Apple Watch Session"
            
            DispatchQueue.main.async {
                locationManager.startTracking(with: narrative)
            }
            
            return ["success": true]
            
        case "stopTracking":
            DispatchQueue.main.async {
                locationManager.stopTracking()
            }
            
            return ["success": true]
            
        case "getStatus":
            var response: [String: Any] = [
                "success": true,
                "isTracking": locationManager.isTracking,
                "locationCount": locationManager.locationCount
            ]
            
            if let currentSession = locationManager.currentSession {
                if let narrative = currentSession.narrative {
                    response["narrative"] = narrative
                }
                
                if let startDate = currentSession.startDate {
                    response["startTime"] = startDate.timeIntervalSince1970
                }
            }
            
            return response
            
        default:
            return ["success": false, "error": "Unknown action"]
        }
    }
}

// MARK: - WCSessionDelegate

extension PhoneConnectivityManager: WCSessionDelegate {
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        DispatchQueue.main.async {
            self.isWatchConnected = (activationState == .activated && session.isPaired && session.isWatchAppInstalled)
            
            if self.isWatchConnected {
                self.sendStatusUpdateToWatch()
            }
        }
    }
    
    func sessionDidBecomeInactive(_ session: WCSession) {
        // Handle session becoming inactive
    }
    
    func sessionDidDeactivate(_ session: WCSession) {
        // Reactivate the session
        session.activate()
    }
    
    func sessionWatchStateDidChange(_ session: WCSession) {
        DispatchQueue.main.async {
            self.isWatchConnected = session.isPaired && session.isWatchAppInstalled
        }
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any], replyHandler: @escaping ([String : Any]) -> Void) {
        let response = handleWatchMessage(message)
        replyHandler(response)
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        _ = handleWatchMessage(message)
    }
}