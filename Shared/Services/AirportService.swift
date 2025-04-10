import Foundation

class AirportService: ObservableObject {
    // Singleton instance
    static let shared = AirportService()
    
    // Private initializer to enforce singleton pattern
    private init() {}
    @Published var airports: [Airport] = []
    @Published var isLoading: Bool = false
    @Published var error: Error? = nil
    
    // Dictionary of airport data
    private let airportData: [String: (name: String, lat: Double, lon: Double, country: String, iata: String?)] = [
        // Czech airports
        "LKPR": ("Prague Václav Havel Airport", 50.1008, 14.26, "CZ", "PRG"),
        "LKTB": ("Brno-Tuřany Airport", 49.1513, 16.6944, "CZ", "BRQ"),
        "LKMT": ("Ostrava Leoš Janáček Airport", 49.6963, 18.1111, "CZ", "OSR"),
        "LKCV": ("Čáslav Air Base", 49.9394, 15.3819, "CZ", nil),
        "LKKV": ("Karlovy Vary Airport", 50.2029, 12.9149, "CZ", "KLV"),
        "LKPD": ("Pardubice Airport", 50.0134, 15.7386, "CZ", "PED"),
        
        // European major airports
        "EGLL": ("London Heathrow Airport", 51.4775, -0.4614, "GB", "LHR"),
        "EGKK": ("London Gatwick Airport", 51.1481, -0.1903, "GB", "LGW"),
        "LFPG": ("Paris Charles de Gaulle Airport", 49.0097, 2.5479, "FR", "CDG"),
        "LFPO": ("Paris Orly Airport", 48.7262, 2.3652, "FR", "ORY"),
        "EDDF": ("Frankfurt Airport", 50.0379, 8.5622, "DE", "FRA"),
        "EDDL": ("Düsseldorf Airport", 51.2895, 6.7668, "DE", "DUS"),
        "EDDB": ("Berlin Brandenburg Airport", 52.3667, 13.5033, "DE", "BER"),
        "EHAM": ("Amsterdam Schiphol Airport", 52.3086, 4.7639, "NL", "AMS"),
        "LEMD": ("Madrid Barajas Airport", 40.4983, -3.5676, "ES", "MAD"),
        "LIRF": ("Rome Fiumicino Airport", 41.8045, 12.2508, "IT", "FCO"),
        "EDDM": ("Munich Airport", 48.3538, 11.7861, "DE", "MUC"),
        "LOWW": ("Vienna International Airport", 48.1103, 16.5697, "AT", "VIE"),
        "LSZH": ("Zurich Airport", 47.4647, 8.5492, "CH", "ZRH"),
        "EKCH": ("Copenhagen Airport", 55.6180, 12.6508, "DK", "CPH"),
        "ESSA": ("Stockholm Arlanda Airport", 59.6498, 17.9237, "SE", "ARN"),
        "LEBL": ("Barcelona El Prat Airport", 41.2971, 2.0785, "ES", "BCN"),
        "EPWA": ("Warsaw Chopin Airport", 52.1657, 20.9671, "PL", "WAW"),
        "LHBP": ("Budapest Ferenc Liszt International Airport", 47.4298, 19.2611, "HU", "BUD"),
        "LSGG": ("Geneva Airport", 46.2380, 6.1089, "CH", "GVA"),
        "ENGM": ("Oslo Gardermoen Airport", 60.1976, 11.0984, "NO", "OSL"),
        "EFHK": ("Helsinki Airport", 60.3183, 24.9630, "FI", "HEL"),
        "EIDW": ("Dublin Airport", 53.4264, -6.2499, "IE", "DUB"),
        "LPPT": ("Lisbon Airport", 38.7756, -9.1354, "PT", "LIS"),
        "LGAV": ("Athens International Airport", 37.9364, 23.9445, "GR", "ATH"),
        
        // North American airports
        "KJFK": ("John F. Kennedy International Airport", 40.6413, -73.7781, "US", "JFK"),
        "KLAX": ("Los Angeles International Airport", 33.9416, -118.4085, "US", "LAX"),
        "KORD": ("O'Hare International Airport", 41.9742, -87.9073, "US", "ORD"),
        "KATL": ("Hartsfield-Jackson Atlanta International Airport", 33.6407, -84.4277, "US", "ATL"),
        "KSFO": ("San Francisco International Airport", 37.6213, -122.3790, "US", "SFO"),
        "KDFW": ("Dallas/Fort Worth International Airport", 32.8998, -97.0403, "US", "DFW"),
        "KMIA": ("Miami International Airport", 25.7932, -80.2906, "US", "MIA"),
        "KLAS": ("Harry Reid International Airport", 36.0840, -115.1537, "US", "LAS"),
        "CYYZ": ("Toronto Pearson International Airport", 43.6777, -79.6248, "CA", "YYZ"),
        "CYVR": ("Vancouver International Airport", 49.1967, -123.1815, "CA", "YVR"),
        "MMMX": ("Mexico City International Airport", 19.4363, -99.0721, "MX", "MEX"),
        
        // Asian airports
        "RJAA": ("Narita International Airport", 35.7647, 140.3864, "JP", "NRT"),
        "RJTT": ("Tokyo Haneda Airport", 35.5494, 139.7798, "JP", "HND"),
        "RKSI": ("Incheon International Airport", 37.4602, 126.4407, "KR", "ICN"),
        "VHHH": ("Hong Kong International Airport", 22.3080, 113.9185, "HK", "HKG"),
        "ZBAA": ("Beijing Capital International Airport", 40.0799, 116.6031, "CN", "PEK"),
        "ZSPD": ("Shanghai Pudong International Airport", 31.1443, 121.8083, "CN", "PVG"),
        "WSSS": ("Singapore Changi Airport", 1.3644, 103.9915, "SG", "SIN"),
        "VTBS": ("Suvarnabhumi Airport", 13.6900, 100.7501, "TH", "BKK"),
        "VIDP": ("Indira Gandhi International Airport", 28.5562, 77.1000, "IN", "DEL"),
        "VABB": ("Chhatrapati Shivaji Maharaj International Airport", 19.0896, 72.8656, "IN", "BOM"),
        "OMDB": ("Dubai International Airport", 25.2528, 55.3644, "AE", "DXB"),
        "OEJN": ("King Abdulaziz International Airport", 21.6790, 39.1225, "SA", "JED"),
        "RKPC": ("Jeju International Airport", 33.5113, 126.4930, "KR", "CJU"),
        
        // Australian and Oceanian airports
        "YSSY": ("Sydney Kingsford Smith Airport", -33.9399, 151.1753, "AU", "SYD"),
        "YMML": ("Melbourne Airport", -37.6690, 144.8410, "AU", "MEL"),
        "YBBN": ("Brisbane Airport", -27.3842, 153.1175, "AU", "BNE"),
        "NZAA": ("Auckland Airport", -37.0082, 174.7850, "NZ", "AKL"),
        
        // South American airports
        "SBGR": ("São Paulo-Guarulhos International Airport", -23.4356, -46.4731, "BR", "GRU"),
        "SAEZ": ("Ezeiza International Airport", -34.8222, -58.5358, "AR", "EZE"),
        "SCEL": ("Santiago International Airport", -33.3898, -70.7947, "CL", "SCL"),
        "SKBO": ("El Dorado International Airport", 4.7016, -74.1469, "CO", "BOG"),
        
        // African airports
        "FACT": ("Cape Town International Airport", -33.9649, 18.6027, "ZA", "CPT"),
        "FAJS": ("O.R. Tambo International Airport", -26.1392, 28.2460, "ZA", "JNB"),
        "HECA": ("Cairo International Airport", 30.1219, 31.4056, "EG", "CAI"),
        "DNMM": ("Murtala Muhammed International Airport", 6.5774, 3.3215, "NG", "LOS")
    ]
    
    // Fetch all airports
    func fetchAirports() {
        isLoading = true
        airports.removeAll()
        
        // Create airport objects from data
        for (code, data) in airportData {
            let airport = Airport(
                id: code,
                icao: code,
                iata: data.iata,
                name: data.name,
                lat: data.lat,
                lon: data.lon,
                location: nil,
                countryiso2: data.country,
                alt_feet: nil,
                alt_meters: nil
            )
            
            airports.append(airport)
        }
        
        isLoading = false
        print("[AirportService] ✅ Loaded \(airports.count) airports")
    }
    
    // For compatibility with existing code
    func fetchAirportsAroundLocation(latitude: Double, longitude: Double, radius: Double = 200.0) {
        fetchAirports()
    }
    
    // Clear all airports
    func clearAirports() {
        airports.removeAll()
    }
}
