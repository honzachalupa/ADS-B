import SwiftUI
import Combine

let FILTER_SHOW_REGULAR_AIRCRAFTS_KEY = "filter_showRegularAircraft"
let FILTER_SHOW_PIA_AIRCRAFTS_KEY = "filter_showPIAAircraft"
let FILTER_SHOW_MILITARY_AIRCRAFTS_KEY = "filter_showMilitaryAircraft"
let FILTER_SHOW_LADD_AIRCRAFTS_KEY = "filter_showLADDAircraft"

enum AircraftEndpointType {
    case regular(latitude: Double, longitude: Double, radius: Int)
    case pia
    case military
    case ladd
    
    var urlPath: String {
        switch self {
            case .regular(let latitude, let longitude, let radius):
                return "/lat/\(latitude)/lon/\(longitude)/dist/\(radius)"
            case .pia:
                return "/pia"
            case .military:
                return "/mil"
            case .ladd:
                return "/ladd"
        }
    }
    
    var description: String {
        switch self {
            case .regular:
                return "Regular Aircraft"
            case .pia:
                return "Privacy ICAO Address Aircraft"
            case .military:
                return "Military Aircraft"
            case .ladd:
                return "Limited Aircraft Data Display Aircraft"
        }
    }
}

class AircraftService: ObservableObject {
    // Singleton instance
    static let shared = AircraftService()
    
    private init() {
        // Set default values for filter keys if not already set
        let defaults = UserDefaults.standard
        
        if defaults.object(forKey: FILTER_SHOW_REGULAR_AIRCRAFTS_KEY) == nil {
            defaults.set(true, forKey: FILTER_SHOW_REGULAR_AIRCRAFTS_KEY)
        }
        
        if defaults.object(forKey: FILTER_SHOW_PIA_AIRCRAFTS_KEY) == nil {
            defaults.set(true, forKey: FILTER_SHOW_PIA_AIRCRAFTS_KEY)
        }
        
        if defaults.object(forKey: FILTER_SHOW_MILITARY_AIRCRAFTS_KEY) == nil {
            defaults.set(true, forKey: FILTER_SHOW_MILITARY_AIRCRAFTS_KEY)
        }
        
        if defaults.object(forKey: FILTER_SHOW_LADD_AIRCRAFTS_KEY) == nil {
            defaults.set(true, forKey: FILTER_SHOW_LADD_AIRCRAFTS_KEY)
        }
    }
    
    @Published var aircraft: [Aircraft] = []
    @Published var isLoading: Bool = false
    @Published var error: Error? = nil
    
    private var cancellables = Set<AnyCancellable>()
    private var aircraftCache: [String: (aircraft: Aircraft, timestamp: Date, endpointType: AircraftEndpointType)] = [:]
    private let cacheRetentionTime: TimeInterval = 10.0
    private let baseURL = "https://api.adsb.lol/v2"
    // Current map center coordinates and zoom level for fetching aircraft data
    internal private(set) var currentLatitude: Double = 0
    internal private(set) var currentLongitude: Double = 0
    // Timer for polling
    private var refreshTimer: Timer?
    @Published private(set) var currentInterval: Int = 5
    @Published private(set) var currentZoomLevel: Double = 15.0 // Default zoom level
    @Published private(set) var lastUpdateTime: Date = .now
    
    // Calculate dynamic refresh interval based on zoom level
    private func calculateRefreshInterval(for zoomLevel: Double) -> Int {
        // Zoom level reference points:
        // - 20: Street level (most zoomed in) -> 5s refresh
        // - 15: City level -> 5s refresh
        // - 10: Regional level -> ~12s refresh
        // - 5: Country level (most zoomed out) -> 30s refresh
        
        let zoomScale = min(max(zoomLevel, 5), 20) // Clamp zoom level between 5 and 20
        
        // For city/street level (15+), use 5s minimum
        if zoomScale >= 15 {
            return 5
        }
        
        // For zoomed out levels (5-15), scale from 5s to 30s
        // Normalize zoom scale to 0-1 range (15->0, 5->1)
        let normalizedZoom = (15.0 - zoomScale) / 10.0
        
        // Use exponential scaling for more natural progression
        // Base: 5 seconds
        // Multiplier range: 1.0 to 6.0 (5s to 30s)
        let multiplier = pow(6.0, normalizedZoom)
        
        // Calculate the actual interval
        let interval = 5.0 * multiplier // Base interval of 5 seconds
        
        // Round to nearest second and ensure bounds
        return Int(min(max(interval.rounded(), 5), 30))
    }
    
    // Update map center coordinates and zoom level
    func updateMapCenter(latitude: Double, longitude: Double, zoomLevel: Double? = nil) {
        let shouldRestartPolling = (currentLatitude != latitude || currentLongitude != longitude)
        
        currentLatitude = latitude
        currentLongitude = longitude
        
        if let zoomLevel = zoomLevel, zoomLevel != currentZoomLevel {
            currentZoomLevel = zoomLevel
            // Restart polling with new interval if coordinates changed or zoom level changed significantly
            let newInterval = calculateRefreshInterval(for: zoomLevel)
            if currentInterval != newInterval {
                startPolling(latitude: latitude, longitude: longitude)
            }
        }
        
        // If coordinates changed, fetch data immediately
        if shouldRestartPolling {
            // Fetch data immediately for the new location
            fetchAllSelectedAircraftTypes(latitude: latitude, longitude: longitude)
            // Then restart the polling timer with current interval
            startPolling(latitude: latitude, longitude: longitude)
        }
    }
    
    // Fetch aircraft from a specific endpoint type
    func fetchAircraft(from endpointType: AircraftEndpointType) {
        isLoading = true
        error = nil
        
        let urlString = "\(baseURL)\(endpointType.urlPath)"
        
        guard let url = URL(string: urlString) else {
            self.error = NSError(domain: "AircraftService", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])
            self.isLoading = false
            return
        }
        
        print("[AircraftService] 🔍 Fetching aircraft from endpoint: \(endpointType.description)")
        
        URLSession.shared.dataTaskPublisher(for: url)
            .map { output -> Data in
                return output.data
            }
            .tryMap { data -> Data in
                // Try to decode a small part of the response to validate JSON structure
                do {
                    let jsonObject = try JSONSerialization.jsonObject(with: data)
                    
                    // Detailed logging to diagnose issues
                    if let json = jsonObject as? [String: Any] {
                        if let aircraft = json["ac"] as? [[String: Any]], !aircraft.isEmpty {
                            print("[AircraftService] 🛩️ Found \(aircraft.count) aircraft in response")
                        } else {
                            print("[AircraftService] ⚠️ No aircraft array found or it's empty")
                        }
                    }
                } catch {
                    print("[AircraftService] ❌ Invalid JSON structure: \(error.localizedDescription)")
                    throw error
                }
                return data
            }
            .tryMap { data -> AircraftResponse in
                #if os(watchOS)
                // On watchOS, always use manual parsing to avoid large integer issues
                if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let aircraftArray = json["ac"] as? [[String: Any]] {
                    
                    print("[AircraftService] 🔧 watchOS: Manual extraction of \(aircraftArray.count) aircraft")
                    
                    // Process each aircraft manually
                    var validAircraft: [Aircraft] = []
                    
                    for aircraftJson in aircraftArray {
                        // Create sanitized JSON by converting large numbers to strings
                        var sanitizedJson = [String: Any]()
                        
                        for (key, value) in aircraftJson {
                            if let intValue = value as? Int, intValue > Int32.max {
                                // Convert large integers to strings
                                sanitizedJson[key] = String(intValue)
                            } else {
                                sanitizedJson[key] = value
                            }
                        }
                        
                        do {
                            let aircraftData = try JSONSerialization.data(withJSONObject: sanitizedJson)
                            let decoder = JSONDecoder()
                            let aircraft = try decoder.decode(Aircraft.self, from: aircraftData)
                            
                            // Only add valid aircraft with coordinates
                            if aircraft.isValid {
                                validAircraft.append(aircraft)
                            }
                        } catch {
                            // Just continue with next aircraft
                        }
                    }
                    
                    if !validAircraft.isEmpty {
                        print("[AircraftService] ✅ Successfully decoded \(validAircraft.count) aircraft on watchOS")
                        let response = AircraftResponse(
                            ac: validAircraft,
                            ctime: (json["ctime"] as? Int) ?? 0,
                            msg: (json["msg"] as? String) ?? "watchOS decode",
                            now: (json["now"] as? Int) ?? 0,
                            ptime: (json["ptime"] as? Int) ?? 0,
                            total: validAircraft.count
                        )
                        return response
                    }
                }
                #else
                // On iOS, try standard decoding first
                let decoder = JSONDecoder()
                do {
                    return try decoder.decode(AircraftResponse.self, from: data)
                } catch {
                    // Standard decoding failed, falling back to manual parsing
                    
                    // Fall back to manual parsing
                    if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                       let aircraftArray = json["ac"] as? [[String: Any]] {
                        
                        print("[AircraftService] 🔧 iOS: Attempting manual extraction of \(aircraftArray.count) aircraft")
                        
                        // Try to decode each aircraft individually
                        var validAircraft: [Aircraft] = []
                        
                        for aircraftJson in aircraftArray {
                            do {
                                let aircraftData = try JSONSerialization.data(withJSONObject: aircraftJson)
                                let aircraft = try decoder.decode(Aircraft.self, from: aircraftData)
                                if aircraft.isValid {
                                    validAircraft.append(aircraft)
                                }
                            } catch {
                                // Continue with next aircraft
                            }
                        }
                        
                        if !validAircraft.isEmpty {
                            print("[AircraftService] ✅ Successfully decoded \(validAircraft.count) aircraft manually")
                            let response = AircraftResponse(
                                ac: validAircraft,
                                ctime: (json["ctime"] as? Int) ?? 0,
                                msg: (json["msg"] as? String) ?? "Partial decode",
                                now: (json["now"] as? Int) ?? 0,
                                ptime: (json["ptime"] as? Int) ?? 0,
                                total: validAircraft.count
                            )
                            return response
                        }
                    }
                }
                #endif
                    
                    // Return an empty response instead of creating a dummy aircraft
                    return AircraftResponse(
                        ac: [],
                        ctime: 0,
                        msg: "No aircraft data could be decoded",
                        now: 0,
                        ptime: 0,
                        total: 0
                    )
                }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                guard let self = self else { return }
                self.isLoading = false
                
                if case .failure(let error) = completion {
                    self.error = error
                    print("[AircraftService] ❌ Error fetching aircraft data: \(error.localizedDescription)")
                }
            } receiveValue: { [weak self] response in
                guard let self = self else { return }
                
                // Only filter out aircraft without valid coordinates
                let validAircraft = response.ac.filter { $0.isValid }
                
                // Update the cache with new aircraft data
                self.updateAircraftCache(with: validAircraft, endpointType: endpointType)
                
                // Get all valid aircraft (from current response and recent cache)
                let combinedAircraft = self.getCombinedAircraftList()
                
                // Update the published aircraft list and last update time
                DispatchQueue.main.async {
                    self.aircraft = combinedAircraft
                    self.lastUpdateTime = .now
                    print("[AircraftService] ✅ Updated \(combinedAircraft.count) aircraft")
                }
            }
            .store(in: &cancellables)
    
    }
    
    // Fetch aircraft around a specific location (convenience method)
    func fetchAircraftAroundLocation(latitude: Double, longitude: Double) {
        // Get the search range from settings, default to 100 if not set
        let searchRange = UserDefaults.standard.integer(forKey: "settings_searchRange")
        let range = searchRange > 0 ? searchRange : 100
        
        fetchAircraft(from: .regular(latitude: latitude, longitude: longitude, radius: range))
    }
    
    // Fetch all selected aircraft types based on user settings
    func fetchAllSelectedAircraftTypes(latitude: Double, longitude: Double) {
        let showRegular = UserDefaults.standard.bool(forKey: FILTER_SHOW_REGULAR_AIRCRAFTS_KEY)
        let showPIA = UserDefaults.standard.bool(forKey: FILTER_SHOW_PIA_AIRCRAFTS_KEY)
        let showMilitary = UserDefaults.standard.bool(forKey: FILTER_SHOW_MILITARY_AIRCRAFTS_KEY)
        let showLADD = UserDefaults.standard.bool(forKey: FILTER_SHOW_LADD_AIRCRAFTS_KEY)
        
        // Get the search range from settings
        let searchRange = UserDefaults.standard.integer(forKey: "settings_searchRange")
        let range = searchRange > 0 ? searchRange : 100
        
        // Cancel any existing requests
        cancellables.forEach { $0.cancel() }
        cancellables.removeAll()
        
        // Create a group of publishers for each selected endpoint
        var publishers: [AnyPublisher<Void, Never>] = []
        
        if showRegular {
            publishers.append(fetchAircraftPublisher(from: .regular(latitude: latitude, longitude: longitude, radius: range)))
        }
        
        if showPIA {
            publishers.append(fetchAircraftPublisher(from: .pia))
        }
        
        if showMilitary {
            publishers.append(fetchAircraftPublisher(from: .military))
        }
        
        if showLADD {
            publishers.append(fetchAircraftPublisher(from: .ladd))
        }
        
        // If no aircraft types are selected, default to regular
        if publishers.isEmpty && !showRegular {
            publishers.append(fetchAircraftPublisher(from: .regular(latitude: latitude, longitude: longitude, radius: range)))
        }
        
        // Merge all publishers and subscribe
        Publishers.MergeMany(publishers)
            .sink { _ in }
            .store(in: &cancellables)
    }
    
    // Create a publisher for fetching aircraft from a specific endpoint
    private func fetchAircraftPublisher(from endpointType: AircraftEndpointType) -> AnyPublisher<Void, Never> {
        Future<Void, Never> { promise in
            self.fetchAircraft(from: endpointType)
            promise(.success(()))
        }.eraseToAnyPublisher()
    }
    
    // Start polling for aircraft data with the interval from settings
    func startPolling(latitude: Double, longitude: Double) {
        // Get the dynamic refresh interval based on zoom level
        let newInterval = calculateRefreshInterval(for: currentZoomLevel)
        print("[AircraftService] 🗺️ New refresh interval: \(newInterval)s (zoom: \(String(format: "%.1f", currentZoomLevel)))")
        
        // If interval hasn't changed and timer exists, do nothing
        if refreshTimer != nil, currentInterval == newInterval {
            print("[AircraftService] ⏱️ Polling already active with interval: \(currentInterval) seconds")
            return
        }
        
        // Stop any existing timer
        stopPolling()
        
        // Store the new interval
        currentInterval = newInterval
        
        print("[AircraftService] ⏱️ Starting aircraft polling with interval: \(currentInterval) seconds")
        
        // Create a new timer with the updated interval
        refreshTimer = Timer.scheduledTimer(withTimeInterval: TimeInterval(currentInterval), repeats: true) { [weak self] _ in
            guard let self = self else { return }
            print("[AircraftService] 🔄 Refreshing aircraft data... (interval: \(self.currentInterval)s)")
            self.fetchAllSelectedAircraftTypes(latitude: self.currentLatitude, longitude: self.currentLongitude)
        }
        
        // Add the timer to the RunLoop
        if let timer = refreshTimer {
            RunLoop.main.add(timer, forMode: .common)
        }
    }
    
    // Stop polling
    func stopPolling() {
        // Cancel any existing Combine publishers
        cancellables.forEach { $0.cancel() }
        cancellables.removeAll()
        
        // Invalidate the timer
        refreshTimer?.invalidate()
        refreshTimer = nil
        
        print("[AircraftService] ⏹️ Polling stopped")
    }
    
    // MARK: - Cache Management
    
    // Update the aircraft cache with new data
    private func updateAircraftCache(with aircraft: [Aircraft], endpointType: AircraftEndpointType) {
        let now = Date()
        
        // Add new aircraft to the cache
        for plane in aircraft {
            aircraftCache[plane.hex] = (aircraft: plane, timestamp: now, endpointType: endpointType)
        }
        
        // Remove stale entries
        aircraftCache = aircraftCache.filter { _, value in
            now.timeIntervalSince(value.timestamp) < cacheRetentionTime
        }
    }
    
    // Get a combined list of aircraft from the current response and recent cache
    private func getCombinedAircraftList() -> [Aircraft] {
        // Get user preferences for which aircraft types to show
        let showRegular = UserDefaults.standard.bool(forKey: FILTER_SHOW_REGULAR_AIRCRAFTS_KEY)
        let showPIA = UserDefaults.standard.bool(forKey: FILTER_SHOW_PIA_AIRCRAFTS_KEY)
        let showMilitary = UserDefaults.standard.bool(forKey: FILTER_SHOW_MILITARY_AIRCRAFTS_KEY)
        let showLADD = UserDefaults.standard.bool(forKey: FILTER_SHOW_LADD_AIRCRAFTS_KEY)
        
        print("[AircraftService] 🔍 Filter settings - Regular: \(showRegular), PIA: \(showPIA), Military: \(showMilitary), LADD: \(showLADD)")
        
        // Filter cached aircraft based on user preferences
        let filteredAircraft = aircraftCache.values.filter { cachedAircraft in
            switch cachedAircraft.endpointType {
            case .regular:
                return showRegular
            case .pia:
                return showPIA
            case .military:
                return showMilitary
            case .ladd:
                return showLADD
            }
        }.map { $0.aircraft }
        
        print("[AircraftService] ✅ Filtered aircraft count: \(filteredAircraft.count)")
        
        return filteredAircraft.sorted { a, b in
            // Sort by distance or altitude if available
            if let altA = a.alt_baro, let altB = b.alt_baro {
                return altA > altB
            }
            return false
        }
    }
    
    // ...
    private func cleanupCache() {
        let currentTime = Date()
        let keysToRemove = aircraftCache.filter { entry in
            currentTime.timeIntervalSince(entry.value.timestamp) > cacheRetentionTime
        }.keys
        
        for key in keysToRemove {
            aircraftCache.removeValue(forKey: key)
        }
    }
}
