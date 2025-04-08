import SwiftUI
import Combine

// MARK: - API Response Structures
struct AirportDataResponse: Codable {
    let status: Int
    let count: Int
    let data: [AirportDataPhoto]
}

struct AirportDataPhoto: Codable {
    let image: String // URL string for the thumbnail
    let link: String
    let photographer: String
}

// MARK: - AircraftPhotoService
class AircraftPhotoService: ObservableObject {
    @Published private(set) var photo: Image?
    @Published private(set) var isLoading = false
    @Published private(set) var error: Error?
    
    private var cancellables = Set<AnyCancellable>()
    private let cache = NSCache<NSString, NSData>()
    private let imageDataCache = NSCache<NSString, NSData>()
    
    func fetchPhoto(for aircraft: Aircraft) {
        // Reset state
        isLoading = true
        error = nil
        print("[AircraftPhotoService] Fetching photo for aircraft: \(aircraft.hex)")
        
        let cacheKey = (aircraft.hex + "_airportdata") as NSString // Use hex + suffix for cache
        
        // Check cache first
        if let cachedData = cache.object(forKey: cacheKey),
           let platformImage = UIImage(data: cachedData as Data) {
            print("[AircraftPhotoService] Cache hit for \(aircraft.hex)")
            photo = Image(uiImage: platformImage)
            isLoading = false
            return
        }
        print("[AircraftPhotoService] Cache miss for \(aircraft.hex)")
        
        // Construct API URL using ICAO hex code
        let hexCode = aircraft.hex.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines).lowercased()
        guard !hexCode.isEmpty,
              let searchURL = URL(string: "https://airport-data.com/api/ac_thumb.json?m=\(hexCode)&n=1") else {
            print("[AircraftPhotoService] Invalid or missing ICAO hex code.")
            self.error = NSError(domain: "AircraftPhotoService", code: 10, userInfo: [NSLocalizedDescriptionKey: "Invalid or missing ICAO hex code"])
            isLoading = false
            return
        }
        
        print("[AircraftPhotoService] API URL: \(searchURL)")
        
        // Fetch API data
        URLSession.shared.dataTaskPublisher(for: searchURL)
            .map(\.data)
            .decode(type: AirportDataResponse.self, decoder: JSONDecoder())
            .tryMap { response -> URL in
                print("[AircraftPhotoService] API Response Status: \(response.status), Count: \(response.count)")
                guard response.status == 200, let firstPhoto = response.data.first else {
                    print("[AircraftPhotoService] No photo data found in API response.")
                    throw NSError(domain: "AircraftPhotoService", code: 11, userInfo: [NSLocalizedDescriptionKey: "No photo data found in API response"])
                }
                
                // Try to guess the high-res URL first, fall back to thumbnail
                let highResGuessUrlString = firstPhoto.image.replacingOccurrences(of: "/thumbnails/", with: "/large/")
                if let highResUrl = URL(string: highResGuessUrlString) {
                    print("[AircraftPhotoService] Trying high-res guess URL: \(highResUrl)")
                    return highResUrl // Attempt to use the guessed high-res URL
                }
                
                // Fallback to the thumbnail URL if guessing failed or wasn't possible
                guard let photoURL = URL(string: firstPhoto.image) else {
                    print("[AircraftPhotoService] Invalid thumbnail URL in API response.")
                    throw NSError(domain: "AircraftPhotoService", code: 14, userInfo: [NSLocalizedDescriptionKey: "Invalid thumbnail URL in API response"])
                }
                print("[AircraftPhotoService] Falling back to thumbnail URL: \(photoURL)")
                return photoURL
            }
            .flatMap { photoURL in
                // Fetch the actual photo thumbnail
                URLSession.shared.dataTaskPublisher(for: photoURL)
                    .map(\.data)
                    .tryMap { data -> (Image, Data) in
                        guard let platformImage = UIImage(data: data) else {
                            print("[AircraftPhotoService] Invalid image data received from API URL.")
                            throw NSError(domain: "AircraftPhotoService", code: 12, userInfo: [NSLocalizedDescriptionKey: "Invalid image data from API"])
                        }
                        #if os(iOS)
                        let swiftUIImage = Image(uiImage: platformImage)
                        #else
                        let swiftUIImage = Image(nsImage: platformImage)
                        #endif
                        return (swiftUIImage, data)
                    }
            }
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.isLoading = false
                    if case .failure(let error) = completion {
                        // Handle decoding errors, network errors, or the 'no photo found' error
                        print("[AircraftPhotoService] Error processing API data or fetching image: \(error.localizedDescription)")
                        if let nsError = error as NSError?, nsError.domain == "AircraftPhotoService" {
                             self?.error = error // Keep our custom errors
                        } else {
                            // Generic error for network/decoding issues
                            self?.error = NSError(domain: "AircraftPhotoService", code: 13, userInfo: [NSLocalizedDescriptionKey: "Failed to fetch or process photo data: \(error.localizedDescription)"])
                        }
                    }
                },
                receiveValue: { [weak self] (image, data) in
                    guard let self = self else { return }
                    print("[AircraftPhotoService] Successfully fetched and decoded image via API.")
                    self.photo = image
                    // Cache the image data using the hex code
                    self.cache.setObject(data as NSData, forKey: cacheKey)
                }
            )
            .store(in: &cancellables)
    }
    
    func cancelLoading() {
        cancellables.forEach { $0.cancel() }
        cancellables.removeAll()
        isLoading = false
    }
}
