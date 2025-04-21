import SwiftUI

struct ListView: View {
    @ObservedObject private var aircraftService = AircraftService.shared
    
    var body: some View {
        NavigationStack {
            List(aircraftService.aircrafts) { aircraft in
                HStack {
                    VStack(alignment: .leading) {
                        Text(aircraft.flight?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "-")
                            .font(.headline)
                        
                        Text(aircraft.hex.uppercased())
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing) {
                        if let altitude = aircraft.alt_baro {
                            Text(formatAltitude(altitude))
                                .font(.subheadline)
                        }
                        
                        if let speed = aircraft.gs {
                            Text(formatSpeed(speed))
                                .font(.subheadline)
                        }
                    }
                }
                .padding(.vertical, 4)
            }
            .navigationTitle("List")
        }
    }
}

#Preview {
    ListView()
}
