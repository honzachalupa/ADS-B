import SwiftUI
import MapKit

struct MapView: View {
    var aircrafts: [Aircraft]
    var onAircraftSelected: ((Aircraft) -> Void)? = nil
    @EnvironmentObject private var locationManager: LocationManager
    
    @State private var cameraPosition = MapCameraPosition.automatic
    @State private var followingAircraft: Aircraft? = nil
    @State private var isFollowingAircraft = false
    @State private var lastKnownPosition: CLLocationCoordinate2D? = nil
    
    var body: some View {
        Map(position: $cameraPosition) {
            UserAnnotation()
            
            ForEach(aircrafts) { aircraft in
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
                            if let onAircraftSelected {
                                onAircraftSelected(aircraft)
                                followingAircraft = aircraft
                                isFollowingAircraft = true
                                moveToAircraft(aircraft)
                            }
                        }
                    }
                }
            }
        }
        .mapControls {
#if os(iOS)
            MapScaleView()
#endif
            MapUserLocationButton()
        }
        .onChange(of: aircrafts) { _, newAircrafts in
            if isFollowingAircraft, let selectedHex = followingAircraft?.hex {
                if let updatedAircraft = newAircrafts.first(where: { $0.hex == selectedHex }) {
                    moveToAircraft(updatedAircraft)
                }
            }
        }
        .onAppear {
            if let userLocation = locationManager.location {
                cameraPosition = .region(MKCoordinateRegion(
                    center: userLocation.coordinate,
                    span: MKCoordinateSpan(latitudeDelta: 1.0, longitudeDelta: 1.0)
                ))
            }
        }
        .onChange(of: locationManager.location) { _, newLocation in
            if !isFollowingAircraft, let location = newLocation, aircrafts.isEmpty {
                cameraPosition = .region(MKCoordinateRegion(
                    center: location.coordinate,
                    span: MKCoordinateSpan(latitudeDelta: 1.0, longitudeDelta: 1.0)
                ))
            }
        }
    }
    
    private func moveToAircraft(_ aircraft: Aircraft) {
        guard let lat = aircraft.lat, let lon = aircraft.lon else {
            return
        }
        
        let coordinate = CLLocationCoordinate2D(latitude: lat, longitude: lon)
        
        let region = MKCoordinateRegion(
            center: coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.3, longitudeDelta: 0.3)
        )
        
        withAnimation(.easeInOut(duration: 0.2)) {
            cameraPosition = .region(region)
        }
    }
}

#Preview {
    MapView(aircrafts: []) { _ in }
}
