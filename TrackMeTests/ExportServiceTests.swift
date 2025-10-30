// TrackMeTests/ExportServiceTests.swift
// Comprehensive unit tests for ExportService

import XCTest
import CoreLocation
import CoreData
@testable import TrackMe

class ExportServiceTests: XCTestCase {
    var exportService: ExportService!
    var persistenceController: PersistenceController!
    var testSession: TrackingSession!
    var testLocations: [LocationEntry]!
    
    override func setUp() {
        super.setUp()
        exportService = ExportService.shared
        persistenceController = PersistenceController(inMemory: true)
        
        // Create test session and locations
        let context = persistenceController.container.viewContext
        testSession = TrackingSession(context: context)
        testSession.id = UUID()
        testSession.narrative = "Test Export Session"
        testSession.startDate = Date(timeIntervalSince1970: 1640000000)
        testSession.endDate = Date(timeIntervalSince1970: 1640003600)
        testSession.isActive = false
        
        testLocations = []
        for i in 0..<5 {
            let location = LocationEntry(context: context)
            location.id = UUID()
            location.latitude = 37.7749 + Double(i) * 0.001
            location.longitude = -122.4194 + Double(i) * 0.001
            location.altitude = 100.0 + Double(i) * 10.0
            location.speed = 5.0 + Double(i)
            location.course = Double(i) * 45.0
            location.accuracy = 10.0
            location.timestamp = Date(timeIntervalSince1970: 1640000000 + TimeInterval(i * 60))
            location.session = testSession
            testLocations.append(location)
        }
        
        try? context.save()
    }
    
    override func tearDown() {
        testLocations = nil
        testSession = nil
        persistenceController = nil
        exportService = nil
        super.tearDown()
    }
    
    // MARK: - GPX Export Tests
    
    func testExportToGPX() {
        let gpx = exportService.exportToGPX(session: testSession, locations: testLocations)
        
        XCTAssertTrue(gpx.contains("<?xml version=\"1.0\" encoding=\"UTF-8\"?>"), "GPX should have XML header")
        XCTAssertTrue(gpx.contains("<gpx version=\"1.1\""), "GPX should have GPX version")
        XCTAssertTrue(gpx.contains("<metadata>"), "GPX should have metadata")
        XCTAssertTrue(gpx.contains("<name>Test Export Session</name>"), "GPX should contain session name")
        XCTAssertTrue(gpx.contains("<trk>"), "GPX should have track element")
        XCTAssertTrue(gpx.contains("<trkpt"), "GPX should have track points")
        XCTAssertTrue(gpx.contains("lat=\"37.7749\""), "GPX should have correct latitude")
        XCTAssertTrue(gpx.contains("lon=\"-122.4194\""), "GPX should have correct longitude")
        XCTAssertTrue(gpx.contains("<ele>"), "GPX should have elevation data")
        XCTAssertTrue(gpx.contains("<time>"), "GPX should have timestamp data")
    }
    
    func testGPXStructure() {
        let gpx = exportService.exportToGPX(session: testSession, locations: testLocations)
        
        // Count track points
        let trkptCount = gpx.components(separatedBy: "<trkpt").count - 1
        XCTAssertEqual(trkptCount, testLocations.count, "GPX should have correct number of track points")
        
        // Verify closing tags
        XCTAssertTrue(gpx.contains("</gpx>"), "GPX should be properly closed")
        XCTAssertTrue(gpx.contains("</trk>"), "Track should be properly closed")
        XCTAssertTrue(gpx.contains("</trkseg>"), "Track segment should be properly closed")
    }
    
    func testGPXWithEmptyLocations() {
        let gpx = exportService.exportToGPX(session: testSession, locations: [])
        
        XCTAssertTrue(gpx.contains("<gpx"), "GPX should be valid even with no locations")
        XCTAssertTrue(gpx.contains("<trk>"), "GPX should have track element")
        XCTAssertTrue(gpx.contains("</gpx>"), "GPX should be properly closed")
    }
    
    // MARK: - KML Export Tests
    
    func testExportToKML() {
        let kml = exportService.exportToKML(session: testSession, locations: testLocations)
        
        XCTAssertTrue(kml.contains("<?xml version=\"1.0\" encoding=\"UTF-8\"?>"), "KML should have XML header")
        XCTAssertTrue(kml.contains("<kml xmlns=\"http://www.opengis.net/kml/2.2\">"), "KML should have KML namespace")
        XCTAssertTrue(kml.contains("<Document>"), "KML should have Document element")
        XCTAssertTrue(kml.contains("<name>Test Export Session</name>"), "KML should contain session name")
        XCTAssertTrue(kml.contains("<Style id=\"trackStyle\">"), "KML should have style definition")
        XCTAssertTrue(kml.contains("<Placemark>"), "KML should have placemark")
        XCTAssertTrue(kml.contains("<LineString>"), "KML should have LineString")
        XCTAssertTrue(kml.contains("<coordinates>"), "KML should have coordinates")
    }
    
    func testKMLCoordinateFormat() {
        let kml = exportService.exportToKML(session: testSession, locations: testLocations)
        
        // KML uses lon,lat,altitude format
        XCTAssertTrue(kml.contains("-122.4194,37.7749,100"), "KML should have coordinates in lon,lat,alt format")
        
        // Verify all locations are included
        for location in testLocations {
            let coordString = "\(location.longitude),\(location.latitude)"
            XCTAssertTrue(kml.contains(coordString), "KML should contain all location coordinates")
        }
    }
    
    func testKMLStructure() {
        let kml = exportService.exportToKML(session: testSession, locations: testLocations)
        
        XCTAssertTrue(kml.contains("</kml>"), "KML should be properly closed")
        XCTAssertTrue(kml.contains("</Document>"), "Document should be properly closed")
        XCTAssertTrue(kml.contains("</Placemark>"), "Placemark should be properly closed")
        XCTAssertTrue(kml.contains("</LineString>"), "LineString should be properly closed")
    }
    
    // MARK: - CSV Export Tests
    
    func testExportToCSV() {
        let csv = exportService.exportToCSV(session: testSession, locations: testLocations)
        
        XCTAssertTrue(csv.contains("Latitude,Longitude,Altitude,Speed,Course,Accuracy,Timestamp"), 
                     "CSV should have header row")
        
        let lines = csv.components(separatedBy: "\n").filter { !$0.isEmpty }
        XCTAssertEqual(lines.count, testLocations.count + 1, "CSV should have header + data rows")
    }
    
    func testCSVDataFormat() {
        let csv = exportService.exportToCSV(session: testSession, locations: testLocations)
        
        // Check first location is present
        XCTAssertTrue(csv.contains("37.7749"), "CSV should contain latitude data")
        XCTAssertTrue(csv.contains("-122.4194"), "CSV should contain longitude data")
        XCTAssertTrue(csv.contains("100.0"), "CSV should contain altitude data")
        XCTAssertTrue(csv.contains("10.0"), "CSV should contain accuracy data")
    }
    
    func testCSVWithSpecialCharacters() {
        let context = persistenceController.container.viewContext
        let specialSession = TrackingSession(context: context)
        specialSession.id = UUID()
        specialSession.narrative = "Test with \"quotes\" and, commas"
        specialSession.startDate = Date()
        
        let csv = exportService.exportToCSV(session: specialSession, locations: testLocations)
        XCTAssertFalse(csv.isEmpty, "CSV should handle special characters")
    }
    
    // MARK: - GeoJSON Export Tests
    
    func testExportToGeoJSON() {
        let geojson = exportService.exportToGeoJSON(session: testSession, locations: testLocations)
        
        XCTAssertTrue(geojson.contains("\"type\": \"Feature\""), "GeoJSON should have Feature type")
        XCTAssertTrue(geojson.contains("\"properties\""), "GeoJSON should have properties")
        XCTAssertTrue(geojson.contains("\"geometry\""), "GeoJSON should have geometry")
        XCTAssertTrue(geojson.contains("\"type\": \"LineString\""), "GeoJSON should have LineString type")
        XCTAssertTrue(geojson.contains("\"coordinates\""), "GeoJSON should have coordinates array")
        XCTAssertTrue(geojson.contains("Test Export Session"), "GeoJSON should contain session name")
    }
    
    func testGeoJSONCoordinateFormat() {
        let geojson = exportService.exportToGeoJSON(session: testSession, locations: testLocations)
        
        // GeoJSON uses [longitude, latitude, altitude] format
        XCTAssertTrue(geojson.contains("[-122.4194, 37.7749, 100"), "GeoJSON should have coordinates in [lon, lat, alt] format")
    }
    
    func testGeoJSONValidity() {
        let geojson = exportService.exportToGeoJSON(session: testSession, locations: testLocations)
        
        // Try to parse as JSON
        if let jsonData = geojson.data(using: .utf8) {
            XCTAssertNoThrow(try JSONSerialization.jsonObject(with: jsonData), "GeoJSON should be valid JSON")
            
            if let json = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any] {
                XCTAssertNotNil(json["type"], "GeoJSON should have type field")
                XCTAssertNotNil(json["properties"], "GeoJSON should have properties field")
                XCTAssertNotNil(json["geometry"], "GeoJSON should have geometry field")
            }
        }
    }
    
    // MARK: - Filename Generation Tests
    
    func testGenerateFilenameGPX() {
        let filename = exportService.generateFilename(session: testSession, format: .gpx)
        
        XCTAssertTrue(filename.contains("TrackMe_"), "Filename should start with TrackMe_")
        XCTAssertTrue(filename.contains(".gpx"), "Filename should have .gpx extension")
        XCTAssertTrue(filename.contains("Test_Export_Session"), "Filename should contain sanitized narrative")
    }
    
    func testGenerateFilenameKML() {
        let filename = exportService.generateFilename(session: testSession, format: .kml)
        XCTAssertTrue(filename.hasSuffix(".kml"), "Filename should have .kml extension")
    }
    
    func testGenerateFilenameCSV() {
        let filename = exportService.generateFilename(session: testSession, format: .csv)
        XCTAssertTrue(filename.hasSuffix(".csv"), "Filename should have .csv extension")
    }
    
    func testGenerateFilenameGeoJSON() {
        let filename = exportService.generateFilename(session: testSession, format: .geojson)
        XCTAssertTrue(filename.hasSuffix(".geojson"), "Filename should have .geojson extension")
    }
    
    func testFilenameSanitization() {
        let context = persistenceController.container.viewContext
        let sessionWithSpecialChars = TrackingSession(context: context)
        sessionWithSpecialChars.id = UUID()
        sessionWithSpecialChars.narrative = "Test / With Special: Characters?"
        sessionWithSpecialChars.startDate = Date()
        
        let filename = exportService.generateFilename(session: sessionWithSpecialChars, format: .gpx)
        
        XCTAssertFalse(filename.contains("/"), "Filename should not contain forward slashes")
        XCTAssertTrue(filename.hasSuffix(".gpx"), "Filename should have .gpx extension")
        // Verify the filename is valid and contains sanitized narrative
        XCTAssertTrue(filename.contains("_"), "Filename should contain underscores as separators")
    }
    
    func testFilenameLengthLimit() {
        let context = persistenceController.container.viewContext
        let sessionWithLongNarrative = TrackingSession(context: context)
        sessionWithLongNarrative.id = UUID()
        sessionWithLongNarrative.narrative = String(repeating: "a", count: 100)
        sessionWithLongNarrative.startDate = Date()
        
        let filename = exportService.generateFilename(session: sessionWithLongNarrative, format: .gpx)
        
        // Narrative should be truncated to 30 characters
        let narrativePart = filename.components(separatedBy: "_")[1]
        XCTAssertLessThanOrEqual(narrativePart.count, 30, "Narrative in filename should be limited to 30 characters")
    }
    
    // MARK: - File Saving Tests
    
    func testSaveToTemporaryFile() {
        let content = "Test content"
        let filename = "test_file.txt"
        
        let fileURL = exportService.saveToTemporaryFile(content: content, filename: filename)
        
        XCTAssertNotNil(fileURL, "File URL should not be nil")
        
        if let fileURL = fileURL {
            XCTAssertTrue(FileManager.default.fileExists(atPath: fileURL.path), "File should exist")
            
            // Read content back
            let readContent = try? String(contentsOf: fileURL, encoding: .utf8)
            XCTAssertEqual(readContent, content, "File content should match")
            
            // Clean up
            try? FileManager.default.removeItem(at: fileURL)
        }
    }
    
    func testSaveEmptyContent() {
        let content = ""
        let filename = "empty_file.txt"
        
        let fileURL = exportService.saveToTemporaryFile(content: content, filename: filename)
        
        XCTAssertNotNil(fileURL, "Should be able to save empty file")
        
        if let fileURL = fileURL {
            XCTAssertTrue(FileManager.default.fileExists(atPath: fileURL.path), "Empty file should exist")
            try? FileManager.default.removeItem(at: fileURL)
        }
    }
    
    func testSaveLargeContent() {
        let largeContent = String(repeating: "Large data content ", count: 10000)
        let filename = "large_file.txt"
        
        let fileURL = exportService.saveToTemporaryFile(content: largeContent, filename: filename)
        
        XCTAssertNotNil(fileURL, "Should be able to save large file")
        
        if let fileURL = fileURL {
            XCTAssertTrue(FileManager.default.fileExists(atPath: fileURL.path), "Large file should exist")
            
            let attributes = try? FileManager.default.attributesOfItem(atPath: fileURL.path)
            let fileSize = attributes?[.size] as? Int64 ?? 0
            XCTAssertGreaterThan(fileSize, 0, "Large file should have non-zero size")
            
            try? FileManager.default.removeItem(at: fileURL)
        }
    }
    
    // MARK: - Export Format Tests
    
    func testAllExportFormats() {
        for format in ExportFormat.allCases {
            let filename = exportService.generateFilename(session: testSession, format: format)
            XCTAssertTrue(filename.hasSuffix(format.fileExtension), "Filename should have correct extension for \(format.rawValue)")
        }
    }
    
    func testExportFormatDescriptions() {
        XCTAssertEqual(ExportFormat.gpx.description, "GPS Exchange Format (Universal)")
        XCTAssertEqual(ExportFormat.kml.description, "Keyhole Markup Language (Google Earth)")
        XCTAssertEqual(ExportFormat.csv.description, "Comma-Separated Values (Spreadsheet)")
        XCTAssertEqual(ExportFormat.geojson.description, "GeoJSON (Web/Developer)")
    }
    
    func testExportFormatExtensions() {
        XCTAssertEqual(ExportFormat.gpx.fileExtension, "gpx")
        XCTAssertEqual(ExportFormat.kml.fileExtension, "kml")
        XCTAssertEqual(ExportFormat.csv.fileExtension, "csv")
        XCTAssertEqual(ExportFormat.geojson.fileExtension, "geojson")
    }
    
    // MARK: - Edge Case Tests
    
    func testExportWithNilNarrative() {
        testSession.narrative = nil
        
        let gpx = exportService.exportToGPX(session: testSession, locations: testLocations)
        XCTAssertTrue(gpx.contains("Tracking Session"), "Should use default narrative when nil")
        
        let filename = exportService.generateFilename(session: testSession, format: .gpx)
        XCTAssertTrue(filename.contains("session"), "Should use default in filename when narrative is nil")
    }
    
    func testExportWithSingleLocation() {
        let singleLocation = [testLocations.first!]
        
        let gpx = exportService.exportToGPX(session: testSession, locations: singleLocation)
        let trkptCount = gpx.components(separatedBy: "<trkpt").count - 1
        XCTAssertEqual(trkptCount, 1, "Should export single location correctly")
    }
    
    func testExportWithZeroAltitude() {
        testLocations.forEach { $0.altitude = 0 }
        
        let kml = exportService.exportToKML(session: testSession, locations: testLocations)
        // Check that coordinates are present with zero altitude
        XCTAssertTrue(kml.contains("<coordinates>"), "KML should have coordinates section")
        XCTAssertTrue(kml.contains(",0"), "Should handle zero altitude correctly")
    }
    
    func testExportPerformance() {
        // Create many locations
        let context = persistenceController.container.viewContext
        var manyLocations: [LocationEntry] = []
        
        for i in 0..<1000 {
            let location = LocationEntry(context: context)
            location.id = UUID()
            location.latitude = 37.7749 + Double(i) * 0.0001
            location.longitude = -122.4194 + Double(i) * 0.0001
            location.altitude = 100.0
            location.timestamp = Date()
            manyLocations.append(location)
        }
        
        measure {
            _ = exportService.exportToGPX(session: testSession, locations: manyLocations)
        }
    }
}

// MARK: - Export Error Handling Tests

class ExportServiceErrorHandlingTests: XCTestCase {
    var exportService: ExportService!
    var persistenceController: PersistenceController!
    var testSession: TrackingSession!
    var testLocations: [LocationEntry]!
    
    override func setUp() {
        super.setUp()
        exportService = ExportService.shared
        persistenceController = PersistenceController(inMemory: true)
        
        let context = persistenceController.container.viewContext
        testSession = TrackingSession(context: context)
        testSession.id = UUID()
        testSession.narrative = "Error Test Session"
        testSession.startDate = Date()
        testSession.endDate = Date().addingTimeInterval(3600)
        
        testLocations = []
        for i in 0..<5 {
            let location = LocationEntry(context: context)
            location.id = UUID()
            location.latitude = 37.7749 + Double(i) * 0.001
            location.longitude = -122.4194
            location.timestamp = Date()
            location.session = testSession
            testLocations.append(location)
        }
        
        try? context.save()
    }
    
    override func tearDown() {
        testLocations = nil
        testSession = nil
        persistenceController = nil
        exportService = nil
        super.tearDown()
    }
    
    // MARK: - File Write Error Tests
    
    func testSaveToInvalidPath() {
        // Try to save to a path that doesn't exist (without creating directories)
        let invalidURL = URL(fileURLWithPath: "/nonexistent/directory/that/does/not/exist/test.gpx")
        let content = "Test content"
        
        do {
            try content.write(to: invalidURL, atomically: true, encoding: .utf8)
            XCTFail("Should have thrown an error for invalid path")
        } catch {
            // Expected to fail
            XCTAssertNotNil(error)
        }
    }
    
    func testSaveToReadOnlyDirectory() {
        // Test attempting to save to a read-only location
        // This simulates permission denied scenarios
        let readOnlyPath = "/System/test_file.gpx"
        let readOnlyURL = URL(fileURLWithPath: readOnlyPath)
        let content = "Test content"
        
        do {
            try content.write(to: readOnlyURL, atomically: true, encoding: .utf8)
            XCTFail("Should have thrown an error for read-only directory")
        } catch {
            // Expected to fail due to permissions
            XCTAssertNotNil(error)
        }
    }
    
    func testSaveWithNilContentReturnsURL() {
        // Empty content should still save successfully
        let content = ""
        let filename = "empty_test.gpx"
        
        let fileURL = exportService.saveToTemporaryFile(content: content, filename: filename)
        
        XCTAssertNotNil(fileURL, "Should be able to save empty content")
        
        // Clean up
        if let url = fileURL {
            try? FileManager.default.removeItem(at: url)
        }
    }
    
    func testSaveToTemporaryDirectorySuccess() {
        let content = exportService.exportToGPX(session: testSession, locations: testLocations)
        let filename = "test_success.gpx"
        
        let fileURL = exportService.saveToTemporaryFile(content: content, filename: filename)
        
        XCTAssertNotNil(fileURL, "Should successfully save to temporary directory")
        
        if let url = fileURL {
            XCTAssertTrue(FileManager.default.fileExists(atPath: url.path))
            
            // Verify content
            let readContent = try? String(contentsOf: url, encoding: .utf8)
            XCTAssertEqual(readContent, content)
            
            // Clean up
            try? FileManager.default.removeItem(at: url)
        }
    }
    
    // MARK: - Large File Handling Tests
    
    func testExportVeryLargeDataset() {
        // Create a very large dataset (10,000 locations)
        let context = persistenceController.container.viewContext
        var largeLocationSet: [LocationEntry] = []
        
        for i in 0..<10000 {
            let location = LocationEntry(context: context)
            location.id = UUID()
            location.latitude = 37.7749 + Double(i) * 0.0001
            location.longitude = -122.4194 + Double(i) * 0.0001
            location.altitude = 100.0 + Double(i)
            location.speed = 5.0 + Double(i % 100)
            location.timestamp = Date().addingTimeInterval(TimeInterval(i))
            largeLocationSet.append(location)
        }
        
        // Test GPX export with large dataset
        let gpx = exportService.exportToGPX(session: testSession, locations: largeLocationSet)
        
        XCTAssertFalse(gpx.isEmpty)
        XCTAssertGreaterThan(gpx.count, 100000) // Should be a large string
        
        // Test that it can be saved
        let filename = exportService.generateFilename(session: testSession, format: .gpx)
        let fileURL = exportService.saveToTemporaryFile(content: gpx, filename: filename)
        
        XCTAssertNotNil(fileURL, "Should be able to save large dataset")
        
        // Clean up
        if let url = fileURL {
            let attributes = try? FileManager.default.attributesOfItem(atPath: url.path)
            let fileSize = attributes?[.size] as? Int64 ?? 0
            XCTAssertGreaterThan(fileSize, 100000, "Large file should have significant size")
            
            try? FileManager.default.removeItem(at: url)
        }
    }
    
    func testExportMemoryEfficiency() {
        // Test that export doesn't cause memory issues with moderate dataset
        let context = persistenceController.container.viewContext
        var locations: [LocationEntry] = []
        
        for i in 0..<5000 {
            let location = LocationEntry(context: context)
            location.id = UUID()
            location.latitude = 37.7749 + Double(i) * 0.0001
            location.longitude = -122.4194
            location.timestamp = Date()
            locations.append(location)
        }
        
        // Export in all formats to test memory usage
        _ = exportService.exportToGPX(session: testSession, locations: locations)
        _ = exportService.exportToKML(session: testSession, locations: locations)
        _ = exportService.exportToCSV(session: testSession, locations: locations)
        _ = exportService.exportToGeoJSON(session: testSession, locations: locations)
        
        // If we get here without crashing, memory handling is adequate
        XCTAssertTrue(true)
    }
    
    // MARK: - Invalid Data Handling Tests
    
    func testExportWithInvalidCoordinates() {
        let context = persistenceController.container.viewContext
        let location = LocationEntry(context: context)
        location.id = UUID()
        location.latitude = 9999.0 // Invalid latitude
        location.longitude = 9999.0 // Invalid longitude
        location.timestamp = Date()
        
        let gpx = exportService.exportToGPX(session: testSession, locations: [location])
        
        // Should still generate valid XML structure
        XCTAssertTrue(gpx.contains("<?xml"))
        XCTAssertTrue(gpx.contains("<gpx"))
        XCTAssertTrue(gpx.contains("9999.0")) // Invalid coords should still be exported
    }
    
    func testExportWithNegativeAltitude() {
        let context = persistenceController.container.viewContext
        let location = LocationEntry(context: context)
        location.id = UUID()
        location.latitude = 37.7749
        location.longitude = -122.4194
        location.altitude = -100.0 // Below sea level
        location.timestamp = Date()
        
        let kml = exportService.exportToKML(session: testSession, locations: [location])
        
        XCTAssertTrue(kml.contains("-100"))
        XCTAssertTrue(kml.contains("<coordinates>"))
    }
    
    func testExportWithExtremeValues() {
        let context = persistenceController.container.viewContext
        let location = LocationEntry(context: context)
        location.id = UUID()
        location.latitude = 89.9999 // Near north pole
        location.longitude = 179.9999 // Near date line
        location.altitude = 8848.0 // Mt. Everest height
        location.speed = 300.0 // Very fast (m/s)
        location.accuracy = 0.1 // Very accurate
        location.timestamp = Date()
        
        let csv = exportService.exportToCSV(session: testSession, locations: [location])
        
        XCTAssertTrue(csv.contains("89.9999"))
        XCTAssertTrue(csv.contains("179.9999"))
        XCTAssertTrue(csv.contains("8848"))
        XCTAssertTrue(csv.contains("300"))
    }
    
    // MARK: - Concurrent Export Tests
    
    func testConcurrentExports() {
        let expectation = XCTestExpectation(description: "Concurrent exports complete")
        expectation.expectedFulfillmentCount = 4
        
        let queue = DispatchQueue(label: "test.concurrent.export", attributes: .concurrent)
        
        // Export in multiple formats concurrently
        queue.async {
            _ = self.exportService.exportToGPX(session: self.testSession, locations: self.testLocations)
            expectation.fulfill()
        }
        
        queue.async {
            _ = self.exportService.exportToKML(session: self.testSession, locations: self.testLocations)
            expectation.fulfill()
        }
        
        queue.async {
            _ = self.exportService.exportToCSV(session: self.testSession, locations: self.testLocations)
            expectation.fulfill()
        }
        
        queue.async {
            _ = self.exportService.exportToGeoJSON(session: self.testSession, locations: self.testLocations)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 5.0)
    }
    
    func testConcurrentFileSaves() {
        let expectation = XCTestExpectation(description: "Concurrent saves complete")
        expectation.expectedFulfillmentCount = 10
        
        let queue = DispatchQueue(label: "test.concurrent.save", attributes: .concurrent)
        
        for i in 0..<10 {
            queue.async {
                let content = "Test content \(i)"
                let filename = "concurrent_test_\(i).txt"
                let fileURL = self.exportService.saveToTemporaryFile(content: content, filename: filename)
                XCTAssertNotNil(fileURL)
                
                // Clean up
                if let url = fileURL {
                    try? FileManager.default.removeItem(at: url)
                }
                
                expectation.fulfill()
            }
        }
        
        wait(for: [expectation], timeout: 10.0)
    }
    
    // MARK: - Filename Edge Cases
    
    func testFilenameWithInvalidCharacters() {
        let context = persistenceController.container.viewContext
        let session = TrackingSession(context: context)
        session.id = UUID()
        session.narrative = "Test/Session With Spaces" // Test / and space sanitization
        session.startDate = Date()
        
        let filename = exportService.generateFilename(session: session, format: .gpx)
        
        // Should sanitize forward slashes and spaces
        XCTAssertFalse(filename.contains("/"), "Forward slash should be sanitized")
        XCTAssertTrue(filename.contains("-"), "Forward slash should be replaced with dash")
        XCTAssertTrue(filename.contains("_"), "Spaces should be replaced with underscores")
        XCTAssertTrue(filename.hasSuffix(".gpx"))
        XCTAssertTrue(filename.hasPrefix("TrackMe_"))
    }
    
    func testFilenameWithUnicodeCharacters() {
        let context = persistenceController.container.viewContext
        let session = TrackingSession(context: context)
        session.id = UUID()
        session.narrative = "Test 日本語 Émojis 🚶‍♂️" // Unicode characters
        session.startDate = Date()
        
        let filename = exportService.generateFilename(session: session, format: .gpx)
        
        // Should handle unicode gracefully
        XCTAssertFalse(filename.isEmpty)
        XCTAssertTrue(filename.hasSuffix(".gpx"))
    }
    
    func testFilenameWithOnlySpaces() {
        let context = persistenceController.container.viewContext
        let session = TrackingSession(context: context)
        session.id = UUID()
        session.narrative = "     " // Only spaces
        session.startDate = Date()
        
        let filename = exportService.generateFilename(session: session, format: .gpx)
        
        // Should handle spaces-only narrative
        XCTAssertFalse(filename.isEmpty)
        XCTAssertTrue(filename.hasSuffix(".gpx"))
        XCTAssertTrue(filename.contains("TrackMe_"))
    }
    
    // MARK: - Export Format Validation
    
    func testGPXXMLValidation() {
        let gpx = exportService.exportToGPX(session: testSession, locations: testLocations)
        
        // Verify well-formed XML
        XCTAssertTrue(gpx.hasPrefix("<?xml"))
        
        // Count opening and closing tags should match
        let trkptOpen = gpx.components(separatedBy: "<trkpt").count - 1
        let trkptClose = gpx.components(separatedBy: "</trkpt>").count - 1
        XCTAssertEqual(trkptOpen, trkptClose, "Opening and closing trkpt tags should match")
        
        // Verify essential elements are present
        XCTAssertTrue(gpx.contains("</gpx>"), "Should have closing gpx tag")
        XCTAssertTrue(gpx.contains("</trk>"), "Should have closing trk tag")
        XCTAssertTrue(gpx.contains("</trkseg>"), "Should have closing trkseg tag")
    }
    
    func testKMLXMLValidation() {
        let kml = exportService.exportToKML(session: testSession, locations: testLocations)
        
        // Verify well-formed XML
        XCTAssertTrue(kml.hasPrefix("<?xml"))
        
        // Verify essential KML elements
        XCTAssertTrue(kml.contains("</kml>"), "Should have closing kml tag")
        XCTAssertTrue(kml.contains("</Document>"), "Should have closing Document tag")
        XCTAssertTrue(kml.contains("</Placemark>"), "Should have closing Placemark tag")
        XCTAssertTrue(kml.contains("</LineString>"), "Should have closing LineString tag")
        XCTAssertTrue(kml.contains("</coordinates>"), "Should have closing coordinates tag")
    }
    
    func testCSVFormatValidation() {
        let csv = exportService.exportToCSV(session: testSession, locations: testLocations)
        
        let lines = csv.components(separatedBy: "\n").filter { !$0.isEmpty }
        
        // Header + data rows
        XCTAssertGreaterThanOrEqual(lines.count, testLocations.count + 1)
        
        // Each data row should have same number of columns as header
        let headerColumns = lines[0].components(separatedBy: ",").count
        
        for i in 1..<min(lines.count, testLocations.count + 1) {
            let rowColumns = lines[i].components(separatedBy: ",").count
            XCTAssertEqual(rowColumns, headerColumns, "Row \(i) should have same number of columns as header")
        }
    }
    
    func testGeoJSONValidation() {
        let geojson = exportService.exportToGeoJSON(session: testSession, locations: testLocations)
        
        // Should be valid JSON
        guard let jsonData = geojson.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any] else {
            XCTFail("GeoJSON should be valid JSON")
            return
        }
        
        // Verify GeoJSON structure
        XCTAssertEqual(json["type"] as? String, "Feature")
        XCTAssertNotNil(json["properties"])
        XCTAssertNotNil(json["geometry"])
        
        if let geometry = json["geometry"] as? [String: Any] {
            XCTAssertEqual(geometry["type"] as? String, "LineString")
            XCTAssertNotNil(geometry["coordinates"])
        }
    }
    
    // MARK: - Edge Case Timestamps
    
    func testExportWithDistantPastTimestamp() {
        let context = persistenceController.container.viewContext
        let location = LocationEntry(context: context)
        location.id = UUID()
        location.latitude = 37.7749
        location.longitude = -122.4194
        location.timestamp = Date(timeIntervalSince1970: 0) // Unix epoch
        
        let gpx = exportService.exportToGPX(session: testSession, locations: [location])
        
        XCTAssertTrue(gpx.contains("<time>"))
        XCTAssertTrue(gpx.contains("1970"))
    }
    
    func testExportWithFutureTimestamp() {
        let context = persistenceController.container.viewContext
        let location = LocationEntry(context: context)
        location.id = UUID()
        location.latitude = 37.7749
        location.longitude = -122.4194
        location.timestamp = Date().addingTimeInterval(86400 * 365 * 10) // 10 years in future
        
        let gpx = exportService.exportToGPX(session: testSession, locations: [location])
        
        XCTAssertTrue(gpx.contains("<time>"))
        // Should still export future dates
    }
    
    func testExportWithNilTimestamp() {
        let context = persistenceController.container.viewContext
        let location = LocationEntry(context: context)
        location.id = UUID()
        location.latitude = 37.7749
        location.longitude = -122.4194
        location.timestamp = nil
        
        let gpx = exportService.exportToGPX(session: testSession, locations: [location])
        
        // Should handle nil timestamp gracefully
        XCTAssertTrue(gpx.contains("<trkpt"))
        XCTAssertTrue(gpx.contains("</trkpt>"))
    }
    
    // MARK: - File Cleanup Tests
    
    func testTemporaryFileCleanup() {
        var fileURLs: [URL] = []
        
        // Create multiple temporary files
        for i in 0..<5 {
            let content = "Test content \(i)"
            let filename = "cleanup_test_\(i).txt"
            if let url = exportService.saveToTemporaryFile(content: content, filename: filename) {
                fileURLs.append(url)
            }
        }
        
        XCTAssertEqual(fileURLs.count, 5)
        
        // Verify all files exist
        for url in fileURLs {
            XCTAssertTrue(FileManager.default.fileExists(atPath: url.path))
        }
        
        // Clean up all files
        for url in fileURLs {
            do {
                try FileManager.default.removeItem(at: url)
                XCTAssertFalse(FileManager.default.fileExists(atPath: url.path))
            } catch {
                XCTFail("Should be able to delete temporary file: \(error)")
            }
        }
    }
    
    // MARK: - Performance Under Error Conditions
    
    func testExportPerformanceWithInvalidData() {
        let context = persistenceController.container.viewContext
        var locations: [LocationEntry] = []
        
        // Create locations with some invalid data
        for i in 0..<1000 {
            let location = LocationEntry(context: context)
            location.id = UUID()
            location.latitude = (i % 2 == 0) ? 37.7749 : 9999.0 // Mix valid and invalid
            location.longitude = (i % 3 == 0) ? -122.4194 : 9999.0
            location.timestamp = Date()
            locations.append(location)
        }
        
        measure {
            _ = exportService.exportToGPX(session: testSession, locations: locations)
        }
    }
}
