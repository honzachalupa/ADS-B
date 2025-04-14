import SwiftUI

let SETTINGS_IS_METRIC_UNITS_KEY = "settings_isMetricUnits"
let SETTINGS_IS_INFO_BOX_ENABLED_KEY = "settings_isQuickInfoEnabled"
let SETTINGS_FETCH_INTERVAL_KEY = "settings_fetchInterval"
let SETTINGS_SEARCH_RANGE_KEY = "settings_searchRange"

struct SettingsView: View {
    @AppStorage(SETTINGS_IS_METRIC_UNITS_KEY) private var isMetricUnits: Bool = false
    @AppStorage(SETTINGS_IS_INFO_BOX_ENABLED_KEY) private var isInfoBoxEnabled: Bool = true
    @AppStorage(SETTINGS_FETCH_INTERVAL_KEY) private var fetchInterval: Int = 5
    @AppStorage(SETTINGS_SEARCH_RANGE_KEY) private var searchRange: Int = 50
    
    var body: some View {
        NavigationStack {
            Form {
#if os(watchOS)
                Section("Filter") {
                    MapFilterTogglesView()
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
                    Picker("Refresh interval", selection: $fetchInterval) {
#if os(iOS)
                        Text("1 second").tag(1)
#endif
                        Text("2 seconds").tag(2)
                        Text("5 seconds").tag(5)
                        Text("10 seconds").tag(10)
                    }
#if os(iOS)
                    .pickerStyle(.menu)
#endif
                    
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
                } footer: {
                    Text("App needs to be restarted for changes to take effect.")
                }

            }
            .navigationTitle("Settings")
        }
    }
}

#Preview {
    SettingsView()
}
