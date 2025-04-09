import Foundation

func formatNumber(_ value: Int?) -> String {
    if let value {
        return NumberFormatter.localizedString(from: NSNumber(value: value), number: .decimal)
    }
    
    return "-"
}

func formatAltitude(_ feet: Int?) -> String {
    if let feet {
        let meters = Int(Double(feet) * 0.3048)
        return "\(formatNumber(feet)) ft (\(formatNumber(meters)) m)"
    }
    
    return "-"
}

func formatSpeed(_ knots: Double?) -> String {
    if let knots {
        let knotsValue = Int(knots)
        let kmhValue = Int(knots * 1.852)
        return "\(formatNumber(knotsValue)) kts (\(formatNumber(kmhValue)) km/h)"
    }
    
    return "-"
}
