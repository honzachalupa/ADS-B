import SwiftUI

let SETTINGS_IS_METRIC_UNITS_KEY = "settings_isMetricUnits"
let SETTINGS_IS_INFO_BOX_ENABLED_KEY = "settings_isQuickInfoEnabled"
let SETTINGS_SEARCH_RANGE_KEY = "settings_searchRange"

struct SettingsView: View {
    @AppStorage(SETTINGS_IS_METRIC_UNITS_KEY) private var isMetricUnits: Bool = false
    @AppStorage(SETTINGS_IS_INFO_BOX_ENABLED_KEY) private var isInfoBoxEnabled: Bool = true
    @AppStorage(SETTINGS_SEARCH_RANGE_KEY) private var searchRange: Int = 50
    
    var body: some View {
        NavigationStack {
            Form {
#if os(watchOS)
                Section("Filter") {
                    MapFilterView()
                    MapLegendView {
                        Text("Legend")
                    }
                }
#endif
                
                Section {
                    Toggle("Show info box below aircraft icon", isOn: $isInfoBoxEnabled)
                    Toggle("Use metric units", isOn: $isMetricUnits)
                }
                
                Section {
                    Picker("Search range", selection: $searchRange) {
#if os(watchOS)
                        Text("20 NM").tag(20)
#endif
                        Text("50 NM").tag(50)
#if os(iOS)
                        Text("100 NM").tag(100)
                        Text("150 NM").tag(150)
                        Text("200 NM").tag(200)
                        Text("250 NM").tag(250)
#endif
                    }
#if os(iOS)
                    .pickerStyle(.menu)
#endif
                } header: {
                    Text("Performance")
                }
            }
            .navigationTitle("Settings")
#if os(iOS)
            .toolbarVisibility(.hidden, for: .tabBar)
#endif
        }
    }
}

#Preview {
    SettingsView()
}
