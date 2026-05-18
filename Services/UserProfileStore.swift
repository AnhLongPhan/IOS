import Foundation
import Observation
import SwiftUI

struct CustomPlaceCategory: Identifiable, Codable, Hashable {
    var id: UUID
    var name: String
    var iconFilename: String?
    var systemIconName: String

    init(
        id: UUID = UUID(),
        name: String,
        iconFilename: String? = nil,
        systemIconName: String = "mappin.circle.fill"
    ) {
        self.id = id
        self.name = name
        self.iconFilename = iconFilename
        self.systemIconName = systemIconName
    }

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case iconFilename
        case systemIconName
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        name = try container.decode(String.self, forKey: .name)
        iconFilename = try container.decodeIfPresent(String.self, forKey: .iconFilename)
        systemIconName = try container.decodeIfPresent(String.self, forKey: .systemIconName) ?? "mappin.circle.fill"
    }
}

enum DisplayMode: String, Codable, CaseIterable, Identifiable {
    case automatic = "Auto"
    case light = "Light"
    case dark = "Dark"

    var id: String { rawValue }

    var colorScheme: ColorScheme? {
        switch self {
        case .automatic: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
}

struct UserProfile: Codable, Hashable {
    var displayName: String
    var enabledPlaceTypeRawValues: [String]
    var customCategories: [CustomPlaceCategory]
    var displayMode: DisplayMode
    var completedAt: Date?

    init(
        displayName: String,
        enabledPlaceTypeRawValues: [String],
        customCategories: [CustomPlaceCategory],
        displayMode: DisplayMode,
        completedAt: Date?
    ) {
        self.displayName = displayName
        self.enabledPlaceTypeRawValues = enabledPlaceTypeRawValues
        self.customCategories = customCategories
        self.displayMode = displayMode
        self.completedAt = completedAt
    }

    static let empty = UserProfile(
        displayName: "",
        enabledPlaceTypeRawValues: PlaceType.allCases.map(\.rawValue),
        customCategories: [],
        displayMode: .automatic,
        completedAt: nil
    )

    enum CodingKeys: String, CodingKey {
        case displayName
        case enabledPlaceTypeRawValues
        case customCategories
        case displayMode
        case completedAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        displayName = try container.decodeIfPresent(String.self, forKey: .displayName) ?? ""
        enabledPlaceTypeRawValues = try container.decodeIfPresent([String].self, forKey: .enabledPlaceTypeRawValues) ?? PlaceType.allCases.map(\.rawValue)
        customCategories = try container.decodeIfPresent([CustomPlaceCategory].self, forKey: .customCategories) ?? []
        displayMode = try container.decodeIfPresent(DisplayMode.self, forKey: .displayMode) ?? .automatic
        completedAt = try container.decodeIfPresent(Date.self, forKey: .completedAt)
    }
}

@Observable
final class UserProfileStore {
    private let storageKey = "travelPin.userProfile"

    var profile: UserProfile

    init() {
        if let data = UserDefaults.standard.data(forKey: storageKey),
           let decoded = try? JSONDecoder().decode(UserProfile.self, from: data) {
            profile = decoded
        } else {
            profile = .empty
        }
    }

    var hasCompletedOnboarding: Bool {
        profile.completedAt != nil && !profile.displayName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var displayName: String {
        profile.displayName
    }

    var displayInitial: String {
        let trimmedName = profile.displayName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let first = trimmedName.first else { return "U" }
        return String(first).uppercased()
    }

    var enabledPlaceTypes: [PlaceType] {
        let decoded = profile.enabledPlaceTypeRawValues.compactMap(PlaceType.init(rawValue:))
        return decoded.isEmpty ? PlaceType.allCases : decoded
    }

    var displayMode: DisplayMode {
        get { profile.displayMode }
        set {
            profile.displayMode = newValue
            save()
        }
    }

    func completeOnboarding(
        displayName: String,
        enabledPlaceTypes: [PlaceType],
        customCategories: [CustomPlaceCategory]
    ) {
        profile = UserProfile(
            displayName: displayName.trimmingCharacters(in: .whitespacesAndNewlines),
            enabledPlaceTypeRawValues: enabledPlaceTypes.map(\.rawValue),
            customCategories: customCategories,
            displayMode: profile.displayMode,
            completedAt: Date()
        )
        save()
    }

    func updatePersonalization(
        enabledPlaceTypes: [PlaceType],
        customCategories: [CustomPlaceCategory]
    ) {
        profile.enabledPlaceTypeRawValues = enabledPlaceTypes.map(\.rawValue)
        profile.customCategories = customCategories
        save()
    }

    func startNewUserSetup() {
        profile = .empty
        save()
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(profile) else { return }
        UserDefaults.standard.set(data, forKey: storageKey)
    }
}
