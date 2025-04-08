import SwiftUI

struct AircraftDetailView: View {
    let aircraft: Aircraft
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(aircraft.formattedFlight.isEmpty ? "Unknown Flight" : aircraft.formattedFlight)
                    .font(.title)
                    .fontWeight(.bold)
                
                Spacer()
                
                Text(aircraft.hex)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Divider()
            
            detailRow(label: "Type", value: aircraft.type)
            
            if let alt = aircraft.alt_baro {
                detailRow(label: "Altitude", value: "\(alt) ft")
            }
            
            if let gs = aircraft.gs {
                detailRow(label: "Ground Speed", value: "\(Int(gs)) kts")
            }
            
            if let track = aircraft.track {
                detailRow(label: "Track", value: "\(Int(track))°")
            }
            
            if let squawk = aircraft.squawk {
                detailRow(label: "Squawk", value: squawk)
            }
            
            if let emergency = aircraft.emergency {
                detailRow(label: "Emergency", value: emergency)
                    .foregroundColor(.red)
            }
            
            if let category = aircraft.category {
                detailRow(label: "Category", value: category)
            }
            
            if let aircraftSeen = aircraft.seen {
                detailRow(label: "Last Seen", value: "\(Int(aircraftSeen)) seconds ago")
            }
            
            detailRow(label: "Signal Strength", value: String(format: "%.1f dB", aircraft.rssi ?? ""))
            
            Spacer()
        }
    }
    
    private func detailRow(label: String, value: String?) -> some View {
        HStack {
            if let value {
                Text(label)
                    .fontWeight(.medium)
                    .frame(width: 120, alignment: .leading)
                
                Text(value)
                    .foregroundColor(.primary)
                
                Spacer()
            }
        }
    }
}
