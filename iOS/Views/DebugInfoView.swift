import SwiftUI

struct DebugInfoView: View {
    @ObservedObject private var aircraftService = AircraftService.shared
    @ObservedObject private var airportService = AirportService.shared
    @State private var currentTime = Date()
    
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    private var timeSinceLastUpdate: String {
        let interval = currentTime.timeIntervalSince(aircraftService.lastUpdateTime)
        return "\(Int(round(interval)))s ago"
    }
    
    private var refreshStatus: String {
        let interval = currentTime.timeIntervalSince(aircraftService.lastUpdateTime)
        if interval > 15 {
            return "ERROR" // Data is stale
        } else {
            return "\(aircraftService.currentInterval)s" // Normal refresh interval
        }
    }
    
    private var militaryAircraft: [Aircraft] {
        aircraftService.aircraft.filter(\.isMilitary)
    }
    
    private var emergencyAircraft: [Aircraft] {
        aircraftService.aircraft.filter(\.isEmergency)
    }
    
    var infoItems: [(String, String)] {
        [
            ("arrow.trianglehead.2.counterclockwise", refreshStatus == "ERROR" ? "Error" : "\(timeSinceLastUpdate)/\(refreshStatus)"),
            ("plus.magnifyingglass", String(format: "%.1f", aircraftService.currentZoomLevel)),
            ("airplane.departure", "\(airportService.airports.count)"),
            ("airplane.up.right", "\(aircraftService.aircraft.count)")
        ]
    }
    
    var body: some View {
        HStack(spacing: 5) {
            ForEach(infoItems, id: \.0) { (iconSystemName, value) in
                Spacer(minLength: 0)
                
                Image(systemName: iconSystemName)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                if iconSystemName == "airplane.up.right" {
                    HStack(spacing: 2) {
                        Text(value)
                        if militaryAircraft.count > 0 {
                            Text("\(militaryAircraft.count)")
                                .foregroundStyle(.green)
                        }
                        if emergencyAircraft.count > 0 {
                            Text("\(emergencyAircraft.count)")
                                .foregroundStyle(.red)
                        }
                    }
                } else {
                    Text(value)
                }
                
                Spacer(minLength: 0)
            }
        }
        .onReceive(timer) { time in
            currentTime = time
        }
    }
}

#Preview {
    DebugInfoView()
}
