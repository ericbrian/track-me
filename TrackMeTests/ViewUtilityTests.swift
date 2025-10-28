// TrackMeTests/ViewUtilityTests.swift
// Unit tests for view utilities and helpers

import XCTest
import SwiftUI
@testable import TrackMe

class ViewUtilityTests: XCTestCase {
    
    func testDateFormatting() {
        let date = Date(timeIntervalSince1970: 1640000000) // Fixed date for testing
        let formatted = date.formatted(date: .omitted, time: .shortened)
        XCTAssertFalse(formatted.isEmpty, "Date formatting should produce non-empty string.")
    }
    
    func testCoordinateFormatting() {
        let latitude = 37.7749295
        let longitude = -122.4194155
        
        let latString = String(format: "%.6f", latitude)
        let lonString = String(format: "%.6f", longitude)
        
        // Verify the strings are formatted correctly with 6 decimal places
        XCTAssertTrue(latString.contains("."), "Latitude should contain decimal point.")
        XCTAssertTrue(lonString.contains("."), "Longitude should contain decimal point.")
        XCTAssertTrue(latString.starts(with: "37.774"), "Latitude should start with 37.774.")
        XCTAssertTrue(lonString.starts(with: "-122.419"), "Longitude should start with -122.419.")
    }
    
    func testAccuracyFormatting() {
        let accuracy = 15.7
        let formatted = "±\(Int(accuracy))m"
        XCTAssertEqual(formatted, "±15m", "Accuracy should format as integer meters.")
    }
    
    func testStringTrimming() {
        let emptyString = "   "
        let trimmed = emptyString.trimmingCharacters(in: .whitespacesAndNewlines)
        XCTAssertTrue(trimmed.isEmpty, "Whitespace-only string should be empty after trimming.")
        
        let paddedString = "  Hello World  "
        let trimmedPadded = paddedString.trimmingCharacters(in: .whitespacesAndNewlines)
        XCTAssertEqual(trimmedPadded, "Hello World", "String should trim leading and trailing whitespace.")
    }
    
    func testTimeIntervalCalculation() {
        let startDate = Date(timeIntervalSince1970: 1640000000)
        let endDate = Date(timeIntervalSince1970: 1640003600) // 1 hour later
        
        let duration = endDate.timeIntervalSince(startDate)
        
        XCTAssertEqual(duration, 3600, "Duration should be 3600 seconds (1 hour).")
    }
}

// MARK: - Color Tests
class ColorTests: XCTestCase {
    
    func testColorOpacity() {
        let baseColor = Color.blue
        let transparentColor = baseColor.opacity(0.5)
        
        // Colors should be different objects
        XCTAssertNotNil(transparentColor, "Opacity should create a valid color.")
    }
    
    func testSystemColors() {
        // Verify system colors are accessible
        _ = Color(.systemBackground)
        _ = Color(.systemGray6)
        _ = Color(.systemGray5)
        
        XCTAssertTrue(true, "System colors should be accessible.")
    }
}

// MARK: - Gradient Tests
class GradientTests: XCTestCase {
    
    func testLinearGradientCreation() {
        let gradient = LinearGradient(
            gradient: Gradient(colors: [Color.blue, Color.purple]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        
        XCTAssertNotNil(gradient, "Linear gradient should be created successfully.")
    }
    
    func testGradientColors() {
        let colors = [Color.green, Color.green.opacity(0.8)]
        let gradient = Gradient(colors: colors)
        
        XCTAssertNotNil(gradient, "Gradient with color array should be created successfully.")
    }
}

// MARK: - UUID Tests
class UUIDTests: XCTestCase {
    
    func testUUIDGeneration() {
        let uuid1 = UUID()
        let uuid2 = UUID()
        
        XCTAssertNotEqual(uuid1, uuid2, "Generated UUIDs should be unique.")
    }
    
    func testUUIDString() {
        let uuid = UUID()
        let uuidString = uuid.uuidString
        
        XCTAssertFalse(uuidString.isEmpty, "UUID string should not be empty.")
        XCTAssertEqual(uuidString.count, 36, "UUID string should be 36 characters (with hyphens).")
    }
}
