import SwiftUI

func formatNumber(_ value: Int?) -> String {
    if let value {
        return NumberFormatter.localizedString(from: NSNumber(value: value), number: .decimal)
    }
    
    return "-"
}

func formatAltitude(_ feet: Int?) -> String {
    if let feet {
        let meters = Int(Double(feet) * 0.3048)
        return "\(formatNumber(feet)) ft (\(formatNumber(meters)) m)"
    }
    
    return "-"
}

func formatSpeed(_ knots: Double?) -> String {
    if let knots {
        let knotsValue = Int(knots)
        let kmhValue = Int(knots * 1.852)
        return "\(formatNumber(knotsValue)) kts (\(formatNumber(kmhValue)) km/h)"
    }
    
    return "-"
}

struct AircraftDetailView: View {
    let aircraft: Aircraft
    @EnvironmentObject private var aircraftService: AircraftService
    
    var aircraftUpdated: Aircraft { aircraftService.aircrafts.first { $0.hex == aircraft.hex } ?? aircraft }
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(aircraftUpdated.formattedFlight)
                .font(.title)
                .fontWeight(.bold)
                .padding(.top)
                .padding(.horizontal)
            
            List {
                if let emergency = aircraftUpdated.emergency, aircraftUpdated.isEmergency {
                    Section("Emergency") {
                        LabeledContent("Status") {
                            Text(emergency)
                        }
                        .foregroundColor(.red)
                    }
                }
                
                Section("Aircraft Information") {
                    LabeledContent("Registration") { Text(aircraftUpdated.r ?? "-") }
                    LabeledContent("ICAO") { Text(aircraftUpdated.hex) }
                    LabeledContent("Type") { Text(aircraftUpdated.type ?? "-") }
                    LabeledContent("Category") { Text(aircraftUpdated.category ?? "-") }
                }
                
                Section("Flight Data") {
                    LabeledContent("Barometric Altitude") {
                        Text(formatAltitude(aircraftUpdated.alt_baro))
                    }
                    
                    LabeledContent("Geometric Altitude") {
                        Text(formatAltitude(aircraftUpdated.alt_geom))
                    }
                    
                    LabeledContent("Ground Speed") {
                        Text(formatSpeed(aircraftUpdated.gs))
                    }
                    
                    LabeledContent("Indicated Airspeed") {
                        Text("\(formatNumber(aircraftUpdated.ias)) kts")
                    }
                    
                    LabeledContent("True Airspeed") {
                        Text("\(formatNumber(aircraftUpdated.tas)) kts")
                    }
                    
                    LabeledContent("Mach") {
                        Text(aircraftUpdated.mach != nil ? String(format: "%.2f", aircraftUpdated.mach!) : "-")
                    }
                    
                    LabeledContent("Heading") {
                        Text(aircraftUpdated.track != nil ? "\(Int(aircraftUpdated.track!))°" : "-")
                    }
                    
                    LabeledContent("Vertical Rate") {
                        if let baroRate = aircraftUpdated.baro_rate {
                            HStack(spacing: 4) {
                                Text("\(formatNumber(abs(baroRate))) ft/min")
                                Image(systemName: baroRate > 0 ? "arrow.up" : "arrow.down")
                            }
                        } else {
                            Text("-")
                        }
                    }
                }
                
                // Transponder data
                Section("Transponder") {
                    LabeledContent("Squawk") {
                        Text(aircraftUpdated.squawk ?? "-")
                    }
                    
                    LabeledContent("Navigation Modes") {
                        Text(aircraftUpdated.nav_modes?.joined(separator: ", ") ?? "-")
                    }
                }
                
                // Position data
                Section("Position") {
                    LabeledContent("Coordinates") {
                        Text(aircraftUpdated.lat != nil && aircraftUpdated.lon != nil ? String(format: "%.6f, %.6f", aircraftUpdated.lat!, aircraftUpdated.lon!) : "-")
                    }
                    
                    LabeledContent("Geometric Rate") {
                        if let geomRate = aircraftUpdated.geom_rate {
                            HStack(spacing: 4) {
                                Text("\(formatNumber(abs(geomRate))) ft/min")
                                Image(systemName: geomRate > 0 ? "arrow.up" : "arrow.down")
                            }
                        } else {
                            Text("-")
                        }
                    }
                }
                
                Section("Signal Data") {
                    LabeledContent("Messages Received") { 
                        Text(formatNumber(aircraftUpdated.messages))
                    }
                    
                    LabeledContent("Last Seen") { 
                        if let seen = aircraftUpdated.seen {
                            Text(String(format: "%.1f seconds ago", seen))
                        } else {
                            Text("-")
                        }
                    }
                    
                    LabeledContent("Signal Strength") { 
                        if let rssi = aircraftUpdated.rssi {
                            Text(String(format: "%.1f dBFS", rssi))
                        } else {
                            Text("-")
                        }
                    }
                    
                    LabeledContent("MLAT") { 
                        if let mlat = aircraftUpdated.mlat, !mlat.isEmpty {
                            Text(mlat.joined(separator: ", "))
                        } else {
                            Text("-")
                        }
                    }
                    
                    LabeledContent("TIS-B") { 
                        if let tisb = aircraftUpdated.tisb, !tisb.isEmpty {
                            Text(tisb.joined(separator: ", "))
                        } else {
                            Text("-")
                        }
                    }
                }
                
                Section("Category Details") {
                    LabeledContent("Category Description") { Text(aircraftUpdated.formattedCategoryDescription) }
                    LabeledContent("Aircraft Model") { Text(aircraftUpdated.t ?? "-") }
                }
            }
        }
        .onChange(of: aircraftService.aircrafts) {
            print(666, "Aircraft updated", aircraftService.aircrafts.count)
        }
    }

}
