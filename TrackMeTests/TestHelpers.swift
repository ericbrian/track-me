import XCTest
import Foundation
import CoreData
import CoreLocation
@testable import TrackMe

// MARK: - Core Data Test Helpers

/// Factory for creating in-memory Core Data stacks for testing
class CoreDataTestStack {
    
    /// Creates an in-memory Core Data stack for testing
    /// - Returns: NSPersistentContainer configured for in-memory storage
    static func createInMemoryStack() -> NSPersistentContainer {
        let container = NSPersistentContainer(name: "TrackMe")
        
        // Use in-memory store for testing
        let description = NSPersistentStoreDescription()
        description.type = NSInMemoryStoreType
        description.shouldAddStoreAsynchronously = false
        
        container.persistentStoreDescriptions = [description]
        
        container.loadPersistentStores { description, error in
            if let error = error {
                fatalError("Failed to load in-memory Core Data stack: \(error)")
            }
        }
        
        return container
    }
    
    /// Creates a test context from an in-memory stack
    /// - Returns: NSManagedObjectContext for testing
    static func createTestContext() -> NSManagedObjectContext {
        return createInMemoryStack().viewContext
    }
}

// MARK: - Mock Location Generator

/// Generates mock CLLocation objects for testing
struct MockLocationGenerator {
    
    /// Generates a mock location with default values
    /// - Parameters:
    ///   - latitude: Latitude in degrees (default: San Francisco)
    ///   - longitude: Longitude in degrees (default: San Francisco)
    ///   - altitude: Altitude in meters (default: 0)
    ///   - horizontalAccuracy: Horizontal accuracy in meters (default: 10)
    ///   - verticalAccuracy: Vertical accuracy in meters (default: 10)
    ///   - course: Course/heading in degrees (default: 0)
    ///   - speed: Speed in m/s (default: 0)
    ///   - timestamp: Timestamp (default: now)
    /// - Returns: CLLocation instance
    static func location(
        latitude: CLLocationDegrees = 37.7749,
        longitude: CLLocationDegrees = -122.4194,
        altitude: CLLocationDistance = 0,
        horizontalAccuracy: CLLocationAccuracy = 10,
        verticalAccuracy: CLLocationAccuracy = 10,
        course: CLLocationDirection = 0,
        speed: CLLocationSpeed = 0,
        timestamp: Date = Date()
    ) -> CLLocation {
        return CLLocation(
            coordinate: CLLocationCoordinate2D(latitude: latitude, longitude: longitude),
            altitude: altitude,
            horizontalAccuracy: horizontalAccuracy,
            verticalAccuracy: verticalAccuracy,
            course: course,
            speed: speed,
            timestamp: timestamp
        )
    }
    
    /// Generates a series of locations along a straight path
    /// - Parameters:
    ///   - startLatitude: Starting latitude
    ///   - startLongitude: Starting longitude
    ///   - count: Number of locations to generate
    ///   - latitudeIncrement: Amount to increment latitude for each point (default: 0.001)
    ///   - longitudeIncrement: Amount to increment longitude for each point (default: 0.001)
    ///   - timeInterval: Time between locations in seconds (default: 1.0)
    ///   - startTime: Starting timestamp (default: now)
    /// - Returns: Array of CLLocation instances
    static func path(
        startLatitude: CLLocationDegrees = 37.7749,
        startLongitude: CLLocationDegrees = -122.4194,
        count: Int = 10,
        latitudeIncrement: CLLocationDegrees = 0.001,
        longitudeIncrement: CLLocationDegrees = 0.001,
        timeInterval: TimeInterval = 1.0,
        startTime: Date = Date()
    ) -> [CLLocation] {
        var locations: [CLLocation] = []
        
        for i in 0..<count {
            let lat = startLatitude + (Double(i) * latitudeIncrement)
            let lon = startLongitude + (Double(i) * longitudeIncrement)
            let time = startTime.addingTimeInterval(Double(i) * timeInterval)
            
            locations.append(location(
                latitude: lat,
                longitude: lon,
                timestamp: time
            ))
        }
        
        return locations
    }
    
    /// Generates locations with varying accuracy (simulating GPS noise)
    /// - Parameters:
    ///   - centerLatitude: Center latitude
    ///   - centerLongitude: Center longitude
    ///   - count: Number of locations
    ///   - maxAccuracy: Maximum horizontal accuracy (default: 50m)
    ///   - timeInterval: Time between locations (default: 1.0s)
    /// - Returns: Array of CLLocation instances with varying accuracy
    static func noisyLocations(
        centerLatitude: CLLocationDegrees = 37.7749,
        centerLongitude: CLLocationDegrees = -122.4194,
        count: Int = 10,
        maxAccuracy: CLLocationAccuracy = 50,
        timeInterval: TimeInterval = 1.0
    ) -> [CLLocation] {
        var locations: [CLLocation] = []
        let startTime = Date()
        
        for i in 0..<count {
            // Add random offset (in degrees, ~0.0001 degree ≈ 11 meters)
            let latOffset = Double.random(in: -0.0005...0.0005)
            let lonOffset = Double.random(in: -0.0005...0.0005)
            let accuracy = Double.random(in: 5...maxAccuracy)
            
            locations.append(location(
                latitude: centerLatitude + latOffset,
                longitude: centerLongitude + lonOffset,
                horizontalAccuracy: accuracy,
                timestamp: startTime.addingTimeInterval(Double(i) * timeInterval)
            ))
        }
        
        return locations
    }
    
    /// Generates a location with poor GPS accuracy
    /// - Returns: CLLocation with high inaccuracy
    static func inaccurateLocation() -> CLLocation {
        return location(horizontalAccuracy: 100)
    }
    
    /// Generates a location with good GPS accuracy
    /// - Returns: CLLocation with low inaccuracy
    static func accurateLocation() -> CLLocation {
        return location(horizontalAccuracy: 5)
    }
}

// MARK: - Test Fixtures

/// Common test data fixtures
struct TestFixtures {
    
    /// Sample narrative strings for testing
    static let narratives = [
        "Morning commute to work",
        "Weekend hiking trip",
        "Evening run in the park",
        "Road trip to the coast",
        "Daily bike ride"
    ]
    
    /// Sample dates for testing
    static let sampleDate = Date(timeIntervalSince1970: 1699747200) // Nov 11, 2023, 12:00 PM UTC
    
    /// Creates a sample tracking session in the given context
    /// - Parameters:
    ///   - context: NSManagedObjectContext to create the session in
    ///   - narrative: Session narrative (default: "Test Session")
    ///   - isActive: Whether the session is active (default: true)
    ///   - startDate: Session start date (default: sample date)
    ///   - endDate: Optional session end date
    /// - Returns: TrackingSession instance
    static func createSession(
        in context: NSManagedObjectContext,
        narrative: String = "Test Session",
        isActive: Bool = true,
        startDate: Date = sampleDate,
        endDate: Date? = nil
    ) -> TrackingSession {
        let session = TrackingSession(context: context)
        session.id = UUID()
        session.narrative = narrative
        session.isActive = isActive
        session.startDate = startDate
        session.endDate = endDate
        
        return session
    }
    
    /// Creates a sample location entry for a session
    /// - Parameters:
    ///   - context: NSManagedObjectContext to create the entry in
    ///   - session: TrackingSession to associate with
    ///   - location: CLLocation to use (default: mock location)
    /// - Returns: LocationEntry instance
    static func createLocationEntry(
        in context: NSManagedObjectContext,
        for session: TrackingSession,
        location: CLLocation = MockLocationGenerator.location()
    ) -> LocationEntry {
        let entry = LocationEntry(context: context)
        entry.id = UUID()
        entry.latitude = location.coordinate.latitude
        entry.longitude = location.coordinate.longitude
        entry.altitude = location.altitude
        entry.accuracy = location.horizontalAccuracy
        entry.course = location.course
        entry.speed = location.speed
        entry.timestamp = location.timestamp
        entry.session = session
        
        return entry
    }
    
    /// Creates multiple location entries for a session
    /// - Parameters:
    ///   - count: Number of entries to create
    ///   - context: NSManagedObjectContext
    ///   - session: TrackingSession to associate with
    /// - Returns: Array of LocationEntry instances
    static func createLocationEntries(
        count: Int,
        in context: NSManagedObjectContext,
        for session: TrackingSession
    ) -> [LocationEntry] {
        let locations = MockLocationGenerator.path(count: count)
        return locations.map { location in
            createLocationEntry(in: context, for: session, location: location)
        }
    }
}

// MARK: - Test Assertions

/// Custom assertion helpers for testing
extension XCTestCase {
    
    /// Asserts that a CLLocation is approximately equal to expected values
    /// - Parameters:
    ///   - location: The location to check
    ///   - latitude: Expected latitude
    ///   - longitude: Expected longitude
    ///   - accuracy: Acceptable difference in degrees (default: 0.0001, ~11m)
    ///   - message: Custom failure message
    func assertLocationNear(
        _ location: CLLocation,
        latitude: CLLocationDegrees,
        longitude: CLLocationDegrees,
        accuracy: CLLocationDegrees = 0.0001,
        _ message: String = "Location not near expected coordinates",
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        XCTAssertEqual(location.coordinate.latitude, latitude, accuracy: accuracy,
                      "\(message) - latitude mismatch", file: file, line: line)
        XCTAssertEqual(location.coordinate.longitude, longitude, accuracy: accuracy,
                      "\(message) - longitude mismatch", file: file, line: line)
    }
    
    /// Asserts that a Core Data save operation succeeds
    /// - Parameters:
    ///   - context: Context to save
    ///   - message: Custom failure message
    func assertSaveSucceeds(
        _ context: NSManagedObjectContext,
        _ message: String = "Failed to save context",
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        XCTAssertNoThrow(try context.save(), message, file: file, line: line)
    }
    
    /// Asserts that a Core Data save operation throws an error
    /// - Parameters:
    ///   - context: Context to save
    ///   - message: Custom failure message
    func assertSaveFails(
        _ context: NSManagedObjectContext,
        _ message: String = "Expected save to fail",
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        XCTAssertThrowsError(try context.save(), message, file: file, line: line)
    }
}
