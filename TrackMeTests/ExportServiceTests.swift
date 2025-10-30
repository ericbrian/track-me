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
