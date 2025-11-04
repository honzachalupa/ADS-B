import SwiftUI
import SwiftCore
import MapKit

struct ContentView: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @ObservedObject private var aircraftService = AircraftService.shared
    @AppStorage(SETTINGS_IS_DEBUG_INFO_BOX_ENABLED_KEY) private var isDebugInfoBoxEnabled: Bool = false
    @State private var selectedAircraft: Aircraft?
    @State private var isSettingsSheetPresented: Bool = false
    @State private var selectedTab: String = "Map"
    
    var body: some View {
        Group {
            if horizontalSizeClass == .regular {
                NavigationSplitView {
                    ListView(selectedAircraft: $selectedAircraft)
                        .toolbar {
                            ToolbarItem(placement: .topBarLeading) {
                                Button {
                                    isSettingsSheetPresented.toggle()
                                } label: {
                                    Label("Settings", systemImage: "gearshape.fill")
                                }
                            }
                        }
                        .sheet(isPresented: $isSettingsSheetPresented) {
                            NavigationStack {
                                SettingsView()
                                    .toolbar {
                                        ToolbarItem(placement: .cancellationAction) {
                                            Button {
                                                isSettingsSheetPresented.toggle()
                                            } label: {
                                                Label("Close", systemImage: "xmark")
                                            }
                                        }
                                    }
                            }
                        }
                } detail: {
                    MapView(selectedAircraft: $selectedAircraft)
                }
            } else {
                TabView(selection: $selectedTab) {
                    Tab("Map", systemImage: "map", value: "Map") {
                        NavigationStack {
                            MapView(selectedAircraft: $selectedAircraft)
                                .toolbar {
                                    ToolbarItem(placement: .topBarLeading) {
                                        NavigationLink {
                                            SettingsView()
                                        } label: {
                                            Label("Settings", systemImage: "gearshape.fill")
                                        }
                                    }
                                    
#if os(iOS)
                                    // ToolbarSpacer(.flexible, placement: .topBarLeading)
#endif
                                }
                        }
                    }
                    
                    Tab("List", systemImage: "list.bullet", value: "List") {
                        ListView(selectedAircraft: $selectedAircraft)
                    }
                }
            }
        }
        .onChange(of: selectedAircraft) { _, aircraft in
            // Switch to Map tab when aircraft is selected on iPhone
            if aircraft != nil && horizontalSizeClass == .compact {
                selectedTab = "Map"
            }
        }
        .overlay {
            if isDebugInfoBoxEnabled {
                VStack {
                    Spacer()
                    
                    DebugInfoView()
                        .padding()
                        .background(.thinMaterial)
                        .clipShape(Capsule())
                        .frame(maxWidth: 500)
                        .padding(.bottom)
                }
            }
        }
        .messageManagerOverlay()
    }
}

#Preview {
    ContentView()
}
