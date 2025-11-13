import XCTest
import CoreData
import CoreLocation
@testable import TrackMe

/// Unit tests for CoreDataLocationRepository
/// Tests all CRUD operations, sorting, batch fetching, and data integrity with real Core Data
final class CoreDataLocationRepositoryTests: XCTestCase {
    
    var repository: CoreDataLocationRepository!
    var sessionRepository: CoreDataSessionRepository!
    var testContext: NSManagedObjectContext!
    var testContainer: NSPersistentContainer!
    
    override func setUp() {
        super.setUp()
        
        // Setup Core Data stack
        let bundle = Bundle(for: TrackingSession.self)
        guard let modelURL = bundle.url(forResource: "TrackMe", withExtension: "momd"),
              let model = NSManagedObjectModel(contentsOf: modelURL) else {
            fatalError("Could not load Core Data model")
        }
        
        testContainer = NSPersistentContainer(name: "TrackMe", managedObjectModel: model)
        let description = NSPersistentStoreDescription()
        description.type = NSInMemoryStoreType
        description.shouldAddStoreAsynchronously = false
        testContainer.persistentStoreDescriptions = [description]
        
        var loadError: Error?
        testContainer.loadPersistentStores { _, error in
            loadError = error
        }
        
        if let loadError = loadError {
            fatalError("Failed to load stores: \(loadError)")
        }
        
        testContext = testContainer.viewContext
        repository = CoreDataLocationRepository(context: testContext)
        sessionRepository = CoreDataSessionRepository(context: testContext)
    }
    
    override func tearDown() {
        repository = nil
        sessionRepository = nil
        testContext = nil
        testContainer = nil
        super.tearDown()
    }
    
    // MARK: - Save Location Tests
    
    func testSaveLocation() throws {
        // Given
        let session = try createTestSession()
        let location = createLocation(latitude: 37.7749, longitude: -122.4194)
        
        // When
        let entry = try repository.saveLocation(location, for: session)
        
        // Then
        XCTAssertNotNil(entry.id)
        XCTAssertEqual(entry.latitude, 37.7749, accuracy: 0.0001)
        XCTAssertEqual(entry.longitude, -122.4194, accuracy: 0.0001)
        XCTAssertEqual(entry.timestamp, location.timestamp)
        XCTAssertEqual(entry.accuracy, location.horizontalAccuracy)
        XCTAssertEqual(entry.altitude, location.altitude)
        XCTAssertEqual(entry.speed, location.speed)
        XCTAssertEqual(entry.course, location.course)
        XCTAssertEqual(entry.session, session)
    }
    
    func testSaveLocationPersistsToDatabase() throws {
        // Given
        let session = try createTestSession()
        let location = createLocation(latitude: 40.7128, longitude: -74.0060)
        
        // When
        let entry = try repository.saveLocation(location, for: session)
        let entryId = entry.id
        
        // Then - Verify it's persisted
        let locations = try repository.fetchLocations(for: session)
        XCTAssertEqual(locations.count, 1)
        XCTAssertEqual(locations.first?.id, entryId)
    }
    
    func testSaveLocationHandlesNegativeSpeed() throws {
        // Given
        let session = try createTestSession()
        let location = createLocation(speed: -1.0)
        
        // When
        let entry = try repository.saveLocation(location, for: session)
        
        // Then - Negative speed should be stored as 0
        XCTAssertEqual(entry.speed, 0.0)
    }
    
    func testSaveLocationHandlesNegativeCourse() throws {
        // Given
        let session = try createTestSession()
        let location = createLocation(course: -1.0)
        
        // When
        let entry = try repository.saveLocation(location, for: session)
        
        // Then - Negative course should be stored as 0
        XCTAssertEqual(entry.course, 0.0)
    }
    
    func testSaveMultipleLocationsForSession() throws {
        // Given
        let session = try createTestSession()
        let locations = [
            createLocation(latitude: 37.7749, longitude: -122.4194),
            createLocation(latitude: 37.7750, longitude: -122.4195),
            createLocation(latitude: 37.7751, longitude: -122.4196)
        ]
        
        // When
        for location in locations {
            _ = try repository.saveLocation(location, for: session)
        }
        
        // Then
        let savedLocations = try repository.fetchLocations(for: session)
        XCTAssertEqual(savedLocations.count, 3)
    }
    
    func testSaveLocationForDifferentSessions() throws {
        // Given
        let session1 = try createTestSession(narrative: "Session 1")
        let session2 = try createTestSession(narrative: "Session 2")
        let location1 = createLocation(latitude: 37.7749, longitude: -122.4194)
        let location2 = createLocation(latitude: 40.7128, longitude: -74.0060)
        
        // When
        _ = try repository.saveLocation(location1, for: session1)
        _ = try repository.saveLocation(location2, for: session2)
        
        // Then
        let session1Locations = try repository.fetchLocations(for: session1)
        let session2Locations = try repository.fetchLocations(for: session2)
        XCTAssertEqual(session1Locations.count, 1)
        XCTAssertEqual(session2Locations.count, 1)
        XCTAssertNotEqual(session1Locations.first?.session, session2Locations.first?.session)
    }
    
    // MARK: - Fetch Locations Tests
    
    func testFetchLocationsWhenEmpty() throws {
        // Given
        let session = try createTestSession()
        
        // When
        let locations = try repository.fetchLocations(for: session)
        
        // Then
        XCTAssertTrue(locations.isEmpty)
    }
    
    func testFetchLocationsSortedByTimestamp() throws {
        // Given
        let session = try createTestSession()
        let timestamps = [
            Date(timeIntervalSince1970: 1000),
            Date(timeIntervalSince1970: 3000),
            Date(timeIntervalSince1970: 2000)
        ]
        
        for timestamp in timestamps {
            let location = createLocation(timestamp: timestamp)
            _ = try repository.saveLocation(location, for: session)
        }
        
        // When
        let locations = try repository.fetchLocations(for: session)
        
        // Then - Should be sorted ascending by timestamp
        XCTAssertEqual(locations.count, 3)
        XCTAssertEqual(locations[0].timestamp?.timeIntervalSince1970, 1000)
        XCTAssertEqual(locations[1].timestamp?.timeIntervalSince1970, 2000)
        XCTAssertEqual(locations[2].timestamp?.timeIntervalSince1970, 3000)
    }
    
    func testFetchLocationsWithCustomSortDescriptors() throws {
        // Given
        let session = try createTestSession()
        let locations = [
            createLocation(latitude: 37.7749, timestamp: Date(timeIntervalSince1970: 1000)),
            createLocation(latitude: 40.7128, timestamp: Date(timeIntervalSince1970: 2000)),
            createLocation(latitude: 51.5074, timestamp: Date(timeIntervalSince1970: 3000))
        ]
        
        for location in locations {
            _ = try repository.saveLocation(location, for: session)
        }
        
        // When - Sort descending by timestamp
        let sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: false)]
        let fetchedLocations = try repository.fetchLocations(
            for: session,
            sortDescriptors: sortDescriptors,
            batchSize: nil
        )
        
        // Then
        XCTAssertEqual(fetchedLocations.count, 3)
        XCTAssertEqual(fetchedLocations[0].timestamp?.timeIntervalSince1970, 3000)
        XCTAssertEqual(fetchedLocations[1].timestamp?.timeIntervalSince1970, 2000)
        XCTAssertEqual(fetchedLocations[2].timestamp?.timeIntervalSince1970, 1000)
    }
    
    func testFetchLocationsWithBatchSize() throws {
        // Given
        let session = try createTestSession()
        
        // Create 100 locations
        for i in 0..<100 {
            let location = createLocation(timestamp: Date(timeIntervalSince1970: Double(i)))
            _ = try repository.saveLocation(location, for: session)
        }
        
        // When
        let locations = try repository.fetchLocations(
            for: session,
            sortDescriptors: [NSSortDescriptor(key: "timestamp", ascending: true)],
            batchSize: 20
        )
        
        // Then
        XCTAssertEqual(locations.count, 100)
        // Batch size is a performance hint, all results should still be returned
    }
    
    func testFetchLocationsOnlyReturnsLocationsForSpecifiedSession() throws {
        // Given
        let session1 = try createTestSession(narrative: "Session 1")
        let session2 = try createTestSession(narrative: "Session 2")
        
        _ = try repository.saveLocation(createLocation(latitude: 37.7749), for: session1)
        _ = try repository.saveLocation(createLocation(latitude: 40.7128), for: session1)
        _ = try repository.saveLocation(createLocation(latitude: 51.5074), for: session2)
        
        // When
        let session1Locations = try repository.fetchLocations(for: session1)
        let session2Locations = try repository.fetchLocations(for: session2)
        
        // Then
        XCTAssertEqual(session1Locations.count, 2)
        XCTAssertEqual(session2Locations.count, 1)
    }
    
    // MARK: - Delete Locations Tests
    
    func testDeleteLocationsForSession() throws {
        // Given
        let session = try createTestSession()
        
        for i in 0..<5 {
            let location = createLocation(latitude: 37.7749 + Double(i) * 0.001)
            _ = try repository.saveLocation(location, for: session)
        }
        
        XCTAssertEqual(try repository.locationCount(for: session), 5)
        
        // When
        try repository.deleteLocations(for: session)
        
        // Then
        let locations = try repository.fetchLocations(for: session)
        XCTAssertTrue(locations.isEmpty)
        XCTAssertEqual(try repository.locationCount(for: session), 0)
    }
    
    func testDeleteLocationsDoesNotAffectOtherSessions() throws {
        // Given
        let session1 = try createTestSession(narrative: "Session 1")
        let session2 = try createTestSession(narrative: "Session 2")
        
        _ = try repository.saveLocation(createLocation(latitude: 37.7749), for: session1)
        _ = try repository.saveLocation(createLocation(latitude: 40.7128), for: session1)
        _ = try repository.saveLocation(createLocation(latitude: 51.5074), for: session2)
        
        // When
        try repository.deleteLocations(for: session1)
        
        // Then
        XCTAssertTrue(try repository.fetchLocations(for: session1).isEmpty)
        XCTAssertEqual(try repository.fetchLocations(for: session2).count, 1)
    }
    
    func testDeleteLocationsWhenSessionHasNoLocations() throws {
        // Given
        let session = try createTestSession()
        
        // When/Then - Should not throw
        XCTAssertNoThrow(try repository.deleteLocations(for: session))
    }
    
    // MARK: - Location Count Tests
    
    func testLocationCountWhenEmpty() throws {
        // Given
        let session = try createTestSession()
        
        // When
        let count = try repository.locationCount(for: session)
        
        // Then
        XCTAssertEqual(count, 0)
    }
    
    func testLocationCountWithMultipleLocations() throws {
        // Given
        let session = try createTestSession()
        
        for i in 0..<10 {
            let location = createLocation(latitude: 37.7749 + Double(i) * 0.001)
            _ = try repository.saveLocation(location, for: session)
        }
        
        // When
        let count = try repository.locationCount(for: session)
        
        // Then
        XCTAssertEqual(count, 10)
    }
    
    func testLocationCountOnlyCountsLocationsForSpecifiedSession() throws {
        // Given
        let session1 = try createTestSession(narrative: "Session 1")
        let session2 = try createTestSession(narrative: "Session 2")
        
        for i in 0..<5 {
            _ = try repository.saveLocation(createLocation(latitude: 37.7749 + Double(i) * 0.001), for: session1)
        }
        
        for i in 0..<3 {
            _ = try repository.saveLocation(createLocation(latitude: 40.7128 + Double(i) * 0.001), for: session2)
        }
        
        // When
        let count1 = try repository.locationCount(for: session1)
        let count2 = try repository.locationCount(for: session2)
        
        // Then
        XCTAssertEqual(count1, 5)
        XCTAssertEqual(count2, 3)
    }
    
    func testLocationCountAfterDeletion() throws {
        // Given
        let session = try createTestSession()
        
        for i in 0..<5 {
            _ = try repository.saveLocation(createLocation(), for: session)
        }
        
        XCTAssertEqual(try repository.locationCount(for: session), 5)
        
        // When
        try repository.deleteLocations(for: session)
        
        // Then
        XCTAssertEqual(try repository.locationCount(for: session), 0)
    }
    
    // MARK: - Data Integrity Tests
    
    func testLocationPreservesAllCLLocationProperties() throws {
        // Given
        let session = try createTestSession()
        let originalLocation = CLLocation(
            coordinate: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
            altitude: 100.5,
            horizontalAccuracy: 10.0,
            verticalAccuracy: 15.0,
            course: 90.0,
            speed: 5.5,
            timestamp: Date(timeIntervalSince1970: 1000)
        )
        
        // When
        let entry = try repository.saveLocation(originalLocation, for: session)
        
        // Then
        XCTAssertEqual(entry.latitude, originalLocation.coordinate.latitude, accuracy: 0.00001)
        XCTAssertEqual(entry.longitude, originalLocation.coordinate.longitude, accuracy: 0.00001)
        XCTAssertEqual(entry.altitude, originalLocation.altitude, accuracy: 0.01)
        XCTAssertEqual(entry.accuracy, originalLocation.horizontalAccuracy, accuracy: 0.01)
        XCTAssertEqual(entry.course, originalLocation.course, accuracy: 0.01)
        XCTAssertEqual(entry.speed, originalLocation.speed, accuracy: 0.01)
        XCTAssertEqual(entry.timestamp, originalLocation.timestamp)
    }
    
    func testLocationMaintainsRelationshipWithSession() throws {
        // Given
        let session = try createTestSession()
        let location = createLocation()
        
        // When
        let entry = try repository.saveLocation(location, for: session)
        
        // Then
        XCTAssertEqual(entry.session, session)
        XCTAssertTrue(session.locations?.contains(entry) ?? false)
    }
    
    func testFetchLocationsReturnsCorrectDataTypes() throws {
        // Given
        let session = try createTestSession()
        _ = try repository.saveLocation(createLocation(), for: session)
        
        // When
        let locations = try repository.fetchLocations(for: session)
        
        // Then
        XCTAssertFalse(locations.isEmpty)
        let location = locations.first!
        XCTAssertNotNil(location.id)
        XCTAssertNotNil(location.timestamp)
        XCTAssertTrue(location.latitude >= -90 && location.latitude <= 90)
        XCTAssertTrue(location.longitude >= -180 && location.longitude <= 180)
    }
    
    // MARK: - Edge Cases Tests
    
    func testSaveLocationWithExtremeCoordinates() throws {
        // Given
        let session = try createTestSession()
        let extremeLocations = [
            createLocation(latitude: 90.0, longitude: 180.0),    // North Pole, Date Line
            createLocation(latitude: -90.0, longitude: -180.0),  // South Pole, Date Line
            createLocation(latitude: 0.0, longitude: 0.0)        // Null Island
        ]
        
        // When/Then
        for location in extremeLocations {
            XCTAssertNoThrow(try repository.saveLocation(location, for: session))
        }
        
        let savedLocations = try repository.fetchLocations(for: session)
        XCTAssertEqual(savedLocations.count, 3)
    }
    
    func testSaveLocationWithZeroAccuracy() throws {
        // Given
        let session = try createTestSession()
        let location = createLocation(horizontalAccuracy: 0.0)
        
        // When
        let entry = try repository.saveLocation(location, for: session)
        
        // Then
        XCTAssertEqual(entry.accuracy, 0.0)
    }
    
    func testSaveLocationWithVeryHighAccuracy() throws {
        // Given
        let session = try createTestSession()
        let location = createLocation(horizontalAccuracy: 10000.0)
        
        // When
        let entry = try repository.saveLocation(location, for: session)
        
        // Then
        XCTAssertEqual(entry.accuracy, 10000.0)
    }
    
    // MARK: - Performance Tests
    
    func testSaveManyLocationsPerformance() {
        let session = try! createTestSession()
        
        measure {
            for i in 0..<100 {
                let location = createLocation(
                    latitude: 37.7749 + Double(i) * 0.001,
                    longitude: -122.4194 + Double(i) * 0.001
                )
                _ = try? repository.saveLocation(location, for: session)
            }
        }
    }
    
    func testFetchManyLocationsPerformance() throws {
        // Given
        let session = try createTestSession()
        
        for i in 0..<1000 {
            let location = createLocation(
                latitude: 37.7749 + Double(i) * 0.0001,
                timestamp: Date(timeIntervalSince1970: Double(i))
            )
            _ = try repository.saveLocation(location, for: session)
        }
        
        // When/Then
        measure {
            _ = try? repository.fetchLocations(for: session)
        }
    }
    
    func testLocationCountPerformance() throws {
        // Given
        let session = try createTestSession()
        
        for i in 0..<1000 {
            _ = try repository.saveLocation(createLocation(), for: session)
        }
        
        // When/Then
        measure {
            _ = try? repository.locationCount(for: session)
        }
    }
    
    // MARK: - Helper Methods
    
    private func createTestSession(
        narrative: String = "Test Session",
        startDate: Date = Date()
    ) throws -> TrackingSession {
        return try sessionRepository.createSession(narrative: narrative, startDate: startDate)
    }
    
    private func createLocation(
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
}
