import Foundation
import CoreData
import SwiftUI

// MARK: - Dependency Container

/// Centralized dependency injection container for TrackMe
/// Manages creation and lifecycle of all app dependencies
class DependencyContainer: ObservableObject {
    
    // MARK: - Core Dependencies
    
    private let persistenceController: PersistenceController
    private let dataContext: DataContextProtocol
    
    // MARK: - Repositories (lazy-loaded)
    
    private lazy var _sessionRepository: SessionRepositoryProtocol = {
        CoreDataSessionRepository(context: dataContext.viewContext)
    }()
    
    private lazy var _locationRepository: LocationRepositoryProtocol = {
        CoreDataLocationRepository(context: dataContext.viewContext)
    }()
    
    // MARK: - Services (lazy-loaded)
    
    private lazy var _locationManager: LocationManager = {
        LocationManager(sessionRepository: _sessionRepository, locationRepository: _locationRepository)
    }()
    
    private lazy var _errorHandler: ErrorHandler = {
        ErrorHandler.shared // Keep as singleton for now - handles global error state
    }()
    
    // MARK: - Initialization
    
    /// Initialize with production dependencies
    init(persistenceController: PersistenceController = .shared) {
        self.persistenceController = persistenceController
        self.dataContext = CoreDataContext(container: persistenceController.container)
    }
    
    /// Initialize with custom dependencies (for testing)
    init(dataContext: DataContextProtocol, 
         sessionRepository: SessionRepositoryProtocol? = nil,
         locationRepository: LocationRepositoryProtocol? = nil) {
        self.persistenceController = PersistenceController(inMemory: true) // Dummy for testing
        self.dataContext = dataContext
        
        if let sessionRepo = sessionRepository {
            self._sessionRepository = sessionRepo
        }
        
        if let locationRepo = locationRepository {
            self._locationRepository = locationRepo
        }
    }
    
    // MARK: - Repository Access
    
    var sessionRepository: SessionRepositoryProtocol {
        _sessionRepository
    }
    
    var locationRepository: LocationRepositoryProtocol {
        _locationRepository
    }
    
    // MARK: - Service Access
    
    var locationManager: LocationManager {
        _locationManager
    }
    
    var errorHandler: ErrorHandler {
        _errorHandler
    }
    
    // MARK: - ViewModel Factory Methods
    
    /// Create a TrackingViewModel with injected dependencies
    func makeTrackingViewModel() -> TrackingViewModel {
        TrackingViewModel(
            locationManager: _locationManager,
            sessionRepository: _sessionRepository,
            errorHandler: _errorHandler
        )
    }
    
    /// Create a HistoryViewModel with injected dependencies
    func makeHistoryViewModel() -> HistoryViewModel {
        HistoryViewModel(
            sessionRepository: _sessionRepository,
            locationRepository: _locationRepository
        )
    }
    
    /// Create a TripMapViewModel with injected dependencies
    func makeTripMapViewModel(session: TrackingSession) -> TripMapViewModel {
        TripMapViewModel(
            session: session,
            locationRepository: _locationRepository
        )
    }
    
    // MARK: - Background Context Factory
    
    /// Create a new background repository for async operations
    func makeBackgroundSessionRepository() -> SessionRepositoryProtocol {
        let backgroundContext = dataContext.newBackgroundContext()
        return CoreDataSessionRepository(context: backgroundContext)
    }
    
    /// Create a new background location repository for async operations
    func makeBackgroundLocationRepository() -> LocationRepositoryProtocol {
        let backgroundContext = dataContext.newBackgroundContext()
        return CoreDataLocationRepository(context: backgroundContext)
    }
}

// MARK: - SwiftUI Environment Key

private struct DependencyContainerKey: EnvironmentKey {
    static let defaultValue = DependencyContainer()
}

extension EnvironmentValues {
    var dependencyContainer: DependencyContainer {
        get { self[DependencyContainerKey.self] }
        set { self[DependencyContainerKey.self] = newValue }
    }
}

// MARK: - View Extension for Convenience

extension View {
    /// Inject the dependency container into the SwiftUI environment
    func withDependencies(_ container: DependencyContainer) -> some View {
        self.environment(\.dependencyContainer, container)
    }
}
