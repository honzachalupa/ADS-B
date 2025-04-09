import SwiftUI

struct AircraftDetailView: View {
    let aircraft: Aircraft
    @EnvironmentObject private var aircraftService: AircraftService
    @StateObject private var photoService = AircraftPhotoService()
    @AppStorage("detail_isShowDetails") private var isShowDetails: Bool = false
    
    var aircraftUpdated: Aircraft { aircraftService.aircrafts.first { $0.hex == aircraft.hex } ?? aircraft }
    
    var body: some View {
        NavigationStack {
            List {
                if let photo = photoService.photo {
                    Section {
                        photo
                            .resizable()
                            .scaledToFill()
                            .frame(maxWidth: .infinity)
                    }
                    .listRowInsets(EdgeInsets())
                }
                
                if let emergency = aircraftUpdated.emergency, aircraftUpdated.isEmergency {
                    Section("Emergency") {
                        LabeledContent("Status") {
                            Text(emergency)
                        }
                        .foregroundColor(.red)
                    }
                }
                
                if isShowDetails {
                    Section {
                        LabeledContent("ICAO") { Text(aircraftUpdated.hex) }
                        LabeledContent("Type") { Text(aircraftUpdated.type ?? "-") }
                    }
                }
                
                Section("Category") {
                    if isShowDetails {
                        LabeledContent("Description") { Text(aircraftUpdated.formattedCategoryDescription) }
                    }
                    
                    LabeledContent("Manufacturer") { Text(aircraftUpdated.getManufacturer()) }
                    LabeledContent("Model") { Text(aircraftUpdated.t ?? "-") }
                }
                
                Section("Flight") {
                    if isShowDetails {
                        LabeledContent("Barometric Altitude") {
                            Text(formatAltitude(aircraftUpdated.alt_baro))
                        }
                    }
                    
                    LabeledContent("Geometric Altitude") {
                        Text(formatAltitude(aircraftUpdated.alt_geom))
                    }
                    
                    LabeledContent("Ground Speed") {
                        Text(formatSpeed(aircraftUpdated.gs))
                    }
                    
                    if isShowDetails {
                        LabeledContent("Indicated Airspeed") {
                            Text("\(formatNumber(aircraftUpdated.ias)) kts")
                        }
                        
                        LabeledContent("True Airspeed") {
                            Text("\(formatNumber(aircraftUpdated.tas)) kts")
                        }
                    
                        LabeledContent("Mach") {
                            Text(aircraftUpdated.mach != nil ? String(format: "%.2f", aircraftUpdated.mach!) : "-")
                        }
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
                    }
                }
                
                Toggle("Show details", isOn: $isShowDetails)
            }
            .navigationTitle(aircraftUpdated.formattedFlight + " - " + (aircraftUpdated.r ?? ""))
            .navigationBarTitleDisplayMode(.inline)
        }
        .onAppear {
            photoService.fetchPhoto(for: aircraftUpdated)
        }
    }

}
