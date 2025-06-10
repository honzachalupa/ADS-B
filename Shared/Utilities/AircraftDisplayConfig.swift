import SwiftUI

struct AircraftDisplayConfig {
    enum AircraftType {
        case helicopter
        case airplane
        case lightAirplane
        case groundVehicle
        case tower
        
        var displayName: String {
            switch self {
                case .helicopter: return String(localized: "Helicopter")
                case .airplane: return String(localized: "Airplane")
                case .lightAirplane: return String(localized: "Light Airplane")
                case .groundVehicle: return String(localized: "Ground Vehicle")
                case .tower: return String(localized: "Tower/Ground Station")
            }
        }
        
        var iconName: String {
            switch self {
                case .airplane, .lightAirplane: return "airplane"
                case .helicopter: return "fanblades"
                case .groundVehicle: return "car.fill"
                case .tower: return "antenna.radiowaves.left.and.right"
            }
        }
        
        var scale: CGFloat {
            switch self {
                case .lightAirplane, .helicopter: return 0.7
                default: return 1
            }
        }
    }
    
    static func getAircraftType(for aircraft: Aircraft) -> AircraftType {
        // Non-aircraft types
        switch aircraft.feederType {
            case .aircraft:
                break // Handle aircraft types below
            case .groundVehicle:
                return .groundVehicle
            case .tower, .groundStation:
                return .tower
        }
        
        // Aircraft type differentiation
        if let type = aircraft.t {
            if type.hasPrefix("R") || type.contains("HELI") {
                return .helicopter
            }
        }
        
        // Light aircraft based on category
        if let category = aircraft.category,
           category == "A1" || category == "A2" {
            return .lightAirplane
        }
        
        // Default to commercial for other aircraft
        return .airplane
    }
    
    static var allTypes: [AircraftType] {
        return [.airplane, .lightAirplane, .helicopter, .groundVehicle, .tower]
    }
    
    struct LegendItem: Identifiable {
        let id = UUID()
        let label: String
        let iconName: String
    }
    
    static var legendItems: [LegendItem] {
        return allTypes.map { type in
            LegendItem(
                label: type.displayName,
                iconName: type.iconName
            )
        }
    }
}
