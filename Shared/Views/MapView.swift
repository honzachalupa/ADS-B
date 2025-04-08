import SwiftUI
import MapKit

struct MapView: View {
    var aircrafts: [Aircraft]
    var onAircraftSelected: ((Aircraft) -> Void)? = nil
    @EnvironmentObject private var locationManager: LocationManager
    @State private var position: MapCameraPosition = .automatic
    
    var body: some View {
        Map(position: $position) {
            UserAnnotation()
            
            ForEach(aircrafts.filter { $0.hasValidCoordinates }) { aircraft in
                Annotation(
                    aircraft.formattedFlight.isEmpty ? aircraft.hex : aircraft.formattedFlight,
                    coordinate: CLLocationCoordinate2D(
                        latitude: aircraft.lat ?? 0,
                        longitude: aircraft.lon ?? 0
                    ),
                    anchor: .bottom
                ) {
                    VStack(spacing: 0) {
                        ZStack {
                            Circle()
                                .fill(aircraft.isEmergency ? Color.red : Color.blue)
                                .frame(width: 30, height: 30)
                            
                            Image(systemName: "airplane")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 15, height: 15)
                                .foregroundColor(.white)
                                .rotationEffect(.degrees(Double(aircraft.track ?? 0) - 90))
                        }
                        .onTapGesture {
                            onAircraftSelected?(aircraft)
                        }
                    }
                }
            }
        }
        #if os(iOS)
        .mapControls {
            MapScaleView()
            MapUserLocationButton()
        }
        #endif
        .onAppear {
            // Center map on user's location if available
            if let userLocation = locationManager.location {
                position = .region(MKCoordinateRegion(
                    center: userLocation.coordinate,
                    span: MKCoordinateSpan(latitudeDelta: 1.0, longitudeDelta: 1.0)
                ))
            }
            // Fallback to first aircraft if user location is not available
            else if let firstAircraft = aircrafts.first(where: { $0.hasValidCoordinates }),
                    let lat = firstAircraft.lat,
                    let lon = firstAircraft.lon {
                position = .region(MKCoordinateRegion(
                    center: CLLocationCoordinate2D(latitude: lat, longitude: lon),
                    span: MKCoordinateSpan(latitudeDelta: 1.0, longitudeDelta: 1.0)
                ))
            }
        }
        .onChange(of: locationManager.location) { _, newLocation in
            // Update map center when location changes, if we have no aircraft selected
            if let location = newLocation, aircrafts.isEmpty {
                position = .region(MKCoordinateRegion(
                    center: location.coordinate,
                    span: MKCoordinateSpan(latitudeDelta: 1.0, longitudeDelta: 1.0)
                ))
            }
        }
    }
}

#Preview {
    @Previewable
    @State var selectedAircraft: Aircraft? = nil
    
    MapView(aircrafts: []) { aircraft in
        selectedAircraft = aircraft
    }
}
