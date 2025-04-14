import SwiftUI

struct AircraftDisplayConfig {
    enum AircraftType {
        case emergency
        case military
        case helicopter
        case lightAircraft
        case commercial
        case groundVehicle
        case tower
        
        var displayName: String {
            switch self {
                case .emergency: return "Emergency"
                case .military: return "Military"
                case .helicopter: return "Helicopter"
                case .lightAircraft: return "Light Aircraft"
                case .commercial: return "Commercial Aircraft"
                case .groundVehicle: return "Ground Vehicle"
                case .tower: return "Tower/Ground Station"
            }
        }
        
        var iconName: String {
            switch self {
                case .emergency, .military, .lightAircraft, .commercial: return "airplane"
                case .helicopter: return "fanblades"
                case .groundVehicle: return "car.fill"
                case .tower: return "antenna.radiowaves.left.and.right"
            }
        }
        
        var color: Color {
            switch self {
                case .emergency: return .red
                case .military: return .green
                case .groundVehicle, .tower: return .gray
                default: return .blue
            }
        }
        
        var scale: CGFloat {
            switch self {
                case .lightAircraft, .helicopter: return 0.7
                default: return 1
            }
        }
    }
    
    static func getAircraftType(for aircraft: Aircraft) -> AircraftType {
        // Emergency aircraft always take priority
        if aircraft.isEmergency {
            return .emergency
        }
        
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
            // Military aircraft (fighters, bombers, military transport)
            if type.contains("-") || 
               (type.hasPrefix("F") && type.count <= 3) || // Fighter jets like F16, F35
               (type.hasPrefix("B") && type.count <= 3) || // Bombers like B52, B2
               (type.hasPrefix("C") && type.count <= 3) {  // Military transport like C17, C130
                return .military
            }
            
            // Helicopters
            if type.hasPrefix("R") || type.contains("HELI") {
                return .helicopter
            }
        }
        
        // Light aircraft based on category
        if let category = aircraft.category, 
           category == "A1" || category == "A2" {
            return .lightAircraft
        }
        
        // Default to commercial for other aircraft
        return .commercial
    }
    
    // Get color for an aircraft
    static func getColor(for aircraft: Aircraft) -> Color {
        return getAircraftType(for: aircraft).color
    }
    
    // Get icon name for an aircraft
    static func getIconName(for aircraft: Aircraft) -> String {
        return getAircraftType(for: aircraft).iconName
    }
    
    // Get all aircraft types for the legend
    static var allTypes: [AircraftType] {
        return [.emergency, .military, .helicopter, .lightAircraft, .commercial, .groundVehicle, .tower]
    }
    
    // Legend item struct for use in MapLegendView
    struct LegendItem: Identifiable {
        let id = UUID()
        let color: Color
        let label: String
        let iconName: String
    }
    
    // Get all legend items
    static var legendItems: [LegendItem] {
        return allTypes.map { type in
            LegendItem(
                color: type.color,
                label: type.displayName,
                iconName: type.iconName
            )
        }
    }
}
