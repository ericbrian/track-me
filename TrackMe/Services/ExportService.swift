import Foundation
import CoreData

class ExportService {
    static let shared = ExportService()
    private let errorHandler = ErrorHandler.shared

    private init() {}

    /// Export a tracking session to GPX format
    /// - Throws: AppError if export fails
    func exportToGPX(session: TrackingSession, locations: [LocationEntry]) throws -> String {
        guard !locations.isEmpty else {
            throw AppError.exportNoLocations
        }
        var gpx = """
        <?xml version="1.0" encoding="UTF-8"?>
        <gpx version="1.1" creator="TrackMe" xmlns="http://www.topografix.com/GPX/1/1" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://www.topografix.com/GPX/1/1 http://www.topografix.com/GPX/1/1/gpx.xsd">
          <metadata>
            <name>\(session.narrative ?? "Tracking Session")</name>
        """
        
        if let startDate = session.startDate {
            gpx += "\n    <time>\(formatDate(startDate))</time>"
        }
        
        gpx += "\n  </metadata>\n  <trk>\n    <name>\(session.narrative ?? "Track")</name>\n    <trkseg>"
        
        for location in locations {
            gpx += "\n      <trkpt lat=\"\(location.latitude)\" lon=\"\(location.longitude)\">"
            
            if location.altitude != 0 {
                gpx += "\n        <ele>\(location.altitude)</ele>"
            }
            
            if let timestamp = location.timestamp {
                gpx += "\n        <time>\(formatDate(timestamp))</time>"
            }
            
            gpx += "\n      </trkpt>"
        }
        
        gpx += "\n    </trkseg>\n  </trk>\n</gpx>"
        
        return gpx
    }
    
    /// Export a tracking session to KML format
    /// - Throws: AppError if export fails
    func exportToKML(session: TrackingSession, locations: [LocationEntry]) throws -> String {
        guard !locations.isEmpty else {
            throw AppError.exportNoLocations
        }
        var kml = """
        <?xml version="1.0" encoding="UTF-8"?>
        <kml xmlns="http://www.opengis.net/kml/2.2">
          <Document>
            <name>\(session.narrative ?? "Tracking Session")</name>
            <Style id="trackStyle">
              <LineStyle>
                <color>ff0000ff</color>
                <width>4</width>
              </LineStyle>
            </Style>
            <Placemark>
              <name>\(session.narrative ?? "Track")</name>
              <styleUrl>#trackStyle</styleUrl>
              <LineString>
                <coordinates>
        """
        
        for location in locations {
            // KML uses lon,lat,altitude format
            let altitude = location.altitude != 0 ? location.altitude : 0
            kml += "\(location.longitude),\(location.latitude),\(altitude)\n"
        }
        
        kml += """
                </coordinates>
              </LineString>
            </Placemark>
          </Document>
        </kml>
        """
        
        return kml
    }
    
    /// Export a tracking session to CSV format
    /// - Throws: AppError if export fails
    func exportToCSV(session: TrackingSession, locations: [LocationEntry]) throws -> String {
        guard !locations.isEmpty else {
            throw AppError.exportNoLocations
        }

        var csv = "Latitude,Longitude,Altitude,Speed,Course,Accuracy,Timestamp\n"

        let dateFormatter = ISO8601DateFormatter()

        for location in locations {
            let timestamp = location.timestamp.map { dateFormatter.string(from: $0) } ?? ""
            csv += "\(location.latitude),\(location.longitude),\(location.altitude),\(location.speed),\(location.course),\(location.accuracy),\(timestamp)\n"
        }

        return csv
    }
    
    /// Export a tracking session to GeoJSON format
    /// - Throws: AppError if export fails
    func exportToGeoJSON(session: TrackingSession, locations: [LocationEntry]) throws -> String {
        guard !locations.isEmpty else {
            throw AppError.exportNoLocations
        }
        var coordinates: [[Double]] = []
        
        for location in locations {
            // GeoJSON uses [longitude, latitude, altitude] format
            let altitude = location.altitude != 0 ? location.altitude : 0
            coordinates.append([location.longitude, location.latitude, altitude])
        }
        
        let coordinatesString = coordinates.map { coord in
            "[\(coord[0]), \(coord[1]), \(coord[2])]"
        }.joined(separator: ", ")
        
        let geojson = """
        {
          "type": "Feature",
          "properties": {
            "name": "\(session.narrative ?? "Tracking Session")",
            "timestamp": "\(formatDate(session.startDate ?? Date()))"
          },
          "geometry": {
            "type": "LineString",
            "coordinates": [\(coordinatesString)]
          }
        }
        """
        
        return geojson
    }
    
    /// Generate a filename for the export
    func generateFilename(session: TrackingSession, format: ExportFormat) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd_HHmmss"
        let dateString = dateFormatter.string(from: session.startDate ?? Date())
        
        let narrative = session.narrative?
            .replacingOccurrences(of: " ", with: "_")
            .replacingOccurrences(of: "/", with: "-")
            .prefix(30) ?? "session"
        
        return "TrackMe_\(narrative)_\(dateString).\(format.fileExtension)"
    }
    
    /// Save export data to a temporary file and return the URL
    /// - Throws: AppError if save fails
    func saveToTemporaryFile(content: String, filename: String) throws -> URL {
        let temporaryDirectory = FileManager.default.temporaryDirectory
        let fileURL = temporaryDirectory.appendingPathComponent(filename)

        do {
            try content.write(to: fileURL, atomically: true, encoding: .utf8)
            return fileURL
        } catch {
            print("⚠️ Failed to save export file: \(error)")
            throw AppError.exportSaveFailed(error)
        }
    }

    /// Legacy method for backward compatibility - returns nil on error
    @available(*, deprecated, message: "Use throwing version instead")
    func saveToTemporaryFileLegacy(content: String, filename: String) -> URL? {
        return try? saveToTemporaryFile(content: content, filename: filename)
    }
    
    // MARK: - Private Helpers
    
    private func formatDate(_ date: Date) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter.string(from: date)
    }
}

// MARK: - Export Format

enum ExportFormat: String, CaseIterable {
    case gpx = "GPX"
    case kml = "KML"
    case csv = "CSV"
    case geojson = "GeoJSON"
    
    var fileExtension: String {
        switch self {
        case .gpx: return "gpx"
        case .kml: return "kml"
        case .csv: return "csv"
        case .geojson: return "geojson"
        }
    }
    
    var description: String {
        switch self {
        case .gpx: return "GPS Exchange Format (Universal)"
        case .kml: return "Keyhole Markup Language (Google Earth)"
        case .csv: return "Comma-Separated Values (Spreadsheet)"
        case .geojson: return "GeoJSON (Web/Developer)"
        }
    }
}
