import XCTest
@testable import TrackMe

/// Unit tests for LocationValidationConfig
/// Tests validate preset configurations and their appropriateness for different use cases
final class LocationValidationConfigTests: XCTestCase {
    
    // MARK: - Default Configuration Tests
    
    func testDefaultConfigurationValues() {
        // Given
        let config = LocationValidationConfig.default
        
        // Then - Verify all values match expected defaults
        XCTAssertEqual(config.maxHorizontalAccuracy, 50.0,
                      "Default config should allow 50m accuracy")
        XCTAssertEqual(config.maxReasonableSpeed, 69.0,
                      "Default config should allow ~250 km/h (69 m/s)")
        XCTAssertEqual(config.maxDistanceJump, 1000.0,
                      "Default config should allow 1km jumps")
        XCTAssertEqual(config.minTimeBetweenUpdates, 5.0,
                      "Default config should require 5s between updates")
        XCTAssertEqual(config.minDistanceBetweenPoints, 200.0,
                      "Default config should require 200m between points")
        XCTAssertTrue(config.adaptiveSampling,
                     "Default config should enable adaptive sampling")
    }
    
    func testDefaultConfigurationSuitableForLongTrips() {
        // Given
        let config = LocationValidationConfig.default
        
        // Then - Verify it's optimized for long trips
        // Should allow highway speeds
        XCTAssertGreaterThan(config.maxReasonableSpeed, 30.0,
                            "Should allow highway driving speeds")
        
        // Should filter enough to keep dataset manageable
        XCTAssertGreaterThan(config.minDistanceBetweenPoints ?? 0, 100.0,
                            "Should require significant distance between points")
        
        // Should allow some GPS variance
        XCTAssertGreaterThan(config.maxHorizontalAccuracy, 20.0,
                            "Should tolerate moderate GPS accuracy")
    }
    
    // MARK: - High Precision Configuration Tests
    
    func testHighPrecisionConfigurationValues() {
        // Given
        let config = LocationValidationConfig.highPrecision
        
        // Then
        XCTAssertEqual(config.maxHorizontalAccuracy, 20.0,
                      "High precision should require 20m accuracy")
        XCTAssertEqual(config.maxReasonableSpeed, 30.0,
                      "High precision should allow ~108 km/h (30 m/s)")
        XCTAssertEqual(config.maxDistanceJump, 500.0,
                      "High precision should allow 500m jumps")
        XCTAssertEqual(config.minTimeBetweenUpdates, 2.0,
                      "High precision should require 2s between updates")
        XCTAssertEqual(config.minDistanceBetweenPoints, 10.0,
                      "High precision should require 10m between points")
        XCTAssertFalse(config.adaptiveSampling,
                      "High precision should disable adaptive sampling for consistent detail")
    }
    
    func testHighPrecisionConfigurationSuitableForWalking() {
        // Given
        let config = LocationValidationConfig.highPrecision
        
        // Then - Verify it's optimized for walking/hiking
        // Should require high accuracy
        XCTAssertLessThan(config.maxHorizontalAccuracy, 30.0,
                         "Should require high GPS accuracy for walking")
        
        // Should capture detailed path
        XCTAssertLessThan(config.minDistanceBetweenPoints ?? Double.infinity, 20.0,
                         "Should capture points frequently for detailed path")
        
        // Should allow walking/jogging speeds but not highway speeds
        XCTAssertLessThan(config.maxReasonableSpeed, 40.0,
                         "Should not expect highway speeds")
        XCTAssertGreaterThan(config.maxReasonableSpeed, 10.0,
                            "Should allow jogging/running speeds")
    }
    
    func testHighPrecisionMoreStrictThanDefault() {
        // Given
        let highPrecision = LocationValidationConfig.highPrecision
        let defaultConfig = LocationValidationConfig.default
        
        // Then - High precision should be more restrictive
        XCTAssertLessThan(highPrecision.maxHorizontalAccuracy,
                         defaultConfig.maxHorizontalAccuracy,
                         "High precision should require better accuracy")
        XCTAssertLessThan(highPrecision.maxReasonableSpeed,
                         defaultConfig.maxReasonableSpeed,
                         "High precision should expect lower speeds")
        XCTAssertLessThan(highPrecision.minDistanceBetweenPoints ?? 0,
                         defaultConfig.minDistanceBetweenPoints ?? 0,
                         "High precision should capture points more frequently")
    }
    
    // MARK: - Efficient Configuration Tests
    
    func testEfficientConfigurationValues() {
        // Given
        let config = LocationValidationConfig.efficient
        
        // Then
        XCTAssertEqual(config.maxHorizontalAccuracy, 65.0,
                      "Efficient config should allow 65m accuracy")
        XCTAssertEqual(config.maxReasonableSpeed, 150.0,
                      "Efficient config should allow ~540 km/h (150 m/s) for flights")
        XCTAssertEqual(config.maxDistanceJump, 5000.0,
                      "Efficient config should allow 5km jumps")
        XCTAssertEqual(config.minTimeBetweenUpdates, 10.0,
                      "Efficient config should require 10s between updates")
        XCTAssertEqual(config.minDistanceBetweenPoints, 500.0,
                      "Efficient config should require 500m between points")
        XCTAssertTrue(config.adaptiveSampling,
                     "Efficient config should enable adaptive sampling")
    }
    
    func testEfficientConfigurationSuitableForLongDistanceTravel() {
        // Given
        let config = LocationValidationConfig.efficient
        
        // Then - Verify it's optimized for flights/very long trips
        // Should allow airplane speeds
        XCTAssertGreaterThan(config.maxReasonableSpeed, 100.0,
                            "Should allow airplane speeds")
        
        // Should minimize dataset size
        XCTAssertGreaterThan(config.minDistanceBetweenPoints ?? 0, 300.0,
                            "Should require large distance between points")
        XCTAssertGreaterThan(config.minTimeBetweenUpdates, 5.0,
                            "Should require longer time between updates")
        
        // Should allow larger GPS variance
        XCTAssertGreaterThan(config.maxHorizontalAccuracy, 50.0,
                            "Should tolerate moderate GPS accuracy")
    }
    
    func testEfficientLessStrictThanDefault() {
        // Given
        let efficient = LocationValidationConfig.efficient
        let defaultConfig = LocationValidationConfig.default
        
        // Then - Efficient should be more lenient
        XCTAssertGreaterThan(efficient.maxReasonableSpeed,
                            defaultConfig.maxReasonableSpeed,
                            "Efficient should allow higher speeds")
        XCTAssertGreaterThan(efficient.minDistanceBetweenPoints ?? 0,
                            defaultConfig.minDistanceBetweenPoints ?? 0,
                            "Efficient should capture points less frequently")
        XCTAssertGreaterThan(efficient.maxDistanceJump,
                            defaultConfig.maxDistanceJump,
                            "Efficient should allow larger jumps")
    }
    
    // MARK: - Permissive Configuration Tests
    
    func testPermissiveConfigurationValues() {
        // Given
        let config = LocationValidationConfig.permissive
        
        // Then
        XCTAssertEqual(config.maxHorizontalAccuracy, 100.0,
                      "Permissive config should allow 100m accuracy")
        XCTAssertEqual(config.maxReasonableSpeed, 150.0,
                      "Permissive config should allow ~540 km/h (150 m/s)")
        XCTAssertEqual(config.maxDistanceJump, 5000.0,
                      "Permissive config should allow 5km jumps")
        XCTAssertEqual(config.minTimeBetweenUpdates, 1.0,
                      "Permissive config should require only 1s between updates")
        XCTAssertNil(config.minDistanceBetweenPoints,
                    "Permissive config should have no distance filtering")
        XCTAssertFalse(config.adaptiveSampling,
                      "Permissive config should disable adaptive sampling")
    }
    
    func testPermissiveConfigurationCreatesLargeDatasets() {
        // Given
        let config = LocationValidationConfig.permissive
        
        // Then - Verify it will generate large datasets
        // No distance filtering means time-based only
        XCTAssertNil(config.minDistanceBetweenPoints,
                    "Should have no distance filtering")
        
        // Very frequent updates
        XCTAssertLessThanOrEqual(config.minTimeBetweenUpdates, 1.0,
                                "Should allow very frequent updates")
        
        // Most lenient accuracy requirements
        XCTAssertGreaterThanOrEqual(config.maxHorizontalAccuracy, 100.0,
                                   "Should be most lenient on accuracy")
    }
    
    func testPermissiveMostLenient() {
        // Given
        let permissive = LocationValidationConfig.permissive
        let defaultConfig = LocationValidationConfig.default
        let highPrecision = LocationValidationConfig.highPrecision
        let efficient = LocationValidationConfig.efficient
        
        // Then - Permissive should be most lenient on accuracy
        XCTAssertGreaterThanOrEqual(permissive.maxHorizontalAccuracy,
                                   defaultConfig.maxHorizontalAccuracy)
        XCTAssertGreaterThanOrEqual(permissive.maxHorizontalAccuracy,
                                   highPrecision.maxHorizontalAccuracy)
        XCTAssertGreaterThanOrEqual(permissive.maxHorizontalAccuracy,
                                   efficient.maxHorizontalAccuracy)
        
        // Should have shortest time between updates (most frequent)
        XCTAssertLessThanOrEqual(permissive.minTimeBetweenUpdates,
                                defaultConfig.minTimeBetweenUpdates)
        XCTAssertLessThanOrEqual(permissive.minTimeBetweenUpdates,
                                highPrecision.minTimeBetweenUpdates)
        XCTAssertLessThanOrEqual(permissive.minTimeBetweenUpdates,
                                efficient.minTimeBetweenUpdates)
    }
    
    // MARK: - Configuration Comparison Tests
    
    func testConfigurationsOrderedByDataVolume() {
        // Given
        let configs = [
            ("permissive", LocationValidationConfig.permissive),
            ("highPrecision", LocationValidationConfig.highPrecision),
            ("default", LocationValidationConfig.default),
            ("efficient", LocationValidationConfig.efficient)
        ]
        
        // Then - Verify expected data volume ordering
        // Permissive generates most data (shortest time, no distance filter)
        XCTAssertNil(configs[0].1.minDistanceBetweenPoints,
                    "Permissive should have no distance filter")
        
        // Efficient generates least data (longest time, largest distance)
        XCTAssertGreaterThan(configs[3].1.minDistanceBetweenPoints ?? 0,
                            configs[2].1.minDistanceBetweenPoints ?? 0,
                            "Efficient should require more distance than default")
    }
    
    func testConfigurationsOrderedBySpeed() {
        // Given - Sorted by max speed
        let configsBySpeed = [
            LocationValidationConfig.highPrecision,     // 30 m/s
            LocationValidationConfig.default,           // 69 m/s
            LocationValidationConfig.efficient,         // 150 m/s
            LocationValidationConfig.permissive         // 150 m/s
        ]
        
        // Then - Verify speed ordering
        for i in 0..<(configsBySpeed.count - 1) {
            XCTAssertLessThanOrEqual(
                configsBySpeed[i].maxReasonableSpeed,
                configsBySpeed[i + 1].maxReasonableSpeed,
                "Configs should be ordered by increasing max speed"
            )
        }
    }
    
    func testConfigurationsOrderedByAccuracy() {
        // Given - Sorted by accuracy requirement (stricter = lower value)
        let configsByAccuracy = [
            LocationValidationConfig.highPrecision,     // 20m
            LocationValidationConfig.default,           // 50m
            LocationValidationConfig.efficient,         // 65m
            LocationValidationConfig.permissive         // 100m
        ]
        
        // Then - Verify accuracy ordering
        for i in 0..<(configsByAccuracy.count - 1) {
            XCTAssertLessThan(
                configsByAccuracy[i].maxHorizontalAccuracy,
                configsByAccuracy[i + 1].maxHorizontalAccuracy,
                "Configs should be ordered by increasing (more lenient) accuracy threshold"
            )
        }
    }
    
    // MARK: - Threshold Reasonableness Tests
    
    func testAllConfigsHavePositiveValues() {
        // Given
        let configs = [
            LocationValidationConfig.default,
            LocationValidationConfig.highPrecision,
            LocationValidationConfig.efficient,
            LocationValidationConfig.permissive
        ]
        
        // Then - All non-nil values should be positive
        for config in configs {
            XCTAssertGreaterThan(config.maxHorizontalAccuracy, 0,
                                "Max horizontal accuracy must be positive")
            XCTAssertGreaterThan(config.maxReasonableSpeed, 0,
                                "Max reasonable speed must be positive")
            XCTAssertGreaterThan(config.maxDistanceJump, 0,
                                "Max distance jump must be positive")
            XCTAssertGreaterThan(config.minTimeBetweenUpdates, 0,
                                "Min time between updates must be positive")
            
            if let minDistance = config.minDistanceBetweenPoints {
                XCTAssertGreaterThan(minDistance, 0,
                                    "Min distance between points must be positive when set")
            }
        }
    }
    
    func testAccuracyThresholdsAreReasonable() {
        // Given
        let configs = [
            ("default", LocationValidationConfig.default),
            ("highPrecision", LocationValidationConfig.highPrecision),
            ("efficient", LocationValidationConfig.efficient),
            ("permissive", LocationValidationConfig.permissive)
        ]
        
        // Then - Accuracy should be within GPS capabilities
        for (name, config) in configs {
            XCTAssertGreaterThan(config.maxHorizontalAccuracy, 5.0,
                                "\(name): Should allow some GPS variance (>5m)")
            XCTAssertLessThan(config.maxHorizontalAccuracy, 200.0,
                             "\(name): Should not be too lenient (<200m)")
        }
    }
    
    func testSpeedThresholdsAreReasonable() {
        // Given
        let configs = [
            ("default", LocationValidationConfig.default),
            ("highPrecision", LocationValidationConfig.highPrecision),
            ("efficient", LocationValidationConfig.efficient),
            ("permissive", LocationValidationConfig.permissive)
        ]
        
        // Then - Speed should be within real-world possibilities
        for (name, config) in configs {
            // Should allow at least jogging speed (~5 m/s)
            XCTAssertGreaterThan(config.maxReasonableSpeed, 5.0,
                                "\(name): Should allow at least jogging speed")
            
            // Should not exceed commercial airplane speeds (~250 m/s)
            XCTAssertLessThan(config.maxReasonableSpeed, 250.0,
                             "\(name): Should not exceed airplane speeds")
        }
    }
    
    func testTimeIntervalsAreReasonable() {
        // Given
        let configs = [
            ("default", LocationValidationConfig.default),
            ("highPrecision", LocationValidationConfig.highPrecision),
            ("efficient", LocationValidationConfig.efficient),
            ("permissive", LocationValidationConfig.permissive)
        ]
        
        // Then - Time intervals should be practical
        for (name, config) in configs {
            // Should allow at least 1 update per minute
            XCTAssertLessThan(config.minTimeBetweenUpdates, 60.0,
                             "\(name): Should update at least once per minute")
            
            // Should require at least some time between updates
            XCTAssertGreaterThanOrEqual(config.minTimeBetweenUpdates, 1.0,
                                       "\(name): Should have minimum time between updates")
        }
    }
    
    func testDistanceThresholdsAreReasonable() {
        // Given
        let configs = [
            ("default", LocationValidationConfig.default),
            ("highPrecision", LocationValidationConfig.highPrecision),
            ("efficient", LocationValidationConfig.efficient)
            // Note: permissive has nil distance threshold
        ]
        
        // Then - Distance filters should be practical
        for (name, config) in configs {
            guard let minDistance = config.minDistanceBetweenPoints else { continue }
            
            // Should be at least GPS accuracy to avoid duplicate points
            XCTAssertGreaterThan(minDistance, 5.0,
                                "\(name): Should filter closer than GPS accuracy")
            
            // Should not be so large as to miss significant route details
            XCTAssertLessThan(minDistance, 1000.0,
                             "\(name): Should not filter out too much detail")
        }
    }
    
    // MARK: - Use Case Validation Tests
    
    func testDefaultConfigEstimatedDataPoints() {
        // Given - Default config for 350km trip
        let config = LocationValidationConfig.default
        let tripDistance = 350_000.0 // meters
        
        // When - Calculate approximate points if traveling at constant speed
        let expectedPoints = tripDistance / (config.minDistanceBetweenPoints ?? 1.0)
        
        // Then - Should be within documented range (700-1750 points)
        XCTAssertGreaterThanOrEqual(expectedPoints, 700.0 * 0.5,
                                   "Should generate reasonable number of points (lower bound)")
        XCTAssertLessThanOrEqual(expectedPoints, 1750.0 * 2.0,
                                "Should generate reasonable number of points (upper bound)")
    }
    
    func testHighPrecisionConfigEstimatedDataPoints() {
        // Given - High precision for 10km walk
        let config = LocationValidationConfig.highPrecision
        let walkDistance = 10_000.0 // meters
        
        // When - Calculate approximate points
        let expectedPoints = walkDistance / (config.minDistanceBetweenPoints ?? 1.0)
        
        // Then - Should generate detailed path (5000-10000 points range)
        XCTAssertGreaterThanOrEqual(expectedPoints, 500.0,
                                   "Should capture detailed walking path")
        XCTAssertLessThanOrEqual(expectedPoints, 10_000.0,
                                "Should not generate excessive points")
    }
    
    func testEfficientConfigEstimatedDataPoints() {
        // Given - Efficient config for 350km trip
        let config = LocationValidationConfig.efficient
        let tripDistance = 350_000.0 // meters
        
        // When - Calculate approximate points
        let expectedPoints = tripDistance / (config.minDistanceBetweenPoints ?? 1.0)
        
        // Then - Should be very efficient (350-700 points range)
        XCTAssertGreaterThanOrEqual(expectedPoints, 350.0 * 0.5,
                                   "Should generate minimum viable points")
        XCTAssertLessThanOrEqual(expectedPoints, 700.0 * 2.0,
                                "Should be efficient with data points")
    }
    
    // MARK: - Adaptive Sampling Tests
    
    func testAdaptiveSamplingConfigurationConsistency() {
        // Given
        let withAdaptive = [
            LocationValidationConfig.default,
            LocationValidationConfig.efficient
        ]
        let withoutAdaptive = [
            LocationValidationConfig.highPrecision,
            LocationValidationConfig.permissive
        ]
        
        // Then - Verify adaptive sampling is consistent with use case
        for config in withAdaptive {
            XCTAssertTrue(config.adaptiveSampling,
                         "Configs for varying speeds should use adaptive sampling")
        }
        
        for config in withoutAdaptive {
            XCTAssertFalse(config.adaptiveSampling,
                          "Configs for consistent detail or legacy should not use adaptive")
        }
    }
}
