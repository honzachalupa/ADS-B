import SwiftUI
import MapKit
import CoreLocation

struct RootView: View {
    @StateObject private var aircraftService = AircraftService()
    @StateObject private var airportService = AirportService()
    @StateObject private var locationManager = LocationManager()
    @State private var selectedAircraft: Aircraft? = nil
    
    var body: some View {
        TabView {
            Tab("Map", systemImage: "map") {
                MapView(aircrafts: aircraftService.aircrafts, airports: airportService.airports)
                    .environmentObject(locationManager)
            }
            
            Tab("List", systemImage: "list.bullet.rectangle.fill") {
                ListView(aircrafts: aircraftService.aircrafts) { aircraft in
                    selectedAircraft = aircraft
                }
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
        .environmentObject(LocationManager())
}
