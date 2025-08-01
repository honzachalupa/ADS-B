import SwiftUI
import SwiftCore
import MapKit

struct ContentView: View {
    @State private var selectedAircraft: Aircraft? = nil

    var body: some View {
        NavigationStack {
            MapView(selectedAircraft: $selectedAircraft)
                .toolbar {
                    ToolbarItem(placement: .bottomBar) {
                        NavigationLink {
                            ListView(selectedAircraft: $selectedAircraft)
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
        .messageManagerOverlay()
    }
}

#Preview {
    ContentView()
}
