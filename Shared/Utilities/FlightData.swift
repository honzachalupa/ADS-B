import Foundation

func formatNumber(_ value: Int?) -> String {
    if let value {
        return NumberFormatter.localizedString(from: NSNumber(value: value), number: .decimal)
    }
    
    return "-"
}

func formatAltitude(_ feet: Int?) -> String {
    let isMetricUnits = UserDefaults.standard.bool(forKey: SETTINGS_IS_METRIC_UNITS_KEY)
    
    if let feet {
        if isMetricUnits {
            let meters = Int(Double(feet) * 0.3048)
            
            return formatNumber(meters) + " m"
        } else {
            return formatNumber(feet) + " ft"
        }
    }
    
    return "-"
}

func formatSpeed(_ knots: Double?) -> String {
    let isMetricUnits = UserDefaults.standard.bool(forKey: SETTINGS_IS_METRIC_UNITS_KEY)
    
    if let knots {
        if isMetricUnits {
            let kmhValue = Int(knots * 1.852)
            
            return formatNumber(kmhValue) + " km/h"
        } else {
            let knotsValue = Int(knots)
            
            return formatNumber(knotsValue) + " kts"
        }
    }
    
    return "-"
}
