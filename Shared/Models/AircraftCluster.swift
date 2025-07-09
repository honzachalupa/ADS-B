import MapKit

struct AircraftCluster: Identifiable {
    let id: String
    var coordinate: CLLocationCoordinate2D
    var items: [Aircraft]
    
    init(coordinate: CLLocationCoordinate2D, items: [Aircraft]) {
        self.coordinate = coordinate
        self.items = items
        // Create stable ID based on sorted aircraft hexes
        self.id = items.map(\.hex).sorted().joined(separator: "-")
    }
    
    var shouldCluster: Bool {
        items.count > 1
    }
}

extension CLLocationCoordinate2D {
    func distance(to coordinate: CLLocationCoordinate2D) -> CLLocationDistance {
        let location1 = CLLocation(latitude: self.latitude, longitude: self.longitude)
        let location2 = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        return location1.distance(from: location2)
    }
}
