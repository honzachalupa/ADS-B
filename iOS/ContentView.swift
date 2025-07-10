import SwiftUI
import SwiftCore
import MapKit

struct RootView: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @ObservedObject private var aircraftService = AircraftService.shared
    @AppStorage(SETTINGS_IS_DEBUG_INFO_BOX_ENABLED_KEY) private var isDebugInfoBoxEnabled: Bool = false
    
    var body: some View {
        Group {
            if horizontalSizeClass == .regular {
                NavigationSplitView {
                    ListView()
                } detail: {
                    MapView()
                }
                
            } else {
                TabView {
                    Tab("Map", systemImage: "map") {
                        MapView()
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
