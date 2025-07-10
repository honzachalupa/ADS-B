import SwiftUI

struct MapFilterView: View {
    @AppStorage(FILTER_SHOW_PIA_AIRCRAFTS_KEY) private var showPIAAircraft: Bool = true
    @AppStorage(FILTER_SHOW_REGULAR_AIRCRAFTS_KEY) private var showRegularAircraft: Bool = true
    @AppStorage(FILTER_SHOW_MILITARY_AIRCRAFTS_KEY) private var showMilitaryAircraft: Bool = true
    @AppStorage(FILTER_SHOW_LADD_AIRCRAFTS_KEY) private var showLADDAircraft: Bool = true
    
    var body: some View {
        Toggle("Regular aircraft (within \(searchRange) NM from your location)", isOn: $showRegularAircraft)
        Toggle("Military aircraft", isOn: $showMilitaryAircraft)
        Toggle("Privacy ICAO Address (PIA) aircraft", isOn: $showPIAAircraft)
        Toggle("Limited Aircraft Data Display (LADD) aircraft", isOn: $showLADDAircraft)
    }
}

#Preview {
    MapFilterView()
}
