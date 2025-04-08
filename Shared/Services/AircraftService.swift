import Foundation
import Combine

// Import models
import SwiftUI

class AircraftService: ObservableObject {
    @Published var aircrafts: [Aircraft] = []
    @Published var isLoading: Bool = false
    @Published var error: Error? = nil
    
    private var cancellables = Set<AnyCancellable>()
    private let baseURL = "https://api.adsb.lol/v2"
    
    // Fetch aircraft around a specific location
    func fetchAircraftAroundLocation(latitude: Double, longitude: Double) {
        isLoading = true
        error = nil
        
        let urlString = "\(baseURL)/lat/\(latitude)/lon/\(longitude)/dist/54" // 54 nm == 100 km
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
                // Filter out aircraft without valid coordinates
                let validAircraft = response.ac.filter { $0.hasValidCoordinates }
                self.aircrafts = validAircraft
                print("✅ Successfully fetched \(response.ac.count) aircraft (\(validAircraft.count) with valid coordinates)")
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
}
