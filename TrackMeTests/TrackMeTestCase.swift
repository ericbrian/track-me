import XCTest
import Combine
import CoreData
import CoreLocation
@testable import TrackMe

/// Base test case class providing common setup, teardown, and utilities
/// Inherit from this class instead of XCTestCase for consistent test infrastructure
class TrackMeTestCase: XCTestCase {
    
    // MARK: - Core Data
    
    /// In-memory Core Data stack for testing
    var testContainer: NSPersistentContainer!
    
    /// Test context for Core Data operations
    var testContext: NSManagedObjectContext!
    
    // MARK: - Mock Repositories
    
    /// Mock session repository for dependency injection
    var mockSessionRepository: MockSessionRepository!
    
    /// Mock location repository for dependency injection
    var mockLocationRepository: MockLocationRepository!
    
    // MARK: - Error Handler
    
    /// Error handler for testing
    var errorHandler: ErrorHandler!
    
    // MARK: - Setup & Teardown
    
    override func setUp() {
        super.setUp()
        
        // Create in-memory Core Data stack
        testContainer = CoreDataTestStack.createInMemoryStack()
        testContext = testContainer.viewContext
        
        // Initialize mock repositories
        mockSessionRepository = MockSessionRepository()
        mockLocationRepository = MockLocationRepository()
        
        // Error handler is a singleton - no need to initialize
        errorHandler = ErrorHandler.shared
    }
    
    override func tearDown() {
        // Clean up Core Data
        clearCoreData()
        testContext = nil
        testContainer = nil
        
        // Reset mocks
        mockSessionRepository?.reset()
        mockSessionRepository = nil
        
        mockLocationRepository?.reset()
        mockLocationRepository = nil
        
        // Clear error handler (sync version - error handler methods need to be callable)
        errorHandler = nil
        
        super.tearDown()
    }
    
    // MARK: - Core Data Helpers
    
    /// Clears all data from the test Core Data stack
    func clearCoreData() {
        guard let context = testContext else { return }
        
        // Fetch and delete all TrackingSessions
        let sessionFetch = NSFetchRequest<NSFetchRequestResult>(entityName: "TrackingSession")
        let sessionDeleteRequest = NSBatchDeleteRequest(fetchRequest: sessionFetch)
        
        // Fetch and delete all LocationEntries
        let locationFetch = NSFetchRequest<NSFetchRequestResult>(entityName: "LocationEntry")
        let locationDeleteRequest = NSBatchDeleteRequest(fetchRequest: locationFetch)
        
        do {
            try context.execute(sessionDeleteRequest)
            try context.execute(locationDeleteRequest)
            try context.save()
        } catch {
            // Silently fail in teardown - tests will fail if data persists incorrectly
        }
    }
    
    /// Saves the test context and asserts success
    func saveContext() {
        do {
            if testContext.hasChanges {
                try testContext.save()
            }
        } catch {
            XCTFail("Failed to save test context: \(error)")
        }
    }
    
    /// Creates a test session using real Core Data
    /// - Parameters:
    ///   - narrative: Session narrative
    ///   - isActive: Whether session is active
    ///   - startDate: Start date
    ///   - endDate: Optional end date
    /// - Returns: TrackingSession instance
    func createTestSession(
        narrative: String = "Test Session",
        isActive: Bool = true,
        startDate: Date = Date(),
        endDate: Date? = nil
    ) -> TrackingSession {
        return TestFixtures.createSession(
            in: testContext,
            narrative: narrative,
            isActive: isActive,
            startDate: startDate,
            endDate: endDate
        )
    }
    
    /// Creates a test location entry using real Core Data
    /// - Parameters:
    ///   - session: Session to associate with
    ///   - location: CLLocation to use
    /// - Returns: LocationEntry instance
    func createTestLocationEntry(
        for session: TrackingSession,
        location: CLLocation = MockLocationGenerator.location()
    ) -> LocationEntry {
        return TestFixtures.createLocationEntry(
            in: testContext,
            for: session,
            location: location
        )
    }
    
    // MARK: - Repository Helpers
    
    /// Creates real Core Data repositories using the test context
    /// - Returns: Tuple of session and location repositories
    func createRealRepositories() -> (SessionRepositoryProtocol, LocationRepositoryProtocol) {
        let sessionRepo = CoreDataSessionRepository(context: testContext)
        let locationRepo = CoreDataLocationRepository(context: testContext)
        return (sessionRepo, locationRepo)
    }
    
    // MARK: - Async Testing Helpers
    
    /// Waits for a condition to be true with timeout.
    /// Fails the current test on timeout instead of trapping the process.
    /// - Parameters:
    ///   - timeout: Maximum time to wait
    ///   - condition: Condition to check
    func wait(
        timeout: TimeInterval = 1.0,
        for condition: @escaping () -> Bool
    ) {
        let expectation = XCTestExpectation(description: "Waiting for condition")

        let checkInterval: TimeInterval = 0.05
        var elapsed: TimeInterval = 0

        var didFulfill = false
        let timer = Timer.scheduledTimer(withTimeInterval: checkInterval, repeats: true) { timer in
            if condition() {
                didFulfill = true
                expectation.fulfill()
                timer.invalidate()
            }
            elapsed += checkInterval
            if elapsed >= timeout {
                timer.invalidate()
            }
        }

        wait(for: [expectation], timeout: timeout + 0.25)

        if !didFulfill {
            timer.invalidate()
            XCTFail("Timed out waiting for condition after \(timeout) seconds")
        }
    }
    
    /// Waits for published value to change
    /// - Parameters:
    ///   - timeout: Maximum time to wait
    ///   - publisher: Publisher to observe
    ///   - condition: Condition to check on published value
    @MainActor
    func waitForPublisher<T>(
        timeout: TimeInterval = 1.0,
        publisher: Published<T>.Publisher,
        condition: @escaping (T) -> Bool
    ) {
        let expectation = XCTestExpectation(description: "Waiting for publisher")
        
        let cancellable = publisher.sink { value in
            if condition(value) {
                expectation.fulfill()
            }
        }
        
        wait(for: [expectation], timeout: timeout)
        cancellable.cancel()
    }
    
    // MARK: - Location Helpers
    
    /// Creates a mock location at a specific coordinate
    func location(
        latitude: CLLocationDegrees,
        longitude: CLLocationDegrees,
        accuracy: CLLocationAccuracy = 10.0
    ) -> CLLocation {
        return MockLocationGenerator.location(
            latitude: latitude,
            longitude: longitude,
            horizontalAccuracy: accuracy
        )
    }
    
    /// Creates a path of locations
    func createPath(count: Int = 10) -> [CLLocation] {
        return MockLocationGenerator.path(count: count)
    }
    
    /// Creates noisy GPS locations
    func createNoisyLocations(count: Int = 10) -> [CLLocation] {
        return MockLocationGenerator.noisyLocations(count: count)
    }
    
    // MARK: - Assertion Helpers
    
    /// Asserts a location matches expected coordinates
    func assertLocation(
        _ location: CLLocation,
        latitude: CLLocationDegrees,
        longitude: CLLocationDegrees,
        accuracy: CLLocationDegrees = 0.0001,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        assertLocationNear(
            location,
            latitude: latitude,
            longitude: longitude,
            accuracy: accuracy,
            file: file,
            line: line
        )
    }
    
    /// Asserts an error occurred and matches expected type
    func assertError<T: Error>(
        _ error: Error?,
        isType expectedType: T.Type,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        guard let error = error else {
            XCTFail("Expected error of type \(expectedType), but got nil", file: file, line: line)
            return
        }
        
        XCTAssertTrue(error is T, "Expected error of type \(expectedType), but got \(type(of: error))", file: file, line: line)
    }
    
    /// Asserts that an AppError matches expected case
    func assertAppError(
        _ error: Error?,
        matches expectedError: AppError,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        guard let appError = error as? AppError else {
            XCTFail("Expected AppError, but got \(String(describing: error))", file: file, line: line)
            return
        }
        
        // Compare error descriptions as a simple way to check equality
        XCTAssertEqual(
            appError.errorDescription,
            expectedError.errorDescription,
            file: file,
            line: line
        )
    }
}

// MARK: - MainActor Support

/// Base test case for MainActor-isolated tests (ViewModels, etc.)
@MainActor
class TrackMeMainActorTestCase: TrackMeTestCase {
    // Inherits all functionality from TrackMeTestCase
    // but ensures tests run on MainActor for UI-related components
    
    /// Override setUp to ensure MainActor isolation for property initialization
    override func setUp() {
        super.setUp()
    }
    
    /// Override tearDown to ensure MainActor isolation for cleanup
    override func tearDown() {
        super.tearDown()
    }
}
