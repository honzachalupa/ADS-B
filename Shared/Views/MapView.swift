import SwiftUI
import MapKit

struct MapView: View {
    @ObservedObject private var locationManager = LocationManager.shared
    @ObservedObject private var aircraftService = AircraftService.shared
    @ObservedObject private var airportService = AirportService.shared
    @AppStorage(SETTINGS_IS_INFO_BOX_ENABLED_KEY) private var isInfoBoxEnabled: Bool = true
    
    @State private var cameraPosition = MapCameraPosition.userLocation(fallback: .automatic)
    @State var selectedAircraft: Aircraft? = nil
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            Map(position: $cameraPosition, selection: $selectedAircraft) {
                UserAnnotation()
                
                ForEach(aircraftService.aircrafts) { aircraft in
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
                                
                                Image(systemName: AircraftDisplayConfig.getIconName(for: aircraft))
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 15, height: 15)
                                    .foregroundStyle(AircraftDisplayConfig.getColor(for: aircraft))
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
            .mapControls {
                MapUserLocationButton()
                MapCompass()
#if os(iOS)
                MapScaleView()
#elseif os(watchOS)
                MapLocationCompass()
#endif
            }
            .sheet(item: $selectedAircraft) { (aircraft: Aircraft) in
                AircraftDetailView(aircraft: aircraft)
                    .presentationDetents([.height(200), .medium, .large])
                    .presentationBackgroundInteraction(.enabled)
            }
            
#if os(iOS)
            VStack {
                MapLegendView()
                MapFilterView()
            }
            .padding(5)
#endif
        }
    }
}

#Preview {
    MapView()
}
