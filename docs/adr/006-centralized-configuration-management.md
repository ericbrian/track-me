# ADR-006: Centralized Configuration Management

## Status

Accepted

## Context

TrackMe has various configuration values scattered throughout the codebase:

- Location tracking parameters (distance filter, accuracy threshold)
- UI constants (map zoom levels, animation durations)
- Feature flags (background tracking enabled, debug mode)
- Performance tuning values (batch sizes, refresh intervals)

These values are currently hardcoded in individual files, making it difficult to:

- Find and modify configuration values
- Maintain consistency across the app
- Test with different configurations
- Support different environments (debug, release, testing)
- Document what can be configured

We need a centralized approach to manage application configuration.

## Decision

We will implement centralized configuration management with:

1. **AppConfig struct** (`Config.swift`) - Single source of truth for all configuration
2. **Config.plist** - External configuration file for easy modification
3. **Typed configuration groups** - Organized by domain (Location, UI, Performance)
4. **Fallback defaults** - Safe defaults if plist is missing or invalid
5. **JSON support** - Optional JSON config for testing/flexibility

Structure:

```swift
struct AppConfig {
    struct Location {
        let distanceFilter: Double
        let accuracyThreshold: Double
        let backgroundTrackingEnabled: Bool
    }
    
    struct UI {
        let mapDefaultZoom: Double
        let animationDuration: Double
    }
    
    // Load from plist with defaults
    static let shared = AppConfig.load()
}
```

## Consequences

### Positive

- Single location for all configuration values
- Easy to find and modify settings
- Better testability (inject test configurations)
- Clear documentation of configurable parameters
- Can modify behavior without recompiling (plist changes)
- Type-safe configuration access
- Support for environment-specific configs
- Prevents magic numbers scattered in code

### Negative

- Initial effort to identify and centralize existing values
- Slight indirection when accessing config values
- Must maintain plist in sync with code structure
- Risk of over-configuration (not everything should be configurable)

### Neutral

- Team must know to check Config.swift for configurable values
- Need discipline to add new config to central location
- Plist must be included in app bundle

## Alternatives Considered

**Environment variables**: Not well-supported in iOS apps. Requires preprocessing.

**UserDefaults**: Good for user preferences, but not ideal for app-wide constants that shouldn't change at runtime.

**Build configurations (#if DEBUG)**: Limited to compile-time, not runtime configurable. Less flexible.

**Multiple plist files**: Could have separate plists per domain, but increases complexity without clear benefit.

**Hardcoded values**: Current approach. Simple but unmaintainable and inflexible.

## Notes

Config.plist should be loaded once at app launch and remain immutable during runtime. For user preferences that change at runtime, continue using UserDefaults or Core Data.

Configuration categories:

- Location (tracking parameters)
- UI (visual constants)
- Performance (batching, caching)
- Features (flags for experimental features)
- Debug (logging levels, test modes)

The plist can be overridden for testing by injecting a test configuration.

---

**Date**: 2025-11-09  
**Author**: TrackMe Team  
**Last Updated**: 2025-11-09
