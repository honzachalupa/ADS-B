import SwiftUI

let SETTINGS_IS_METRIC_UNITS_KEY = "settings_isMetricUnits"

struct SettingsView: View {
    @AppStorage(SETTINGS_IS_METRIC_UNITS_KEY) private var isMetricUnits: Bool = false
    
    var body: some View {
        NavigationStack {
            Form {
                Toggle("Use metric units", isOn: $isMetricUnits)
            }
            .navigationTitle("Settings")
        }
    }
}

#Preview {
    SettingsView()
}
