import SwiftUI
import MapKit
import CoreLocation
import SwiftCore

struct MapView: View {
    @AppStorage(SETTINGS_IS_INFO_BOX_ENABLED_KEY) private var isInfoBoxEnabled: Bool = true
    @StateObject var messageService = MessageManager.shared
    @ObservedObject private var aircraftService = AircraftService.shared
    @State private var cameraPosition: MapCameraPosition = .automatic
    @State private var selectedAircraft: Aircraft?
    @State private var selectedMapStyle: MapStyle = .standard
    
    // Aircraft and airport data
    @State private var aircraftList: [Aircraft] = []
    @State private var airportList: [Airport] = []
    @State private var updateTimer: Timer?
    @State private var hasInitialData = false
    @State private var mapCenterDebounceTimer: Timer?
    @State private var lastMapCenter: CLLocationCoordinate2D?
    @State private var lastErrorCheck = Date()
    
    // Aircraft counts for debug info
    
    private var emergencyCount: Int {
        aircraftList.filter(\.isEmergency).count
    }
    
    private var militaryCount: Int {
        aircraftList.filter { aircraft in
            let flight = aircraft.formattedFlight.uppercased()
            let militaryCallsigns = ["RCH", "REACH", "CONVOY", "ARMY", "NAVY", "USAF", "MARINES", "USMC"]
            return militaryCallsigns.contains { flight.hasPrefix($0) }
        }.count
    }
    
    private var whiteCount: Int {
        aircraftList.count - emergencyCount - militaryCount
    }
    
    // Helper functions for aircraft display
    private func aircraftColor(for aircraft: Aircraft) -> Color {
        if aircraft.isEmergency {
            return .red // Emergency aircraft - big and red
        } else if isMilitaryAircraft(aircraft) {
            return .green // Military aircraft - green
        } else {
            return .white // Default - white
        }
    }
    
    private func isMilitaryAircraft(_ aircraft: Aircraft) -> Bool {
        let flight = aircraft.formattedFlight.uppercased()
        let militaryCallsigns = ["RCH", "REACH", "CONVOY", "ARMY", "NAVY", "USAF", "MARINES", "USMC"]
        return militaryCallsigns.contains { flight.hasPrefix($0) }
    }
    
    private func formatSpeed(_ speed: Double?) -> String {
        guard let speed = speed else { return "N/A" }
        return "\(Int(speed)) kt"
    }
    
    private func startDataUpdates() {
        // Initial load - immediate fetch from service
        fetchAircraftData()
        fetchAirportData()
        
        // Start with frequent polling for initial data load
        startFastPolling()
    }
    
    private func startFastPolling() {
        // Fast polling (0.2 seconds) until we get initial data
        updateTimer = Timer.scheduledTimer(withTimeInterval: 0.2, repeats: true) { _ in
            Task {
                await fetchAircraftDataAsync()
                await fetchAirportDataAsync()
                
                // Switch to slower polling once we have data
                await MainActor.run {
                    if !hasInitialData && !aircraftList.isEmpty {
                        hasInitialData = true
                        updateTimer?.invalidate()
                        startSlowPolling()
                    }
                }
            }
        }
    }
    
    private func startSlowPolling() {
        // Slower polling (5 seconds) for ongoing updates
        updateTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { _ in
            Task {
                await fetchAircraftDataAsync()
                await fetchAirportDataAsync()
            }
        }
    }
    
    private func stopDataUpdates() {
        updateTimer?.invalidate()
        updateTimer = nil
        mapCenterDebounceTimer?.invalidate()
        mapCenterDebounceTimer = nil
    }
    
    private func fetchAircraftData() {
        // Direct access to service data - no reactive bindings
        let service = AircraftService.shared
        aircraftList = service.aircraft
    }
    
    private func fetchAircraftDataAsync() async {
        // Async version to prevent UI lag during updates
        let service = AircraftService.shared
        let newAircraft = service.aircraft
        
        // Check for service errors (only check every 30 seconds to avoid spam)
        let now = Date()
        let shouldCheckError = now.timeIntervalSince(lastErrorCheck) > 30
        
        if shouldCheckError {
            let timeSinceLastUpdate = now.timeIntervalSince(service.lastUpdateTime)
            let hasRecentError = timeSinceLastUpdate > 60
            
            if hasRecentError {
                let formatter = DateFormatter()
                formatter.timeStyle = .short
                let lastUpdateString = formatter.string(from: service.lastUpdateTime)
                
                messageService.show(
                    "ADS-B service may be experiencing issues. Data last updated: \(lastUpdateString)",
                    type: .error
                )
            }
            
            await MainActor.run {
                lastErrorCheck = now
            }
        }
        
        // Update on main thread
        await MainActor.run {
            aircraftList = newAircraft
        }
    }
    
    private func fetchAirportData() {
        // Direct access to service data - no reactive bindings
        let service = AirportService.shared
        airportList = service.airports
    }
    
    private func fetchAirportDataAsync() async {
        // Async version to prevent UI lag during updates
        let service = AirportService.shared
        let newAirports = service.airports
        
        // Update on main thread
        await MainActor.run {
            airportList = newAirports
        }
    }
    
    private func updateAircraftServiceLocation(with region: MKCoordinateRegion) {
        let newCenter = region.center
        
        // Calculate zoom level from region span
        #if os(iOS)
        let screenWidth = UIScreen.main.bounds.width
        #else
        let screenWidth = WKInterfaceDevice.current().screenBounds.width
        #endif
        
        let zoomLevel = log2(360 * (Double(screenWidth) / 256.0) / region.span.longitudeDelta) + 1.0
        
        // Check if we should flush data when zooming out above level 6
        let aircraftService = AircraftService.shared
        let wasZoomedIn = aircraftService.currentZoomLevel > 6
        let isZoomedIn = zoomLevel > 6
        
        // Only flush data when transitioning from zoomed in to zoomed out
        if wasZoomedIn && !isZoomedIn {
            flushAreaAircraftData()
        }
        
        // Only fetch area-specific aircraft data when zoomed in more than level 6
        if zoomLevel <= 6 {
            return
        }
        
        // Check if map center has changed significantly to avoid unnecessary updates
        if let lastCenter = lastMapCenter {
            let distance = CLLocation(latitude: lastCenter.latitude, longitude: lastCenter.longitude)
                .distance(from: CLLocation(latitude: newCenter.latitude, longitude: newCenter.longitude))
            
            // Only update if moved more than 100km (radius is 250nm/463km)
            if distance < 100000 {
                return
            }
        }
        
        // Cancel previous debounce timer
        mapCenterDebounceTimer?.invalidate()
        
        // Start debounce timer (0.5 seconds)
        mapCenterDebounceTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) { _ in
            // Flush area-specific aircraft data when moving to a different area
            self.flushAreaAircraftData()
            
            // Update aircraft service with new map center
            aircraftService.updateMapCenter(
                latitude: newCenter.latitude,
                longitude: newCenter.longitude,
                zoomLevel: zoomLevel
            )
            
            // Only trigger fast polling for map position changes, not zoom changes
            // This reduces API calls since zoom changes don't need fresh area data
            self.startFastPollingForMapChange()
        }
        
        // Update last map center
        lastMapCenter = newCenter
    }
    
    private func startFastPollingForMapChange() {
        // Cancel current timer
        updateTimer?.invalidate()
        
        // Start fast polling (0.3 seconds) for quick data after map move
        let pollLimit = 3
        var pollCount = 0
        
        updateTimer = Timer.scheduledTimer(withTimeInterval: 0.3, repeats: true) { timer in
            Task { @MainActor in
                await fetchAircraftDataAsync()
                await fetchAirportDataAsync()
                
                pollCount += 1
                
                // After 3 fast polls (0.9 seconds), switch back to slow polling
                if pollCount >= pollLimit {
                    timer.invalidate()
                    self.startSlowPolling()
                }
            }
        }
    }
    
    private func updateZoomLevel(with region: MKCoordinateRegion) {
        // Calculate zoom level from region span
        #if os(iOS)
        let screenWidth = UIScreen.main.bounds.width
        #else
        let screenWidth = WKInterfaceDevice.current().screenBounds.width
        #endif
        
        let zoomLevel = log2(360 * (Double(screenWidth) / 256.0) / region.span.longitudeDelta) + 1.0
        
        // Always update AircraftService zoom level for debug info display
        // This ensures the refresh interval in debug info updates immediately
        let aircraftService = AircraftService.shared
        aircraftService.updateMapCenter(
            latitude: aircraftService.currentLatitude,
            longitude: aircraftService.currentLongitude,
            zoomLevel: zoomLevel
        )
    }
    
    private func flushAreaAircraftData() {
        // Clear all aircraft data when switching areas or zooming out
        // This ensures stale area-specific data doesn't persist
        aircraftList.removeAll()
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Map(position: $cameraPosition, selection: $selectedAircraft) {
                    UserAnnotation()
                    
                    ForEach(aircraftList, id: \.hex) { aircraft in
                        let code = aircraft.formattedFlight.isEmpty ? aircraft.hex : aircraft.formattedFlight
                        let aircraftType = AircraftDisplayConfig.getAircraftType(for: aircraft)
                        let isSimpleLabel = !isInfoBoxEnabled || aircraftService.currentZoomLevel <= 9

                        Annotation(
                            isSimpleLabel ? code : "",
                            coordinate: CLLocationCoordinate2D(
                                latitude: aircraft.lat ?? 0,
                                longitude: aircraft.lon ?? 0
                            ),
                            anchor: .top
                        ) {
                            VStack {
                                ZStack {
                                    Circle()
                                        .fill(.black.opacity(0.5))
                                        .frame(width: 30, height: 30)
                                    
                                    Image(systemName: aircraftType.iconName)
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 15, height: 15)
                                        .foregroundStyle(aircraftColor(for: aircraft))
                                        .rotationEffect(.degrees(Double(aircraft.track ?? 0) - 90))
                                }
                                .scaleEffect(aircraftType.scale)
                                
                                if !isSimpleLabel {
                                    VStack {
                                        Text(code)
                                            .fontWeight(.semibold)
                                            .font(.caption)
                                        
                                        if let groundSpeed = aircraft.gs, groundSpeed > 0 {
                                            Text(formatSpeed(groundSpeed))
                                                .font(.caption2)
                                        }

                                        if let altitude = aircraft.alt_baro {
                                            Text(formatAltitude(altitude))
                                                .font(.caption2)
                                        }
                                    }
                                    .padding(.horizontal, 4)
                                    .padding(.vertical, 2)
                                    .background(.black.opacity(0.5))
                                    .cornerRadius(4)
                                }
                            }
                            .onTapGesture {
                                selectedAircraft = aircraft
                            }
                        }
                    }
                    
                    ForEach(airportList, id: \.id) { airport in
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
                .onMapCameraChange(frequency: .onEnd) { context in
                    updateZoomLevel(with: context.region)
                    updateAircraftServiceLocation(with: context.region)
                }
                .mapStyle(MapStyle.standard)
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
            }
        }
        .sheet(item: $selectedAircraft) { (aircraft: Aircraft) in
            AircraftDetailView(aircraft: aircraft)
                .presentationDetents([.medium, .large])
                .presentationBackgroundInteraction(.enabled)
        }
        .onAppear {
            startDataUpdates()
        }
        .onDisappear {
            stopDataUpdates()
        }
    }
}

// MARK: - Preview

#Preview {
    MapView()
}
