import SwiftUI
import CoreLocation
import Combine

/// Manages app lifecycle events and coordinates polling behavior
class AppLifecycleManager: ObservableObject {
    // Singleton instance
    static let shared = AppLifecycleManager()
    
    // Services
    private let aircraftService = AircraftService.shared
    private let airportService = AirportService.shared
    private let locationManager = LocationManager.shared
    
    // Location subscription
    private var locationSubscription: AnyCancellable?
    
    // Private initializer to enforce singleton pattern
    private init() {
        // Setup location change observation
        setupLocationObserving()
    }
    
    // Setup location observing
    private func setupLocationObserving() {
        locationSubscription = locationManager.$location
            .compactMap { $0 }
            .sink { [weak self] location in
                guard let self = self else { return }
                // Update aircraft service with initial location
                // The actual polling will use map center coordinates
                self.aircraftService.updateMapCenter(latitude: location.coordinate.latitude, 
                                                   longitude: location.coordinate.longitude)
                
                // Start polling with the initial coordinates
                self.aircraftService.startPolling(latitude: location.coordinate.latitude, 
                                                longitude: location.coordinate.longitude)
                
                // Update airports around the current location
                self.airportService.fetchAirportsAroundLocation(latitude: location.coordinate.latitude, 
                                                              longitude: location.coordinate.longitude)
            }
    }
    
    // Initialize app services
    func initializeApp() {
        // Request location permissions
        locationManager.requestPermission()
        locationManager.requestLocation()
        
        // Fetch airport data
        if let location = locationManager.location {
            airportService.fetchAirportsAroundLocation(latitude: location.coordinate.latitude, 
                                                     longitude: location.coordinate.longitude)
        } else {
            // Default to Prague if location is not available
            airportService.fetchAirportsAroundLocation(latitude: 50.0755, longitude: 14.4378)
        }
        
        // Start aircraft tracking with a slight delay to allow location to be determined
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.startTracking()
        }
    }
    
    // Start aircraft tracking
    private func startTracking() {
        if let location = locationManager.location {
            aircraftService.startPolling(latitude: location.coordinate.latitude, 
                                         longitude: location.coordinate.longitude)
        } else {
            // Default to Prague if location is not available
            aircraftService.startPolling(latitude: 50.0755, longitude: 14.4378)
        }
    }
    
    // Handle scene phase changes
    func handleScenePhaseChange(from oldPhase: ScenePhase, to newPhase: ScenePhase) {
        switch newPhase {
        case .active:
            // App is in foreground - restart polling if we have a location
            if let location = locationManager.location {
                print("[AppLifecycleManager] App became active - restarting aircraft polling")
                aircraftService.startPolling(latitude: location.coordinate.latitude, 
                                           longitude: location.coordinate.longitude)
            }
        case .background, .inactive:
            // App is in background or inactive - stop polling to save data and battery
            print("[AppLifecycleManager] App entered background - stopping aircraft polling")
            aircraftService.stopPolling()
        @unknown default:
            break
        }
    }
}

// MARK: - View Modifier
struct AppLifecycleModifier: ViewModifier {
    @Environment(\.scenePhase) private var scenePhase
    @State private var previousScenePhase: ScenePhase = .inactive
    @State private var hasInitialized = false
    
    func body(content: Content) -> some View {
        content
            .onAppear {
                if !hasInitialized {
                    // Initialize the app only once
                    AppLifecycleManager.shared.initializeApp()
                    hasInitialized = true
                }
            }
            .onChange(of: scenePhase) { oldPhase, newPhase in
                AppLifecycleManager.shared.handleScenePhaseChange(from: oldPhase, to: newPhase)
            }
    }
}

// MARK: - View Extension
extension View {
    /// Applies app lifecycle management to handle background/foreground transitions
    func withAppLifecycleManagement() -> some View {
        self.modifier(AppLifecycleModifier())
    }
}
