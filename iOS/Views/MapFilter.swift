import SwiftUI

struct MapFilter: View {
    @AppStorage(FILTER_SHOW_REGULAR_AIRCRAFT_KEY) private var showRegularAircraft: Bool = true
    @AppStorage(FILTER_SHOW_PIA_AIRCRAFT_KEY) private var showPIAAircraft: Bool = true
    @AppStorage(FILTER_SHOW_MILITARY_AIRCRAFT_KEY) private var showMilitaryAircraft: Bool = true
    @AppStorage(FILTER_SHOW_LADD_AIRCRAFT_KEY) private var showLADDAircraft: Bool = true
    
    var body: some View {
        Menu {
            Toggle("Regular aircraft", isOn: $showRegularAircraft)
            Toggle("Privacy ICAO Address (PIA) aircraft", isOn: $showPIAAircraft)
            Toggle("Military aircraft", isOn: $showMilitaryAircraft)
            Toggle("Limited Aircraft Data Display (LADD) aircraft", isOn: $showLADDAircraft)
        } label: {
            Image(systemName: "line.3.horizontal.decrease.circle")
                .resizable()
                .scaledToFit()
                .frame(width: 20, height: 20)
                .padding(12)
                .background(.thickMaterial)
                .cornerRadius(8)
                .fontWeight(.medium)
        }
    }
}

#Preview {
    MapFilter()
}
