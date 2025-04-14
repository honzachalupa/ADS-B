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
    var isValid: Bool { 
        #if os(watchOS)
        // For watchOS, only require valid coordinates
        return lat != nil && lon != nil
        #else
        // For iOS, require valid coordinates and flight information
        return lat != nil && lon != nil && !formattedFlight.isEmpty
        #endif
    }
    
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
        guard let t = t else { return "-" }
        
        // More comprehensive manufacturer mapping
        let manufacturerMap: [(pattern: String, manufacturer: String)] = [
            // Airbus
            ("A3", "Airbus"),
            ("A2", "Airbus"),
            ("A1", "Airbus"),
            ("A30", "Airbus"),
            ("A31", "Airbus"),
            ("A32", "Airbus"),
            ("A33", "Airbus"),
            ("A34", "Airbus"),
            ("A35", "Airbus"),
            ("A38", "Airbus"),
            
            // Boeing
            ("B7", "Boeing"),
            ("B6", "Boeing"),
            ("B5", "Boeing"),
            ("B4", "Boeing"),
            ("B3", "Boeing"),
            ("B2", "Boeing"),
            ("B1", "Boeing"),
            ("B77", "Boeing"),
            ("B76", "Boeing"),
            ("B75", "Boeing"),
            ("B74", "Boeing"),
            ("B73", "Boeing"),
            ("B72", "Boeing"),
            ("B71", "Boeing"),
            ("B70", "Boeing"),
            ("B38", "Boeing"),
            ("B39", "Boeing"),
            ("B78", "Boeing"),
            
            // Bombardier
            ("CRJ", "Bombardier"),
            ("CL6", "Bombardier"),
            ("BD", "Bombardier"),
            ("DH8", "Bombardier"),
            ("DHC", "Bombardier"),
            
            // Embraer
            ("E1", "Embraer"),
            ("E2", "Embraer"),
            ("E3", "Embraer"),
            ("E4", "Embraer"),
            ("E5", "Embraer"),
            ("E17", "Embraer"),
            ("E19", "Embraer"),
            ("E75", "Embraer"),
            ("E90", "Embraer"),
            ("E95", "Embraer"),
            ("ERJ", "Embraer"),
            
            // ATR
            ("AT", "ATR"),
            ("AT4", "ATR"),
            ("AT7", "ATR"),
            
            ("C17", "Boeing"),
            ("C5", "Lockheed"),
            
            // Cessna
            ("C", "Cessna"),
            ("C1", "Cessna"),
            ("C2", "Cessna"),
            ("C25", "Cessna"),
            ("C56", "Cessna"),
            ("C72", "Cessna"),
            ("C82", "Cessna"),
            ("C20", "Cessna"),
            ("C21", "Cessna"),
            
            // Beechcraft
            ("BE", "Beechcraft"),
            ("BE1", "Beechcraft"),
            ("BE2", "Beechcraft"),
            ("BE3", "Beechcraft"),
            ("BE4", "Beechcraft"),
            ("BE9", "Beechcraft"),
            ("BE10", "Beechcraft"),
            ("BE20", "Beechcraft"),
            ("BE35", "Beechcraft"),
            ("BE36", "Beechcraft"),
            ("BE40", "Beechcraft"),
            ("BE55", "Beechcraft"),
            ("BE58", "Beechcraft"),
            ("BE60", "Beechcraft"),
            ("BE76", "Beechcraft"),
            ("BE99", "Beechcraft"),
            ("BE10", "Beechcraft"),
            ("BE20", "Beechcraft"),
            ("BE30", "Beechcraft"),
            ("BE40", "Beechcraft"),
            
            // Piper
            ("PA", "Piper"),
            ("PA2", "Piper"),
            ("PA3", "Piper"),
            ("PA4", "Piper"),
            ("PA6", "Piper"),
            ("PA18", "Piper"),
            ("PA23", "Piper"),
            ("PA24", "Piper"),
            ("PA28", "Piper"),
            ("PA31", "Piper"),
            ("PA32", "Piper"),
            ("PA34", "Piper"),
            ("PA44", "Piper"),
            ("PA46", "Piper"),
            
            // Gulfstream
            ("G", "Gulfstream"),
            ("G1", "Gulfstream"),
            ("G2", "Gulfstream"),
            ("G3", "Gulfstream"),
            ("G4", "Gulfstream"),
            ("G5", "Gulfstream"),
            ("G6", "Gulfstream"),
            ("G7", "Gulfstream"),
            ("GLF", "Gulfstream"),
            
            // McDonnell Douglas
            ("MD", "McDonnell Douglas"),
            ("MD8", "McDonnell Douglas"),
            ("MD9", "McDonnell Douglas"),
            ("MD1", "McDonnell Douglas"),
            ("DC", "McDonnell Douglas"),
            
            // Fokker
            ("F", "Fokker"),
            ("F7", "Fokker"),
            ("F10", "Fokker"),
            ("F27", "Fokker"),
            ("F28", "Fokker"),
            ("F50", "Fokker"),
            ("F70", "Fokker"),
            ("F10", "Fokker"),
            
            // Dassault
            ("FA", "Dassault"),
            ("FA7", "Dassault"),
            ("FA8", "Dassault"),
            ("FA9", "Dassault"),
            ("F90", "Dassault"),
            ("F20", "Dassault"),
            ("F50", "Dassault"),
            ("F90", "Dassault"),
            
            // Learjet
            ("LJ", "Learjet"),
            ("LR", "Learjet"),
            
            // Cirrus
            ("SR", "Cirrus"),
            ("SR2", "Cirrus"),
            ("SR22", "Cirrus"),
            
            // Pilatus
            ("PC", "Pilatus"),
            ("PC6", "Pilatus"),
            ("PC12", "Pilatus"),
            ("PC24", "Pilatus"),
            
            // Sikorsky (Helicopters)
            ("S", "Sikorsky"),
            ("S76", "Sikorsky"),
            ("S92", "Sikorsky"),
            
            // Bell (Helicopters)
            ("B06", "Bell"),
            ("B47", "Bell"),
            ("B20", "Bell"),
            ("B42", "Bell"),
            ("B42", "Bell"),
            ("B429", "Bell"),
            
            // Eurocopter/Airbus Helicopters
            ("EC", "Airbus Helicopters"),
            ("EC3", "Airbus Helicopters"),
            ("EC45", "Airbus Helicopters"),
            ("AS", "Airbus Helicopters"),
            ("H1", "Airbus Helicopters"),
            ("H6", "Airbus Helicopters"),
            
            // Robinson (Helicopters)
            ("R22", "Robinson"),
            ("R44", "Robinson"),
            ("R66", "Robinson"),
            
            // De Havilland
            ("DH", "De Havilland"),
            
            // Antonov
            ("AN", "Antonov"),
            ("AN2", "Antonov"),
            ("AN12", "Antonov"),
            ("AN24", "Antonov"),
            ("AN26", "Antonov"),
            ("AN28", "Antonov"),
            ("AN30", "Antonov"),
            ("AN32", "Antonov"),
            ("AN72", "Antonov"),
            ("AN74", "Antonov"),
            ("AN124", "Antonov"),
            ("AN225", "Antonov"),
            
            // Tupolev
            ("TU", "Tupolev"),
            ("TU1", "Tupolev"),
            ("TU2", "Tupolev"),
            ("TU9", "Tupolev"),
            ("TU16", "Tupolev"),
            ("TU95", "Tupolev"),
            ("TU134", "Tupolev"),
            ("TU154", "Tupolev"),
            ("TU204", "Tupolev"),
            ("TU214", "Tupolev"),
            
            // Ilyushin
            ("IL", "Ilyushin"),
            ("IL1", "Ilyushin"),
            ("IL2", "Ilyushin"),
            ("IL6", "Ilyushin"),
            ("IL7", "Ilyushin"),
            ("IL8", "Ilyushin"),
            ("IL9", "Ilyushin"),
            ("IL14", "Ilyushin"),
            ("IL18", "Ilyushin"),
            ("IL62", "Ilyushin"),
            ("IL76", "Ilyushin"),
            ("IL86", "Ilyushin"),
            ("IL96", "Ilyushin"),
            
            // Sukhoi
            ("SU", "Sukhoi"),
            ("SU9", "Sukhoi"),
            ("SU24", "Sukhoi"),
            ("SU25", "Sukhoi"),
            ("SU27", "Sukhoi"),
            ("SU30", "Sukhoi"),
            ("SU33", "Sukhoi"),
            ("SU34", "Sukhoi"),
            ("SU35", "Sukhoi"),
            ("SU57", "Sukhoi"),
            ("SU95", "Sukhoi"),
            ("SU100", "Sukhoi"),
            
            // Yakovlev
            ("YK", "Yakovlev"),
            ("YAK", "Yakovlev"),
            
            // Lockheed Martin
            ("L", "Lockheed Martin"),
            ("L1", "Lockheed Martin"),
            ("L10", "Lockheed Martin"),
            ("L18", "Lockheed Martin"),
            ("L18", "Lockheed Martin"),
            ("L10", "Lockheed Martin"),
            ("L40", "Lockheed Martin"),
            ("L10", "Lockheed Martin"),
            ("L38", "Lockheed Martin")
        ]
        
        // Try to find a match from our detailed mapping
        for (pattern, manufacturer) in manufacturerMap {
            if t.hasPrefix(pattern) {
                return manufacturer
            }
        }
        
        // Special case for common military aircraft that don't follow standard patterns
        if t.contains("HAWK") { return "BAE Systems" }
        if t.contains("GRIPEN") { return "Saab" }
        if t.contains("EUFI") || t.contains("TYPHOON") { return "Eurofighter" }
        if t.contains("RAFALE") { return "Dassault" }
        if t.contains("MIRAGE") { return "Dassault" }
        if t.contains("MIG") { return "Mikoyan" }
        
        // If we couldn't identify the manufacturer
        return "-"
    }
}
