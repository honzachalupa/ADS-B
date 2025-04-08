import SwiftUI
import MapKit
import CoreLocation

struct RootView: View {
    @StateObject private var aircraftService = AircraftService()
    @StateObject private var locationManager = LocationManager()
    @State private var selectedAircraft: Aircraft? = nil
    
    var body: some View {
        MapView(aircrafts: aircraftService.aircrafts) { aircraft in
            selectedAircraft = aircraft
        }
        .ignoresSafeArea()

        .environmentObject(locationManager)
        .sheet(item: $selectedAircraft) { (aircraft: Aircraft) in
            AircraftDetailView(aircraft: aircraft)
                .environmentObject(aircraftService)
                .presentationDetents([.height(200), .medium, .large])
                .presentationBackgroundInteraction(.enabled)
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
}
