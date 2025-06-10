import SwiftUI
import MapKit

struct MapUserLocationControlView: View {
    @Binding var cameraPosition: MapCameraPosition
    var userLocation: MapCameraPosition { .userLocation(fallback: .automatic) }
    
    var body: some View {
        Button {
            withAnimation {
                cameraPosition = userLocation
            }
        } label: {
            Label("Current location", systemImage: cameraPosition == userLocation ? "location.fill" : "location")
        }
    }
}

#Preview {
    @Previewable
    @State var cameraPosition: MapCameraPosition = .userLocation(fallback: .automatic)
    
    MapUserLocationControlView(cameraPosition: $cameraPosition)
}
