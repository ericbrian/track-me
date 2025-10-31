import XCTest
import CoreData
@testable import TrackMe

final class HistoryViewModelTests: XCTestCase {
    var persistence: PersistenceController! 
    var context: NSManagedObjectContext! 

    override func setUp() {
        super.setUp()
        persistence = PersistenceController(inMemory: true)
        context = persistence.container.viewContext
    }

    override func tearDown() {
        context = nil
        persistence = nil
        super.tearDown()
    }

    func testAttachAndFetchSessions_NoCrash() {
        // Arrange: create a couple of sessions
        for i in 0..<3 {
            let s = TrackingSession(context: context)
            s.id = UUID()
            s.narrative = "S\(i)"
            s.startDate = Date().addingTimeInterval(TimeInterval(-i * 60))
            s.isActive = false
        }
        try? context.save()

        // Act
        let vm = HistoryViewModel()
        vm.attach(context: context)

        // Assert
        XCTAssertEqual(vm.sessions.count, 3)
    }
}
