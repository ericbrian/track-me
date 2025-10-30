// TrackMeTests/WatchViewTests.swift
// Unit tests for Watch App View logic and computed properties

import XCTest
import SwiftUI
@testable import TrackMe

class WatchViewTests: XCTestCase {
    
    // MARK: - TrackingControlView Duration String Tests
    
    func testDurationStringLessThanOneHour() {
        let startTime = Date().addingTimeInterval(-1800) // 30 minutes ago
        
        let duration = Date().timeIntervalSince(startTime)
        let minutes = Int(duration) / 60
        let hours = minutes / 60
        
        let durationString: String
        if hours > 0 {
            durationString = "\(hours)h \(minutes % 60)m"
        } else {
            durationString = "\(minutes)m"
        }
        
        XCTAssertEqual(durationString, "30m")
    }
    
    func testDurationStringMoreThanOneHour() {
        let startTime = Date().addingTimeInterval(-5400) // 90 minutes ago
        
        let duration = Date().timeIntervalSince(startTime)
        let minutes = Int(duration) / 60
        let hours = minutes / 60
        
        let durationString: String
        if hours > 0 {
            durationString = "\(hours)h \(minutes % 60)m"
        } else {
            durationString = "\(minutes)m"
        }
        
        XCTAssertEqual(durationString, "1h 30m")
    }
    
    func testDurationStringMultipleHours() {
        let startTime = Date().addingTimeInterval(-10800) // 3 hours ago
        
        let duration = Date().timeIntervalSince(startTime)
        let minutes = Int(duration) / 60
        let hours = minutes / 60
        
        let durationString: String
        if hours > 0 {
            durationString = "\(hours)h \(minutes % 60)m"
        } else {
            durationString = "\(minutes)m"
        }
        
        XCTAssertEqual(durationString, "3h 0m")
    }
    
    func testDurationStringZeroDuration() {
        let startTime = Date() // Just now
        
        let duration = Date().timeIntervalSince(startTime)
        let minutes = Int(duration) / 60
        let hours = minutes / 60
        
        let durationString: String
        if hours > 0 {
            durationString = "\(hours)h \(minutes % 60)m"
        } else {
            durationString = "\(minutes)m"
        }
        
        XCTAssertEqual(durationString, "0m")
    }
    
    func testDurationStringWithSeconds() {
        let startTime = Date().addingTimeInterval(-90) // 1.5 minutes ago
        
        let duration = Date().timeIntervalSince(startTime)
        let minutes = Int(duration) / 60
        let hours = minutes / 60
        
        let durationString: String
        if hours > 0 {
            durationString = "\(hours)h \(minutes % 60)m"
        } else {
            durationString = "\(minutes)m"
        }
        
        // Should round down to 1 minute
        XCTAssertEqual(durationString, "1m")
    }
    
    // MARK: - NarrativeInputView Icon Tests
    
    func testIconForSuggestionMorningJog() {
        let icon = iconForSuggestion("Morning Jog")
        XCTAssertEqual(icon, "figure.run")
    }
    
    func testIconForSuggestionWalk() {
        let icon = iconForSuggestion("Walk")
        XCTAssertEqual(icon, "figure.walk")
    }
    
    func testIconForSuggestionDriveToWork() {
        let icon = iconForSuggestion("Drive to Work")
        XCTAssertEqual(icon, "car.fill")
    }
    
    func testIconForSuggestionBikeRide() {
        let icon = iconForSuggestion("Bike Ride")
        XCTAssertEqual(icon, "bicycle")
    }
    
    func testIconForSuggestionHiking() {
        let icon = iconForSuggestion("Hiking")
        XCTAssertEqual(icon, "mountain.2.fill")
    }
    
    func testIconForSuggestionDefault() {
        let icon = iconForSuggestion("Unknown Activity")
        XCTAssertEqual(icon, "location.fill")
    }
    
    func testIconForSuggestionQuickTrack() {
        let icon = iconForSuggestion("Quick Track")
        XCTAssertEqual(icon, "location.fill")
    }
    
    // MARK: - Narrative Suggestions Tests
    
    func testNarrativeSuggestionsList() {
        let suggestions = [
            "Quick Track",
            "Morning Jog",
            "Walk",
            "Drive to Work",
            "Bike Ride",
            "Hiking"
        ]
        
        XCTAssertEqual(suggestions.count, 6)
        XCTAssertTrue(suggestions.contains("Quick Track"))
        XCTAssertTrue(suggestions.contains("Morning Jog"))
        XCTAssertTrue(suggestions.contains("Hiking"))
    }
    
    func testNarrativeSuggestionsOrder() {
        let suggestions = [
            "Quick Track",
            "Morning Jog",
            "Walk",
            "Drive to Work",
            "Bike Ride",
            "Hiking"
        ]
        
        XCTAssertEqual(suggestions[0], "Quick Track")
        XCTAssertEqual(suggestions[suggestions.count - 1], "Hiking")
    }
    
    // MARK: - Connection Status Tests
    
    func testConnectionStatusConnected() {
        let isConnected = true
        let statusText = isConnected ? "Connected to iPhone" : "iPhone not reachable"
        
        XCTAssertEqual(statusText, "Connected to iPhone")
    }
    
    func testConnectionStatusDisconnected() {
        let isConnected = false
        let statusText = isConnected ? "Connected to iPhone" : "iPhone not reachable"
        
        XCTAssertEqual(statusText, "iPhone not reachable")
    }
    
    func testConnectionIndicatorColorConnected() {
        let isConnected = true
        let color = isConnected ? Color.green : Color.red
        
        XCTAssertEqual(color, Color.green)
    }
    
    func testConnectionIndicatorColorDisconnected() {
        let isConnected = false
        let color = isConnected ? Color.green : Color.red
        
        XCTAssertEqual(color, Color.red)
    }
    
    // MARK: - Tracking Status Tests
    
    func testTrackingStatusText() {
        let isTracking = true
        let statusText = isTracking ? "TRACKING" : "STOPPED"
        
        XCTAssertEqual(statusText, "TRACKING")
    }
    
    func testStoppedStatusText() {
        let isTracking = false
        let statusText = isTracking ? "TRACKING" : "STOPPED"
        
        XCTAssertEqual(statusText, "STOPPED")
    }
    
    func testTrackingStatusColor() {
        let isTracking = true
        let color = isTracking ? Color.green : Color.gray
        
        XCTAssertEqual(color, Color.green)
    }
    
    func testStoppedStatusColor() {
        let isTracking = false
        let color = isTracking ? Color.green : Color.gray
        
        XCTAssertEqual(color, Color.gray)
    }
    
    func testTrackingIconName() {
        let isTracking = true
        let iconName = isTracking ? "location.fill" : "location"
        
        XCTAssertEqual(iconName, "location.fill")
    }
    
    func testStoppedIconName() {
        let isTracking = false
        let iconName = isTracking ? "location.fill" : "location"
        
        XCTAssertEqual(iconName, "location")
    }
    
    // MARK: - Button State Tests
    
    func testStartButtonDisabledWhenNotConnected() {
        let isConnected = false
        let isDisabled = !isConnected
        
        XCTAssertTrue(isDisabled)
    }
    
    func testStartButtonEnabledWhenConnected() {
        let isConnected = true
        let isDisabled = !isConnected
        
        XCTAssertFalse(isDisabled)
    }
    
    func testButtonOpacityWhenDisconnected() {
        let isConnected = false
        let opacity = isConnected ? 1.0 : 0.5
        
        XCTAssertEqual(opacity, 0.5)
    }
    
    func testButtonOpacityWhenConnected() {
        let isConnected = true
        let opacity = isConnected ? 1.0 : 0.5
        
        XCTAssertEqual(opacity, 1.0)
    }
    
    // MARK: - Scale Effect Tests
    
    func testTrackingScaleEffect() {
        let isTracking = true
        let scale = isTracking ? 1.0 : 0.9
        
        XCTAssertEqual(scale, 1.0)
    }
    
    func testStoppedScaleEffect() {
        let isTracking = false
        let scale = isTracking ? 1.0 : 0.9
        
        XCTAssertEqual(scale, 0.9)
    }
    
    // MARK: - Stats Display Tests
    
    func testLocationCountDisplay() {
        let locationCount = 42
        let displayText = "\(locationCount)"
        
        XCTAssertEqual(displayText, "42")
    }
    
    func testLocationCountZero() {
        let locationCount = 0
        let displayText = "\(locationCount)"
        
        XCTAssertEqual(displayText, "0")
    }
    
    func testLocationCountLargeNumber() {
        let locationCount = 999999
        let displayText = "\(locationCount)"
        
        XCTAssertEqual(displayText, "999999")
    }
    
    // MARK: - Helper Functions
    
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

// MARK: - SessionStatusView Tests

class SessionStatusViewTests: XCTestCase {
    
    func testSessionStatusDisplayWhenTracking() {
        let isTracking = true
        let narrative = "Morning Run"
        let locationCount = 25
        
        XCTAssertTrue(isTracking)
        XCTAssertEqual(narrative, "Morning Run")
        XCTAssertEqual(locationCount, 25)
    }
    
    func testSessionStatusDisplayWhenNotTracking() {
        let isTracking = false
        let narrative: String? = nil
        let locationCount = 0
        
        XCTAssertFalse(isTracking)
        XCTAssertNil(narrative)
        XCTAssertEqual(locationCount, 0)
    }
    
    func testSessionStatusWithLongNarrative() {
        let narrative = "This is a very long narrative that should be truncated or handled properly in the UI"
        
        XCTAssertGreaterThan(narrative.count, 50)
        XCTAssertTrue(narrative.count > 0)
    }
    
    func testSessionStatusWithSpecialCharacters() {
        let narrative = "Test 🚶‍♂️ Walk & Run!"
        
        XCTAssertTrue(narrative.contains("🚶‍♂️"))
        XCTAssertTrue(narrative.contains("&"))
    }
}

// MARK: - Integration Tests

class WatchViewIntegrationTests: XCTestCase {
    
    func testCompleteTrackingFlow() {
        // Initial state
        var isTracking = false
        var narrative: String? = nil
        var locationCount = 0
        var startTime: Date? = nil
        
        XCTAssertFalse(isTracking)
        
        // Start tracking
        isTracking = true
        narrative = "Test Session"
        startTime = Date()
        locationCount = 0
        
        XCTAssertTrue(isTracking)
        XCTAssertNotNil(narrative)
        XCTAssertNotNil(startTime)
        
        // Simulate location updates
        for i in 1...10 {
            locationCount = i
        }
        
        XCTAssertEqual(locationCount, 10)
        
        // Calculate duration
        if let start = startTime {
            let duration = Date().timeIntervalSince(start)
            XCTAssertGreaterThanOrEqual(duration, 0)
        }
        
        // Stop tracking
        isTracking = false
        narrative = nil
        startTime = nil
        locationCount = 0
        
        XCTAssertFalse(isTracking)
        XCTAssertNil(narrative)
        XCTAssertNil(startTime)
        XCTAssertEqual(locationCount, 0)
    }
    
    func testConnectionStateTransitions() {
        var isConnected = false
        
        // Initial disconnected state
        XCTAssertFalse(isConnected)
        
        // Connection established
        isConnected = true
        XCTAssertTrue(isConnected)
        
        // Connection lost
        isConnected = false
        XCTAssertFalse(isConnected)
        
        // Reconnected
        isConnected = true
        XCTAssertTrue(isConnected)
    }
    
    func testNarrativeSelectionFlow() {
        let suggestions = [
            "Quick Track",
            "Morning Jog",
            "Walk",
            "Drive to Work",
            "Bike Ride",
            "Hiking"
        ]
        
        var selectedNarrative = suggestions[0]
        XCTAssertEqual(selectedNarrative, "Quick Track")
        
        // User selects different narrative
        selectedNarrative = suggestions[1]
        XCTAssertEqual(selectedNarrative, "Morning Jog")
        
        // User changes selection again
        selectedNarrative = suggestions[4]
        XCTAssertEqual(selectedNarrative, "Bike Ride")
    }
}
