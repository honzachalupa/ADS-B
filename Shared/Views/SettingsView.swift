import SwiftUI

let SETTINGS_IS_METRIC_UNITS_KEY = "settings_isMetricUnits"
let SETTINGS_IS_INFO_BOX_ENABLED_KEY = "settings_isQuickInfoEnabled"
let SETTINGS_FETCH_INTERVAL_KEY = "settings_fetchInterval"
let SETTINGS_SEARCH_RANGE_KEY = "settings_searchRange"

class Settings: ObservableObject {
    static let shared = Settings()
    
    @Published var fetchInterval: Int = UserDefaults.standard.integer(forKey: SETTINGS_FETCH_INTERVAL_KEY) {
        didSet {
            UserDefaults.standard.set(fetchInterval, forKey: SETTINGS_FETCH_INTERVAL_KEY)
            // Restart polling with new interval
            AircraftService.shared.startPolling(
                latitude: AircraftService.shared.currentLatitude,
                longitude: AircraftService.shared.currentLongitude
            )
        }
    }
    
    private init() {}
}

struct SettingsView: View {
    @AppStorage(SETTINGS_IS_METRIC_UNITS_KEY) private var isMetricUnits: Bool = false
    @AppStorage(SETTINGS_IS_INFO_BOX_ENABLED_KEY) private var isInfoBoxEnabled: Bool = true
    @StateObject private var settings = Settings.shared
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
                    Picker("Refresh interval", selection: $settings.fetchInterval) {
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
