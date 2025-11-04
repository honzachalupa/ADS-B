import SwiftUI
import SwiftCore

struct ListView: View {
    @Binding public var selectedAircraft: Aircraft?
    
    @ObservedObject private var aircraftService = AircraftService.shared
    @State private var searchText: String = ""
    
    var aircraftFiltered: [Aircraft] {
        aircraftService.aircraft.filter {
            searchText.isEmpty ||
            $0.hex.contains(searchText) ||
            $0.formattedFlight.contains(searchText)
        }
    }
    
    var body: some View {
        NavigationStack {
            List(aircraftFiltered) { aircraft in
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
                .contentShape(Rectangle())
                .onTapGesture {
                    selectedAircraft = aircraft
                }
                .searchable(text: $searchText)
            }
            .navigationTitle("Aircraft")
        }
    }
}

#Preview {
    ListView(selectedAircraft: .constant(nil))
}
