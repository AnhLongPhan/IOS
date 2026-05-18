import Foundation
import CoreLocation
import Observation

private extension Array where Element == String {
    func removingDuplicates() -> [String] {
        var seen = Set<String>()
        return filter { seen.insert($0).inserted }
    }
}

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
    // Tọa độ → tên địa danh (city, country, formattedAddress)
    func reverseGeocode(
        latitude: Double,
        longitude: Double
    ) async -> (city: String, country: String, formattedAddress: String) {
        let location = CLLocation(
            latitude: latitude,
            longitude: longitude
        )

        do {
            let placemarks = try await geocoder.reverseGeocodeLocation(location)
            if let placemark = placemarks.first {
                let city = placemark.locality
                    ?? placemark.subAdministrativeArea
                    ?? placemark.administrativeArea
                    ?? ""
                let country = placemark.country ?? ""
                let formattedAddress = [
                    placemark.name,
                    placemark.thoroughfare,
                    placemark.subLocality,
                    placemark.locality,
                    placemark.administrativeArea,
                    placemark.postalCode,
                    placemark.country
                ]
                .compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
                .removingDuplicates()
                .joined(separator: ", ")
                return (city, country, formattedAddress)
            }
        } catch {
            print("Geocoding error: \(error)")
        }

        return ("", "", "")
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
