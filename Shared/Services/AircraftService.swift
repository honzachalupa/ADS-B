import SwiftUI
import Combine

class AircraftService: ObservableObject {
    // Singleton instance
    static let shared = AircraftService()
    
    private init() {}
    
    @Published var aircrafts: [Aircraft] = []
    @Published var isLoading: Bool = false
    @Published var error: Error? = nil
    
    private var cancellables = Set<AnyCancellable>()
    private var aircraftCache: [String: (aircraft: Aircraft, timestamp: Date)] = [:]
    private let cacheRetentionTime: TimeInterval = 10.0
    private let baseURL = "https://api.adsb.lol/v2"
    
    // Fetch aircraft around a specific location
    func fetchAircraftAroundLocation(latitude: Double, longitude: Double) {
        isLoading = true
        error = nil
        
        // Get the search range from settings, default to 100 if not set
        let searchRange = UserDefaults.standard.double(forKey: SETTINGS_SEARCH_RANGE_KEY)
        let range = searchRange > 0 ? Int(searchRange) : 100
        
        let urlString = "\(baseURL)/lat/\(latitude)/lon/\(longitude)/dist/\(range)"
        
        guard let url = URL(string: urlString) else {
            self.error = NSError(domain: "AircraftService", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])
            self.isLoading = false
            return
        }
        
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
                        print("[AircraftService] 📊 JSON root keys: \(json.keys.joined(separator: ", "))")
                        
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
            .sink { completion in
                self.isLoading = false
                
                if case .failure(let error) = completion {
                    self.error = error
                    // Error fetching aircraft data
                }
            } receiveValue: { response in
                // Only filter out aircraft without valid coordinates
                let validAircraft = response.ac.filter { $0.isValid }
                
                // Update the cache with new aircraft data
                self.updateAircraftCache(with: validAircraft)
                
                // Get all valid aircraft (from current response and recent cache)
                let combinedAircraft = self.getCombinedAircraftList()
                
                // Update the published aircraft list
                self.aircrafts = combinedAircraft
                // Successfully fetched and processed aircraft data
            }
            .store(in: &cancellables)
    
    }
    
    // Start polling for aircraft data with the interval from settings
    func startPolling(latitude: Double, longitude: Double) {
        // Get the fetch interval from settings
        let fetchInterval = UserDefaults.standard.double(forKey: SETTINGS_FETCH_INTERVAL_KEY)
        
        // Use default of 5 seconds if not set
        let interval = fetchInterval > 0 ? fetchInterval : 5.0
        
        // Cancel any existing timers
        cancellables.forEach { $0.cancel() }
        cancellables.removeAll()
        
        // Starting aircraft polling with the configured interval
        
        // Create a timer that fires at the configured interval
        Timer.publish(every: interval, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.fetchAircraftAroundLocation(latitude: latitude, longitude: longitude)
            }
            .store(in: &cancellables)
        
        // Initial fetch
        fetchAircraftAroundLocation(latitude: latitude, longitude: longitude)
    }
    
    // Stop polling
    func stopPolling() {
        cancellables.forEach { $0.cancel() }
        cancellables.removeAll()
    }
    
    // MARK: - Cache Management
    
    // Update the cache with new aircraft data
    private func updateAircraftCache(with newAircraft: [Aircraft]) {
        let currentTime = Date()
        
        // Add or update aircraft in the cache
        for aircraft in newAircraft {
            aircraftCache[aircraft.hex] = (aircraft: aircraft, timestamp: currentTime)
        }
        
        // Remove expired aircraft from cache
        cleanupCache()
    }
    
    // Get combined list of current aircraft and cached aircraft
    private func getCombinedAircraftList() -> [Aircraft] {
        // Get all aircraft from cache that haven't expired
        return Array(aircraftCache.values.map { $0.aircraft })
    }
    
    // Remove expired aircraft from cache
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
