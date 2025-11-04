import SwiftUI

struct AircraftDetailView: View {
    let aircraft: Aircraft
    @ObservedObject private var aircraftService = AircraftService.shared
    @StateObject private var photoService = AircraftPhotoService()
    @AppStorage("detail_isShowDetails") private var isShowDetails: Bool = false
    
    var aircraftUpdated: Aircraft { aircraftService.aircraft.first { $0.hex == aircraft.hex } ?? aircraft }
    
    var body: some View {
        NavigationStack {
            List {
                if let photo = photoService.photo {
                    Section {
                        HStack {
                            photo
                                .resizable()
                                .scaledToFill()
                                .frame(maxWidth: .infinity)
                        }
                        .listRowInsets(EdgeInsets())
                    }
                }
                
                if let emergency = aircraftUpdated.emergency, aircraftUpdated.isEmergency {
                    Section("Emergency") {
                        LabeledContent("Status") {
                            Text(emergency)
                        }
                        .foregroundColor(.red)
                    }
                }
                
                Section("Flight") {
                    LabeledContent("Flight") {
                        Text(aircraftUpdated.formattedFlight)
                            .fontWeight(.bold)
                    }
                    
                    LabeledContent("Registration") { Text(aircraftUpdated.r ?? "-")}
                    
                    if isShowDetails {
                        LabeledContent("Barometric Altitude") {
                            Text(formatAltitude(aircraftUpdated.alt_baro))
                        }
                    }
                    
                    LabeledContent("Geometric Altitude") { Text(formatAltitude(aircraftUpdated.alt_geom))}
                    LabeledContent("Ground Speed") { Text(formatSpeed(aircraftUpdated.gs))}
                    
                    if isShowDetails {
                        LabeledContent("Indicated Airspeed") { Text("\(formatNumber(aircraftUpdated.ias)) kts") }
                        LabeledContent("True Airspeed") { Text("\(formatNumber(aircraftUpdated.tas)) kts") }
                    
                        LabeledContent("Mach") {
                            Text(aircraftUpdated.mach != nil ? String(format: "%.2f", aircraftUpdated.mach!) : "-")
                        }
                    }
                    
                    LabeledContent("Heading") {
                        if let track = aircraftUpdated.track {
                            HStack(spacing: 6) {
                                Text("\(Int(track))°")
                                
                                Image(systemName: "airplane")
                                    .rotationEffect(.degrees(track - 90))
                            }
                        } else {
                            Text("-")
                        }
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
                
                Section("Aircraft") {
                    LabeledContent("Manufacturer") { Text(aircraftUpdated.getManufacturer()) }
                    LabeledContent("Model") { Text(aircraftUpdated.t ?? "-") }
                    
                    if isShowDetails {
                        LabeledContent("Description") { Text(aircraftUpdated.formattedCategoryDescription) }
                        LabeledContent("ICAO") { Text(aircraftUpdated.hex) }
                        LabeledContent("Type") { Text(aircraftUpdated.type ?? "-") }
                    }
                }
                
                if isShowDetails {
                    Section("Transponder") {
                        LabeledContent("Squawk") {
                            Text(aircraftUpdated.squawk ?? "-")
                        }
                        
                        LabeledContent("Navigation Modes") {
                            Text(aircraftUpdated.nav_modes?.joined(separator: ", ") ?? "-")
                        }
                    }
                }
                
                Section("Operational Status") {
                    if let emergency = aircraftUpdated.emergency, aircraftUpdated.isEmergency {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.red)
                            
                            Text("Emergency: \(emergency)")
                                .fontWeight(.bold)
                                .foregroundColor(.red)
                        }
                    }
                        
                    if isShowDetails {
                        if let squawk = aircraftUpdated.squawk {
                            LabeledContent("Transponder Code") {
                                HStack {
                                    Text(squawk)
                                    if squawk == "7500" || squawk == "7600" || squawk == "7700" {
                                        Image(systemName: "exclamationmark.triangle")
                                            .foregroundColor(.orange)
                                    }
                                }
                            }
                        }
                    }
                }
                
                if isShowDetails {
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
                }
                
                // Add Navigation Modes section
                if let navModes = aircraftUpdated.nav_modes, !navModes.isEmpty {
                    Section("Navigation") {
                        ForEach(navModes, id: \.self) { mode in
                            HStack {
                                getNavModeIcon(for: mode)
                                    .foregroundColor(.blue)
                                Text(getNavModeDescription(for: mode))
                            }
                        }
                    }
                }
                
                if isShowDetails {
                    Section("Signal") {
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
                        
                        // Add signal quality visualization
                        if let rssi = aircraftUpdated.rssi {
                            VStack(alignment: .leading) {
                                Text("Signal Strength")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                HStack(spacing: 2) {
                                    ForEach(0..<5) { i in
                                        Rectangle()
                                            .fill(getSignalColor(rssi: rssi, barIndex: i))
                                            .frame(width: 15, height: 4 + CGFloat(i) * 3)
                                    }
                                }
                                .padding(.top, 2)
                            }
                        }
                    }
                }
                
                Toggle("Show details", isOn: $isShowDetails)
            }
            .navigationTitle(aircraftUpdated.formattedFlight)
            .navigationBarTitleDisplayMode(.inline)
        }
        .onAppear {
            photoService.clearPhoto()
            photoService.fetchPhoto(for: aircraftUpdated)
        }
    }
}

#Preview {
    // AircraftDetailView()
}

extension AircraftDetailView {
    // Helper function to get icon for navigation mode
    func getNavModeIcon(for mode: String) -> Image {
        switch mode.lowercased() {
            case "autopilot":
                return Image(systemName: "airplane.circle")
            case "vnav", "vnav_path":
                return Image(systemName: "arrow.up.and.down")
            case "alt_hold":
                return Image(systemName: "arrow.left.and.right")
            case "approach":
                return Image(systemName: "location.north.fill")
            case "lnav":
                return Image(systemName: "point.topleft.down.curvedto.point.bottomright.up")
            case "tcas":
                return Image(systemName: "dot.radiowaves.left.and.right")
            default:
                return Image(systemName: "gearshape")
        }
    }
    
    // Helper function to get description for navigation mode
    func getNavModeDescription(for mode: String) -> String {
        switch mode.lowercased() {
            case "autopilot":
                return "Autopilot"
            case "vnav", "vnav_path":
                return "Vertical Navigation"
            case "alt_hold":
                return "Altitude Hold"
            case "approach":
                return "Approach Mode"
            case "lnav":
                return "Lateral Navigation"
            case "tcas":
                return "Traffic Collision Avoidance System"
            default:
                return mode
        }
    }
    
    // Helper function to format numbers with commas
    func formatNumber(_ value: Int?) -> String {
        guard let value = value else { return "-" }
        
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: value)) ?? String(value)
    }
    
    // Helper function to get color for signal strength bars
    func getSignalColor(rssi: Double, barIndex: Int) -> Color {
        // RSSI typically ranges from -90 (weak) to -10 (strong)
        // Convert to a 0-5 scale
        let normalizedStrength = min(5, max(0, (rssi + 90) / 16))
        
        // Determine if this bar should be filled based on signal strength
        let shouldFill = Double(barIndex) < normalizedStrength
        
        if shouldFill {
            // Color gradient from red (weak) to green (strong)
            if normalizedStrength < 2 {
                return .red
            } else if normalizedStrength < 3.5 {
                return .orange
            } else {
                return .green
            }
        } else {
            return Color.gray.opacity(0.3)
        }
    }
}
