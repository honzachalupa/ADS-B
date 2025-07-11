import SwiftUI
import MapKit

struct MarkerView: View {
    var size: Double
    var iconSystemName: String
    var fillColor: Color
    var foregroundColor: Color
    
    var body: some View {
        ZStack {
            Circle()
                .fill(fillColor)
                .frame(width: size, height: size)
            
            Image(systemName: iconSystemName)
                .resizable()
                .scaledToFit()
                .frame(width: size / 2, height: size / 2)
                .foregroundStyle(foregroundColor)
        }
    }
}

struct AircraftMarkerView {
    let aircraft: Aircraft
    let isInfoBoxEnabled: Bool
    let currentZoomLevel: Double
    @Binding var selectedAircraft: Aircraft?
    
    // Pre-computed values for performance
    private let code: String
    private let aircraftType: AircraftDisplayConfig.AircraftType
    private let aircraftColor: Color
    private let isSimpleLabel: Bool
    private let rotationAngle: Double
    
    init(aircraft: Aircraft, isInfoBoxEnabled: Bool, currentZoomLevel: Double, selectedAircraft: Binding<Aircraft?>) {
        self.aircraft = aircraft
        self.isInfoBoxEnabled = isInfoBoxEnabled
        self.currentZoomLevel = currentZoomLevel
        self._selectedAircraft = selectedAircraft
        
        // Pre-compute expensive calculations
        self.code = aircraft.formattedFlight.isEmpty ? aircraft.hex : aircraft.formattedFlight
        self.aircraftType = AircraftDisplayConfig.getAircraftType(for: aircraft)
        self.aircraftColor = Self.calculateAircraftColor(for: aircraft)
        self.isSimpleLabel = !isInfoBoxEnabled || currentZoomLevel <= 9
        self.rotationAngle = aircraftType.shouldRotateWithHeading ? Double(aircraft.track ?? 0) - 90 : 0
    }
    
    private static func calculateAircraftColor(for aircraft: Aircraft) -> Color {
        if aircraft.isEmergency {
            return .red
        } else if aircraft.isMilitary {
            return .green
        } else {
            return .white
        }
    }
    
    var annotation: some MapContent {
        Annotation(
            isSimpleLabel ? code : "",
            coordinate: CLLocationCoordinate2D(
                latitude: aircraft.lat ?? 0,
                longitude: aircraft.lon ?? 0
            ),
            anchor: .top
        ) {
            VStack {
                MarkerView(
                    size: 30,
                    iconSystemName: aircraftType.iconName,
                    fillColor: .black.opacity(0.5),
                    foregroundColor: aircraftColor
                )
                .rotationEffect(.degrees(rotationAngle))
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
                    .background(.background.opacity(0.5))
                    .cornerRadius(4)
                }
            }
            .onTapGesture {
                selectedAircraft = aircraft
            }
            .zIndex(1)
        }
    }
}

extension AircraftMarkerView: MapContent {
    var body: some MapContent {
        annotation
    }
}
