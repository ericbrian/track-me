# ADR-003: Adopt MVVM Architecture Pattern

## Status

Accepted

## Context

TrackMe requires a clear separation of concerns between UI, business logic, and data management. The application has:

- Multiple views (tracking, history, maps)
- Complex state management (location updates, session tracking)
- Data persistence via Core Data
- Reactive updates from location services

We needed an architecture pattern that:

- Separates UI from business logic
- Works well with SwiftUI's declarative paradigm
- Supports testability
- Allows for reactive data flow
- Scales as the application grows

## Decision

We will use the Model-View-ViewModel (MVVM) architecture pattern with the following structure:

- **Models**: Data entities (`Data/` directory) - Core Data models and domain objects
- **Views**: SwiftUI views (`Views/` directory) - UI components only, no business logic
- **ViewModels**: Implicit in Services - Logic handled by service classes like `LocationManager`
- **Services**: Business logic (`Services/` directory) - LocationManager, PhoneConnectivityManager, etc.

## Consequences

### Positive

- Clear separation between UI (SwiftUI views) and logic (Services)
- Services are testable in isolation without UI dependencies
- Views remain simple and focused on presentation
- Reactive updates via Combine work naturally with MVVM
- Easy to reason about data flow: Services → Views
- Business logic is reusable across different views

### Negative

- Additional layer of abstraction compared to putting logic in views
- Requires discipline to keep views "dumb" and logic in services
- Can lead to service classes growing large if not properly subdivided

### Neutral

- Team must understand MVVM principles
- Slightly more files/classes than monolithic approach

## Alternatives Considered

**MVC (Model-View-Controller)**: Traditional iOS pattern, but Controllers become massive and hard to test. Less suitable for SwiftUI's reactive nature.

**VIPER**: More complex with additional layers (Interactor, Presenter, Router). Overkill for an app of TrackMe's scope.

**Redux/Unidirectional**: Strict unidirectional data flow. Good for complex state management but adds boilerplate. Not needed for our use case.

**Logic in Views**: Simplest but makes testing difficult and violates separation of concerns. Views become bloated.

## Notes

Our implementation keeps logic centralized in `Services/` classes like `LocationManager.swift`. These services publish state changes that SwiftUI views observe and react to. This aligns well with SwiftUI's `@StateObject`, `@ObservedObject`, and `@Published` property wrappers.

---

**Date**: 2025-11-09  
**Author**: Eric  
**Last Updated**: 2025-11-09
