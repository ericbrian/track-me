import XCTest
import CoreData
@testable import TrackMe

@MainActor
final class HistoryListViewModelTests: XCTestCase {
    var viewContext: NSManagedObjectContext!
    var viewModel: HistoryListViewModel!
    
    override func setUp() async throws {
        try await super.setUp()
        viewContext = PersistenceController.preview.container.viewContext
        viewModel = HistoryListViewModel()
    }
    
    override func tearDown() async throws {
        viewModel.detach()
        viewModel = nil
        viewContext = nil
        try await super.tearDown()
    }
    
    // MARK: - Initialization Tests
    
    func testInitialization() {
        XCTAssertNotNil(viewModel)
        XCTAssertEqual(viewModel.sessions.count, 0)
        XCTAssertFalse(viewModel.isConfigured)
        XCTAssertEqual(viewModel.searchText, "")
    }
    
    // MARK: - Lifecycle Tests
    
    func testAttach() {
        // When
        viewModel.attach(context: viewContext)
        
        // Then
        XCTAssertTrue(viewModel.isConfigured)
    }
    
    func testAttach_MultipleCallsIgnored() {
        // When
        viewModel.attach(context: viewContext)
        let sessionsAfterFirst = viewModel.sessions.count
        
        viewModel.attach(context: viewContext)
        let sessionsAfterSecond = viewModel.sessions.count
        
        // Then
        XCTAssertEqual(sessionsAfterFirst, sessionsAfterSecond)
        XCTAssertTrue(viewModel.isConfigured)
    }
    
    func testDetach() {
        // Given
        viewModel.attach(context: viewContext)
        XCTAssertTrue(viewModel.isConfigured)
        
        // When
        viewModel.detach()
        
        // Then
        XCTAssertFalse(viewModel.isConfigured)
    }
    
    // MARK: - Session Loading Tests
    
    func testLoadSessions_Empty() {
        // When
        viewModel.attach(context: viewContext)
        
        // Then
        XCTAssertTrue(viewModel.isEmpty)
        XCTAssertEqual(viewModel.sessions.count, 0)
    }
    
    func testLoadSessions_WithData() {
        // Given
        let session1 = TrackingSession(context: viewContext)
        session1.id = UUID()
        session1.narrative = "Trip 1"
        session1.startDate = Date()
        
        let session2 = TrackingSession(context: viewContext)
        session2.id = UUID()
        session2.narrative = "Trip 2"
        session2.startDate = Date().addingTimeInterval(-3600)
        
        try? viewContext.save()
        
        // When
        viewModel.attach(context: viewContext)
        
        // Then
        XCTAssertFalse(viewModel.isEmpty)
        XCTAssertEqual(viewModel.sessions.count, 2)
        
        // Verify sorting (most recent first)
        XCTAssertEqual(viewModel.sessions[0].narrative, "Trip 1")
        XCTAssertEqual(viewModel.sessions[1].narrative, "Trip 2")
    }
    
    // MARK: - Search/Filter Tests
    
    func testFilteredSessions_NoSearchText() {
        // Given
        let session1 = TrackingSession(context: viewContext)
        session1.id = UUID()
        session1.narrative = "Trip 1"
        session1.startDate = Date()
        
        let session2 = TrackingSession(context: viewContext)
        session2.id = UUID()
        session2.narrative = "Trip 2"
        session2.startDate = Date()
        
        try? viewContext.save()
        viewModel.attach(context: viewContext)
        
        // When
        viewModel.searchText = ""
        
        // Then
        XCTAssertEqual(viewModel.filteredSessions.count, 2)
    }
    
    func testFilteredSessions_WithSearchText() {
        // Given
        let session1 = TrackingSession(context: viewContext)
        session1.id = UUID()
        session1.narrative = "Morning Run"
        session1.startDate = Date()
        
        let session2 = TrackingSession(context: viewContext)
        session2.id = UUID()
        session2.narrative = "Evening Walk"
        session2.startDate = Date()
        
        try? viewContext.save()
        viewModel.attach(context: viewContext)
        
        // When
        viewModel.searchText = "run"
        
        // Then
        XCTAssertEqual(viewModel.filteredSessions.count, 1)
        XCTAssertEqual(viewModel.filteredSessions[0].narrative, "Morning Run")
    }
    
    func testFilteredSessions_CaseInsensitive() {
        // Given
        let session = TrackingSession(context: viewContext)
        session.id = UUID()
        session.narrative = "Morning Run"
        session.startDate = Date()
        
        try? viewContext.save()
        viewModel.attach(context: viewContext)
        
        // When
        viewModel.searchText = "MORNING"
        
        // Then
        XCTAssertEqual(viewModel.filteredSessions.count, 1)
    }
    
    func testFilteredSessions_NoMatches() {
        // Given
        let session = TrackingSession(context: viewContext)
        session.id = UUID()
        session.narrative = "Morning Run"
        session.startDate = Date()
        
        try? viewContext.save()
        viewModel.attach(context: viewContext)
        
        // When
        viewModel.searchText = "xyz"
        
        // Then
        XCTAssertEqual(viewModel.filteredSessions.count, 0)
    }
    
    // MARK: - Delete Tests
    
    func testDeleteSessions() {
        // Given
        let session1 = TrackingSession(context: viewContext)
        session1.id = UUID()
        session1.narrative = "Trip 1"
        session1.startDate = Date()
        
        let session2 = TrackingSession(context: viewContext)
        session2.id = UUID()
        session2.narrative = "Trip 2"
        session2.startDate = Date()
        
        try? viewContext.save()
        viewModel.attach(context: viewContext)
        
        XCTAssertEqual(viewModel.sessions.count, 2)
        
        // When
        let indexSet = IndexSet(integer: 0)
        viewModel.deleteSessions(offsets: indexSet)
        
        // Wait for background deletion
        let expectation = XCTestExpectation(description: "Deletion completed")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
        
        // Refresh to see changes
        viewModel.refresh()
        
        // Then
        XCTAssertEqual(viewModel.sessions.count, 1)
    }
    
    // MARK: - Refresh Tests
    
    func testRefresh() {
        // Given
        viewModel.attach(context: viewContext)
        XCTAssertEqual(viewModel.sessions.count, 0)
        
        // Add a session directly to Core Data
        let session = TrackingSession(context: viewContext)
        session.id = UUID()
        session.narrative = "New Trip"
        session.startDate = Date()
        try? viewContext.save()
        
        // When
        viewModel.refresh()
        
        // Then
        XCTAssertEqual(viewModel.sessions.count, 1)
    }
    
    // MARK: - FetchedResultsController Tests
    
    func testFetchedResultsControllerUpdates() {
        // Given
        viewModel.attach(context: viewContext)
        XCTAssertEqual(viewModel.sessions.count, 0)
        
        // When - add session
        let session = TrackingSession(context: viewContext)
        session.id = UUID()
        session.narrative = "Dynamic Trip"
        session.startDate = Date()
        try? viewContext.save()
        
        // Wait for FRC update
        let expectation = XCTestExpectation(description: "FRC updated")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
        
        // Then
        XCTAssertGreaterThan(viewModel.sessions.count, 0)
    }
}
