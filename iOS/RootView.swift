import SwiftUI
import MapKit
import CoreLocation

struct RootView: View {
    @StateObject private var aircraftService = AircraftService()
    @StateObject private var locationManager = LocationManager()
    @State private var selectedAircraft: Aircraft? = nil
    
    var body: some View {
        TabView {
            Tab("Map", systemImage: "map") {
                MapView(aircrafts: aircraftService.aircrafts) { aircraft in
                    selectedAircraft = aircraft
                }
                .sheet(item: $selectedAircraft) { (aircraft: Aircraft) in
                    AircraftDetailView(aircraft: aircraft)
                        .environmentObject(aircraftService)
                        .presentationDetents([.height(200), .medium, .large])
                        .presentationBackgroundInteraction(.enabled)
                }
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
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                startTracking()
            }
        }
        .onChange(of: locationManager.location) { _, newLocation in
            if let location = newLocation {
                aircraftService.startPolling(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)
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
