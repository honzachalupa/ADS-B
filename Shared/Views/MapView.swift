import SwiftUI
import MapKit

struct MapView: View {
    var aircrafts: [Aircraft]
    var onAircraftSelected: ((Aircraft) -> Void)? = nil
    @EnvironmentObject private var locationManager: LocationManager
    @AppStorage(SETTINGS_IS_INFO_BOX_ENABLED_KEY) private var isInfoBoxEnabled: Bool = true
    
    @State private var cameraPosition = MapCameraPosition.automatic
    @State private var followingAircraft: Aircraft? = nil
    @State private var isFollowingAircraft = false
    @State private var lastKnownPosition: CLLocationCoordinate2D? = nil
    
    var body: some View {
        Map(position: $cameraPosition) {
            UserAnnotation()
            
            ForEach(aircrafts) { aircraft in
                Annotation(
                    "",
                    coordinate: CLLocationCoordinate2D(
                        latitude: aircraft.lat ?? 0,
                        longitude: aircraft.lon ?? 0
                    ),
                    anchor: .top
                ) {
                    VStack(spacing: 0) {
                        ZStack {
                            Circle()
                                .fill(getMarkerColor(for: aircraft))
                                .frame(width: 30, height: 30)
                                .opacity(0.7)
                            
                            Image(systemName: getMarkerIcon(for: aircraft))
                                .resizable()
                                .scaledToFit()
                                .frame(width: 15, height: 15)
                                .foregroundColor(.white)
                                .rotationEffect(aircraft.feederType == .aircraft ? .degrees(Double(aircraft.track ?? 0) - 90) : .degrees(0))
                        }
                        
                        VStack {
                            Text(aircraft.formattedFlight.isEmpty ? aircraft.hex : aircraft.formattedFlight)
                                .fontWeight(.semibold)
                                .font(.caption)
                            
                            if isInfoBoxEnabled {
                                if let groundSpeed = aircraft.gs {
                                    Text(formatSpeed(groundSpeed))
                                        .font(.caption2)
                                }
                                
                                if let altitude = aircraft.alt_baro {
                                    Text(formatAltitude(altitude))
                                        .font(.caption2)
                                }
                            }
                            
                        }
                        .padding(.horizontal, 4)
                        .padding(.vertical, 2)
                        .background(.ultraThinMaterial)
                        .cornerRadius(4)
                        .padding(.top, 3)
                    }
                    .onTapGesture {
                        if aircraft.feederType == .aircraft, let onAircraftSelected {
                            onAircraftSelected(aircraft)
                            followingAircraft = aircraft
                            isFollowingAircraft = true
                            moveToAircraft(aircraft)
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
    
    private func getMarkerColor(for aircraft: Aircraft) -> Color {
        if aircraft.isEmergency {
            return .red
        }
        
        switch aircraft.feederType {
            case .aircraft:
                return .blue
            default:
                return .gray
        }
    }
    
    private func getMarkerIcon(for aircraft: Aircraft) -> String {
        switch aircraft.feederType {
            case .aircraft:
                return "airplane"
            default:
                return "antenna.radiowaves.left.and.right"
        }
    }
}

#Preview {
    MapView(aircrafts: PreviewAircraftData.getAircrafts())
        .environmentObject(LocationManager())
}
