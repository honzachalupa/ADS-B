import Foundation

class ServiceManager {
    static let shared = ServiceManager()
    
    private(set) var aircraftService: AircraftService?
    private(set) var airportService: AirportService?
    private(set) var locationManager: LocationManager?
    
    private init() {}
    
    func registerServices(aircraftService: AircraftService, airportService: AirportService, locationManager: LocationManager) {
        self.aircraftService = aircraftService
        self.airportService = airportService
        self.locationManager = locationManager
    }
}
