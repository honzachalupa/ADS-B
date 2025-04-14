import SwiftUI

struct MapFilterView: View {
    var body: some View {
#if os(iOS)
        Menu {
            MapFilterTogglesView()
        } label: {
            MapControlView(iconName: "line.3.horizontal.decrease.circle")
        }
#endif
    }
}

struct MapFilterTogglesView: View {
    @AppStorage(SETTINGS_SEARCH_RANGE_KEY) private var searchRange: Int = 50
    @AppStorage(FILTER_SHOW_PIA_AIRCRAFTS_KEY) private var showPIAAircrafts: Bool = true
    @AppStorage(FILTER_SHOW_REGULAR_AIRCRAFTS_KEY) private var showRegularAircrafts: Bool = true
    @AppStorage(FILTER_SHOW_MILITARY_AIRCRAFTS_KEY) private var showMilitaryAircrafts: Bool = true
    @AppStorage(FILTER_SHOW_LADD_AIRCRAFTS_KEY) private var showLADDAircrafts: Bool = true
    
    var body: some View {
        Toggle("Regular aircrafts (within \(searchRange) NM from your location)", isOn: $showRegularAircrafts)
        Toggle("Military aircrafts", isOn: $showMilitaryAircrafts)
        Toggle("Privacy ICAO Address (PIA) aircrafts", isOn: $showPIAAircrafts)
        Toggle("Limited Aircraft Data Display (LADD) aircrafts", isOn: $showLADDAircrafts)
    }
}

#Preview {
    MapFilterView()
}
