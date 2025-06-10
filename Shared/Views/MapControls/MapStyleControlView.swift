import SwiftUI
import MapKit

struct MapStyleControlView: View {
    @Binding var mapStyle: MapStyle
    
    var body: some View {
#if os(iOS)
        Menu {
            Button { mapStyle = .standard } label: {
                Text("Standard")
            }
            
            Button { mapStyle = .hybrid(elevation: .realistic) } label: {
                Text("Hybrid")
            }
            
            Button { mapStyle = .imagery(elevation: .realistic) } label: {
                Text("Imagery")
            }
        } label: {
            Label("Map style", systemImage: "map.fill")
        }
#endif
    }
}

#Preview {
    @Previewable
    @State var selectedMapStyle: MapStyle = .standard
    
    MapStyleControlView(mapStyle: $selectedMapStyle)
}
