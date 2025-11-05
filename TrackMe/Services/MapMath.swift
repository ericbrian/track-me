import Foundation
import MapKit

/// Utility math helpers for map rendering and geometry.
enum MapMath {
    /// Compute a region that fits all provided coordinates with padding, handling antimeridian crossing.
    /// - Parameters:
    ///   - coords: Coordinates to fit.
    ///   - minSpan: Minimum span in degrees for both latitude and longitude.
    ///   - paddingScale: Multiplier to add some padding around the fitted bounds.
    /// - Returns: MKCoordinateRegion covering the coordinates.
    static func computeRegion(
        for coords: [CLLocationCoordinate2D],
        minSpan: Double = 0.01,
        paddingScale: Double = 1.2
    ) -> MKCoordinateRegion {
        guard !coords.isEmpty else {
            return MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: 0, longitude: 0),
                span: MKCoordinateSpan(latitudeDelta: 100, longitudeDelta: 100)
            )
        }

        // Latitudes are simple
        let lats = coords.map { $0.latitude }
        let minLat = lats.min() ?? 0
        let maxLat = lats.max() ?? 0

        // Handle longitudes possibly crossing the antimeridian.
        let lons = coords.map { $0.longitude }

        // Strategy: compute two spans — normal [-180,180] and unwrapped where we add 360 to negatives — choose the smaller span.
        let normalMinLon = lons.min() ?? 0
        let normalMaxLon = lons.max() ?? 0
        let normalSpanLon = normalMaxLon - normalMinLon

        let unwrappedLons = lons.map { $0 < 0 ? $0 + 360.0 : $0 }
        let unwrapMinLon = unwrappedLons.min() ?? 0
        let unwrapMaxLon = unwrappedLons.max() ?? 0
        let unwrapSpanLon = unwrapMaxLon - unwrapMinLon

        let useUnwrapped = unwrapSpanLon < normalSpanLon

        let (minLonUsed, maxLonUsed): (Double, Double) = useUnwrapped ? (unwrapMinLon, unwrapMaxLon) : (normalMinLon, normalMaxLon)
        var centerLon = (minLonUsed + maxLonUsed) / 2.0
        if useUnwrapped {
            // Bring center back into [-180, 180]
            if centerLon > 180 { centerLon -= 360 }
        }

        let centerLat = (minLat + maxLat) / 2.0
        let spanLat = max(maxLat - minLat, minSpan) * paddingScale

        let rawSpanLon = max((maxLonUsed - minLonUsed), minSpan) * paddingScale
        // Clamp longitude span to a reasonable maximum to avoid zooming out to the whole world due to outliers
        let spanLon = min(rawSpanLon, 350) // never more than almost the full wrap

        let center = CLLocationCoordinate2D(latitude: centerLat, longitude: centerLon)
        let span = MKCoordinateSpan(latitudeDelta: spanLat, longitudeDelta: spanLon)
        return MKCoordinateRegion(center: center, span: span)
    }

    /// Split a sequence of coordinates into segments when crossing the antimeridian (|deltaLon| > 180).
    /// This avoids drawing a long line across the map.
    /// - Parameter coords: Source coordinates in [-90..90], [-180..180]
    /// - Returns: Array of coordinate segments, each safe to render as a polyline.
    static func splitSegmentsAcrossAntimeridian(_ coords: [CLLocationCoordinate2D]) -> [[CLLocationCoordinate2D]] {
        guard coords.count >= 2 else { return coords.isEmpty ? [] : [coords] }

        var segments: [[CLLocationCoordinate2D]] = []
        var current: [CLLocationCoordinate2D] = [coords[0]]

        for i in 1..<coords.count {
            let prev = coords[i - 1]
            let next = coords[i]
            let dLon = abs(next.longitude - prev.longitude)
            if dLon > 180 { // crossing the antimeridian
                // end current segment, and start a new one with the current point
                current.append(next) // add the crossing point to finish this segment
                if current.count >= 2 { segments.append(current) }
                current = [next] // start new segment with the same point
            } else {
                current.append(next)
            }
        }
        if current.count >= 2 { segments.append(current) }
        return segments
    }
}
