# Dependency Injection Architecture

TrackMe uses Dependency Injection (DI) with protocol-based repositories to achieve loose coupling, testability, and maintainability.

## Overview

The DI architecture consists of:

1. **Repository Protocols** - Abstract data access interfaces
2. **Repository Implementations** - Concrete Core Data implementations
3. **ViewModels** - Business logic with injected dependencies
4. **DependencyContainer** - Factory for creating dependencies
5. **Views** - UI that observes ViewModels

## Architecture Flow

```
┌─────────────────────────────────────────┐
│         DependencyContainer             │
│  (creates and provides dependencies)    │
└────────────┬────────────────────────────┘
             │
             ├──> ViewModel (observes)
             │    └──> Repository Protocol
             │         └──> Core Data Implementation
             │
             └──> Service (LocationManager)
                  └──> Repository Protocol
                       └──> Core Data Implementation
```

## Repository Protocols

### SessionRepositoryProtocol

Manages tracking sessions:

```swift
protocol SessionRepositoryProtocol {
    func fetchActiveSessions() throws -> [TrackingSession]
    func fetchAllSessions() throws -> [TrackingSession]
    func createSession(narrative: String, startDate: Date) throws -> TrackingSession
    func endSession(_ session: TrackingSession, endDate: Date) throws
    func deleteSession(_ session: TrackingSession) throws
    func recoverOrphanedSessions() throws -> Int
}
```

### LocationRepositoryProtocol

Manages location entries:

```swift
protocol LocationRepositoryProtocol {
    func saveLocation(_ location: CLLocation, for session: TrackingSession) throws -> LocationEntry
    func fetchLocations(for session: TrackingSession) throws -> [LocationEntry]
    func deleteLocations(for session: TrackingSession) throws
    func locationCount(for session: TrackingSession) throws -> Int
}
```

## Using the DependencyContainer

### In Your App

Initialize the container at app launch:

```swift
@main
struct TrackMeApp: App {
    @StateObject private var container = DependencyContainer()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .withDependencies(container)
        }
    }
}
```

### In Your Views

Access ViewModels through the container:

```swift
struct TrackingView: View {
    @Environment(\.dependencyContainer) private var container
    @StateObject private var viewModel: TrackingViewModel
    
    init() {
        // Initialize via environment won't work for @StateObject
        // Use a factory pattern instead
    }
    
    var body: some View {
        // Use viewModel...
    }
}

// Better approach - inject directly:
struct TrackingView: View {
    @StateObject var viewModel: TrackingViewModel
    
    var body: some View {
        // Use viewModel...
    }
}

// Create the view:
let container = DependencyContainer()
TrackingView(viewModel: container.makeTrackingViewModel())
```

### Creating ViewModels

The container provides factory methods:

```swift
let container = DependencyContainer()

// Create ViewModels
let trackingVM = container.makeTrackingViewModel()
let historyVM = container.makeHistoryViewModel()
let mapVM = container.makeTripMapViewModel(session: mySession)
```

### Accessing Services

Access services through the container:

```swift
let container = DependencyContainer()
let locationManager = container.locationManager
let errorHandler = container.errorHandler
```

### Accessing Repositories Directly

For custom logic, access repositories:

```swift
let container = DependencyContainer()
let sessionRepo = container.sessionRepository
let locationRepo = container.locationRepository

// Use repository
let sessions = try sessionRepo.fetchAllSessions()
```

## ViewModels

ViewModels encapsulate business logic and accept dependencies via constructor injection.

### TrackingViewModel

Manages tracking state and user interactions:

```swift
class TrackingViewModel: ObservableObject {
    @Published var isTracking = false
    @Published var narrative = ""
    @Published var locationCount = 0
    
    private let locationManager: LocationManager
    private let sessionRepository: SessionRepositoryProtocol
    
    init(locationManager: LocationManager,
         sessionRepository: SessionRepositoryProtocol,
         errorHandler: ErrorHandler) {
        // Store dependencies
    }
    
    func startTracking() { /* ... */ }
    func stopTracking() { /* ... */ }
}
```

### HistoryViewModel

Manages session list and filtering:

```swift
class HistoryViewModel: ObservableObject {
    @Published var sessions: [TrackingSession] = []
    @Published var searchText = ""
    
    private let sessionRepository: SessionRepositoryProtocol
    private let locationRepository: LocationRepositoryProtocol
    
    init(sessionRepository: SessionRepositoryProtocol,
         locationRepository: LocationRepositoryProtocol) {
        // Store dependencies
    }
    
    func loadSessions() { /* ... */ }
    func deleteSession(_ session: TrackingSession) { /* ... */ }
}
```

### TripMapViewModel

Manages map state for a session:

```swift
class TripMapViewModel: ObservableObject {
    @Published var locations: [LocationEntry] = []
    @Published var mapRegion: MapRegion?
    
    private let session: TrackingSession
    private let locationRepository: LocationRepositoryProtocol
    
    init(session: TrackingSession,
         locationRepository: LocationRepositoryProtocol) {
        // Store dependencies
    }
    
    func loadLocations() { /* ... */ }
}
```

## Testing with DI

### Mock Repositories

Create mock implementations for testing:

```swift
class MockSessionRepository: SessionRepositoryProtocol {
    var sessions: [TrackingSession] = []
    var shouldThrowError = false
    
    func fetchAllSessions() throws -> [TrackingSession] {
        if shouldThrowError { throw TestError.mockError }
        return sessions
    }
    
    func createSession(narrative: String, startDate: Date) throws -> TrackingSession {
        let session = TrackingSession()
        session.narrative = narrative
        session.startDate = startDate
        sessions.append(session)
        return session
    }
    
    // Implement other methods...
}
```

### Test ViewModels

Inject mock repositories for isolated testing:

```swift
func testTrackingViewModel() {
    // Arrange
    let mockSessionRepo = MockSessionRepository()
    let mockLocationRepo = MockLocationRepository()
    let mockLocationManager = MockLocationManager(
        sessionRepository: mockSessionRepo,
        locationRepository: mockLocationRepo
    )
    
    let viewModel = TrackingViewModel(
        locationManager: mockLocationManager,
        sessionRepository: mockSessionRepo,
        errorHandler: ErrorHandler()
    )
    
    // Act
    viewModel.narrative = "Test Trip"
    viewModel.startTracking()
    
    // Assert
    XCTAssertTrue(viewModel.isTracking)
    XCTAssertEqual(mockSessionRepo.sessions.count, 1)
}
```

### Test Container

Create a test container with mock dependencies:

```swift
func makeTestContainer() -> DependencyContainer {
    let mockContext = MockDataContext()
    let mockSessionRepo = MockSessionRepository()
    let mockLocationRepo = MockLocationRepository()
    
    return DependencyContainer(
        dataContext: mockContext,
        sessionRepository: mockSessionRepo,
        locationRepository: mockLocationRepo
    )
}
```

## Migration Guide

### From Direct Core Data Access

**Before:**
```swift
struct HistoryView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \TrackingSession.startDate, ascending: false)]
    ) private var sessions: FetchedResults<TrackingSession>
}
```

**After:**
```swift
struct HistoryView: View {
    @StateObject var viewModel: HistoryViewModel
    
    var body: some View {
        List(viewModel.filteredSessions) { session in
            // ...
        }
    }
}
```

### From Singleton Pattern

**Before:**
```swift
class LocationManager {
    static let shared = LocationManager()
    private var persistenceController = PersistenceController.shared
}
```

**After:**
```swift
class LocationManager {
    private let sessionRepository: SessionRepositoryProtocol
    private let locationRepository: LocationRepositoryProtocol
    
    init(sessionRepository: SessionRepositoryProtocol,
         locationRepository: LocationRepositoryProtocol) {
        self.sessionRepository = sessionRepository
        self.locationRepository = locationRepository
    }
}
```

## Best Practices

### Do's

✅ **Depend on protocols, not concrete types**
```swift
class ViewModel {
    private let repository: SessionRepositoryProtocol // Good
}
```

✅ **Inject dependencies via initializer**
```swift
init(repository: SessionRepositoryProtocol) {
    self.repository = repository
}
```

✅ **Use the container to create dependencies**
```swift
let viewModel = container.makeTrackingViewModel()
```

✅ **Keep ViewModels testable with protocols**

✅ **Create mock implementations for testing**

### Don'ts

❌ **Don't create dependencies inside classes**
```swift
class ViewModel {
    private let repository = CoreDataRepository() // Bad
}
```

❌ **Don't use singletons for testable components**
```swift
let data = PersistenceController.shared // Bad for new code
```

❌ **Don't couple Views directly to Core Data**
```swift
@FetchRequest var sessions: FetchedResults<TrackingSession> // Avoid in new code
```

❌ **Don't instantiate ViewModels directly**
```swift
@StateObject var viewModel = TrackingViewModel(...) // Use container instead
```

## Related Documentation

- [ADR-007: Dependency Injection with Protocol-Based Repositories](adr/007-dependency-injection-repositories.md)
- [ADR-003: MVVM Architecture Pattern](adr/003-mvvm-architecture.md)
- [ADR-002: Core Data for Local Persistence](adr/002-core-data-persistence.md)

## Files

- `TrackMe/Data/RepositoryProtocols.swift` - Protocol definitions
- `TrackMe/Data/CoreDataRepositories.swift` - Core Data implementations
- `TrackMe/DependencyContainer.swift` - Dependency injection container
- `TrackMe/ViewModels/ViewModels.swift` - ViewModel implementations
