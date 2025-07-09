import SwiftUI
import MapKit

struct AircraftMarkerView: View {
    let aircraft: Aircraft
    @State private var isVisible = false
    
    private var aircraftType: AircraftDisplayConfig.AircraftType {
        AircraftDisplayConfig.getAircraftType(for: aircraft)
    }
    
    private var aircraftColor: Color {
        // Simple 3-color scheme: emergency red, military green, default white
        if aircraft.isEmergency {
            return .red // Emergency aircraft - big and red
        } else if isMilitaryAircraft {
            return .green // Military aircraft - green
        } else {
            return .white // Default - white
        }
    }
    
    private var isMilitaryAircraft: Bool {
        // Very conservative military aircraft detection - only obvious military callsigns
        let flight = aircraft.formattedFlight.uppercased()
        
        // Only the most obvious military callsigns to avoid false positives
        let militaryCallsigns = ["RCH", "REACH", "CONVOY", "ARMY", "NAVY", "USAF", "MARINES", "USMC"]
        
        for callsign in militaryCallsigns {
            if flight.hasPrefix(callsign) {
                return true
            }
        }
        
        return false
    }
    
    private var displayCode: String {
        aircraft.formattedFlight.isEmpty ? aircraft.hex : aircraft.formattedFlight
    }
    
    @ViewBuilder
    var body: some View {
        // Only show flight code when zoomed in enough
        if let track = aircraft.track, !displayCode.isEmpty {
            // With flight code (when zoomed in)
            VStack(spacing: 0) {
                // Flight code badge
                Text(displayCode)
                    .font(.system(size: 10, weight: .semibold))
                    .fixedSize()
                    .padding(.horizontal, 4)
                    .padding(.vertical, 2)
                    .background(Color.black.opacity(0.7))
                    .foregroundColor(.white)
                    .cornerRadius(4)
                    .allowsHitTesting(false)
                
                // Aircraft icon
                Image(systemName: aircraftType.iconName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 20, height: 20)
                    .foregroundColor(aircraftColor)
                    .rotationEffect(.degrees(track + 90))
            }
        } else {
            // Just the aircraft icon (when zoomed out)
            Image(systemName: aircraftType.iconName)
                .resizable()
                .scaledToFit()
                .frame(width: 16, height: 16)
                .foregroundColor(aircraftColor)
                .rotationEffect(.degrees((aircraft.track ?? 0) - 90))
        }
    }
}

// MARK: - Preview
#Preview {
    VStack {
        if let aircraft = PreviewAircraftData.getAircrafts().first {
            AircraftMarkerView(aircraft: aircraft)
                .frame(width: 100, height: 100)
        } else {
            Text("No preview data available")
        }
    }
    .background(Color.gray.opacity(0.2))
}
