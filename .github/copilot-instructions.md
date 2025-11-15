# Copilot Instructions for TrackMe

## Project Overview

TrackMe is a privacy-first iOS app for real-time GPS tracking, session management, and local data storage. It uses SwiftUI, Core Location, Core Data, and Combine. The app is structured for clarity and extensibility, with a focus on user privacy and offline operation.

## Architecture & Key Components

- **MVVM with SwiftUI**: Views in `Views/`, logic in `Services/`, persistence in `Data/`.
- **LocationManager** (`Services/LocationManager.swift`): Handles all GPS logic, permissions, and background tracking. Updates are filtered for accuracy and frequency.
- **Core Data** (`Data/Persistence.swift`, `TrackMe.xcdatamodeld/`): Stores sessions (`TrackingSession`) and location points (`LocationEntry`).
- **Phone/Watch Communication**: `PhoneConnectivityManager.swift` and `WatchConnectivityManager.swift` manage cross-device sync (if implemented).
- **UI**: Main screens are `TrackingView.swift` (start/stop, narrative), `HistoryView.swift` (session list), and `TripMapView.swift` (map display).

## Developer Workflows

- **Build**: Open `TrackMe.xcodeproj` in Xcode 15+, select a physical iOS device, and run. Simulator does not provide real GPS data.
- **Debug**: Use Xcode's debugger and device logs. Location updates require device permissions.
- **Database**: Schema is defined in `TrackMe.xcdatamodeld`. Use Core Data tools for inspection.
- **Testing**: Unit tests are in `TrackMeTests/`. Run tests via:
  ```bash
  xcodebuild test -scheme TrackMe -destination 'platform=iOS Simulator,id=0609225E-F180-495E-8270-D487A0FB5219'
  ```
  Or use Cmd+U in Xcode. Tests cover LocationManager, Core Data persistence, connectivity managers, and integration scenarios.

## Project-Specific Patterns

- **Session Management**: Each tracking session has a narrative, start/end times, and a list of `LocationEntry` points. See `TrackingView.swift` and `LocationManager.swift` for flow.
- **Background Tracking**: Enabled via Core Location; ensure permissions are set to "Always Allow" for full functionality.
- **Data Privacy**: All data is local; no network sync or analytics. Do not add external data transmission without explicit user consent.
- **Combine**: Used for reactive updates between services and views.

## Integration Points

- **Core Location**: All location logic is centralized in `LocationManager.swift`.
- **Core Data**: Accessed via `Persistence.swift` and the Core Data model.
- **Watch App**: Communication logic is in `PhoneConnectivityManager.swift` and `WatchConnectivityManager.swift`.

## Conventions

- **SwiftUI for all UI**; UIKit is not used.
- **MVVM separation**: Keep business logic out of views.
- **No external analytics or tracking**.
- **All data is local by default**.

## Apple Best Practices

### Swift API Design Guidelines

- **Naming**: Use clear, descriptive names that read naturally at the call site
  - Functions and methods: start with verbs (`calculateDistance()`, `startTracking()`)
  - Types and properties: use nouns (`LocationEntry`, `sessionCount`)
  - Boolean properties/functions: use `is`, `has`, `should` prefixes (`isActive`, `hasPermission`)
- **Parameter Labels**: Ensure first parameter label reads naturally in context
  - Omit label when function name makes context clear: `sessions.remove(at: index)`
  - Include label for clarity: `sessions.filter(by: narrative)`
- **Avoid abbreviations**: Use full words unless abbreviation is well-known (e.g., `URL`, `ID`)

### Memory Management

- **Avoid Retain Cycles**: Use `weak` or `unowned` for delegate patterns and closures
  - Always use `[weak self]` in closures that might outlive their context
  - Use `[weak self] in` in Combine pipelines and async operations
- **Value Types First**: Prefer structs over classes when possible (SwiftUI views, models)
- **Reference Types**: Use classes only when needed (Core Data managed objects, managers with state)

### Concurrency & Threading

- **Use Swift Concurrency**: Prefer `async/await` over completion handlers for new code
- **MainActor**: Mark UI-related classes and methods with `@MainActor`
  - ViewModels that publish to UI should be `@MainActor`
  - UI updates must happen on main thread
- **Sendable**: Ensure types passed across concurrency boundaries conform to `Sendable`
- **Background Work**: Use `Task.detached` for CPU-intensive work
- **Core Data**: Perform operations on appropriate context's queue using `perform` or `performAndWait`

### Error Handling

- **Use Swift Error Handling**: Define custom error types conforming to `Error`
- **Propagate Errors**: Use `throws` instead of optional returns when errors need context
- **Handle Gracefully**: Catch errors at appropriate boundaries and provide user feedback
- **Don't Swallow Errors**: Always log or handle errors; never use empty `catch` blocks

### SwiftUI Best Practices

- **State Management**: 
  - Use `@State` for view-local state
  - Use `@StateObject` for view-owned ObservableObjects (created by view)
  - Use `@ObservedObject` for injected ObservableObjects (owned elsewhere)
  - Use `@EnvironmentObject` for app-wide shared state
- **Performance**: 
  - Keep view body lightweight; extract complex logic to computed properties or methods
  - Use `LazyVStack`/`LazyHStack` for long lists
  - Avoid expensive operations in view body (use `task` or `onAppear`)
- **View Composition**: Break large views into smaller, reusable components
- **Previews**: Provide meaningful PreviewProviders for development

### Core Data Best Practices

- **Context Management**: Use appropriate context for the task
  - Main context for UI updates
  - Background contexts for imports/exports
- **Fetch Requests**: Use predicates and sort descriptors; limit fetch results
- **NSFetchedResultsController**: Use for table/list views with automatic updates
- **Save Operations**: 
  - Check `hasChanges` before saving
  - Handle save errors appropriately
  - Batch updates for large operations

### Privacy & Security

- **Request Permissions**: Always explain why permissions are needed (Info.plist descriptions)
- **Minimal Data**: Only collect data necessary for app functionality
- **Keychain**: Use for sensitive data (passwords, tokens) - not applicable here but good practice
- **Data Protection**: Enable appropriate file protection levels
- **Privacy Manifests**: Keep privacy documentation up to date

### Accessibility

- **VoiceOver**: Ensure all interactive elements have accessibility labels
- **Dynamic Type**: Support system font size preferences
- **Color Contrast**: Ensure sufficient contrast ratios (WCAG guidelines)
- **Reduce Motion**: Respect accessibility settings for animations
- **Accessibility Modifiers**: Use `.accessibilityLabel()`, `.accessibilityHint()`, `.accessibilityValue()`

### Performance & Battery

- **Location Services**: 
  - Use appropriate accuracy level for task (don't always use `bestForNavigation`)
  - Stop location updates when not needed
  - Use deferred updates or significant location change monitoring when appropriate
- **Battery Efficiency**: 
  - Minimize background work
  - Batch network requests (not applicable here)
  - Use efficient data structures and algorithms
- **Memory**: Monitor memory usage; release large objects when done

### Testing Best Practices

- **Unit Tests**: Test business logic in isolation
- **Mock Dependencies**: Use protocols and dependency injection for testability
- **Integration Tests**: Test component interactions
- **UI Tests**: Test critical user flows (consider adding)
- **Code Coverage**: Aim for meaningful coverage, not just high percentages
- **Test Naming**: Use descriptive names that explain what's being tested

### Code Quality

- **Force Unwrapping**: Never force unwrap in production code (use `guard`, `if let`, or optional chaining)
- **Implicitly Unwrapped Optionals**: Avoid unless necessary (IBOutlets in UIKit)
- **Access Control**: Use appropriate levels (`private`, `fileprivate`, `internal`, `public`)
- **Extensions**: Organize code using extensions for protocol conformance and feature grouping
- **Documentation**: Add documentation comments for public APIs and complex logic
- **SwiftLint**: Consider adding SwiftLint for consistent code style

### Human Interface Guidelines

- **Navigation**: Use standard iOS navigation patterns
- **Gestures**: Support expected gestures (swipe to delete, pull to refresh)
- **Feedback**: Provide immediate visual/haptic feedback for user actions
- **Loading States**: Show progress for long operations
- **Error States**: Display clear, actionable error messages
- **Empty States**: Provide guidance when lists/views are empty

## Examples

- To add a new data field to sessions, update the Core Data model and relevant Swift files in `Data/` and `Views/`.
- To change location update frequency, adjust `LocationManager.swift` (distance filter, accuracy).

## Key Files/Directories

- `TrackMe/Services/LocationManager.swift`
- `TrackMe/Data/Persistence.swift`
- `TrackMe/Views/TrackingView.swift`, `HistoryView.swift`, `TripMapView.swift`
- `TrackMe.xcdatamodeld/`
- `TrackMeTests/` - Unit tests for all major components

# Critical Directives:

- Before fixing bugs and the like, create a unit test that reproduces the issue. Then fix the issue and ensure the test passes.
- Ensure all new features have corresponding unit tests.
- After adding a unit test, run the full test suite to ensure no regressions and then update the code coverage report.
- Verify that all references are properly imported at the top of each Swift file when creating new resources. Also verify that files are registered in the Xcode project if they need to be referenced by other code files.
- Follow Swift API Design Guidelines for all new code.
- Use `[weak self]` in closures and Combine pipelines to avoid retain cycles.
- Mark UI-related code with `@MainActor` appropriately.
- Provide meaningful error messages and handle errors gracefully.
- Consider accessibility in all UI implementations.
- Optimize for battery efficiency, especially with location services.
- Use this simulator for testing: iPhone 15 and Apple Watch (0609225E-F180-495E-8270-D487A0FB5219)

## Learning Resources

For developers new to iOS development, refer to:

- [Swift.org Documentation](https://swift.org/documentation/)
- [Apple Developer Documentation](https://developer.apple.com/documentation/)
- [SwiftUI Tutorials](https://developer.apple.com/tutorials/swiftui)
- [Human Interface Guidelines](https://developer.apple.com/design/human-interface-guidelines/)
- [Swift API Design Guidelines](https://swift.org/documentation/api-design-guidelines/)
- [WWDC Videos](https://developer.apple.com/videos/) - especially sessions on SwiftUI, Core Data, and Core Location

---

For questions, review the README or inspect the above files for implementation patterns. Run unit tests to validate changes.

