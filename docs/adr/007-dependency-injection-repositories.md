# ADR-007: Adopt Dependency Injection with Protocol-Based Repositories

## Status

Accepted

## Context

TrackMe currently uses several patterns that make testing difficult and create tight coupling:

- **Singleton pattern**: `PersistenceController.shared`, `ErrorHandler.shared`, `PhoneConnectivityManager.shared`
- **Direct Core Data access**: Views use `@FetchRequest` and directly access Core Data entities
- **Hardcoded dependencies**: Services instantiate their own dependencies
- **No ViewModels**: Logic is split between views and service singletons

This creates several problems:

- **Difficult to test**: Cannot inject mock dependencies for unit tests
- **Tight coupling**: Components depend on concrete implementations
- **Hard to reason about**: Data flow is unclear, state changes are implicit
- **Violates SOLID principles**: Especially Dependency Inversion Principle
- **Fragile**: Changes to one component ripple through the system

We need a better architecture for managing dependencies and data access.

## Decision

We will adopt **Dependency Injection (DI)** with **protocol-based repositories**:

1. **Repository Pattern**: Abstract data access behind protocols
   - `SessionRepositoryProtocol`: Session CRUD operations
   - `LocationRepositoryProtocol`: Location entry management
   - Implementations use Core Data but views don't know this

2. **Protocol-Based Dependencies**: Services depend on protocols, not concrete types
   - `LocationManager` accepts a `SessionRepository` via initializer
   - Easy to swap implementations (Core Data, in-memory, mock)

3. **ViewModels**: Extract logic from views into testable ViewModels
   - ViewModels accept repositories via initializer (constructor injection)
   - Views observe ViewModels via `@StateObject` or `@ObservedObject`
   - ViewModels are `ObservableObject` classes with `@Published` properties

4. **Dependency Container**: Centralized dependency creation and lifecycle
   - `DependencyContainer` creates and provides dependencies
   - Passed through SwiftUI environment
   - Supports different configurations (production, testing)

5. **Phase out Singletons**: Replace singleton pattern with injected dependencies
   - Keep singletons only where truly necessary (e.g., app-level services)
   - Most components receive dependencies via injection

## Consequences

### Positive

- **Highly testable**: Easy to inject mocks and test in isolation
- **Loose coupling**: Components depend on protocols, not implementations
- **Clear dependencies**: All dependencies visible in initializers
- **Flexible**: Easy to swap implementations or add new ones
- **Better MVVM**: Clear separation between Views, ViewModels, and Models
- **Easier refactoring**: Changes to implementations don't affect protocols
- **Thread safety**: Each context/repository can manage its own threading
- **Scalable**: Easy to add new features without affecting existing code

### Negative

- **More boilerplate**: Protocols, implementations, and container code
- **Learning curve**: Team must understand DI and repository patterns
- **Initial refactoring effort**: Existing code must be migrated
- **Slightly more complex setup**: Must wire up dependencies at app start
- **Risk of over-abstraction**: Must balance abstraction with pragmatism

### Neutral

- Different architecture than typical SwiftUI examples
- Requires discipline to maintain DI throughout codebase
- ViewModels add a layer between Views and data

## Alternatives Considered

**Continue with Singletons**: Simple but makes testing very difficult. Doesn't scale well.

**Property Injection**: Inject dependencies via properties after initialization. More fragile than constructor injection.

**Service Locator**: Global registry of dependencies. Creates hidden dependencies and makes testing harder than DI.

**Environment Objects only**: SwiftUI's built-in DI. Good for app-wide dependencies but lacks the flexibility and testability of protocol-based DI.

**Direct Core Data access in Views**: Current approach for some views. Couples views to Core Data and makes testing impossible.

## Notes

### Implementation Strategy

**Phase 1**: Create protocols and implementations (non-breaking)
- Define repository protocols
- Create Core Data implementations
- Create dependency container

**Phase 2**: Introduce ViewModels (non-breaking)
- Extract logic from views into ViewModels
- ViewModels use repositories via DI
- Views observe ViewModels

**Phase 3**: Refactor services (breaking changes)
- Update services to accept injected dependencies
- Replace singleton usage with DI where appropriate
- Update views to use new service APIs

**Phase 4**: Remove old patterns (cleanup)
- Remove or minimize singleton usage
- Remove direct Core Data access from views
- Update tests to use DI

### Architecture Flow

```
View → ViewModel → Repository → Core Data
  ↑        ↑            ↑
  └─────DI Container────┘
```

### Example Usage

```swift
// Protocol
protocol SessionRepositoryProtocol {
    func fetchActiveSessions() throws -> [TrackingSession]
    func createSession(narrative: String) throws -> TrackingSession
    func endSession(_ session: TrackingSession) throws
}

// Implementation
class CoreDataSessionRepository: SessionRepositoryProtocol {
    private let context: NSManagedObjectContext
    init(context: NSManagedObjectContext) { ... }
}

// ViewModel
class TrackingViewModel: ObservableObject {
    private let sessionRepository: SessionRepositoryProtocol
    @Published var isTracking = false
    
    init(sessionRepository: SessionRepositoryProtocol) {
        self.sessionRepository = sessionRepository
    }
    
    func startTracking(narrative: String) {
        // Use repository...
    }
}

// View
struct TrackingView: View {
    @StateObject private var viewModel: TrackingViewModel
    
    init(container: DependencyContainer) {
        _viewModel = StateObject(wrappedValue: container.makeTrackingViewModel())
    }
}
```

### Testing Benefits

```swift
// Mock repository for testing
class MockSessionRepository: SessionRepositoryProtocol {
    var sessions: [TrackingSession] = []
    func fetchActiveSessions() throws -> [TrackingSession] { sessions }
}

// Easy to test
func testStartTracking() {
    let mockRepo = MockSessionRepository()
    let viewModel = TrackingViewModel(sessionRepository: mockRepo)
    viewModel.startTracking(narrative: "Test")
    XCTAssertTrue(viewModel.isTracking)
}
```

## Additional Resources

- **[Dependency Injection Guide](../DependencyInjection.md)** - Comprehensive usage guide with examples, testing patterns, migration strategies, and best practices for implementing DI in TrackMe

---

**Date**: 2025-11-09  
**Author**: TrackMe Team  
**Last Updated**: 2025-11-09
