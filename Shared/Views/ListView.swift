import SwiftUI

struct ListView: View {
    var aircrafts: [Aircraft]
    var onAircraftSelected: ((Aircraft?) -> Void)? = nil
    
    var body: some View {
        NavigationView {
            List {
                ForEach(aircrafts) { aircraft in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(aircraft.flight?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "N/A")
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
                    .onTapGesture {
                        if aircraft.feederType == .aircraft, let onAircraftSelected {
                            onAircraftSelected(aircraft)
                        }
                    }
                }
            }
            .navigationTitle("List")
            .overlay {
                if aircrafts.isEmpty {
                    ContentUnavailableView(
                        "No Aircraft Found", 
                        systemImage: "airplane", 
                        description: Text("No aircraft in range")
                    )
                }
            }
        }
    }
}

#Preview {
    ListView(aircrafts: PreviewAircraftData.getAircrafts())
        .environmentObject(LocationManager())
}
