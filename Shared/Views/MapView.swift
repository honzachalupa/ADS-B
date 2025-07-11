import SwiftUI
import MapKit
import CoreLocation
import SwiftCore

struct MapView: View {
    @AppStorage(SETTINGS_IS_INFO_BOX_ENABLED_KEY) private var isInfoBoxEnabled: Bool = true
    @StateObject var messageService = MessageManager.shared
    @ObservedObject private var aircraftService = AircraftService.shared
    @ObservedObject private var locationManager = LocationManager.shared
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
        aircraftList.filter(\.isMilitary).count
    }
    
    private var whiteCount: Int {
        aircraftList.count - emergencyCount - militaryCount
    }
    
    // Helper functions for aircraft display
    private func aircraftColor(for aircraft: Aircraft) -> Color {
        if aircraft.isEmergency {
            return .red // Emergency aircraft - big and red
        } else if aircraft.isMilitary {
            return .green // Military aircraft - green
        } else {
            return .white // Default - white
        }
    }
    
    private func iconName(for aircraft: Aircraft) -> String {
        switch aircraft.feederType {
        case .aircraft:
            if let type = aircraft.t {
                if type.hasPrefix("R") || type.contains("HELI") {
                    return "fanblades"
                }
            }
            return "airplane"
        case .groundVehicle:
            return "car.fill"
        case .tower, .groundStation:
            return "antenna.radiowaves.left.and.right"
        }
    }
    
    private func rotationAngle(for aircraft: Aircraft) -> Double {
        let shouldRotate = aircraft.feederType == .aircraft
        return shouldRotate ? Double(aircraft.track ?? 0) - 90 : 0
    }
    
    private func scale(for aircraft: Aircraft) -> CGFloat {
        if aircraft.feederType == .aircraft {
            if let type = aircraft.t, type.hasPrefix("R") || type.contains("HELI") {
                return 0.7 // Helicopter
            }
            if let category = aircraft.category, category == "A1" || category == "A2" {
                return 0.7 // Light aircraft
            }
        }
        return 1.0
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
        
        // Start debounce timer (1.0 seconds) - longer delay for smoother UX
        mapCenterDebounceTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: false) { _ in
            // Update aircraft service with new map center
            aircraftService.updateMapCenter(
                latitude: newCenter.latitude,
                longitude: newCenter.longitude,
                zoomLevel: zoomLevel
            )
            
            // Gradual polling for map position changes - let new data replace old gradually
            self.startFastPollingForMapChange()
        }
        
        // Update last map center
        lastMapCenter = newCenter
    }
    
    private func startFastPollingForMapChange() {
        // Cancel current timer
        updateTimer?.invalidate()
        
        // Slower polling (1.5 seconds) for less aggressive updates after map move
        let pollLimit = 2
        var pollCount = 0
        
        updateTimer = Timer.scheduledTimer(withTimeInterval: 1.5, repeats: true) { timer in
            Task { @MainActor in
                await fetchAircraftDataAsync()
                await fetchAirportDataAsync()
                
                pollCount += 1
                
                // After 2 polls (3 seconds), switch back to slow polling
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
    
    private func panToUserLocation() {
        // Check if we have user location and pan to it
        if let userLocation = locationManager.location {
            let region = MKCoordinateRegion(
                center: userLocation.coordinate,
                latitudinalMeters: 20000, // 20km radius - much tighter zoom
                longitudinalMeters: 20000
            )
            
            withAnimation(.easeInOut(duration: 1.5)) {
                cameraPosition = .region(region)
            }
        } else {
            // Location not available yet, try again after a short delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                self.panToUserLocation()
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Map(position: $cameraPosition, selection: $selectedAircraft) {
                    UserAnnotation()
                    
                    // Airport markers - rendered first (bottom layer)
                    ForEach(airportList, id: \.id) { airport in
                        Annotation(
                            airport.icao,
                            coordinate: airport.coordinate
                        ) {
                            MarkerView(
                                size: 20,
                                iconSystemName: "airplane.departure",
                                fillColor: .blue.opacity(0.7),
                                foregroundColor: .white
                            )
                            .zIndex(0)
                        }
                    }
                    
                    // Aircraft markers - rendered second (top layer)
                    ForEach(aircraftList, id: \.hex) { aircraft in
                        let isSimpleLabel = !isInfoBoxEnabled || aircraftService.currentZoomLevel <= 9

                        Annotation(
                            isSimpleLabel ? (aircraft.formattedFlight.isEmpty ? aircraft.hex : aircraft.formattedFlight) : "",
                            coordinate: CLLocationCoordinate2D(
                                latitude: aircraft.lat ?? 0,
                                longitude: aircraft.lon ?? 0
                            ),
                            anchor: .top
                        ) {
                            let iconName = aircraft.feederType == .aircraft ? "airplane" : (aircraft.feederType == .groundVehicle ? "car.fill" : "antenna.radiowaves.left.and.right")
                            let color: Color = aircraft.isEmergency ? .red : (aircraft.isMilitary ? .green : .white)
                            let rotation = aircraft.feederType == .aircraft ? Double(aircraft.track ?? 0) - 90 : 0
                            
                            VStack {
                                MarkerView(
                                    size: 30,
                                    iconSystemName: iconName,
                                    fillColor: .black.opacity(0.5),
                                    foregroundColor: color
                                )
                                .rotationEffect(.degrees(rotation))
                                
                                if !isSimpleLabel {
                                    Text(aircraft.formattedFlight.isEmpty ? aircraft.hex : aircraft.formattedFlight)
                                        .fontWeight(.semibold)
                                        .font(.caption)
                                        .padding(.horizontal, 4)
                                        .padding(.vertical, 2)
                                        .background(.background.opacity(0.5))
                                        .cornerRadius(4)
                                }
                            }
                            .onTapGesture {
                                selectedAircraft = aircraft
                            }
                            .zIndex(1)
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
            panToUserLocation()
        }
        .onDisappear {
            stopDataUpdates()
        }
        .onChange(of: locationManager.location) { _, newLocation in
            // Pan to user location when it becomes available
            if newLocation != nil && cameraPosition == .automatic {
                panToUserLocation()
            }
        }
    }
}

// MARK: - Preview

#Preview {
    MapView()
}
