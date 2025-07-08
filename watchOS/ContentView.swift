import SwiftUI
import MapKit

struct RootView: View {
    @State private var selectedAircraft: Aircraft? = nil

    var body: some View {
        NavigationStack {
            MapView()
                .toolbar {
                    ToolbarItem(placement: .bottomBar) {
                        NavigationLink {
                            ListView()
                        } label: {
                            Label("List", systemImage: "list.bullet")
                        }
                    }
                    
                    ToolbarItem(placement: .topBarLeading) {
                        NavigationLink {
                            SettingsView()
                        } label: {
                            Label("Settings", systemImage: "gearshape.fill")
                        }
                    }
                }
        }
    }
}

#Preview {
    RootView()
}
