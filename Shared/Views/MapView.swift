import SwiftUI
import MapKit
import CoreLocation
import SwiftCore

struct MapView: View {
    @Binding public var selectedAircraft: Aircraft?
    @State private var isDetailPresented = false
    
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @AppStorage("mapStyleSelection") private var mapStyleSelection: String = "standard"
    @AppStorage(SETTINGS_IS_INFO_BOX_ENABLED_KEY) private var isInfoBoxEnabled: Bool = true
    @StateObject var messageService = MessageManager.shared
    @ObservedObject private var aircraftService = AircraftService.shared
    @ObservedObject private var locationManager = LocationManager.shared
    @State private var cameraPosition: MapCameraPosition = .automatic
    
    // Aircraft and airport data
    @State private var aircraftList: [Aircraft] = []
    @State private var airportList: [Airport] = []
    @State private var updateTimer: Timer?
    @State private var hasInitialData = false
    @State private var mapCenterDebounceTimer: Timer?
    @State private var lastMapCenter: CLLocationCoordinate2D?
    @State private var lastErrorCheck = Date()
    
    // Map region tracking for performance filtering
    @State private var currentMapRegion: MKCoordinateRegion?
    
    // Helper function to filter aircraft by region
    private func getVisibleAircraft(in region: MKCoordinateRegion?) -> [Aircraft] {
        guard let region = region else { return aircraftList }
        
        return aircraftList.filter { aircraft in
            guard let lat = aircraft.lat, let lon = aircraft.lon else { return false }
            
            let latDelta = region.span.latitudeDelta * 0.6 // Add some buffer
            let lonDelta = region.span.longitudeDelta * 0.6
            
            let minLat = region.center.latitude - latDelta
            let maxLat = region.center.latitude + latDelta
            let minLon = region.center.longitude - lonDelta
            let maxLon = region.center.longitude + lonDelta
            
            return lat >= minLat && lat <= maxLat && lon >= minLon && lon <= maxLon
        }
    }
    
    // Filtered aircraft for performance
    private var visibleAircraft: [Aircraft] {
        let visible = getVisibleAircraft(in: currentMapRegion)
        print("[MapView] Total aircraft: \(aircraftList.count), Visible: \(visible.count), Region: \(currentMapRegion != nil)")
        return visible
    }
    
    // Aircraft counts for debug info - use visible aircraft for performance
    private var emergencyCount: Int {
        visibleAircraft.filter(\.isEmergency).count
    }
    
    private var militaryCount: Int {
        visibleAircraft.filter(\.isMilitary).count
    }
    
    private var whiteCount: Int {
        visibleAircraft.count - emergencyCount - militaryCount
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
        
        // Check for service errors - if data is older than 15 seconds, something is wrong
        let now = Date()
        let timeSinceLastUpdate = now.timeIntervalSince(service.lastUpdateTime)
        let shouldCheckError = now.timeIntervalSince(lastErrorCheck) > 15
        
        if shouldCheckError {
            let hasRecentError = timeSinceLastUpdate > 15 // Data should be fresher than 15 seconds
            
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
    
    private func panToAircraft(_ aircraft: Aircraft) {
        guard let lat = aircraft.lat, let lon = aircraft.lon else { 
            print("[MapView] Cannot pan to aircraft \(aircraft.hex): no coordinates")
            return 
        }
        
        print("[MapView] Panning to aircraft \(aircraft.hex) at \(lat), \(lon)")
        
        // Calculate offset to keep aircraft visible above the sheet
        let baseCoordinate = CLLocationCoordinate2D(latitude: lat, longitude: lon)
        let offsetCoordinate: CLLocationCoordinate2D
        
        if isDetailPresented && horizontalSizeClass == .compact {
            // On iPhone with sheet open, offset the center upward so aircraft is visible above sheet
            // Sheet covers about 50-60% of screen, so offset significantly more
            let latOffset = 0.05
            offsetCoordinate = CLLocationCoordinate2D(latitude: lat - latOffset, longitude: lon)
        } else {
            offsetCoordinate = baseCoordinate
        }
        
        let region = MKCoordinateRegion(
            center: offsetCoordinate,
            latitudinalMeters: 10000, // 10km radius for tighter zoom
            longitudinalMeters: 10000
        )
        
        withAnimation(.easeInOut(duration: 1.0)) {
            cameraPosition = .region(region)
        }
    }
    
    private func aircraftMapAnnotation(for aircraft: Aircraft) -> some MapContent {
        let isSimpleLabel = !isInfoBoxEnabled || aircraftService.currentZoomLevel <= 9
        let displayTitle: String = {
            if isSimpleLabel {
                return aircraft.formattedFlight.isEmpty ? aircraft.hex : aircraft.formattedFlight
            } else {
                return ""
            }
        }()
        let coordinate = CLLocationCoordinate2D(
            latitude: aircraft.lat ?? 0,
            longitude: aircraft.lon ?? 0
        )

        return Annotation(
            displayTitle,
            coordinate: coordinate,
            anchor: .top
        ) {
            aircraftMapMarkerView(for: aircraft, isSimpleLabel: isSimpleLabel)
        }
    }
    
    private func aircraftMapMarkerView(for aircraft: Aircraft, isSimpleLabel: Bool) -> some View {
        let iconName: String = {
            switch aircraft.feederType {
            case .aircraft:
                return "airplane"
            case .groundVehicle:
                return "car.fill"
            default:
                return "antenna.radiowaves.left.and.right"
            }
        }()
        let color: Color = {
            if aircraft.isEmergency {
                return .red
            } else if aircraft.isMilitary {
                return .green
            } else {
                return .white
            }
        }()
        let rotation = aircraft.feederType == .aircraft ? Double(aircraft.track ?? 0) - 90 : 0
        
        return VStack {
            MarkerView(
                size: 30,
                iconSystemName: iconName,
                fillColor: .black.opacity(0.5),
                foregroundColor: color
            )
            .rotationEffect(.degrees(rotation))
            
            if !isSimpleLabel {
                let labelText = aircraft.formattedFlight.isEmpty ? aircraft.hex : aircraft.formattedFlight
                Text(labelText)
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
            isDetailPresented = true
        }
        .zIndex(1)
    }
    
    var mapView: some View {
        Map(position: $cameraPosition) {
            UserAnnotation()
            
            ForEach(airportList, id: \.id) { airport in
                airportMapAnnotation(for: airport)
            }
            
            ForEach(visibleAircraft, id: \.hex) { aircraft in
                aircraftMapAnnotation(for: aircraft)
            }
        }
    }
    
    private func airportMapAnnotation(for airport: Airport) -> some MapContent {
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

    var body: some View {
        NavigationStack {
            ZStack {
                mapView
                    .mapStyle(mapStyleSelection == "satelite" ? .hybrid(elevation: .realistic) : .standard)
                    .mapControls {
                        MapUserLocationButton()
                        MapCompass()
#if !os(watchOS)
                        MapPitchToggle()
                        MapScaleView()
#endif
                    }
                    .onMapCameraChange(frequency: .continuous) { context in
                        currentMapRegion = context.region // Track current region for filtering
                    }
                    .onMapCameraChange(frequency: .onEnd) { context in
                        updateZoomLevel(with: context.region)
                        updateAircraftServiceLocation(with: context.region)
                    }
                    .toolbar {
                        ToolbarItem(placement: .topBarTrailing) {
                            MapFilterControlView()
                        }
                        
                        ToolbarItem(placement: .topBarTrailing) {
                            MapLegendView {
                                Label("Legend", systemImage: "info.circle.fill")
                            }
                        }
#if !os(watchOS)
                        ToolbarItem(placement: .topBarTrailing) {
                            MapStylePickerView(selection: $mapStyleSelection)
                        }
#endif
                    }
            }
        }
#if os(iOS)
        .inspector(isPresented: Binding(
            get: { isDetailPresented && horizontalSizeClass == .regular },
            set: { newValue in
                if !newValue {
                    isDetailPresented = false
                    selectedAircraft = nil
                }
            }
        )) {
            if let selectedAircraft {
                ZStack(alignment: .topLeading) {
                    AircraftDetailView(aircraft: selectedAircraft)
                        .presentationDetents([.medium, .large])
                        .presentationBackgroundInteraction(.enabled)
                        .presentationCompactAdaptation(.sheet)
                        .presentationDragIndicator(.visible)
                    
                    if horizontalSizeClass == .regular {
                        Button {
                            withAnimation {
                                isDetailPresented = false
                                self.selectedAircraft = nil
                            }
                        } label: {
                            Label("Close", systemImage: "xmark")
                        }
                        .padding(.leading, 20)
                        .padding(.bottom, 10)
                    }
                }
            }
        }
        .sheet(isPresented: Binding(
            get: { isDetailPresented && horizontalSizeClass == .compact && selectedAircraft != nil },
            set: { newValue in
                if !newValue {
                    isDetailPresented = false
                    selectedAircraft = nil
                }
            }
        )) {
            if let selectedAircraft {
                NavigationStack {
                    AircraftDetailView(aircraft: selectedAircraft)
                        .navigationTitle(selectedAircraft.formattedFlight)
                        .navigationBarTitleDisplayMode(.inline)
                }
                .presentationDetents([.medium, .large])
                .presentationBackgroundInteraction(.enabled)
            }
        }
#endif
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
        .onChange(of: selectedAircraft) { _, aircraft in
            // Pan to selected aircraft from ListView and show inspector
            if let aircraft = aircraft {
                // Add a small delay to ensure the map is fully loaded when switching tabs
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    panToAircraft(aircraft)
                }
                isDetailPresented = true
            } else {
                isDetailPresented = false
            }
        }
    }
}

#Preview {
    MapView(selectedAircraft: .constant(nil))
}
