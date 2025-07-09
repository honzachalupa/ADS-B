import SwiftUI
import MapKit
import CoreLocation

// MINIMAL TEST - NO SERVICES, NO REACTIVE BINDINGS, NO COMPLEX COMPONENTS
struct MapView: View {
    @State private var cameraPosition: MapCameraPosition = .automatic
    @State private var selectedAircraft: Aircraft?
    @State private var selectedMapStyle: MapStyle = .standard
    
    // REAL AIRCRAFT DATA - But still simple approach
    @State private var aircraftList: [Aircraft] = []
    @State private var airportList: [Airport] = []
    @State private var updateTimer: Timer?
    @State private var hasInitialData = false
    @State private var mapCenterDebounceTimer: Timer?
    @State private var lastMapCenter: CLLocationCoordinate2D?
    
    // Debug info
    private var uniqueCategories: Int {
        Set(aircraftList.compactMap(\.category)).count
    }
    
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
    
    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottomTrailing) {
                // MINIMAL MAP - Just hardcoded test data
                Map(position: $cameraPosition, selection: $selectedAircraft) {
                    UserAnnotation()
                    
                    // AIRCRAFT MARKERS - Increase limit to test performance at scale
                    ForEach(Array(aircraftList.prefix(500)), id: \.hex) { aircraft in
                        if let lat = aircraft.lat, let lon = aircraft.lon {
                            let coordinate = CLLocationCoordinate2D(latitude: lat, longitude: lon)
                            Annotation(
                                aircraft.hex,
                                coordinate: coordinate
                            ) {
                                // TEST: Add back AircraftMarkerView to see if it's the bottleneck
                                AircraftMarkerView(aircraft: aircraft)
                                    .onTapGesture {
                                        selectedAircraft = aircraft
                                    }
                            }
                        }
                    }
                    
                    // Airport Markers - Direct from state array
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
                    // Only update aircraft service when map center changes significantly (panning)
                    // Ignore zoom-only changes to avoid unnecessary API calls
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
                
                // SIMPLE DEBUG INFO
                VStack(alignment: .trailing) {
                    Text("Aircraft: \(aircraftList.count)")
                    Text("Showing: \(min(500, aircraftList.count))")
                    Text("Emergency: \(emergencyCount)")
                    Text("Military: \(militaryCount)")
                    Text("White: \(whiteCount)")
                }
                .font(.system(size: 10, design: .monospaced))
                .padding(8)
                .background(Color.black.opacity(0.7))
                .foregroundColor(.white)
                .cornerRadius(8)
                .padding()
            }
        }
        .sheet(item: $selectedAircraft) { (aircraft: Aircraft) in
            // SIMPLE SHEET - No complex AircraftDetailView
            VStack {
                Text("Aircraft: \(aircraft.hex)")
                Text("Flight: \(aircraft.formattedFlight)")
                Button("Close") {
                    selectedAircraft = nil
                }
            }
            .padding()
        }
        .onAppear {
            startDataUpdates()
        }
        .onDisappear {
            stopDataUpdates()
        }
    }
    
    // MARK: - Simple Data Management
    
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
        aircraftList = service.aircrafts
    }
    
    private func fetchAircraftDataAsync() async {
        // Async version to prevent UI lag during updates
        let service = AircraftService.shared
        let newAircraft = service.aircrafts
        
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
            // Calculate zoom level from region span
            #if os(iOS)
            let screenWidth = UIScreen.main.bounds.width
            #else
            let screenWidth = WKInterfaceDevice.current().screenBounds.width
            #endif
            
            let zoomLevel = log2(360 * (Double(screenWidth) / 256.0) / region.span.longitudeDelta) + 1.0
            
            // Update aircraft service with new map center
            let aircraftService = AircraftService.shared
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
        var pollCount = 0
        updateTimer = Timer.scheduledTimer(withTimeInterval: 0.3, repeats: true) { timer in
            Task {
                await fetchAircraftDataAsync()
                await fetchAirportDataAsync()
                
                pollCount += 1
                
                // After 3 fast polls (0.9 seconds), switch back to slow polling
                if pollCount >= 3 {
                    timer.invalidate()
                    await MainActor.run {
                        self.startSlowPolling()
                    }
                }
            }
        }
    }
    
}

// MARK: - Preview

#Preview {
    MapView()
}