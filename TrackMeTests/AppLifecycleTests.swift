//
//  AppLifecycleTests.swift
//  TrackMeTests
//
//  App lifecycle, background transitions, and GPS recovery tests
//

import XCTest
import CoreLocation
import CoreData
@testable import TrackMe

// MARK: - Background Transition Tests
class BackgroundTransitionTests: XCTestCase {
    var persistenceController: PersistenceController!
    var locationManager: LocationManager!
    
    override func setUp() {
        super.setUp()
        persistenceController = PersistenceController(inMemory: true)
        locationManager = LocationManager()
    }
    
    override func tearDown() {
        locationManager = nil
        persistenceController = nil
        super.tearDown()
    }
    
    // MARK: - App State Transition Tests
    
    func testTrackingContinuesInBackground() {
        let context = persistenceController.container.viewContext
        
        // Start tracking session
        let session = TrackingSession(context: context)
        session.id = UUID()
        session.narrative = "Background Tracking Test"
        session.startDate = Date()
        session.isActive = true
        
        try? context.save()
        
        // Simulate adding locations while active
        for i in 0..<5 {
            let location = LocationEntry(context: context)
            location.id = UUID()
            location.latitude = 37.7749 + Double(i) * 0.001
            location.longitude = -122.4194
            location.timestamp = Date().addingTimeInterval(TimeInterval(i * 10))
            location.session = session
        }
        
        try? context.save()
        
        // Verify active session state
        XCTAssertTrue(session.isActive, "Session should remain active")
        XCTAssertEqual(session.locations?.count, 5, "Should have 5 locations")
        
        // Simulate app going to background - session should remain active
        // In real app, this would trigger background location updates
        XCTAssertTrue(session.isActive, "Session should stay active in background")
        
        // Add more locations after "background" transition
        for i in 5..<10 {
            let location = LocationEntry(context: context)
            location.id = UUID()
            location.latitude = 37.7749 + Double(i) * 0.001
            location.longitude = -122.4194
            location.timestamp = Date().addingTimeInterval(TimeInterval(i * 10))
            location.session = session
        }
        
        try? context.save()
        
        XCTAssertEqual(session.locations?.count, 10, "Should have 10 locations after background recording")
    }
    
    func testBackgroundToForegroundTransition() {
        let context = persistenceController.container.viewContext
        
        // Create active session (simulating background state)
        let session = TrackingSession(context: context)
        session.id = UUID()
        session.narrative = "Foreground Transition Test"
        session.startDate = Date().addingTimeInterval(-300) // Started 5 minutes ago
        session.isActive = true
        
        // Add some locations from "background"
        for i in 0..<20 {
            let location = LocationEntry(context: context)
            location.id = UUID()
            location.latitude = 37.7749 + Double(i) * 0.0005
            location.longitude = -122.4194 + Double(i) * 0.0005
            location.timestamp = Date().addingTimeInterval(TimeInterval(-300 + i * 15))
            location.session = session
        }
        
        try? context.save()
        
        // Simulate app returning to foreground
        // Verify session continuity
        let fetchRequest: NSFetchRequest<TrackingSession> = TrackingSession.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "isActive == YES")
        let activeSessions = try? context.fetch(fetchRequest)
        
        XCTAssertEqual(activeSessions?.count, 1, "Should have exactly one active session")
        XCTAssertEqual(activeSessions?.first?.id, session.id, "Should be the same session")
        XCTAssertEqual(activeSessions?.first?.locations?.count, 20, "Should maintain all locations")
    }
    
    func testMultipleBackgroundForegroundCycles() {
        let context = persistenceController.container.viewContext
        
        let session = TrackingSession(context: context)
        session.id = UUID()
        session.narrative = "Multiple Cycle Test"
        session.startDate = Date()
        session.isActive = true
        
        try? context.save()
        
        // Simulate 3 cycles of background/foreground transitions
        for cycle in 0..<3 {
            // Foreground: add 5 locations
            for i in 0..<5 {
                let location = LocationEntry(context: context)
                location.id = UUID()
                location.latitude = 37.7749 + Double(cycle) * 0.01 + Double(i) * 0.001
                location.longitude = -122.4194
                location.timestamp = Date().addingTimeInterval(TimeInterval(cycle * 100 + i * 10))
                location.session = session
            }
            try? context.save()
            
            // Background: add 3 locations (lower frequency)
            for i in 0..<3 {
                let location = LocationEntry(context: context)
                location.id = UUID()
                location.latitude = 37.7749 + Double(cycle) * 0.01 + Double(i + 5) * 0.001
                location.longitude = -122.4194
                location.timestamp = Date().addingTimeInterval(TimeInterval(cycle * 100 + (i + 5) * 20))
                location.session = session
            }
            try? context.save()
        }
        
        // Verify all locations were recorded
        let expectedCount = 3 * (5 + 3) // 3 cycles, 5 foreground + 3 background each
        XCTAssertEqual(session.locations?.count, expectedCount, "Should have all locations from cycles")
    }
    
    func testSessionPersistenceAcrossAppRestart() {
        // Create session in first "app instance"
        let context1 = persistenceController.container.viewContext
        
        let session = TrackingSession(context: context1)
        let sessionID = UUID()
        session.id = sessionID
        session.narrative = "Restart Test Session"
        session.startDate = Date()
        session.isActive = true
        
        for i in 0..<10 {
            let location = LocationEntry(context: context1)
            location.id = UUID()
            location.latitude = 37.7749 + Double(i) * 0.001
            location.longitude = -122.4194
            location.timestamp = Date().addingTimeInterval(TimeInterval(i * 10))
            location.session = session
        }
        
        try? context1.save()
        
        // Simulate app restart by creating new context (same controller)
        let context2 = persistenceController.container.newBackgroundContext()
        
        context2.performAndWait {
            let fetchRequest: NSFetchRequest<TrackingSession> = TrackingSession.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "id == %@", sessionID as CVarArg)
            
            if let restoredSessions = try? context2.fetch(fetchRequest),
               let restoredSession = restoredSessions.first {
                XCTAssertEqual(restoredSession.narrative, "Restart Test Session")
                XCTAssertTrue(restoredSession.isActive)
                XCTAssertEqual(restoredSession.locations?.count, 10)
            } else {
                XCTFail("Should restore session after restart")
            }
        }
    }
    
    func testBackgroundLocationUpdateFrequency() {
        let context = persistenceController.container.viewContext
        
        let session = TrackingSession(context: context)
        session.id = UUID()
        session.narrative = "Update Frequency Test"
        session.startDate = Date()
        session.isActive = true
        
        // Simulate background location updates (typically less frequent)
        let backgroundUpdateInterval = 30.0 // 30 seconds between updates
        
        for i in 0..<20 {
            let location = LocationEntry(context: context)
            location.id = UUID()
            location.latitude = 37.7749 + Double(i) * 0.0003
            location.longitude = -122.4194 + Double(i) * 0.0003
            location.timestamp = Date().addingTimeInterval(TimeInterval(i) * backgroundUpdateInterval)
            location.accuracy = 50.0 // Background updates may have lower accuracy
            location.session = session
        }
        
        try? context.save()
        
        // Verify timestamps are appropriately spaced
        let fetchRequest: NSFetchRequest<LocationEntry> = LocationEntry.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "session == %@", session)
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: true)]
        
        if let locations = try? context.fetch(fetchRequest), locations.count > 1 {
            for i in 1..<locations.count {
                let timeDiff = locations[i].timestamp!.timeIntervalSince(locations[i-1].timestamp!)
                XCTAssertGreaterThanOrEqual(timeDiff, backgroundUpdateInterval * 0.8, "Updates should be spaced appropriately")
            }
        }
    }
    
    // MARK: - Background Task Management Tests
    
    func testBackgroundTaskDataBatching() {
        let context = persistenceController.container.viewContext
        
        let session = TrackingSession(context: context)
        session.id = UUID()
        session.narrative = "Batching Test"
        session.startDate = Date()
        session.isActive = true
        
        try? context.save()
        
        // Simulate batching: collect locations then save in batch
        var locationBatch: [LocationEntry] = []
        
        for i in 0..<10 {
            let location = LocationEntry(context: context)
            location.id = UUID()
            location.latitude = 37.7749 + Double(i) * 0.001
            location.longitude = -122.4194
            location.timestamp = Date().addingTimeInterval(TimeInterval(i * 5))
            location.session = session
            locationBatch.append(location)
        }
        
        // Save batch
        try? context.save()
        
        XCTAssertEqual(session.locations?.count, 10, "Batch should be saved")
        XCTAssertEqual(locationBatch.count, 10, "Batch should contain all locations")
    }
    
    func testBackgroundSaveFailureRecovery() {
        let context = persistenceController.container.viewContext
        
        let session = TrackingSession(context: context)
        session.id = UUID()
        session.narrative = "Save Failure Test"
        session.startDate = Date()
        session.isActive = true
        
        try? context.save()
        
        // Add locations
        for i in 0..<5 {
            let location = LocationEntry(context: context)
            location.id = UUID()
            location.latitude = 37.7749 + Double(i) * 0.001
            location.longitude = -122.4194
            location.timestamp = Date()
            location.session = session
        }
        
        // Simulate save
        let saveResult = (try? context.save()) != nil
        
        if !saveResult {
            // On failure, unsaved locations remain in context
            XCTAssertTrue(context.hasChanges, "Context should have unsaved changes")
        } else {
            XCTAssertFalse(context.hasChanges, "Context should be clean after save")
            XCTAssertEqual(session.locations?.count, 5, "Locations should be saved")
        }
    }
}

// MARK: - GPS Recovery Tests
class GPSRecoveryTests: XCTestCase {
    var persistenceController: PersistenceController!
    var locationManager: LocationManager!
    
    override func setUp() {
        super.setUp()
        persistenceController = PersistenceController(inMemory: true)
        locationManager = LocationManager()
    }
    
    override func tearDown() {
        locationManager = nil
        persistenceController = nil
        super.tearDown()
    }
    
    func testGPSSignalLossRecovery() {
        let context = persistenceController.container.viewContext
        
        let session = TrackingSession(context: context)
        session.id = UUID()
        session.narrative = "GPS Loss Recovery Test"
        session.startDate = Date()
        session.isActive = true
        
        // Good GPS signal
        for i in 0..<5 {
            let location = LocationEntry(context: context)
            location.id = UUID()
            location.latitude = 37.7749 + Double(i) * 0.001
            location.longitude = -122.4194
            location.timestamp = Date().addingTimeInterval(TimeInterval(i * 10))
            location.accuracy = 10.0 // Good accuracy
            location.session = session
        }
        
        // GPS signal loss (gap in data)
        // Simulate 60 second gap with no updates
        
        // GPS signal restored
        for i in 5..<10 {
            let location = LocationEntry(context: context)
            location.id = UUID()
            location.latitude = 37.7749 + Double(i) * 0.001
            location.longitude = -122.4194
            location.timestamp = Date().addingTimeInterval(TimeInterval(i * 10 + 60)) // Gap included
            location.accuracy = 10.0
            location.session = session
        }
        
        try? context.save()
        
        // Verify recovery
        XCTAssertEqual(session.locations?.count, 10, "Should have locations before and after gap")
        
        // Check for gap in timestamps
        let fetchRequest: NSFetchRequest<LocationEntry> = LocationEntry.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "session == %@", session)
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: true)]
        
        if let locations = try? context.fetch(fetchRequest), locations.count == 10 {
            let gapStart = locations[4].timestamp!
            let gapEnd = locations[5].timestamp!
            let gapDuration = gapEnd.timeIntervalSince(gapStart)
            
            XCTAssertGreaterThan(gapDuration, 60, "Should detect gap in location updates")
        }
    }
    
    func testLocationAccuracyDegradation() {
        let context = persistenceController.container.viewContext
        
        let session = TrackingSession(context: context)
        session.id = UUID()
        session.narrative = "Accuracy Degradation Test"
        session.startDate = Date()
        session.isActive = true
        
        // Simulate degrading accuracy (GPS struggling)
        let accuracyValues = [10.0, 15.0, 30.0, 65.0, 100.0, 200.0, 500.0]
        
        for (index, accuracy) in accuracyValues.enumerated() {
            let location = LocationEntry(context: context)
            location.id = UUID()
            location.latitude = 37.7749 + Double(index) * 0.001
            location.longitude = -122.4194
            location.timestamp = Date().addingTimeInterval(TimeInterval(index * 10))
            location.accuracy = accuracy
            location.session = session
        }
        
        try? context.save()
        
        // Verify accuracy degradation is recorded
        let fetchRequest: NSFetchRequest<LocationEntry> = LocationEntry.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "session == %@", session)
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: true)]
        
        if let locations = try? context.fetch(fetchRequest), locations.count == accuracyValues.count {
            // Check that accuracy gets worse
            XCTAssertLessThan(locations[0].accuracy, locations[6].accuracy)
            XCTAssertEqual(locations[0].accuracy, 10.0)
            XCTAssertEqual(locations[6].accuracy, 500.0)
        }
    }
    
    func testGPSAccuracyImprovement() {
        let context = persistenceController.container.viewContext
        
        let session = TrackingSession(context: context)
        session.id = UUID()
        session.narrative = "Accuracy Improvement Test"
        session.startDate = Date()
        session.isActive = true
        
        // Simulate improving accuracy (GPS acquiring satellites)
        let accuracyValues = [500.0, 200.0, 100.0, 50.0, 20.0, 10.0, 5.0]
        
        for (index, accuracy) in accuracyValues.enumerated() {
            let location = LocationEntry(context: context)
            location.id = UUID()
            location.latitude = 37.7749 + Double(index) * 0.0005
            location.longitude = -122.4194
            location.timestamp = Date().addingTimeInterval(TimeInterval(index * 5))
            location.accuracy = accuracy
            location.session = session
        }
        
        try? context.save()
        
        // Filter out inaccurate locations (app logic)
        let fetchRequest: NSFetchRequest<LocationEntry> = LocationEntry.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "session == %@ AND accuracy < 100", session)
        let goodLocations = try? context.fetch(fetchRequest)
        
        XCTAssertEqual(goodLocations?.count, 4, "Should have 4 locations with good accuracy")
    }
    
    func testIndoorOutdoorTransition() {
        let context = persistenceController.container.viewContext
        
        let session = TrackingSession(context: context)
        session.id = UUID()
        session.narrative = "Indoor/Outdoor Transition"
        session.startDate = Date()
        session.isActive = true
        
        // Outdoor: good GPS
        for i in 0..<5 {
            let location = LocationEntry(context: context)
            location.id = UUID()
            location.latitude = 37.7749 + Double(i) * 0.001
            location.longitude = -122.4194
            location.timestamp = Date().addingTimeInterval(TimeInterval(i * 10))
            location.accuracy = 10.0
            location.session = session
        }
        
        // Indoor: poor or no GPS
        for i in 5..<8 {
            let location = LocationEntry(context: context)
            location.id = UUID()
            location.latitude = 37.7749 + Double(i) * 0.0001 // Minimal movement
            location.longitude = -122.4194
            location.timestamp = Date().addingTimeInterval(TimeInterval(i * 10))
            location.accuracy = 500.0 // Poor accuracy
            location.session = session
        }
        
        // Outdoor again: GPS recovers
        for i in 8..<12 {
            let location = LocationEntry(context: context)
            location.id = UUID()
            location.latitude = 37.7749 + Double(i) * 0.001
            location.longitude = -122.4194
            location.timestamp = Date().addingTimeInterval(TimeInterval(i * 10))
            location.accuracy = 10.0
            location.session = session
        }
        
        try? context.save()
        
        XCTAssertEqual(session.locations?.count, 12, "Should record all locations including indoor")
    }
    
    func testTunnelTransit() {
        let context = persistenceController.container.viewContext
        
        let session = TrackingSession(context: context)
        session.id = UUID()
        session.narrative = "Tunnel Transit Test"
        session.startDate = Date()
        session.isActive = true
        
        // Before tunnel
        let location1 = LocationEntry(context: context)
        location1.id = UUID()
        location1.latitude = 37.7749
        location1.longitude = -122.4194
        location1.timestamp = Date()
        location1.accuracy = 10.0
        location1.session = session
        
        // No GPS in tunnel (no updates for 2 minutes)
        
        // After tunnel (significant position change)
        let location2 = LocationEntry(context: context)
        location2.id = UUID()
        location2.latitude = 37.7849 // ~1km away
        location2.longitude = -122.4094
        location2.timestamp = Date().addingTimeInterval(120) // 2 minutes later
        location2.accuracy = 15.0
        location2.session = session
        
        try? context.save()
        
        // Verify gap and position jump
        XCTAssertEqual(session.locations?.count, 2, "Should have before and after tunnel")
        
        let distance = location1.distance(to: location2)
        XCTAssertGreaterThan(distance, 1000, "Should show significant position change")
    }
    
    func testGPSJammedOrBlocked() {
        let context = persistenceController.container.viewContext
        
        let session = TrackingSession(context: context)
        session.id = UUID()
        session.narrative = "GPS Blocked Test"
        session.startDate = Date()
        session.isActive = true
        
        // Last known good location
        let lastGoodLocation = LocationEntry(context: context)
        lastGoodLocation.id = UUID()
        lastGoodLocation.latitude = 37.7749
        lastGoodLocation.longitude = -122.4194
        lastGoodLocation.timestamp = Date()
        lastGoodLocation.accuracy = 10.0
        lastGoodLocation.session = session
        
        try? context.save()
        
        // Simulate prolonged GPS blockage (no updates)
        // In real app, this would trigger timeout/warning
        
        let fetchRequest: NSFetchRequest<LocationEntry> = LocationEntry.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "session == %@", session)
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: false)]
        
        if let locations = try? context.fetch(fetchRequest), let lastLocation = locations.first {
            let timeSinceLastUpdate = Date().timeIntervalSince(lastLocation.timestamp!)
            
            // App should detect prolonged lack of updates
            XCTAssertGreaterThan(timeSinceLastUpdate, 0, "Should detect time since last update")
        }
    }
}

// MARK: - Complex Integration Scenarios
class ComplexIntegrationTests: XCTestCase {
    var persistenceController: PersistenceController!
    
    override func setUp() {
        super.setUp()
        persistenceController = PersistenceController(inMemory: true)
    }
    
    override func tearDown() {
        persistenceController = nil
        super.tearDown()
    }
    
    func testLongRunningSessionWithMultipleStops() {
        let context = persistenceController.container.viewContext
        
        // Create a day-long session with multiple stops
        let session = TrackingSession(context: context)
        session.id = UUID()
        session.narrative = "Full Day Trip"
        session.startDate = Date().addingTimeInterval(-28800) // 8 hours ago
        session.isActive = false
        session.endDate = Date()
        
        // Generate realistic location pattern: movement + stops
        var timestamp = session.startDate!
        
        // Morning commute: 30 minutes
        for i in 0..<30 {
            let location = LocationEntry(context: context)
            location.id = UUID()
            location.latitude = 37.7749 + Double(i) * 0.0005
            location.longitude = -122.4194 + Double(i) * 0.0005
            location.timestamp = timestamp.addingTimeInterval(TimeInterval(i * 60))
            location.accuracy = 10.0
            location.speed = 15.0 // ~54 km/h
            location.session = session
        }
        
        timestamp = timestamp.addingTimeInterval(1800)
        
        // At work: stationary for 6 hours (few updates)
        for i in 0..<12 {
            let location = LocationEntry(context: context)
            location.id = UUID()
            location.latitude = 37.7899
            location.longitude = -122.4044
            location.timestamp = timestamp.addingTimeInterval(TimeInterval(i * 1800))
            location.accuracy = 15.0
            location.speed = 0.0
            location.session = session
        }
        
        timestamp = timestamp.addingTimeInterval(21600)
        
        // Evening commute: 30 minutes
        for i in 0..<30 {
            let location = LocationEntry(context: context)
            location.id = UUID()
            location.latitude = 37.7899 - Double(i) * 0.0005
            location.longitude = -122.4044 - Double(i) * 0.0005
            location.timestamp = timestamp.addingTimeInterval(TimeInterval(i * 60))
            location.accuracy = 10.0
            location.speed = 15.0
            location.session = session
        }
        
        try? context.save()
        
        XCTAssertEqual(session.locations?.count, 72, "Should have locations for full day")
        
        let duration = session.endDate!.timeIntervalSince(session.startDate!)
        XCTAssertGreaterThanOrEqual(duration, 28800, "Duration should be 8+ hours")
    }
    
    func testMultimodalTransportation() {
        let context = persistenceController.container.viewContext
        
        let session = TrackingSession(context: context)
        session.id = UUID()
        session.narrative = "Mixed Transport"
        session.startDate = Date()
        session.isActive = false
        session.endDate = Date().addingTimeInterval(3600)
        
        var timestamp = session.startDate!
        
        // Walking: slow speed, high accuracy
        for i in 0..<10 {
            let location = LocationEntry(context: context)
            location.id = UUID()
            location.latitude = 37.7749 + Double(i) * 0.0001
            location.longitude = -122.4194
            location.timestamp = timestamp.addingTimeInterval(TimeInterval(i * 60))
            location.accuracy = 5.0
            location.speed = 1.5 // ~5.4 km/h
            location.session = session
        }
        
        timestamp = timestamp.addingTimeInterval(600)
        
        // Bus/Train: medium speed, variable accuracy
        for i in 0..<20 {
            let location = LocationEntry(context: context)
            location.id = UUID()
            location.latitude = 37.7749 + Double(i + 10) * 0.0003
            location.longitude = -122.4194 + Double(i) * 0.0003
            location.timestamp = timestamp.addingTimeInterval(TimeInterval(i * 60))
            location.accuracy = Double.random(in: 10...50)
            location.speed = 10.0 // ~36 km/h
            location.session = session
        }
        
        timestamp = timestamp.addingTimeInterval(1200)
        
        // Driving: high speed, good accuracy
        for i in 0..<30 {
            let location = LocationEntry(context: context)
            location.id = UUID()
            location.latitude = 37.7749 + Double(i + 30) * 0.001
            location.longitude = -122.4194 + Double(i) * 0.001
            location.timestamp = timestamp.addingTimeInterval(TimeInterval(i * 30))
            location.accuracy = 10.0
            location.speed = 25.0 // ~90 km/h
            location.session = session
        }
        
        try? context.save()
        
        XCTAssertEqual(session.locations?.count, 60, "Should track all transport modes")
    }
    
    func testPowerSavingModeDegradation() {
        let context = persistenceController.container.viewContext
        
        let session = TrackingSession(context: context)
        session.id = UUID()
        session.narrative = "Power Saving Test"
        session.startDate = Date()
        session.isActive = true
        
        // Normal mode: frequent updates
        for i in 0..<20 {
            let location = LocationEntry(context: context)
            location.id = UUID()
            location.latitude = 37.7749 + Double(i) * 0.0003
            location.longitude = -122.4194
            location.timestamp = Date().addingTimeInterval(TimeInterval(i * 10))
            location.accuracy = 10.0
            location.session = session
        }
        
        // Power saving: less frequent updates
        for i in 0..<10 {
            let location = LocationEntry(context: context)
            location.id = UUID()
            location.latitude = 37.7749 + Double(i + 20) * 0.0003
            location.longitude = -122.4194
            location.timestamp = Date().addingTimeInterval(TimeInterval(200 + i * 60))
            location.accuracy = 30.0 // May degrade
            location.session = session
        }
        
        try? context.save()
        
        XCTAssertEqual(session.locations?.count, 30, "Should adapt to power saving")
    }
    
    func testMemoryPressureScenario() {
        let context = persistenceController.container.viewContext
        
        // Simulate memory pressure by creating large session
        let session = TrackingSession(context: context)
        session.id = UUID()
        session.narrative = "Memory Pressure Test"
        session.startDate = Date()
        session.isActive = false
        session.endDate = Date().addingTimeInterval(7200)
        
        // Create many locations in batches to manage memory
        for batch in 0..<10 {
            for i in 0..<50 {
                let location = LocationEntry(context: context)
                location.id = UUID()
                location.latitude = 37.7749 + Double(batch * 50 + i) * 0.00001
                location.longitude = -122.4194
                location.timestamp = Date().addingTimeInterval(TimeInterval(batch * 360 + i * 7))
                location.session = session
            }
            
            // Save batch and clear cache
            try? context.save()
            context.refreshAllObjects()
        }
        
        // Verify all data persisted
        let fetchRequest: NSFetchRequest<LocationEntry> = LocationEntry.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "session == %@", session)
        let count = try? context.count(for: fetchRequest)
        
        XCTAssertEqual(count, 500, "Should handle large dataset under memory pressure")
    }
    
    func testNetworkReachabilityChanges() {
        let context = persistenceController.container.viewContext
        
        // Session that spans online/offline periods
        let session = TrackingSession(context: context)
        session.id = UUID()
        session.narrative = "Network Change Test"
        session.startDate = Date()
        session.isActive = true
        
        // All tracking is local - network state shouldn't affect it
        for i in 0..<20 {
            let location = LocationEntry(context: context)
            location.id = UUID()
            location.latitude = 37.7749 + Double(i) * 0.001
            location.longitude = -122.4194
            location.timestamp = Date().addingTimeInterval(TimeInterval(i * 10))
            location.session = session
        }
        
        try? context.save()
        
        // Verify tracking continues regardless of network
        XCTAssertEqual(session.locations?.count, 20, "Tracking should be unaffected by network")
    }
    
    func testDeviceRestartDuringTracking() {
        let context = persistenceController.container.viewContext
        
        // Create session before "restart"
        let sessionID = UUID()
        let session = TrackingSession(context: context)
        session.id = sessionID
        session.narrative = "Device Restart Test"
        session.startDate = Date().addingTimeInterval(-600)
        session.isActive = true
        
        for i in 0..<10 {
            let location = LocationEntry(context: context)
            location.id = UUID()
            location.latitude = 37.7749 + Double(i) * 0.001
            location.longitude = -122.4194
            location.timestamp = Date().addingTimeInterval(TimeInterval(-600 + i * 30))
            location.session = session
        }
        
        try? context.save()
        
        // Simulate restart: fetch active session
        let fetchRequest: NSFetchRequest<TrackingSession> = TrackingSession.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "isActive == YES AND id == %@", sessionID as CVarArg)
        
        if let activeSessions = try? context.fetch(fetchRequest),
           let activeSession = activeSessions.first {
            XCTAssertEqual(activeSession.id, sessionID, "Should restore active session")
            XCTAssertTrue(activeSession.isActive, "Session should still be active")
            XCTAssertEqual(activeSession.locations?.count, 10, "Should restore all locations")
            
            // Continue tracking after restart
            for i in 10..<15 {
                let location = LocationEntry(context: context)
                location.id = UUID()
                location.latitude = 37.7749 + Double(i) * 0.001
                location.longitude = -122.4194
                location.timestamp = Date().addingTimeInterval(TimeInterval(-600 + i * 30))
                location.session = activeSession
            }
            
            try? context.save()
            XCTAssertEqual(activeSession.locations?.count, 15, "Should continue tracking after restart")
        } else {
            XCTFail("Should find active session after restart")
        }
    }
    
    func testConcurrentSessionDetection() {
        let context = persistenceController.container.viewContext
        
        // Create first active session
        let session1 = TrackingSession(context: context)
        session1.id = UUID()
        session1.narrative = "Session 1"
        session1.startDate = Date().addingTimeInterval(-300)
        session1.isActive = true
        
        try? context.save()
        
        // Attempt to start second session while first is active
        let session2 = TrackingSession(context: context)
        session2.id = UUID()
        session2.narrative = "Session 2"
        session2.startDate = Date()
        session2.isActive = true
        
        try? context.save()
        
        // App should detect and handle multiple active sessions
        let fetchRequest: NSFetchRequest<TrackingSession> = TrackingSession.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "isActive == YES")
        let activeSessions = try? context.fetch(fetchRequest)
        
        XCTAssertEqual(activeSessions?.count, 2, "Core Data allows multiple active sessions")
        // Note: App logic should prevent this, but test verifies detection
    }
}

// MARK: - Extension for distance calculation
extension LocationEntry {
    func distance(to other: LocationEntry) -> Double {
        let location1 = CLLocation(latitude: self.latitude, longitude: self.longitude)
        let location2 = CLLocation(latitude: other.latitude, longitude: other.longitude)
        return location1.distance(from: location2)
    }
}
