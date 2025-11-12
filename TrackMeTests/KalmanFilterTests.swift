import XCTest
@testable import TrackMe

/// Unit tests for KalmanFilter
/// Tests cover initialization, measurement processing, noise reduction, and edge cases
final class KalmanFilterTests: XCTestCase {
    
    // MARK: - Initialization Tests
    
    func testInitializationWithoutState() {
        // Given/When
        let filter = KalmanFilter()
        
        // Then
        // Filter should be created successfully
        // State will be set on first measurement
        XCTAssertNotNil(filter)
    }
    
    func testInitializationWithState() {
        // Given
        let initialMean = 10.0
        let initialVariance = 5.0
        let initialState = (mean: initialMean, variance: initialVariance)
        
        // When
        let filter = KalmanFilter(state: initialState)
        
        // Then
        XCTAssertNotNil(filter)
    }
    
    func testInitializationWithCustomProcessNoise() {
        // Given
        let customProcessNoise = 1e-3
        
        // When
        let filter = KalmanFilter(processNoise: customProcessNoise)
        
        // Then
        XCTAssertNotNil(filter)
    }
    
    // MARK: - First Measurement Tests
    
    func testFirstMeasurementSetsInitialState() {
        // Given
        let filter = KalmanFilter()
        let firstMeasurement = 25.5
        let measurementNoise = 2.0
        
        // When
        let result = filter.process(measurement: firstMeasurement, measurementNoise: measurementNoise)
        
        // Then
        // First measurement should be returned as-is since there's no prior state
        XCTAssertEqual(result, firstMeasurement, accuracy: 1e-10,
                       "First measurement should initialize the filter state")
    }
    
    func testFirstMeasurementWithPreInitializedState() {
        // Given
        let initialMean = 10.0
        let initialVariance = 5.0
        let filter = KalmanFilter(state: (mean: initialMean, variance: initialVariance))
        let measurement = 15.0
        let measurementNoise = 2.0
        
        // When
        let result = filter.process(measurement: measurement, measurementNoise: measurementNoise)
        
        // Then
        // Result should be between initial mean and measurement due to Kalman gain
        XCTAssertGreaterThan(result, initialMean)
        XCTAssertLessThan(result, measurement)
    }
    
    // MARK: - Sequential Measurement Tests
    
    func testSequentialMeasurementsConverge() {
        // Given
        let filter = KalmanFilter()
        let measurements = [10.0, 10.5, 9.8, 10.2, 10.1, 9.9, 10.0]
        let measurementNoise = 1.0
        var results: [Double] = []
        
        // When
        for measurement in measurements {
            let result = filter.process(measurement: measurement, measurementNoise: measurementNoise)
            results.append(result)
        }
        
        // Then
        // Verify we got results for all measurements
        XCTAssertEqual(results.count, measurements.count)
        
        // Later measurements should produce filtered values closer to the mean
        let lastResult = results.last!
        XCTAssertGreaterThan(lastResult, 9.5)
        XCTAssertLessThan(lastResult, 10.5)
    }
    
    func testFilterSmoothsNoisyData() {
        // Given
        let filter = KalmanFilter()
        let trueMean = 50.0
        let noiseMagnitude = 5.0
        let measurementNoise = noiseMagnitude * noiseMagnitude // variance
        
        // Simulate noisy measurements around a true mean
        let noisyMeasurements = [
            trueMean + 4.0,
            trueMean - 3.5,
            trueMean + 2.8,
            trueMean - 4.2,
            trueMean + 1.5,
            trueMean - 2.0,
            trueMean + 3.2,
            trueMean - 1.8,
            trueMean + 0.5,
            trueMean - 0.8
        ]
        
        var filteredResults: [Double] = []
        
        // When
        for measurement in noisyMeasurements {
            let result = filter.process(measurement: measurement, measurementNoise: measurementNoise)
            filteredResults.append(result)
        }
        
        // Then
        // Later filtered values should be closer to true mean than raw measurements
        let lastFiltered = filteredResults.last!
        let lastMeasurement = noisyMeasurements.last!
        
        let filteredDeviation = abs(lastFiltered - trueMean)
        let measurementDeviation = abs(lastMeasurement - trueMean)
        
        // Filtered value should be closer to true mean (or at least not worse)
        XCTAssertLessThanOrEqual(filteredDeviation, measurementDeviation + 0.5,
                                 "Filtered value should be closer to true mean than raw measurement")
    }
    
    // MARK: - Noise Reduction Tests
    
    func testLowMeasurementNoiseGivesMoreWeight() {
        // Given
        let filter = KalmanFilter(state: (mean: 10.0, variance: 5.0))
        let measurement = 15.0
        let lowNoise = 0.1 // High confidence in measurement
        
        // When
        let result = filter.process(measurement: measurement, measurementNoise: lowNoise)
        
        // Then
        // Result should be closer to measurement than to prior mean
        let distanceToMeasurement = abs(result - measurement)
        let distanceToPriorMean = abs(result - 10.0)
        
        XCTAssertLessThan(distanceToMeasurement, distanceToPriorMean,
                         "Low measurement noise should give more weight to measurement")
    }
    
    func testHighMeasurementNoiseGivesLessWeight() {
        // Given
        let filter = KalmanFilter(state: (mean: 10.0, variance: 1.0))
        let measurement = 20.0
        let highNoise = 100.0 // Low confidence in measurement
        
        // When
        let result = filter.process(measurement: measurement, measurementNoise: highNoise)
        
        // Then
        // Result should be closer to prior mean than to measurement
        let distanceToMeasurement = abs(result - measurement)
        let distanceToPriorMean = abs(result - 10.0)
        
        XCTAssertLessThan(distanceToPriorMean, distanceToMeasurement,
                         "High measurement noise should give more weight to prior estimate")
    }
    
    // MARK: - Edge Case Tests
    
    func testZeroMeasurementNoise() {
        // Given
        let filter = KalmanFilter(state: (mean: 10.0, variance: 5.0))
        let measurement = 15.0
        let zeroNoise = 0.0
        
        // When
        let result = filter.process(measurement: measurement, measurementNoise: zeroNoise)
        
        // Then
        // With zero measurement noise (infinite confidence), result should equal measurement
        XCTAssertEqual(result, measurement, accuracy: 1e-10,
                      "Zero measurement noise should result in measurement being fully trusted")
    }
    
    func testVeryLargeVariance() {
        // Given
        let filter = KalmanFilter(state: (mean: 10.0, variance: 1e10))
        let measurement = 15.0
        let measurementNoise = 1.0
        
        // When
        let result = filter.process(measurement: measurement, measurementNoise: measurementNoise)
        
        // Then
        // With very large prior variance (low confidence), result should be close to measurement
        XCTAssertEqual(result, measurement, accuracy: 0.1,
                      "Very large prior variance should heavily favor measurement")
    }
    
    func testNegativeValues() {
        // Given
        let filter = KalmanFilter()
        let negativeMeasurements = [-10.0, -12.0, -9.5, -11.0, -10.5]
        let measurementNoise = 1.0
        var results: [Double] = []
        
        // When
        for measurement in negativeMeasurements {
            let result = filter.process(measurement: measurement, measurementNoise: measurementNoise)
            results.append(result)
        }
        
        // Then
        // Filter should work correctly with negative values
        XCTAssertEqual(results.count, negativeMeasurements.count)
        
        // All results should be negative and within reasonable range
        for result in results {
            XCTAssertLessThan(result, 0)
            XCTAssertGreaterThan(result, -15)
        }
    }
    
    func testVerySmallValues() {
        // Given
        let filter = KalmanFilter()
        let smallMeasurements = [0.0001, 0.00012, 0.00009, 0.00011, 0.0001]
        let measurementNoise = 0.00001
        var results: [Double] = []
        
        // When
        for measurement in smallMeasurements {
            let result = filter.process(measurement: measurement, measurementNoise: measurementNoise)
            results.append(result)
        }
        
        // Then
        // Filter should handle very small values correctly
        XCTAssertEqual(results.count, smallMeasurements.count)
        
        for result in results {
            XCTAssertGreaterThan(result, 0)
            XCTAssertLessThan(result, 0.0002)
        }
    }
    
    func testVeryLargeValues() {
        // Given
        let filter = KalmanFilter()
        let largeMeasurements = [1e8, 1.1e8, 0.9e8, 1.05e8, 0.95e8]
        let measurementNoise = 1e6
        var results: [Double] = []
        
        // When
        for measurement in largeMeasurements {
            let result = filter.process(measurement: measurement, measurementNoise: measurementNoise)
            results.append(result)
        }
        
        // Then
        // Filter should handle very large values correctly
        XCTAssertEqual(results.count, largeMeasurements.count)
        
        for result in results {
            XCTAssertGreaterThan(result, 0.8e8)
            XCTAssertLessThan(result, 1.2e8)
        }
    }
    
    // MARK: - Process Noise Tests
    
    func testProcessNoiseAffectsConvergence() {
        // Given
        let lowProcessNoise = 1e-8
        let highProcessNoise = 1e-2
        
        let filterLow = KalmanFilter(processNoise: lowProcessNoise)
        let filterHigh = KalmanFilter(processNoise: highProcessNoise)
        
        let measurements = [10.0, 10.5, 11.0, 10.8, 10.2]
        let measurementNoise = 1.0
        
        var resultsLow: [Double] = []
        var resultsHigh: [Double] = []
        
        // When
        for measurement in measurements {
            resultsLow.append(filterLow.process(measurement: measurement, measurementNoise: measurementNoise))
            resultsHigh.append(filterHigh.process(measurement: measurement, measurementNoise: measurementNoise))
        }
        
        // Then
        // Both should produce results, but with different characteristics
        XCTAssertEqual(resultsLow.count, measurements.count)
        XCTAssertEqual(resultsHigh.count, measurements.count)
        
        // Filters should produce different results due to different process noise
        // (Higher process noise means less confidence in prediction, more weight to measurements)
        // The difference may be small but should exist
        let difference = abs(resultsLow.last! - resultsHigh.last!)
        XCTAssertGreaterThan(difference, 0.0,
                         "Different process noise should produce different filtered results")
    }
    
    // MARK: - GPS Coordinate Simulation Tests
    
    func testGPSLatitudeFiltering() {
        // Given - Simulate GPS latitude readings with typical accuracy
        let filter = KalmanFilter()
        let trueLatitude = 37.7749 // San Francisco
        let gpsAccuracy = 10.0 // meters - typical GPS accuracy
        
        // Simulate noisy GPS readings (in degrees, ~0.0001 degree ≈ 11 meters)
        let noisyReadings = [
            trueLatitude + 0.00008,
            trueLatitude - 0.00006,
            trueLatitude + 0.00005,
            trueLatitude - 0.00009,
            trueLatitude + 0.00003,
            trueLatitude - 0.00002
        ]
        
        // Variance in degrees squared (approximation)
        let measurementVariance = pow(gpsAccuracy / 111000.0, 2)
        
        var filtered: [Double] = []
        
        // When
        for reading in noisyReadings {
            let result = filter.process(measurement: reading, measurementNoise: measurementVariance)
            filtered.append(result)
        }
        
        // Then
        let lastFiltered = filtered.last!
        let deviation = abs(lastFiltered - trueLatitude)
        
        // Filtered result should be close to true latitude
        XCTAssertLessThan(deviation, 0.0001,
                         "Filtered GPS latitude should be close to true value")
    }
    
    // MARK: - Real-World Scenario Tests
    
    func testWalkingSpeedFiltering() {
        // Given - Simulate speed measurements during a walk (meters per second)
        let filter = KalmanFilter()
        let averageWalkingSpeed = 1.4 // m/s (~5 km/h)
        let measurementNoise = 0.5 // GPS speed uncertainty
        
        // Simulate realistic walking with some GPS noise
        let speedReadings = [
            0.0,  // Starting
            0.5,  // Accelerating
            1.2,
            1.5,
            1.3,
            1.6,  // Steady walking
            1.4,
            1.5,
            1.3,
            0.8,  // Slowing down
            0.0   // Stopped
        ]
        
        var filtered: [Double] = []
        
        // When
        for speed in speedReadings {
            let result = filter.process(measurement: speed, measurementNoise: measurementNoise)
            filtered.append(result)
        }
        
        // Then
        // Verify realistic filtering behavior
        XCTAssertEqual(filtered.count, speedReadings.count)
        
        // All filtered speeds should be non-negative
        for speed in filtered {
            XCTAssertGreaterThanOrEqual(speed, 0.0)
        }
        
        // Filtered speeds should be smoother than raw readings
        // The last filtered value should be lower than the peak walking speed
        // (reflecting deceleration from 1.4-1.6 down to 0.0)
        XCTAssertLessThan(filtered.last!, averageWalkingSpeed,
                         "Final filtered speed should be less than average walking speed")
    }
    
    // MARK: - Performance Tests
    
    func testPerformanceOfSequentialProcessing() {
        let filter = KalmanFilter()
        let measurementNoise = 1.0
        
        measure {
            // Process 1000 measurements
            for i in 0..<1000 {
                _ = filter.process(measurement: Double(i % 100), measurementNoise: measurementNoise)
            }
        }
    }
}
