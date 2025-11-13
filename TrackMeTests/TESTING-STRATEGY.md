# Suggested Testing Strategy

Start Here: Core Business Logic (Highest Priority)

1. KalmanFilter Tests
    Tests to write:
        Initialization with/without initial state
        First measurement processing
        Sequential measurement filtering
        Noise reduction verification
        Edge cases (zero variance, extreme values)
    Estimated: 30 minutes

2. LocationValidationConfig Tests
    Why? Pure data structures, no side effects, used throughout tracking
    Tests to write:
        Verify all preset configurations (default, highPrecision, efficient, permissive)
        Validate threshold values are reasonable
        Test configuration comparison
    Estimated: 20 minutes

3. Repository Protocol Mock Implementations
    Why? Essential for testing components that use repositories
    Create:
        MockSessionRepository
        MockLocationRepository
        Include configurable success/failure modes
    Estimated: 45 minutes

4. CoreDataSessionRepository Tests
    Dependencies: In-memory Core Data stack
    Tests to write:
        Create session with narrative
        Fetch active sessions
        End session
        Delete session
        Recover orphaned sessions
        Location count calculation
        Concurrent access scenarios
    Estimated: 1.5 hours

5. CoreDataLocationRepository Tests
    Dependencies: In-memory Core Data stack
    Tests to write:
        Save location for session
        Fetch locations with sorting
        Batch fetching
        Delete locations
        Location count
    Estimated: 1 hour

6. ErrorHandler Tests
    Why? Centralized error handling, relatively isolated
    Tests to write:
        Handle AppError types
        Convert generic errors to AppError
        Error context mapping
        Published state updates
    Estimated: 45 minutes

7. LocationManager Tests (Most Complex)
    Dependencies: Mock CLLocationManager, Mock repositories
    Tests to write:
        Authorization state changes
        Start/stop tracking
        Location validation logic
        Distance/time filtering
        Adaptive sampling
        Background mode handling
        Session lifecycle
        Error scenarios
    Estimated: 3-4 hours (complex but critical)

8. TrackingViewModel Tests
    Dependencies: Mock LocationManager, Mock repositories
    Tests to write:
        Start/stop tracking
        App lifecycle handling
        Session creation/ending
        Error handling integration
        State synchronization
    Estimated: 1.5 hours

9. HistoryListViewModel Tests
    Tests to write:
        Session fetching
        Session deletion
        Sorting/filtering
    Estimated: 1 hour

10. End-to-End Session Flow Tests
    Full session lifecycle with real Core Data
    Location filtering and storage
    Export functionality
    Estimated: 2 hours
