import SwiftUI

let SETTINGS_IS_METRIC_UNITS_KEY = "settings_isMetricUnits"
let SETTINGS_IS_INFO_BOX_ENABLED_KEY = "settings_isQuickInfoEnabled"

struct SettingsView: View {
    @AppStorage(SETTINGS_IS_METRIC_UNITS_KEY) private var isMetricUnits: Bool = false
    @AppStorage(SETTINGS_IS_INFO_BOX_ENABLED_KEY) private var isInfoBoxEnabled: Bool = true
    
    var body: some View {
        NavigationStack {
            Form {
                Toggle("Show info box below aircraft icon", isOn: $isInfoBoxEnabled)
                Toggle("Use metric units", isOn: $isMetricUnits)
            }
            .navigationTitle("Settings")
        }
    }
}

#Preview {
    SettingsView()
}
