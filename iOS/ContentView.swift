import SwiftUI
import SwiftCore
import MapKit

struct RootView: View {
    @AppStorage(SETTINGS_IS_DEBUG_INFO_BOX_ENABLED_KEY) private var isDebugInfoBoxEnabled: Bool = false
    
    var body: some View {
        TabView {
            Tab("Map", systemImage: "map") {
                MapView()
            }
            
            Tab("List", systemImage: "list.bullet") {
                ListView()
            }
        }
        .tabViewBottomAccessory {
            if isDebugInfoBoxEnabled {
                DebugInfoView()
            }
        }
        .tabBarMinimizeBehavior(.onScrollDown)
        .mapFeatureSelectionAccessory()
        .messageManagerOverlay()
    }
}

#Preview {
    RootView()
}
