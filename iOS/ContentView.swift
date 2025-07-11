import SwiftUI
import SwiftCore
import MapKit

struct RootView: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @ObservedObject private var aircraftService = AircraftService.shared
    @AppStorage(SETTINGS_IS_DEBUG_INFO_BOX_ENABLED_KEY) private var isDebugInfoBoxEnabled: Bool = false
    @State private var isSettingsSheetPresented: Bool = false
    
    var body: some View {
        Group {
            if horizontalSizeClass == .regular {
                NavigationSplitView {
                    ListView()
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
                            SettingsView()
                        }
                } detail: {
                    MapView()
                }
            } else {
                TabView {
                    Tab("Map", systemImage: "map") {
                        NavigationStack {
                            MapView()
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
                    
                    Tab("List", systemImage: "list.bullet") {
                        ListView()
                    }
                }
            }
        }
        /* .tabViewBottomAccessory {
            if isDebugInfoBoxEnabled {
                DebugInfoView()
            }
        }
        .tabBarMinimizeBehavior(.onScrollDown) */
        .messageManagerOverlay()
    }
}

#Preview {
    RootView()
}
