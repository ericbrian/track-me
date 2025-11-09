# ADR-002: Use Core Data for Local Persistence

## Status

Accepted

## Context

TrackMe needs to store GPS tracking sessions and location points locally on the device. The data model includes:

- Tracking sessions with metadata (narrative, start/end times)
- Location entries (latitude, longitude, timestamp, accuracy)
- Potentially thousands of location points per session
- Relationships between sessions and their location points

We needed a persistence solution that:

- Works offline (no network required)
- Handles large datasets efficiently
- Supports complex queries and relationships
- Integrates well with SwiftUI and iOS ecosystem
- Respects user privacy (local-only storage)

## Decision

We will use Core Data as our local persistence layer, with a schema defined in `TrackMe.xcdatamodeld` and managed through `Persistence.swift`.

The data model includes:

- `TrackingSession` entity (one-to-many with LocationEntry)
- `LocationEntry` entity (stores individual GPS points)

## Consequences

### Positive

- Native Apple framework with excellent iOS integration
- Powerful querying capabilities via NSFetchRequest
- Efficient handling of large datasets with batch operations
- Built-in relationship management
- Migration support for schema changes
- Works seamlessly with SwiftUI via @FetchRequest
- Thread-safe with NSManagedObjectContext
- All data stays local (privacy-first)

### Negative

- Learning curve for Core Data concepts
- More complex than simple file storage or UserDefaults
- Requires careful thread management for background tasks
- Schema changes require migration planning

### Neutral

- Core Data is iOS-specific (not cross-platform)
- Debugging requires Xcode Core Data tools

## Alternatives Considered

**Realm**: Modern, easy to use, but adds external dependency and doesn't integrate as seamlessly with Apple's ecosystem.

**SQLite directly**: More control but significantly more boilerplate code. Core Data provides a higher-level abstraction.

**File-based storage (JSON/Codable)**: Simple but inefficient for large datasets and complex queries. No built-in relationship management.

**UserDefaults**: Only suitable for small amounts of data. Not appropriate for potentially thousands of location points.

## Notes

Core Data's integration with SwiftUI's @FetchRequest makes it ideal for reactive UI updates. The persistence layer is centralized in `Persistence.swift` for easy testing and maintenance.

---

**Date**: 2025-11-09  
**Author**: Eric  
**Last Updated**: 2025-11-09
