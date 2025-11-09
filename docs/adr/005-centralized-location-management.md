# ADR-005: Centralized Location Management

## Status

Accepted

## Context

Location tracking is core to TrackMe's functionality. The app needs to:

- Request and manage location permissions
- Track user location in foreground and background
- Filter location updates for accuracy and frequency
- Provide location data to multiple views
- Support starting/stopping tracking sessions
- Handle battery efficiency concerns

Multiple components need access to location data and tracking state. We needed to determine how to structure location-related code.

## Decision

All location logic is centralized in a single `LocationManager` service class (`Services/LocationManager.swift`) that:

- Wraps Core Location framework (CLLocationManager)
- Manages all permission requests and states
- Handles background location tracking configuration
- Filters location updates based on accuracy and distance
- Publishes location updates via Combine
- Coordinates with Core Data for persistence
- Acts as the single source of truth for tracking state

Views and other components access location functionality exclusively through this service.

## Consequences

### Positive

- Single source of truth for location logic
- Easier to test location functionality in isolation
- Consistent location handling across the app
- Centralized permission management
- Battery optimization logic in one place
- Easier to debug location issues
- Clear API for starting/stopping tracking
- Prevents duplicate CLLocationManager instances

### Negative

- LocationManager could become large if not well-organized
- All location features depend on this single class
- Changes to location logic require updating this central service

### Neutral

- Must ensure LocationManager doesn't become a "god object"
- Need to maintain clear boundaries within LocationManager

## Alternatives Considered

**Distributed location logic**: Each view manages its own CLLocationManager. This leads to duplication, inconsistent state, and multiple permission requests.

**Protocol-based abstraction**: Could define a protocol with multiple implementations. Adds complexity without clear benefit for our use case.

**Passive location observer**: Views could observe CLLocationManager directly. Doesn't provide centralized filtering and business logic.

## Notes

`LocationManager.swift` uses Combine's `@Published` properties to notify subscribers of location updates and state changes. This integrates seamlessly with SwiftUI views.

The manager includes logic for:

- Distance filtering (avoids too-frequent updates)
- Accuracy filtering (ignores low-accuracy points)
- Background tracking configuration
- Battery-efficient location updates

---

**Date**: 2025-11-09  
**Author**: Eric  
**Last Updated**: 2025-11-09
