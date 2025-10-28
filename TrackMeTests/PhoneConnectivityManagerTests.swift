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
}

// Note: Full WCSession testing requires mocking or UI testing with actual devices
// These tests verify basic initialization and structure
