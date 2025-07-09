import SwiftUI

struct DebugInfoView: View {
    @Environment(\.tabViewBottomAccessoryPlacement) var tabViewBottomAccessoryPlacement
    @ObservedObject private var aircraftService = AircraftService.shared
    @State private var currentTime = Date()
    @State private var isInfoPopoverPresented: Bool = false
    
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    private var timeSinceLastUpdate: String {
        let interval = currentTime.timeIntervalSince(aircraftService.lastUpdateTime)
        return "\(Int(round(interval)))s ago"
    }
    
    var infoItems: [(String, String)] {
        [
            ("arrow.trianglehead.2.counterclockwise", "\(timeSinceLastUpdate)/\(aircraftService.currentInterval)s"),
            ("plus.magnifyingglass", String(format: "%.1f", aircraftService.currentZoomLevel)),
            ("airplane.up.right", "\(aircraftService.aircrafts.count) \(tabViewBottomAccessoryPlacement == .expanded ? "aircrafts" : "")")
        ]
    }
    
    var body: some View {
        HStack(spacing: 5) {
            ForEach(infoItems, id: \.0) { (iconSystemName, value) in
                Spacer()
                
                Image(systemName: iconSystemName)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                Text(value)
                
                Spacer()
            }
        }
        .onTapGesture {
            isInfoPopoverPresented.toggle()
        }
        .popover(isPresented: $isInfoPopoverPresented) {
            Text("TODO")
                .presentationCompactAdaptation(.popover)
        }
        .onReceive(timer) { time in
            currentTime = time
        }
        // Force view to update when aircraft count changes
        .id(aircraftService.aircrafts.count)
    }
}

#Preview {
    DebugInfoView()
}
