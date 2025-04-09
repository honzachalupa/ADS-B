import SwiftUI
import MapKit

struct MapView: View {
    var aircrafts: [Aircraft]
    var airports: [Airport] = []
    var onAircraftSelected: ((Aircraft?) -> Void)? = nil
    @EnvironmentObject private var locationManager: LocationManager
    @AppStorage(SETTINGS_IS_INFO_BOX_ENABLED_KEY) private var isInfoBoxEnabled: Bool = true
    
    @State private var cameraPosition = MapCameraPosition.userLocation(fallback: .automatic)
    @State var selectedAircraft: Aircraft? = nil
    
    var body: some View {
        Map(position: $cameraPosition, selection: $selectedAircraft) {
            UserAnnotation()
            
            ForEach(aircrafts) { aircraft in
                let code = aircraft.formattedFlight.isEmpty ? aircraft.hex : aircraft.formattedFlight
                let hasNoData = (aircraft.gs == nil || (aircraft.gs ?? 0) <= 0) && aircraft.alt_baro == nil
                let isSimpleLabel = !isInfoBoxEnabled || hasNoData
                
                Annotation(
                    isSimpleLabel ? code : "",
                    coordinate: CLLocationCoordinate2D(
                        latitude: aircraft.lat ?? 0,
                        longitude: aircraft.lon ?? 0
                    ),
                    anchor: .top
                ) {
                    VStack(spacing: 0) {
                        ZStack {
                            Circle()
                                .fill(.thinMaterial)
                                .frame(width: 30, height: 30)
                            
                            Image(systemName: getMarkerIcon(for: aircraft))
                                .resizable()
                                .scaledToFit()
                                .frame(width: 15, height: 15)
                                .foregroundStyle(getMarkerColor(for: aircraft))
                                .rotationEffect(aircraft.feederType == .aircraft ? .degrees(Double(aircraft.track ?? 0) - 90) : .degrees(0))
                        }
                        
                        if !isSimpleLabel {
                            VStack {
                                Text(code)
                                    .fontWeight(.semibold)
                                    .font(.caption)
                                
                                if let groundSpeed = aircraft.gs, groundSpeed > 0 {
                                    Text(formatSpeed(groundSpeed))
                                        .font(.caption2)
                                }
                                
                                if let altitude = aircraft.alt_baro {
                                    Text(formatAltitude(altitude))
                                        .font(.caption2)
                                }
                            }
                            .padding(.horizontal, 4)
                            .padding(.vertical, 2)
                            .background(.thickMaterial)
                            .cornerRadius(4)
                            .padding(.top, 3)
                        }
                    }
                    /* .onTapGesture {
                        if aircraft.feederType == .aircraft, let onAircraftSelected {
                            onAircraftSelected(aircraft)
                        }
                    } */
                }
                .tag(aircraft)
            }
            
            ForEach(airports) { airport in
                Annotation(
                    airport.icao,
                    coordinate: airport.coordinate,
                ) {
                    ZStack {
                        Circle()
                            .fill(.thinMaterial)
                            .frame(width: 30, height: 30)
                        
                        Image(systemName: "airplane.departure")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 15, height: 15)
                    }
                }
            }
        }
        .mapControls {
            MapUserLocationButton()
            MapCompass()
#if os(iOS)
            MapScaleView()
#elseif os(watchOS)
            MapLocationCompass()
#endif
        }
        .onChange(of: selectedAircraft) {
            if let onAircraftSelected {
                onAircraftSelected(selectedAircraft)
            }
        }
    }
    
    private func getMarkerColor(for aircraft: Aircraft) -> Color {
        if aircraft.isEmergency {
            return .red
        }
        
        switch aircraft.feederType {
            case .aircraft:
                return Color.blue
            default:
                return Color.primary
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
