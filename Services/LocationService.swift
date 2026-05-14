import Foundation
import CoreLocation
import Observation

@Observable
class LocationService: NSObject, CLLocationManagerDelegate {
    var userLocation: CLLocationCoordinate2D? = nil
    var authorizationStatus: CLAuthorizationStatus = .notDetermined
    var errorMessage: String? = nil

    private let manager = CLLocationManager()
    private let geocoder = CLGeocoder()

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
    }

    // MARK: - Location
    func requestPermission() {
        manager.requestWhenInUseAuthorization()
    }

    func startUpdating() {
        manager.startUpdatingLocation()
    }

    func stopUpdating() {
        manager.stopUpdatingLocation()
    }

    // MARK: - Reverse Geocode
    // Tọa độ → tên địa danh (city, country)
    func reverseGeocode(
        latitude: Double,
        longitude: Double
    ) async -> (city: String, country: String) {
        let location = CLLocation(
            latitude: latitude,
            longitude: longitude
        )

        do {
            let placemarks = try await geocoder.reverseGeocodeLocation(location)
            if let placemark = placemarks.first {
                let city = placemark.locality
                    ?? placemark.administrativeArea
                    ?? ""
                let country = placemark.country ?? ""
                return (city, country)
            }
        } catch {
            print("Geocoding error: \(error)")
        }

        return ("", "")
    }

    // MARK: - CLLocationManagerDelegate
    func locationManager(
        _ manager: CLLocationManager,
        didUpdateLocations locations: [CLLocation]
    ) {
        userLocation = locations.last?.coordinate
    }

    func locationManagerDidChangeAuthorization(
        _ manager: CLLocationManager
    ) {
        authorizationStatus = manager.authorizationStatus
        if manager.authorizationStatus == .authorizedWhenInUse {
            startUpdating()
        }
    }

    func locationManager(
        _ manager: CLLocationManager,
        didFailWithError error: Error
    ) {
        errorMessage = error.localizedDescription
    }
}
