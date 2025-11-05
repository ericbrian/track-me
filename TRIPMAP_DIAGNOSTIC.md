# TripMapView Diagnostic Report

## Test Results: ✅ All 19 Tests Passed

All core functionality tests passed, indicating the data layer is working correctly. The issue is likely in the UI rendering or iOS 17+ Map API usage.

## Identified Issues

### 1. **Empty Session Problem** (Most Likely)

**Symptom:** Map button appears but shows blank map
**Cause:** Session may have no location data
**Test:** `testSessionWithoutLocationsIsEmpty()` - PASSED
**Solution:**

```swift
// Check if session has locations before showing map button
private var hasLocations: Bool {
    (session.locations?.count ?? 0) > 0
}

// Only show map button if locations exist
if hasLocations {
    Button(action: onTapMap) {
        // Map button UI
    }
}
```

### 2. **Map API Compatibility Issue** (iOS 17+)

**Problem:** Using modern iOS 17+ Map API which may not render on simulator
**Current Code:**

```swift
Map(position: .constant(.region(region))) {
    // Annotations
}
```

**Issue:** The `.constant()` binding prevents map from updating when region changes
**Solution:**

```swift
@State private var mapPosition: MapCameraPosition

// Initialize in onAppear
mapPosition = .region(region)

// Use in Map
# TripMapView Diagnostic Report

Updated: 2025-11-05

## Summary

The “screwed up” map behavior had three root causes, all now fixed:

- Antimeridian wrapping broke polylines and region fitting for global trips. Fixed by introducing `MapMath` with antimeridian-aware region calculation and polyline segmentation.
- Freezes when tapping Share were caused by heavy, synchronous export work in the view hierarchy. Fixed by deferring export to a background queue and presenting a share sheet with a temporary file URL.
- A Core Data crash (“A fetch request must have an entity.”) occurred due to an implicit fetch request without an entity. Fixed by constructing an explicit `NSFetchRequest<LocationEntry>(entityName:)` in `TripMapView`.

All related unit tests pass, including new tests for `MapMath` and existing `TripMapViewTests`.

## Fixes in Code

1) Antimeridian-safe map rendering

- Added `TrackMe/Services/MapMath.swift` providing:
  - `computeRegion(for:minSpan:paddingScale:)` that chooses the minimal longitudinal span, handling 180° crossing.
  - `splitSegmentsAcrossAntimeridian(_:)` that breaks a polyline into segments to avoid wrap-around artifacts.
- Updated `TrackMe/Views/TripMapView.swift` to:
  - Use `Map(position:)` with `@State var mapPosition` and set it once via `setInitialCameraPositionIfNeeded()`.
  - Render multiple `MapPolyline` instances from `routePolylines` built by `MapMath.splitSegmentsAcrossAntimeridian`.

2) Responsive sharing (no UI freeze)

- Replaced eager `ShareLink` content generation with a lazy, async export:
  - Generate CSV off the main thread via `ExportService`.
  - Save to a temporary file and present a share sheet.
- Consolidated the share UI to a reusable `ShareSheet` wrapper (`TrackMe/Views/ShareSheet.swift`).

3) Core Data stability

- In `TripMapView.init`, build the fetch explicitly:
  - `let request = NSFetchRequest<LocationEntry>(entityName: "LocationEntry")`
  - Set `sortDescriptors` and `predicate` for the session, and initialize `FetchRequest(fetchRequest:animation:)`.

## Tests and Status

- TripMapView tests: PASS
- MapMath tests: PASS
- Full suite: PASS (minor simulator launch warnings are benign; unit tests complete successfully)

## Notes and Guardrails

- Keep the heavy work out of SwiftUI view bodies; prefer async tasks with state updates on the main queue.
- When computing regions across the globe, always consider the antimeridian and use segmented polylines to avoid artifacts.
- With Core Data + SwiftUI property wrappers, prefer explicit entity-based `NSFetchRequest` when constructing requests manually.

## Next Steps

- Exercise the map with real device long trips and antimeridian crossings to validate visuals and performance.
- Consider streaming very large exports to file to reduce memory spikes further if you expect multi-hour sessions with high-frequency points.
- Monitor for any regressions in watch/phone sync flows if those features are enabled.
Add this to `HistoryView.swift` to hide map button when no locations:
