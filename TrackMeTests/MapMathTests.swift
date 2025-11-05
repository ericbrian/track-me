import XCTest
import MapKit
@testable import TrackMe

final class MapMathTests: XCTestCase {
    func testComputeRegionAcrossAntimeridianSmallSpan() {
        // Points near +179 and -179 longitude should produce a small longitudinal span
        let coords = [
            CLLocationCoordinate2D(latitude: 10.0, longitude: 179.0),
            CLLocationCoordinate2D(latitude: 11.0, longitude: -179.0)
        ]
        let region = MapMath.computeRegion(for: coords, minSpan: 0.01, paddingScale: 1.2)
        XCTAssertLessThan(region.span.longitudeDelta, 10.0, "Span should be small across antimeridian, not ~358°")
        XCTAssertTrue(CLLocationCoordinate2DIsValid(region.center))
    }

    func testSplitSegmentsAcrossAntimeridian() {
        let coords = [
            CLLocationCoordinate2D(latitude: 0, longitude: 179.5),
            CLLocationCoordinate2D(latitude: 0.1, longitude: -179.5), // cross
            CLLocationCoordinate2D(latitude: 0.2, longitude: -179.4)
        ]

        let segments = MapMath.splitSegmentsAcrossAntimeridian(coords)
        XCTAssertEqual(segments.count, 2, "Should split into two segments when crossing antimeridian")
        XCTAssertGreaterThanOrEqual(segments[0].count, 2)
        XCTAssertGreaterThanOrEqual(segments[1].count, 2)
    }

    func testComputeRegionEmptyDefaults() {
        let region = MapMath.computeRegion(for: [])
        XCTAssertEqual(region.center.latitude, 0, accuracy: 0.0001)
        XCTAssertEqual(region.center.longitude, 0, accuracy: 0.0001)
        XCTAssertGreaterThan(region.span.latitudeDelta, 0)
        XCTAssertGreaterThan(region.span.longitudeDelta, 0)
    }
}
