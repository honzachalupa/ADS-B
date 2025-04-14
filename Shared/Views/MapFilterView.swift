import SwiftUI

struct MapFilterView: View {
    var body: some View {
        Menu {
            MapFilterTogglesView()
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

struct MapFilterTogglesView: View {
    @AppStorage(FILTER_SHOW_PIA_AIRCRAFTS_KEY) private var showPIAAircrafts: Bool = true
    @AppStorage(FILTER_SHOW_REGULAR_AIRCRAFTS_KEY) private var showRegularAircrafts: Bool = true
    @AppStorage(FILTER_SHOW_MILITARY_AIRCRAFTS_KEY) private var showMilitaryAircrafts: Bool = true
    @AppStorage(FILTER_SHOW_LADD_AIRCRAFTS_KEY) private var showLADDAircrafts: Bool = true
    
    var body: some View {
        Toggle("Regular aircrafts", isOn: $showRegularAircrafts)
        Toggle("Military aircrafts", isOn: $showMilitaryAircrafts)
        Toggle("Privacy ICAO Address (PIA) aircrafts", isOn: $showPIAAircrafts)
        Toggle("Limited Aircraft Data Display (LADD) aircrafts", isOn: $showLADDAircrafts)
    }
}

#Preview {
    MapFilterView()
}
