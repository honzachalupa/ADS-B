import SwiftUI
import SwiftCore
import MapKit
import CoreLocation

#if os(iOS)
import UIKit
#elseif os(watchOS)
import WatchKit
#endif

// MARK: - MapView Extensions

extension CLLocationCoordinate2D {
    func isWithin(region: MKCoordinateRegion) -> Bool {
        let center = region.center
        let northEast = CLLocationCoordinate2D(
            latitude: center.latitude + region.span.latitudeDelta / 2,
            longitude: center.longitude + region.span.longitudeDelta / 2
        )
        let southWest = CLLocationCoordinate2D(
            latitude: center.latitude - region.span.latitudeDelta / 2,
            longitude: center.longitude - region.span.longitudeDelta / 2
        )
        
        return (latitude >= southWest.latitude && latitude <= northEast.latitude) &&
               (longitude >= southWest.longitude && longitude <= northEast.longitude)
    }
}

struct MapView_Old: View {
    @ObservedObject private var locationManager = LocationManager.shared
    @ObservedObject private var aircraftService = AircraftService.shared
    @ObservedObject private var airportService = AirportService.shared
    @AppStorage(SETTINGS_IS_INFO_BOX_ENABLED_KEY) private var isInfoBoxEnabled: Bool = true
    @AppStorage(SETTINGS_SEARCH_RANGE_KEY) private var searchRange: Double = 50.0
    
    // Performance monitoring
    #if DEBUG
    @State private var lastUpdateTime: Date = .now
    @State private var visibleAircraftCount: Int = 0
    @State private var totalAircraftCount: Int = 0
    private let performanceMonitor = PerformanceMonitor()
    #endif
    
    // MARK: - State Properties
    
    @State private var cameraPosition: MapCameraPosition = .automatic
    @State private var selectedAircraft: Aircraft?
    @State private var selectedMapStyle: MapStyle = .standard
    @State private var updateCount = 0
    @State private var currentSpan: MKCoordinateSpan?
    
    
    
    // MARK: - Helper Methods
    
    // Helper to get span from camera position
    private func getSpan(from cameraPosition: MapCameraPosition) -> MKCoordinateSpan {
        return cameraPosition.region?.span ?? MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
    }
    
    private func updateRegion(_ region: MKCoordinateRegion) {
        // Update the camera position
        self.cameraPosition = .region(region)
        
        // Calculate zoom level
        #if os(iOS)
        let screenWidth = UIScreen.main.bounds.width
        #else
        let screenWidth = WKInterfaceDevice.current().screenBounds.width
        #endif
        
        let zoomLevel = log2(360 * (Double(screenWidth) / 256.0) / region.span.longitudeDelta) + 1.0
        
        // Update aircraft service with new center and zoom
        aircraftService.updateMapCenter(
            latitude: region.center.latitude,
            longitude: region.center.longitude,
            zoomLevel: zoomLevel
        )
    }
    
    private func formatSpeed(_ speed: Double?) -> String {
        guard let speed = speed, speed > 0 else { return "N/A" }
        return "\(Int(speed))"
    }
    
    private func formatAltitude(_ altitude: Double?) -> String {
        guard let altitude = altitude else { return "N/A" }
        return "\(Int(altitude))"
    }
    
    // MARK: - Computed Properties
    
    private var visibleAircraft: [Aircraft] {
        guard let region = cameraPosition.region else { return [] }
        
        let filtered = aircraftService.aircrafts.filter { aircraft in
            guard let lat = aircraft.lat, let lon = aircraft.lon else { return false }
            let coord = CLLocationCoordinate2D(latitude: lat, longitude: lon)
            return coord.isWithin(region: region)
        }
        
        #if DEBUG
        // Update performance metrics
        DispatchQueue.main.async {
            self.visibleAircraftCount = filtered.count
            self.totalAircraftCount = aircraftService.aircrafts.count
            self.updateCount += 1
            self.lastUpdateTime = .now
        }
        #endif
        
        return filtered
    }
    
    
    // MARK: - Main View
    
    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottomTrailing) {
                // Main Map View
                Map(position: $cameraPosition, selection: $selectedAircraft) {
                    UserAnnotation()
                    
                    // Aircraft Markers - Direct Annotations
                    ForEach(visibleAircraft, id: \.hex) { aircraft in
                        if let lat = aircraft.lat, let lon = aircraft.lon {
                            let coordinate = CLLocationCoordinate2D(latitude: lat, longitude: lon)
                            Annotation(
                                aircraft.formattedFlight.trimmingCharacters(in: .whitespaces).isEmpty ? 
                                    aircraft.hex : aircraft.formattedFlight,
                                coordinate: coordinate
                            ) {
                                AircraftMarkerView(aircraft: aircraft)
                                    .onTapGesture {
                                        selectedAircraft = aircraft
                                    }
                            }
                        }
                    }
                    
                    // Airport Markers
                    ForEach(airportService.airports) { airport in
                        Annotation(
                            airport.icao,
                            coordinate: airport.coordinate
                        ) {
                            Image(systemName: "airplane.departure")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 16, height: 16)
                                .foregroundColor(.blue)
                        }
                    }
                }
                .onMapCameraChange(frequency: .onEnd) { (context: MapCameraUpdateContext) in
                    // Only update when user stops interacting
                    let region = context.region
                    currentSpan = region.span
                    
                    // Direct update without throttling
                    updateRegion(region)
                }
                .mapStyle(MapStyle.standard)
                .animation(.easeInOut(duration: 0.3), value: cameraPosition)
                #if DEBUG
                .overlay(alignment: .bottomTrailing) {
                    VStack(alignment: .trailing) {
                        Text("Aircraft: \(visibleAircraftCount)/\(totalAircraftCount)")
                        Text("FPS: \(performanceMonitor.fps, specifier: "%.1f")")
                        Text("Updates: \(updateCount)")
                        Text("Visible: \(visibleAircraftCount)")
                        Text("Last: \(lastUpdateTime, style: .time)")
                    }
                    .font(.system(size: 10, design: .monospaced))
                    .padding(8)
                    .background(Color.black.opacity(0.7))
                    .foregroundColor(.white)
                    .cornerRadius(8)
                    .padding()
                }
                #endif
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        NavigationLink {
                            SettingsView()
                        } label: {
                            Label("Settings", systemImage: "gearshape.fill")
                        }
                    }
                    
                    ToolbarItem(placement: .topBarLeading) {
                        MapFilterControlView()
                    }
                    
                    ToolbarItem(placement: .topBarLeading) {
                        MapLegendView {
                            Label("Legend", systemImage: "info.circle.fill")
                        }
                    }
                    
                    ToolbarItem(placement: .topBarTrailing) {
                        MapStyleControlView(mapStyle: $selectedMapStyle)
                    }
                    
                    ToolbarItem(placement: .topBarTrailing) {
                        MapUserLocationControlView(cameraPosition: $cameraPosition)
                    }
                }
                .sheet(item: $selectedAircraft) { (aircraft: Aircraft) in
                    AircraftDetailView(aircraft: aircraft)
                        .presentationDetents([.medium, .large])
                        .presentationBackgroundInteraction(.enabled)
                }
            }
        }
    }
}

// MARK: - Performance Monitor

#if DEBUG && os(iOS)
private class PerformanceMonitor: NSObject {
    private var lastUpdateTime: TimeInterval = 0
    private var frameCount: Int = 0
    private var lastFPSUpdate: TimeInterval = 0
    private(set) var fps: Double = 0
    private var displayLink: CADisplayLink?
    
    override init() {
        super.init()
        lastUpdateTime = CACurrentMediaTime()
        lastFPSUpdate = lastUpdateTime
        
        // Setup display link for FPS monitoring (iOS only)
        #if os(iOS)
        displayLink = CADisplayLink(target: self, selector: #selector(updateFrame(displayLink:)))
        displayLink?.add(to: .main, forMode: .common)
        #endif
    }
    
    @objc private func updateFrame(displayLink: CADisplayLink) {
        frameCount += 1
        
        let currentTime = CACurrentMediaTime()
        let elapsed = currentTime - lastFPSUpdate
        
        // Update FPS every second
        if elapsed >= 1.0 {
            fps = Double(frameCount) / elapsed
            frameCount = 0
            lastFPSUpdate = currentTime
        }
    }
    
    deinit {
        #if os(iOS)
        displayLink?.invalidate()
        #endif
    }
}
#else
private class PerformanceMonitor {
    var fps: Double = 0
}
#endif

// MARK: - Preview

#Preview {
    MapView()
}
