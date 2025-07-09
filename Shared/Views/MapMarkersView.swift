import SwiftUI
import MapKit

struct MapMarkersView: MapContent {
    let clusters: [AircraftCluster]
    let onClusterTap: (AircraftCluster) -> Void
    let onAircraftTap: (Aircraft) -> Void
    
    init(clusters: [AircraftCluster], onClusterTap: @escaping (AircraftCluster) -> Void, onAircraftTap: @escaping (Aircraft) -> Void) {
        self.clusters = clusters
        self.onClusterTap = onClusterTap
        self.onAircraftTap = onAircraftTap
    }
    
    @MainActor var body: some MapContent {
        ForEach(clusters, id: \.id) { cluster in
            if cluster.items.count > 1 {
                // Show cluster
                Annotation(
                    "\(cluster.items.count)",
                    coordinate: cluster.coordinate
                ) {
                    ClusterMarkerView(count: cluster.items.count)
                        .onTapGesture {
                            onClusterTap(cluster)
                        }
                }
            } else {
                // Show individual aircraft
                if let aircraft = cluster.items.first, let lat = aircraft.lat, let lon = aircraft.lon {
                    let coordinate = CLLocationCoordinate2D(latitude: lat, longitude: lon)
                    Annotation(
                        aircraft.formattedFlight.trimmingCharacters(in: .whitespaces).isEmpty ? 
                            aircraft.hex : aircraft.formattedFlight,
                        coordinate: coordinate
                    ) {
                        AircraftMarkerView(aircraft: aircraft)
                            .onTapGesture {
                                onAircraftTap(aircraft)
                            }
                    }
                }
            }
        }
    }
}

#Preview {
    let aircraft: Aircraft = PreviewAircraftData.getSingleAircraft()!
    let clusters: [AircraftCluster] = [
        AircraftCluster(coordinate: CLLocationCoordinate2D(latitude: 37.3346, longitude: -122.0090), 
                      items: [aircraft])
    ]
    
    Map {
        MapMarkersView(
            clusters: clusters,
            onClusterTap: { _ in },
            onAircraftTap: { _ in }
        )
    }
}
