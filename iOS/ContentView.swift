import SwiftUI
import MapKit

struct RootView: View {
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
            DebugInfoView()
        }
        .tabBarMinimizeBehavior(.onScrollDown)
        .mapFeatureSelectionAccessory()
    }
}

#Preview {
    RootView()
}
