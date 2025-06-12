import SwiftUI
import SwiftCore
import MapKit

struct MapView: View {
    @ObservedObject private var locationManager = LocationManager.shared
    @ObservedObject private var aircraftService = AircraftService.shared
    @ObservedObject private var airportService = AirportService.shared
    @AppStorage(SETTINGS_IS_INFO_BOX_ENABLED_KEY) private var isInfoBoxEnabled: Bool = true
    
    @State private var cameraPosition = MapCameraPosition.userLocation(fallback: .automatic)
    @State private var selectedMapStyle: MapStyle = .standard
    @State var selectedAircraft: Aircraft? = nil
    
    var body: some View {
        NavigationStack {
            Map(position: $cameraPosition, selection: $selectedAircraft) {
                UserAnnotation()
                
                ForEach(aircraftService.aircrafts) { aircraft in
                    let code = aircraft.formattedFlight.isEmpty ? aircraft.hex : aircraft.formattedFlight
                    let hasNoData = (aircraft.gs == nil || (aircraft.gs ?? 0) <= 0) && aircraft.alt_baro == nil
                    let aircraftType = AircraftDisplayConfig.getAircraftType(for: aircraft)
                    let isSimpleLabel = !isInfoBoxEnabled || hasNoData
                    
                    /* Marker(code, systemImage: aircraftType.iconName, coordinate: CLLocationCoordinate2D(
                        latitude: aircraft.lat ?? 0,
                        longitude: aircraft.lon ?? 0
                    )) */
                    
                    Annotation(
                        isSimpleLabel ? code : "",
                        coordinate: CLLocationCoordinate2D(
                            latitude: aircraft.lat ?? 0,
                            longitude: aircraft.lon ?? 0
                        ),
                        anchor: .top
                    ) {
                        VStack {
                            ZStack {
                                Circle()
                                    .fill(.thinMaterial)
                                    .frame(width: 30, height: 30)
                                
                                Image(systemName: aircraftType.iconName)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 15, height: 15)
                                    .foregroundStyle(aircraft.type == "mlat" ? .green : .blue)
                                    .rotationEffect(aircraft.feederType == .aircraft ? .degrees(Double(aircraft.track ?? 0) - 90) : .degrees(0))
                            }
                            .scaleEffect(aircraftType.scale)
                            
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
                            }
                        }
                    }
                    .tag(aircraft)
                }
                
                ForEach(airportService.airports) { airport in
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
            .mapStyle(selectedMapStyle)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    NavigationLink {
                        SettingsView()
                    } label: {
                        Label("Settings", systemImage: "gearshape.fill")
                    }
                }
                
                /* #if os(iOS)
                if #available(iOS 26, *) {
                    ToolbarSpacer(.fixed, placement: .topBarLeading)
                }
                #endif */
                
                ToolbarItem(placement: .topBarLeading) {
                    MapFilterControlView()
                }
                
                ToolbarItem(placement: .topBarLeading) {
                    MapLegendView {
                        Label("Legend", systemImage: "info.circle.fill")
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    MapStyleControlView(mapStyle: $selectedMapStyle)
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    MapUserLocationControlView(cameraPosition: $cameraPosition)
                }
            }
            .sheet(item: $selectedAircraft) { (aircraft: Aircraft) in
                AircraftDetailView(aircraft: aircraft)
                    .presentationDetents([.medium, .large])
                    .presentationBackgroundInteraction(.enabled)
            }
        }
    }
}

#Preview {
    MapView()
}
