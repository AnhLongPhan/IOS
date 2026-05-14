//
//  GeocodingService.swift
//  TravelPin
//
//  Created by longanh on 14/5/26.
//

import Foundation

// Model decode từ Nominatim API
struct NominatimResponse: Codable {
    let address: NominatimAddress?

    struct NominatimAddress: Codable {
        let city: String?
        let town: String?
        let village: String?
        let county: String?
        let state: String?
        let country: String?

        // Lấy tên thành phố từ nhiều field khác nhau
        var resolvedCity: String {
            city ?? town ?? village ?? county ?? state ?? ""
        }
    }
}

class GeocodingService {

    // Nominatim reverse geocode
    // Chỉ dùng khi CLGeocoder thất bại
    func reverseGeocode(
        latitude: Double,
        longitude: Double
    ) async -> (city: String, country: String) {
        let urlString = "https://nominatim.openstreetmap.org/reverse"
            + "?lat=\(latitude)"
            + "&lon=\(longitude)"
            + "&format=json"

        guard let url = URL(string: urlString) else {
            return ("", "")
        }

        // Nominatim yêu cầu User-Agent header
        var request = URLRequest(url: url)
        request.setValue(
            "TravelPin/1.0",
            forHTTPHeaderField: "User-Agent"
        )

        do {
            let (data, response) = try await URLSession.shared.data(
                for: request
            )

            // Kiểm tra HTTP status
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                return ("", "")
            }

            let result = try JSONDecoder().decode(
                NominatimResponse.self,
                from: data
            )

            let city    = result.address?.resolvedCity ?? ""
            let country = result.address?.country ?? ""
            return (city, country)

        } catch {
            print("Nominatim error: \(error)")
            return ("", "")
        }
    }
}
