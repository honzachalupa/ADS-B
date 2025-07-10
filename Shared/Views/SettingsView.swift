import SwiftUI

let SETTINGS_IS_METRIC_UNITS_KEY = "settings_isMetricUnits"
let SETTINGS_IS_INFO_BOX_ENABLED_KEY = "settings_isQuickInfoEnabled"
let SETTINGS_IS_DEBUG_INFO_BOX_ENABLED_KEY = "settings_isDebugInfoBoxEnabled"

struct SettingsView: View {
    @AppStorage(SETTINGS_IS_METRIC_UNITS_KEY) private var isMetricUnits: Bool = false
    @AppStorage(SETTINGS_IS_INFO_BOX_ENABLED_KEY) private var isInfoBoxEnabled: Bool = true
    @AppStorage(SETTINGS_IS_DEBUG_INFO_BOX_ENABLED_KEY) private var isDebugInfoBoxEnabled: Bool = false
    
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
                    
                    #if os(iOS)
                    Toggle("Show debug info box", isOn: $isDebugInfoBoxEnabled)
                    #endif
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
