import SwiftUI
import Combine

class AircraftService: ObservableObject {
    @Published var aircrafts: [Aircraft] = []
    @Published var isLoading: Bool = false
    @Published var error: Error? = nil
    
    // Cache to store recently seen aircraft with timestamps
    private var aircraftCache: [String: (aircraft: Aircraft, timestamp: Date)] = [:]
    // How long to keep aircraft in cache (in seconds)
    private let cacheRetentionTime: TimeInterval = 10.0
    
    private var cancellables = Set<AnyCancellable>()
    private let baseURL = "https://api.adsb.lol/v2"
    
    // Fetch aircraft around a specific location
    func fetchAircraftAroundLocation(latitude: Double, longitude: Double) {
        isLoading = true
        error = nil
        
        let urlString = "\(baseURL)/lat/\(latitude)/lon/\(longitude)/dist/100"
        print("🔍 Fetching aircraft data from: \(urlString)")
        
        guard let url = URL(string: urlString) else {
            self.error = NSError(domain: "AircraftService", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])
            self.isLoading = false
            print("❌ Invalid URL: \(urlString)")
            return
        }
        
        URLSession.shared.dataTaskPublisher(for: url)
            .map { output -> Data in
                // Log the raw response for debugging
                print("📡 Received response with \(output.data.count) bytes")
                if let jsonString = String(data: output.data, encoding: .utf8) {
                    print("📄 Raw JSON response (first 500 chars): \(String(jsonString.prefix(500)))...")
                }
                return output.data
            }
            .tryMap { data -> Data in
                // Try to decode a small part of the response to validate JSON structure
                do {
                    let _ = try JSONSerialization.jsonObject(with: data)
                    print("✅ JSON structure is valid")
                } catch {
                    print("❌ Invalid JSON structure: \(error.localizedDescription)")
                    throw error
                }
                return data
            }
            .decode(type: AircraftResponse.self, decoder: JSONDecoder())
            .receive(on: DispatchQueue.main)
            .sink { completion in
                self.isLoading = false
                
                if case .failure(let error) = completion {
                    self.error = error
                    print("❌ Error fetching aircraft data: \(error.localizedDescription)")
                    
                    // Provide more detailed error information for debugging
                    if let decodingError = error as? DecodingError {
                        switch decodingError {
                        case .typeMismatch(let type, let context):
                            print("   Type mismatch: Expected \(type) at \(context.codingPath)")
                        case .valueNotFound(let type, let context):
                            print("   Value not found: Expected \(type) at \(context.codingPath)")
                        case .keyNotFound(let key, let context):
                            print("   Key not found: \(key) at \(context.codingPath)")
                        case .dataCorrupted(let context):
                            print("   Data corrupted: \(context.debugDescription)")
                        @unknown default:
                            print("   Unknown decoding error")
                        }
                    }
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
                print("✅ Successfully fetched \(response.ac.count) aircraft (\(validAircraft.count) with valid coordinates, \(combinedAircraft.count) after caching)")
            }
            .store(in: &cancellables)
    }
    
    // Start polling for aircraft data every second
    func startPolling(latitude: Double, longitude: Double) {
        // Cancel any existing timers
        cancellables.forEach { $0.cancel() }
        cancellables.removeAll()
        
        // Create a timer that fires every second
        Timer.publish(every: 1.0, on: .main, in: .common)
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
