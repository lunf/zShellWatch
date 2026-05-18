//
//  CLAuthorizationStatus+StatusText.swift
//  TermiWatchWidget
//

import CoreLocation

extension CLAuthorizationStatus {
    var statusText: String {
        switch self {
        case .notDetermined:
            return "Not Determined"
        case .restricted:
            return "Restricted"
        case .denied:
            return "Denied"
        case .authorizedAlways:
            return "Authorized"
        case .authorizedWhenInUse:
            return "Authorized"
        @unknown default:
            return "Unknown"
        }
    }
}
