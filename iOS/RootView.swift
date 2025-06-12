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
        .tabViewStyle(.sidebarAdaptable)
    }
}

#Preview {
    RootView()
}
