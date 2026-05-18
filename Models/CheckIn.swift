//
//  CheckIn.swift
//  TravelPin
//
//  Created by longanh on 13/5/26.
//
import Foundation
struct CheckIn: Identifiable, Codable , Hashable  {
    var id: UUID = .init()
    var ownerUserID: UUID? = nil
    var name: String
    var note: String = ""
    var latitude: Double
    var longitude: Double
    var visitedAt: Date = Date()
    var city: String = ""
    var country: String = ""
    var formattedAddress: String = ""
    var placeType: PlaceType = .travel
    var customPlaceCategoryID: UUID? = nil
    var category: PlaceCategory = .other
    var transportationMode: TransportationMode = .car
    var photoPath: String? = nil
    var isVisited: Bool = true

    init(
        id: UUID = .init(),
        ownerUserID: UUID? = nil,
        name: String,
        note: String = "",
        latitude: Double,
        longitude: Double,
        visitedAt: Date = Date(),
        city: String = "",
        country: String = "",
        formattedAddress: String = "",
        placeType: PlaceType = .travel,
        customPlaceCategoryID: UUID? = nil,
        category: PlaceCategory = .other,
        transportationMode: TransportationMode = .car,
        photoPath: String? = nil,
        isVisited: Bool = true
    ) {
        self.id = id
        self.ownerUserID = ownerUserID
        self.name = name
        self.note = note
        self.latitude = latitude
        self.longitude = longitude
        self.visitedAt = visitedAt
        self.city = city
        self.country = country
        self.formattedAddress = formattedAddress
        self.placeType = placeType
        self.customPlaceCategoryID = customPlaceCategoryID
        self.category = category
        self.transportationMode = transportationMode
        self.photoPath = photoPath
        self.isVisited = isVisited
    }
    
    var locationDisplay: String {
        if city.isEmpty && country.isEmpty {
            return formattedAddress.isEmpty ? "Unknown location" : formattedAddress
        }
        if city.isEmpty {
            return country
        }
        if country.isEmpty {
            return city
        }
        return "\(city), \(country)"
    }

    var addressDisplay: String {
        formattedAddress.isEmpty ? locationDisplay : formattedAddress
    }
    
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: visitedAt)
    }
}

extension CheckIn {
    enum CodingKeys: String, CodingKey {
        case id
        case ownerUserID
        case name
        case note
        case latitude
        case longitude
        case visitedAt
        case city
        case country
        case formattedAddress
        case placeType
        case customPlaceCategoryID
        case category
        case transportationMode
        case photoPath
        case isVisited
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? .init()
        ownerUserID = try container.decodeIfPresent(UUID.self, forKey: .ownerUserID)
        name = try container.decode(String.self, forKey: .name)
        note = try container.decodeIfPresent(String.self, forKey: .note) ?? ""
        latitude = try container.decode(Double.self, forKey: .latitude)
        longitude = try container.decode(Double.self, forKey: .longitude)
        visitedAt = try container.decodeIfPresent(Date.self, forKey: .visitedAt) ?? Date()
        city = try container.decodeIfPresent(String.self, forKey: .city) ?? ""
        country = try container.decodeIfPresent(String.self, forKey: .country) ?? ""
        formattedAddress = try container.decodeIfPresent(String.self, forKey: .formattedAddress) ?? ""
        placeType = try container.decodeIfPresent(PlaceType.self, forKey: .placeType) ?? .travel
        customPlaceCategoryID = try container.decodeIfPresent(UUID.self, forKey: .customPlaceCategoryID)
        category = try container.decodeIfPresent(PlaceCategory.self, forKey: .category) ?? .other
        transportationMode = try container.decodeIfPresent(TransportationMode.self, forKey: .transportationMode) ?? .car
        photoPath = try container.decodeIfPresent(String.self, forKey: .photoPath)
        isVisited = try container.decodeIfPresent(Bool.self, forKey: .isVisited) ?? true
    }
}

enum PlaceType: String, Codable, CaseIterable {
    case travel = "Du lịch"
    case food = "Ăn uống"
    case checkIn = "Check-in"
    case coffee = "Cà phê"
    case other = "Khác"

    var icon: String {
        switch self {
        case .travel: return "suitcase.fill"
        case .food: return "fork.knife"
        case .checkIn: return "camera.fill"
        case .coffee: return "cup.and.saucer.fill"
        case .other: return "ellipsis.circle.fill"
        }
    }
}

enum TransportationMode: String, Codable, CaseIterable {
    case car = "Ô tô"
    case motorbike = "Xe máy"
    case bus = "Xe khách"
    case train = "Tàu hỏa"
    case plane = "Máy bay"
    case walking = "Đi bộ"
    case other = "Khác"

    var icon: String {
        switch self {
        case .car: return "car.fill"
        case .motorbike: return "scooter"
        case .bus: return "bus.fill"
        case .train: return "tram.fill"
        case .plane: return "airplane"
        case .walking: return "figure.walk"
        case .other: return "ellipsis.circle.fill"
        }
    }
}

enum PlaceCategory: String, Codable, CaseIterable {
    case extendedFamily = "Đại gia đình"
    case family = "Gia đình"
    case couple = "Vợ chồng"
    case solo = "Một mình"
    case other = "Khác"
    
    var icon: String {
        switch self {
        case .extendedFamily: return "person.3.fill"
        case .family: return "person.2.fill"
        case .couple: return "heart.fill"
        case .solo: return "person.fill"
        case .other: return "ellipsis.circle.fill"
        }
    }
    
    var color: String {
        switch self {
        case .extendedFamily: return "purple"
        case .family: return "green"
        case .couple: return "pink"
        case .solo: return "blue"
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
                category: .family
            ),
            CheckIn(
                name: "Bun Cha Huong Lien",
                note: "Famous bun cha restaurant",
                latitude: 20.9990, longitude: 105.8412,
                visitedAt: Date().addingTimeInterval(-86400 * 8),
                city: "Hanoi", country: "Vietnam",
                category: .couple
            ),
            CheckIn(
                name: "Hoi An Ancient Town",
                note: "UNESCO World Heritage Site",
                latitude: 15.8801, longitude: 108.3380,
                visitedAt: Date().addingTimeInterval(-86400 * 5),
                city: "Hoi An", country: "Vietnam",
                category: .extendedFamily
            ),
            CheckIn(
                name: "Son Doong Cave",
                note: "Largest cave in the world",
                latitude: 17.4500, longitude: 106.2833,
                visitedAt: Date().addingTimeInterval(-86400 * 3),
                city: "Quang Binh", country: "Vietnam",
                category: .solo
            ),
            CheckIn(
                name: "Ben Thanh Market",
                note: "Iconic market in Ho Chi Minh City",
                latitude: 10.7725, longitude: 106.6980,
                visitedAt: Date().addingTimeInterval(-86400 * 1),
                city: "Ho Chi Minh City", country: "Vietnam",
                category: .couple
            ),
        ]
    }
}
