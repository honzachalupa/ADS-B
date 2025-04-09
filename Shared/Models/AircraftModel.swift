import Foundation

struct FlexibleValue: Codable {
    private let _stringValue: String?
    private let _intValue: Int?
    private let _doubleValue: Double?
    private let _boolValue: Bool?
    
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
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
    
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
            _intValue = nil
            _doubleValue = nil
            _stringValue = nil
            _boolValue = nil
        } else {
            _intValue = nil
            _doubleValue = nil
            _stringValue = nil
            _boolValue = nil
        }
    }
    
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

typealias AltitudeValue = FlexibleValue

struct AircraftResponse: Codable {
    let ac: [Aircraft]
    let ctime: Int
    let msg: String
    let now: Int
    let ptime: Int
    let total: Int
}

struct Aircraft: Codable, Identifiable, Equatable, Hashable {
    static func == (lhs: Aircraft, rhs: Aircraft) -> Bool {
        return lhs.hex == rhs.hex
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(hex)
    }

    let hex: String
    let type: String?
    let flight: String?
    let r: String?
    let t: String?
    let category: String?
    let lat: Double?
    let lon: Double?
    private let _alt_baro: AltitudeValue?
    private let _alt_geom: AltitudeValue?
    
    var alt_baro: Int? { _alt_baro?.intValue }
    var alt_geom: Int? {  _alt_geom?.intValue }
    
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
    
    private let _gs: FlexibleValue?
    private let _track: FlexibleValue?
    private let _ias: FlexibleValue?
    private let _tas: FlexibleValue?
    private let _mach: FlexibleValue?
    
    var gs: Double? { return _gs?.doubleValue }
    var track: Double? { return _track?.doubleValue }
    var ias: Int? { return _ias?.intValue }
    var tas: Int? { return _tas?.intValue }
    var mach: Double? { return _mach?.doubleValue }
    let squawk: String?
    let emergency: String?
    
    var isEmergency: Bool {
        return emergency != nil && emergency != "none"
    }
    
    let mlat: [String]?
    let tisb: [String]?
    private let _messages: FlexibleValue?
    private let _seen: FlexibleValue?
    private let _rssi: FlexibleValue?
    var messages: Int? { return _messages?.intValue }
    var seen: Double? { return _seen?.doubleValue }
    var rssi: Double? { return _rssi?.doubleValue }
    private let _baro_rate: FlexibleValue?
    private let _geom_rate: FlexibleValue?
    let nav_modes: [String]?
    var baro_rate: Int? { return _baro_rate?.intValue }
    var geom_rate: Int? { return _geom_rate?.intValue }
    var id: String { hex }
    var formattedFlight: String { flight?.trimmingCharacters(in: .whitespaces) ?? "" }
    var formattedAircraftType: String { t ?? "Unknown" }
    var isValid: Bool { lat != nil && lon != nil && !formattedFlight.isEmpty }
    
    enum FeederType {
        case aircraft
        case tower
        case groundStation
        case groundVehicle
    }
    
    var feederType: FeederType {
        guard let t else {
            return .groundVehicle
        }
        
        if t.contains("TWR") {
            return .tower
        }
        
        if t.contains("GND") {
            return .groundStation
        }
        
        return .aircraft
    }
    
    var formattedCategoryDescription: String {
        guard let category = category else { return "Unknown" }
        
        switch category {
            case "A0": return "No ADS-B Emitter Category Information (A0)"
            case "A1": return "Light Aircraft (A1)"
            case "A2": return "Small Aircraft (A2)"
            case "A3": return "Medium Aircraft (A3)"
            case "A4": return "High Vortex Large Aircraft (A4)"
            case "A5": return "Heavy Aircraft (A5)"
            case "A6": return "High Performance Aircraft (A6)"
            case "A7": return "Rotorcraft (A7)"
            default: return "Category: \(category)"
        }
    }
}

extension Aircraft {
    func getManufacturer() -> String {
        guard let type = t else { return "-" }
        
        let manufacturerPrefixes: [String: String] = [
            "A3": "Airbus",
            "A2": "Airbus",
            "A1": "Airbus",
            "B7": "Boeing",
            "B6": "Boeing",
            "B5": "Boeing",
            "B4": "Boeing",
            "B3": "Boeing",
            "B2": "Boeing",
            "B1": "Boeing",
            "E": "Embraer",
            "CRJ": "Bombardier",
            "DH": "De Havilland",
            "AT": "ATR",
            "BE": "Beechcraft",
            "C": "Cessna",
            "PA": "Piper",
            "G": "Gulfstream",
            "MD": "McDonnell Douglas",
            "F": "Fokker"
        ]
        
        for (prefix, manufacturer) in manufacturerPrefixes {
            if type.hasPrefix(prefix) {
                return manufacturer
            }
        }
        
        return "-"
    }
}
