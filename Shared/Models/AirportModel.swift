import Foundation
import MapKit

struct Airport: Codable, Identifiable {
    let id: String
    let icao: String
    let iata: String?
    let name: String
    let lat: Double
    let lon: Double
    let location: String?
    let countryiso2: String?
    let alt_feet: Double?
    let alt_meters: Double?
    
    enum CodingKeys: String, CodingKey {
        case icao, iata, name, lat, lon, location, countryiso2, alt_feet, alt_meters
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        icao = try container.decode(String.self, forKey: .icao)
        id = icao // Use ICAO as the ID
        iata = try container.decodeIfPresent(String.self, forKey: .iata)
        name = try container.decode(String.self, forKey: .name)
        lat = try container.decode(Double.self, forKey: .lat)
        lon = try container.decode(Double.self, forKey: .lon)
        location = try container.decodeIfPresent(String.self, forKey: .location)
        countryiso2 = try container.decodeIfPresent(String.self, forKey: .countryiso2)
        alt_feet = try container.decodeIfPresent(Double.self, forKey: .alt_feet)
        alt_meters = try container.decodeIfPresent(Double.self, forKey: .alt_meters)
    }
    
    // For manually creating airports
    init(id: String, icao: String, iata: String?, name: String, lat: Double, lon: Double, location: String?, countryiso2: String?, alt_feet: Double?, alt_meters: Double?) {
        self.id = id
        self.icao = icao
        self.iata = iata
        self.name = name
        self.lat = lat
        self.lon = lon
        self.location = location
        self.countryiso2 = countryiso2
        self.alt_feet = alt_feet
        self.alt_meters = alt_meters
    }
    
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: lat, longitude: lon)
    }
    
    var formattedAltitude: String {
        if let alt = alt_feet {
            return "\(Int(alt)) ft"
        }
        return "N/A"
    }
}

class AirportAnnotation: NSObject, MKAnnotation {
    let airport: Airport
    var coordinate: CLLocationCoordinate2D
    
    init(airport: Airport) {
        self.airport = airport
        self.coordinate = airport.coordinate
        super.init()
    }
    
    var title: String? { "\(airport.name) (\(airport.icao))" }
    var subtitle: String? { airport.iata != nil ? "IATA: \(airport.iata!)" : nil }
}
