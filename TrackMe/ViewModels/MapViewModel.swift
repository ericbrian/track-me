import Foundation
import SwiftUI
import MapKit
import CoreLocation
import CoreData
import Combine

/// ViewModel for map display - manages map state, camera position, and location selection
@MainActor
final class MapViewModel: ObservableObject {
    
    // MARK: - Dependencies
    
    private let session: TrackingSession
    private weak var viewContext: NSManagedObjectContext?
    
    // MARK: - Published State
    
    @Published var mapPosition: MapCameraPosition = .automatic
    @Published var selectedLocation: LocationEntry?
    @Published var showRoute = true
    @Published var locations: [LocationEntry] = []
    @Published var isPresentingShare = false
    @Published var shareURL: URL?
    
    // MARK: - Private State
    
    private var didSetInitialRegion = false
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Computed Properties
    
    var hasLocations: Bool {
        !locations.isEmpty
    }
    
    var routePolylines: [MKPolyline] {
        guard locations.count > 1 else { return [] }
        let coordinates = locations.map { 
            CLLocationCoordinate2D(latitude: $0.latitude, longitude: $0.longitude) 
        }
        let segments = MapMath.splitSegmentsAcrossAntimeridian(coordinates)
        return segments.map { segment in
            MKPolyline(coordinates: segment, count: segment.count)
        }
    }
    
    // MARK: - Initialization
    
    init(session: TrackingSession, viewContext: NSManagedObjectContext) {
        self.session = session
        self.viewContext = viewContext
    }
    
    // MARK: - Actions
    
    func loadLocations() {
        guard let context = viewContext else { return }
        
        // Refresh the session to ensure relationships are loaded
        context.refresh(session, mergeChanges: true)
        
        // Fetch locations for this session
        let request = NSFetchRequest<LocationEntry>(entityName: "LocationEntry")
        request.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: true)]
        request.predicate = NSPredicate(format: "session == %@", session)
        
        do {
            locations = try context.fetch(request)
            setInitialCameraPositionIfNeeded()
        } catch {
            print("MapViewModel: Failed to fetch locations: \(error)")
            locations = []
        }
    }
    
    func toggleRoute() {
        showRoute.toggle()
    }
    
    func selectLocation(_ location: LocationEntry) {
        if selectedLocation?.id == location.id {
            selectedLocation = nil
        } else {
            selectedLocation = location
        }
    }
    
    func deselectLocation() {
        selectedLocation = nil
    }
    
    func isStartLocation(_ location: LocationEntry) -> Bool {
        locations.first?.id == location.id
    }
    
    func isEndLocation(_ location: LocationEntry) -> Bool {
        locations.last?.id == location.id
    }
    
    func shareSession() {
        guard !locations.isEmpty else { return }
        
        // Capture values on the main actor before going to background
        let session = self.session
        let locations = self.locations
        
        // Perform export off the main thread
        Task.detached(priority: .userInitiated) {
            do {
                let csv = try ExportService.shared.exportToCSV(
                    session: session, 
                    locations: locations
                )
                let filename = ExportService.shared.generateFilename(
                    session: session, 
                    format: .csv
                )
                let fileURL = try ExportService.shared.saveToTemporaryFile(
                    content: csv, 
                    filename: filename
                )
                
                await MainActor.run {
                    self.shareURL = fileURL
                    self.isPresentingShare = true
                }
            } catch let error as AppError {
                await MainActor.run {
                    ErrorHandler.shared.handle(error)
                }
            } catch {
                await MainActor.run {
                    ErrorHandler.shared.handle(.unknown(error))
                }
            }
        }
    }
    
    // MARK: - Private Helpers
    
    private func setInitialCameraPositionIfNeeded() {
        guard !didSetInitialRegion else { return }
        
        if locations.isEmpty {
            mapPosition = .automatic
            didSetInitialRegion = true
            return
        }
        
        let coords = locations.map { 
            CLLocationCoordinate2D(latitude: $0.latitude, longitude: $0.longitude) 
        }
        let region = MapMath.computeRegion(for: coords, minSpan: 0.01, paddingScale: 1.4)
        mapPosition = .region(region)
        didSetInitialRegion = true
    }
    
    func onLocationsChanged() {
        setInitialCameraPositionIfNeeded()
    }
}
