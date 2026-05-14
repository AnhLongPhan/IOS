//
//  CheckIn.swift
//  TravelPin
//
//  Created by longanh on 13/5/26.
//
import Foundation
struct CheckIn: Identifiable, Codable , Hashable  {
    var id: UUID = .init()
    var name: String
    var note: String = ""
    var latitude: Double
    var longitude: Double
    var visitedAt: Date = Date()
    var city: String = ""
    var country: String = ""
    var category: PlaceCategory = .other
    var photoPath: String? = nil
    var isVisited: Bool = true
    
    var locationDisplay: String {
        if city.isEmpty && country.isEmpty {
            return "Unknow location"
        }
        if city.isEmpty {
            return country
        }
        if country.isEmpty {
            return city
        }
        return "\(city), \(country)"
    }
    
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: visitedAt)
    }
}

enum PlaceCategory: String, Codable, CaseIterable {
    case nature = "Nature"
    case food = "Food"
    case culture = "Culture"
    case adventure = "Adventure"
    case other = "Other"
    var icon: String {
        switch self {
        case .nature: return "leaf.fill"
        case .food: return "fork.knife"
        case .culture: return "building.column.fill"
        case .adventure: return "figure.hiking"
        case .other: return "mapin.fill"
        }
    }
    
    var color: String {
        switch self {
        case .nature: return "green"
        case .food: return "orange"
        case .culture: return "blue"
        case .adventure: return "red"
        case .other: return "gray"
        }
    }
}

// MARK: - Mock Data
extension CheckIn {
    static var mockData: [CheckIn] {
        [
            CheckIn(
                name: "Hoan Kiem Lake",
                note: "Beautiful lake in the heart of Hanoi",
                latitude: 21.0285, longitude: 105.8542,
                visitedAt: Date().addingTimeInterval(-86400 * 10),
                city: "Hanoi", country: "Vietnam",
                category: .nature
            ),
            CheckIn(
                name: "Bun Cha Huong Lien",
                note: "Famous bun cha restaurant",
                latitude: 20.9990, longitude: 105.8412,
                visitedAt: Date().addingTimeInterval(-86400 * 8),
                city: "Hanoi", country: "Vietnam",
                category: .food
            ),
            CheckIn(
                name: "Hoi An Ancient Town",
                note: "UNESCO World Heritage Site",
                latitude: 15.8801, longitude: 108.3380,
                visitedAt: Date().addingTimeInterval(-86400 * 5),
                city: "Hoi An", country: "Vietnam",
                category: .culture
            ),
            CheckIn(
                name: "Son Doong Cave",
                note: "Largest cave in the world",
                latitude: 17.4500, longitude: 106.2833,
                visitedAt: Date().addingTimeInterval(-86400 * 3),
                city: "Quang Binh", country: "Vietnam",
                category: .adventure
            ),
            CheckIn(
                name: "Ben Thanh Market",
                note: "Iconic market in Ho Chi Minh City",
                latitude: 10.7725, longitude: 106.6980,
                visitedAt: Date().addingTimeInterval(-86400 * 1),
                city: "Ho Chi Minh City", country: "Vietnam",
                category: .food
            ),
        ]
    }
}
