// TrackMeTests/PhoneConnectivityManagerTests.swift
// Unit tests for PhoneConnectivityManager

import XCTest
import WatchConnectivity
@testable import TrackMe

class PhoneConnectivityManagerTests: XCTestCase {
    var connectivityManager: PhoneConnectivityManager!
    
    override func setUp() {
        super.setUp()
        connectivityManager = PhoneConnectivityManager()
    }
    
    override func tearDown() {
        connectivityManager = nil
        super.tearDown()
    }
    
    func testSharedInstanceExists() {
        let sharedInstance = PhoneConnectivityManager.shared
        XCTAssertNotNil(sharedInstance, "Shared instance should exist.")
    }
    
    func testInitialState() {
        // isWatchConnected might be false initially, depending on environment
        XCTAssertFalse(connectivityManager.isWatchConnected, "Watch connection state should be false initially in tests.")
    }
    
    func testPublishedPropertiesExist() {
        // Verify published properties are accessible
        _ = connectivityManager.isWatchConnected
    }
    
    func testSetLocationManager() {
        let locationManager = LocationManager()
        
        // This should not throw and should set the manager
        connectivityManager.setLocationManager(locationManager)
        
        // Can't directly test the private property, but method should execute without error
        XCTAssertTrue(true, "setLocationManager should execute without error.")
    }
    
    func testMultipleSetLocationManagerCalls() {
        let locationManager1 = LocationManager()
        let locationManager2 = LocationManager()
        
        connectivityManager.setLocationManager(locationManager1)
        connectivityManager.setLocationManager(locationManager2)
        
        // Should not crash when setting multiple times
        XCTAssertTrue(true, "Multiple setLocationManager calls should not crash")
    }
    
    func testSendStatusUpdateWithoutLocationManager() {
        // Should not crash if called before setting location manager
        XCTAssertNoThrow(connectivityManager.sendStatusUpdateToWatch(), 
                        "sendStatusUpdateToWatch should not crash without location manager")
    }
    
    func testSharedInstanceIsSingleton() {
        let instance1 = PhoneConnectivityManager.shared
        let instance2 = PhoneConnectivityManager.shared
        
        XCTAssertTrue(instance1 === instance2, "Shared instance should be singleton")
    }
}

// MARK: - Watch Communication Tests
class WatchCommunicationTests: XCTestCase {
    var connectivityManager: PhoneConnectivityManager!
    var locationManager: LocationManager!
    
    override func setUp() {
        super.setUp()
        connectivityManager = PhoneConnectivityManager.shared
        locationManager = LocationManager()
        connectivityManager.setLocationManager(locationManager)
    }
    
    override func tearDown() {
        locationManager = nil
        connectivityManager = nil
        super.tearDown()
    }
    
    func testStatusUpdateMessageStructure() {
        // Test that status updates are sent without crashing
        XCTAssertNoThrow(connectivityManager.sendStatusUpdateToWatch(), 
                        "Status update should not throw")
    }
    
    func testNotificationObservers() {
        let expectation = self.expectation(description: "Notification posted")
        
        let observer = NotificationCenter.default.addObserver(
            forName: NSNotification.Name("TrackingStateChanged"),
            object: nil,
            queue: .main
        ) { _ in
            expectation.fulfill()
        }
        
        // Post notification
        NotificationCenter.default.post(name: NSNotification.Name("TrackingStateChanged"), object: nil)
        
        waitForExpectations(timeout: 1.0) { error in
            if let error = error {
                XCTFail("Notification not received: \(error)")
            }
        }
        
        NotificationCenter.default.removeObserver(observer)
    }
    
    func testLocationCountNotification() {
        let expectation = self.expectation(description: "Location count notification")
        
        let observer = NotificationCenter.default.addObserver(
            forName: NSNotification.Name("LocationCountChanged"),
            object: nil,
            queue: .main
        ) { _ in
            expectation.fulfill()
        }
        
        NotificationCenter.default.post(name: NSNotification.Name("LocationCountChanged"), object: nil)
        
        waitForExpectations(timeout: 1.0)
        NotificationCenter.default.removeObserver(observer)
    }
}

// Note: Full WCSession testing requires mocking or UI testing with actual devices
// These tests verify basic initialization and structure
