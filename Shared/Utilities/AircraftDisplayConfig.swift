import SwiftUI

// Shared configuration for aircraft display styles
struct AircraftDisplayConfig {
    
    // Aircraft type definitions
    enum AircraftType {
        case emergency
        case military
        case helicopter
        case lightAircraft
        case commercial
        case groundVehicle
        case tower
        
        // Display name for the legend
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
        
        // SF Symbol icon name
        var iconName: String {
            switch self {
                case .emergency, .military, .helicopter, .lightAircraft, .commercial:
                    return "airplane"
                case .groundVehicle:
                    return "car.fill"
                case .tower:
                    return "antenna.radiowaves.left.and.right"
            }
        }
        
        // Color for the aircraft type
        var color: Color {
            switch self {
                case .emergency: return .red
                case .military: return .green
                case .helicopter: return .purple
                case .lightAircraft: return .mint
                case .commercial: return .blue
                case .groundVehicle: return .gray
                case .tower: return .gray
            }
        }
    }
    
    // Determine aircraft type based on aircraft data
    static func getAircraftType(for aircraft: Aircraft) -> AircraftType {
        // Emergency aircraft always take priority
        if aircraft.isEmergency {
            return .emergency
        }
        
        // Force military type for aircraft from military endpoint
        if aircraft.forcedMilitaryType {
            return .military
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
