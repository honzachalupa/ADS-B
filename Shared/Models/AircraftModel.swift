import Foundation
import MapKit
import SwiftUI

// MARK: - Helper Types
// Flexible value type to handle different data formats from the API
struct FlexibleValue: Codable {
    // Private storage properties
    private let _stringValue: String?
    private let _intValue: Int?
    private let _doubleValue: Double?
    private let _boolValue: Bool?
    
    // Computed properties to get values in different formats
    var intValue: Int? {
        if let intVal = _intValue {
            return intVal
        } else if let doubleVal = _doubleValue {
            return Int(doubleVal)
        } else if let stringVal = _stringValue, let intFromString = Int(stringVal) {
            return intFromString
        } else if let boolVal = _boolValue {
            return boolVal ? 1 : 0
        }
        return nil
    }
    
    var doubleValue: Double? {
        if let doubleVal = _doubleValue {
            return doubleVal
        } else if let intVal = _intValue {
            return Double(intVal)
        } else if let stringVal = _stringValue, let doubleFromString = Double(stringVal) {
            return doubleFromString
        } else if let boolVal = _boolValue {
            return boolVal ? 1.0 : 0.0
        }
        return nil
    }
    
    var stringValue: String? {
        if let stringVal = _stringValue {
            return stringVal
        } else if let intVal = _intValue {
            return String(intVal)
        } else if let doubleVal = _doubleValue {
            return String(doubleVal)
        } else if let boolVal = _boolValue {
            return String(boolVal)
        }
        return nil
    }
    
    var boolValue: Bool? {
        if let boolVal = _boolValue {
            return boolVal
        } else if let intVal = _intValue {
            return intVal != 0
        } else if let doubleVal = _doubleValue {
            return doubleVal != 0
        } else if let stringVal = _stringValue?.lowercased() {
            return stringVal == "true" || stringVal == "yes" || stringVal == "1"
        }
        return nil
    }
    
    // Custom init to handle different types
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        
        // Try to decode as different types
        if let intVal = try? container.decode(Int.self) {
            _intValue = intVal
            _doubleValue = nil
            _stringValue = nil
            _boolValue = nil
        } else if let doubleVal = try? container.decode(Double.self) {
            _doubleValue = doubleVal
            _intValue = nil
            _stringValue = nil
            _boolValue = nil
        } else if let stringVal = try? container.decode(String.self) {
            _stringValue = stringVal
            _intValue = nil
            _doubleValue = nil
            _boolValue = nil
        } else if let boolVal = try? container.decode(Bool.self) {
            _boolValue = boolVal
            _intValue = nil
            _doubleValue = nil
            _stringValue = nil
        } else if container.decodeNil() {
            // If explicitly nil, set all to nil
            _intValue = nil
            _doubleValue = nil
            _stringValue = nil
            _boolValue = nil
        } else {
            // If we can't decode as any of the expected types, set all to nil
            _intValue = nil
            _doubleValue = nil
            _stringValue = nil
            _boolValue = nil
        }
    }
    
    // Encode function - encode in the most appropriate format
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        if let intVal = _intValue {
            try container.encode(intVal)
        } else if let doubleVal = _doubleValue {
            try container.encode(doubleVal)
        } else if let stringVal = _stringValue {
            try container.encode(stringVal)
        } else if let boolVal = _boolValue {
            try container.encode(boolVal)
        } else {
            try container.encodeNil()
        }
    }
}

// Use FlexibleValue for altitude as well
typealias AltitudeValue = FlexibleValue

// MARK: - Aircraft Models
// A simplified model for the API response
struct AircraftResponse: Codable {
    let ac: [Aircraft]
    let ctime: Int
    let msg: String
    let now: Int
    let ptime: Int
    let total: Int
}

// Basic Aircraft model with essential fields
struct Aircraft: Codable, Identifiable, Equatable {
    // Implement Equatable
    static func == (lhs: Aircraft, rhs: Aircraft) -> Bool {
        return lhs.hex == rhs.hex
    }
    // Basic identification
    let hex: String
    let type: String?
    let flight: String?
    let r: String?
    let t: String?
    let category: String?
    
    // Position
    let lat: Double?
    let lon: Double?
    private let _alt_baro: AltitudeValue?
    private let _alt_geom: AltitudeValue?
    
    // Computed properties to handle different altitude formats
    var alt_baro: Int? {
        return _alt_baro?.intValue
    }
    
    var alt_geom: Int? {
        return _alt_geom?.intValue
    }
    
    // Custom CodingKeys to map our private properties
    private enum CodingKeys: String, CodingKey {
        case hex, type, flight, r, t, category
        case lat, lon
        case _alt_baro = "alt_baro"
        case _alt_geom = "alt_geom"
        case _gs = "gs", _track = "track", _ias = "ias", _tas = "tas", _mach = "mach"
        case squawk, emergency
        case mlat, tisb
        case _messages = "messages", _seen = "seen", _rssi = "rssi"
        case _baro_rate = "baro_rate", _geom_rate = "geom_rate", nav_modes
    }
    
    // Speed and direction
    private let _gs: FlexibleValue?
    private let _track: FlexibleValue?
    private let _ias: FlexibleValue?
    private let _tas: FlexibleValue?
    private let _mach: FlexibleValue?
    
    // Computed properties for speed values
    var gs: Double? { return _gs?.doubleValue }
    var track: Double? { return _track?.doubleValue }
    var ias: Int? { return _ias?.intValue }
    var tas: Int? { return _tas?.intValue }
    var mach: Double? { return _mach?.doubleValue }
    
    // Status
    let squawk: String?
    let emergency: String?
    
    // Computed property to check if aircraft has a real emergency
    var isEmergency: Bool {
        return emergency != nil && emergency != "none"
    }
    
    // Metadata
    let mlat: [String]?
    let tisb: [String]?
    private let _messages: FlexibleValue?
    private let _seen: FlexibleValue?
    private let _rssi: FlexibleValue?
    
    // Computed properties for metadata
    var messages: Int? { return _messages?.intValue }
    var seen: Double? { return _seen?.doubleValue }
    var rssi: Double? { return _rssi?.doubleValue }
    
    // Additional fields
    private let _baro_rate: FlexibleValue?
    private let _geom_rate: FlexibleValue?
    let nav_modes: [String]?
    
    // Computed properties for rate values
    var baro_rate: Int? { return _baro_rate?.intValue }
    var geom_rate: Int? { return _geom_rate?.intValue }
    
    // Computed property for SwiftUI's Identifiable protocol
    var id: String { hex }
    
    // Helper computed properties
    var hasValidCoordinates: Bool {
        return lat != nil && lon != nil
    }
    
    var formattedFlight: String {
        return flight?.trimmingCharacters(in: .whitespaces) ?? "N/A"
    }
    
    var formattedRegistration: String {
        return r ?? hex
    }
    
    var formattedAltitude: String {
        if let altitude = alt_baro {
            return "\(altitude) ft"
        } else if let geoAltitude = alt_geom {
            return "\(geoAltitude) ft (geo)"
        } else {
            return "N/A"
        }
    }
    
    var formattedGroundSpeed: String {
        if let groundSpeed = gs {
            return "\(Int(groundSpeed)) kts"
        } else {
            return "N/A"
        }
    }
    
    var formattedIndicatedAirSpeed: String {
        if let speed = ias {
            return "\(speed) kts"
        } else {
            return "N/A"
        }
    }
    
    var formattedTrueAirSpeed: String {
        if let speed = tas {
            return "\(speed) kts"
        } else {
            return "N/A"
        }
    }
    
    var formattedMach: String {
        if let mach = mach {
            return String(format: "%.2f", mach)
        } else {
            return "N/A"
        }
    }
    
    var formattedAircraftType: String {
        return t ?? "Unknown"
    }
    
    var formattedCategoryDescription: String {
        guard let category = category else { return "Unknown" }
        
        switch category {
        case "A0": return "No ADS-B Emitter Category Information"
        case "A1": return "Light Aircraft"
        case "A2": return "Small Aircraft"
        case "A3": return "Medium Aircraft"
        case "A4": return "High Vortex Large Aircraft"
        case "A5": return "Heavy Aircraft"
        case "A6": return "High Performance Aircraft"
        case "A7": return "Rotorcraft"
        default: return "Category: \(category)"
        }
    }
}

// MARK: - Map Annotation
class AircraftAnnotation: NSObject, MKAnnotation {
    let aircraft: Aircraft
    var coordinate: CLLocationCoordinate2D
    
    init(aircraft: Aircraft) {
        self.aircraft = aircraft
        self.coordinate = CLLocationCoordinate2D(
            latitude: aircraft.lat ?? 0,
            longitude: aircraft.lon ?? 0
        )
        super.init()
    }
    
    var title: String? {
        return aircraft.formattedFlight != "N/A" ? aircraft.formattedFlight : aircraft.hex
    }
    
    var subtitle: String? {
        return "\(aircraft.formattedAltitude) | \(aircraft.formattedGroundSpeed)"
    }
}
