import Foundation
import CoreLocation
import Observation

@Observable
class LocationService: NSObject, CLLocationManagerDelegate {
    var userLocation: CLLocationCoordinate2D? = nil
    var authorizationStatus: CLAuthorizationStatus = .notDetermined
    var errorMessage: String? = nil

    private let manager = CLLocationManager()

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
    }

    func requestPermission() {
        manager.requestWhenInUseAuthorization()
    }

    func startUpdating() {
        manager.startUpdatingLocation()
    }

    func stopUpdating() {
        manager.stopUpdatingLocation()
    }

    // MARK: - CLLocationManagerDelegate
    func locationManager(_ manager: CLLocationManager,
                         didUpdateLocations locations: [CLLocation]) {
        userLocation = locations.last?.coordinate
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus
        if manager.authorizationStatus == .authorizedWhenInUse {
            startUpdating()
        }
    }

    func locationManager(_ manager: CLLocationManager,
                         didFailWithError error: Error) {
        errorMessage = error.localizedDescription
    }
}
