import SwiftUI
import MapKit
import CoreLocation

struct RootView: View {
    @ObservedObject var aircraftService = AircraftService.shared
    @ObservedObject var airportService = AirportService.shared
    @ObservedObject var locationManager = LocationManager.shared
    
    var body: some View {
        TabView {
            Tab("Map", systemImage: "map") {
                MapView(aircrafts: aircraftService.aircrafts, airports: airportService.airports)
            }
            
            Tab("List", systemImage: "list.bullet") {
                ListView(aircrafts: aircraftService.aircrafts)
            }
            
            Tab("Settings", systemImage: "gearshape.fill") {
                SettingsView()
            }
        }
        .onAppear {
            locationManager.requestPermission()
            locationManager.requestLocation()
            
            // Fetch airport data
            if let location = locationManager.location {
                airportService.fetchAirportsAroundLocation(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)
            } else {
                // Default to Prague if location is not available
                airportService.fetchAirportsAroundLocation(latitude: 50.0755, longitude: 14.4378)
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                startTracking()
            }
        }
        .onChange(of: locationManager.location) { oldLocation, newLocation in
            if let location = newLocation {
                // Update both aircraft and airport data when location changes
                aircraftService.startPolling(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)
                airportService.fetchAirportsAroundLocation(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)
            }
        }
    }
    
    private func startTracking() {
        if let location = locationManager.location {
            aircraftService.startPolling(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)
        } else {
            aircraftService.startPolling(latitude: 50.0755, longitude: 14.4378)
        }
    }
}

#Preview {
    RootView()
}
