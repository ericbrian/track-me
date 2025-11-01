import CoreLocation

/// A simple Kalman filter for smoothing `CLLocation` data.
/// This helps to reduce noise from GPS readings.
class KalmanFilter {
    private var state: (mean: Double, variance: Double)?
    private let processNoise: Double
    
    /// Initializes a new Kalman filter.
    /// - Parameter state: The initial state (mean and variance). If nil, the first processed value will set the initial state.
    /// - Parameter processNoise: How much noise we expect in the process.
    init(state: (mean: Double, variance: Double)? = nil, processNoise: Double = 1e-5) {
        self.state = state
        self.processNoise = processNoise
    }
    
    /// Processes a new measurement and returns the filtered value.
    /// - Parameter measurement: The new value to process.
    /// - Parameter measurementNoise: The uncertainty of the measurement.
    /// - Returns: The filtered value.
    func process(measurement: Double, measurementNoise: Double) -> Double {
        if let currentState = state {
            // Prediction update
            let predictedMean = currentState.mean
            let predictedVariance = currentState.variance + processNoise
            
            // Measurement update
            let kalmanGain = predictedVariance / (predictedVariance + measurementNoise)
            let newMean = predictedMean + kalmanGain * (measurement - predictedMean)
            let newVariance = (1 - kalmanGain) * predictedVariance
            
            self.state = (mean: newMean, variance: newVariance)
            return newMean
        } else {
            // If this is the first measurement, initialize the state
            self.state = (mean: measurement, variance: measurementNoise)
            return measurement
        }
    }
}
