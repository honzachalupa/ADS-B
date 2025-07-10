import Foundation

struct PreviewAircraftData {
    static func getAircraft() -> [Aircraft] {
        let jsonString = """
        {
            "ac": [
                {
                    "hex": "a1b2c3",
                    "type": "B738",
                    "flight": "SWA1234",
                    "r": "N12345",
                    "t": "B738",
                    "category": "A3",
                    "lat": 37.7749,
                    "lon": -122.4194,
                    "alt_baro": 25000,
                    "alt_geom": 25100,
                    "gs": 450.0,
                    "track": 90.0,
                    "ias": 320,
                    "tas": 380,
                    "mach": 0.78,
                    "squawk": "1200",
                    "nav_modes": ["autopilot", "vnav"],
                    "baro_rate": 0
                },
                {
                    "hex": "d4e5f6",
                    "type": "A320",
                    "flight": "DAL2468",
                    "r": "N67890",
                    "t": "A320",
                    "category": "A3",
                    "lat": 37.6213,
                    "lon": -122.3790,
                    "alt_baro": 5000,
                    "alt_geom": 5050,
                    "gs": 220.0,
                    "track": 180.0,
                    "ias": 210,
                    "tas": 230,
                    "mach": 0.45,
                    "squawk": "7500",
                    "emergency": "general",
                    "nav_modes": ["tcas"],
                    "baro_rate": -500
                },
                {
                    "hex": "g7h8i9",
                    "type": "H60",
                    "flight": "USCG6042",
                    "r": "CG6042",
                    "t": "H60",
                    "category": "A7",
                    "lat": 37.8044,
                    "lon": -122.2711,
                    "alt_baro": 1200,
                    "alt_geom": 1250,
                    "gs": 110.0,
                    "track": 270.0,
                    "ias": 105,
                    "tas": 115,
                    "squawk": "1201",
                    "baro_rate": 0
                }
            ],
            "msg": "Aircraft",
            "now": 1617211234,
            "total": 3,
            "ctime": 1617211234,
            "ptime": 1617211234
        }
        """
        
        if let jsonData = jsonString.data(using: .utf8),
           let response = try? JSONDecoder().decode(AircraftResponse.self, from: jsonData) {
            return response.ac
        }
        
        return []
    }
    
    static func getSingleAircraft() -> Aircraft? {
        return getAircraft().first
    }
    
    static func getEmergencyAircraft() -> Aircraft? {
        return getAircraft().first(where: { $0.isEmergency })
    }
}
