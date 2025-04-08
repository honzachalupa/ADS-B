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
        .edgesIgnoringSafeArea(.all)
        /* TabView {
            Tab("Map", systemImage: "airplane") {
                MapView(aircrafts: aircraftService.aircrafts) { aircraft in
                    selectedAircraft = aircraft
                }
                .edgesIgnoringSafeArea(.all)
            }
            
            Tab("Settings", systemImage: "gearshape.fill") {
                Text("Settings")
            }
        } */
        .environmentObject(locationManager)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    startTracking()
                } label: {
                    Image(systemName: "location")
                }
            }
        }
        .sheet(item: $selectedAircraft) { (aircraft: Aircraft) in
            AircraftDetailView(aircraft: aircraft)
                .presentationDetents([.medium, .large])
        }
        .onAppear {
            locationManager.requestPermission()
            locationManager.requestLocation()
            
            // Start tracking with a slight delay to ensure location is available
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                startTracking()
            }
        }
        .onChange(of: locationManager.location) { _, newLocation in
            if let location = newLocation {
                print("Location changed, updating aircraft data: \(location.coordinate.latitude), \(location.coordinate.longitude)")
                aircraftService.startPolling(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)
            }
        }
    }
    
    private func startTracking() {
        if let location = locationManager.location {
            print("Using device location: \(location.coordinate.latitude), \(location.coordinate.longitude)")
            
            aircraftService.startPolling(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)
        } else {
            print("Using default location (Prague)")
            
            aircraftService.startPolling(latitude: 50.0755, longitude: 14.4378)
        }
    }
}

#Preview {
    RootView()
}
