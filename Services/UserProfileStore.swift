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
    var id: UUID
    var displayName: String
    var enabledPlaceTypeRawValues: [String]
    var customCategories: [CustomPlaceCategory]
    var displayMode: DisplayMode
    var completedAt: Date?

    init(
        id: UUID = UUID(),
        displayName: String,
        enabledPlaceTypeRawValues: [String],
        customCategories: [CustomPlaceCategory],
        displayMode: DisplayMode,
        completedAt: Date?
    ) {
        self.id = id
        self.displayName = displayName
        self.enabledPlaceTypeRawValues = enabledPlaceTypeRawValues
        self.customCategories = customCategories
        self.displayMode = displayMode
        self.completedAt = completedAt
    }

    static let empty = UserProfile(
        id: UUID(),
        displayName: "",
        enabledPlaceTypeRawValues: PlaceType.allCases.map(\.rawValue),
        customCategories: [],
        displayMode: .automatic,
        completedAt: nil
    )

    enum CodingKeys: String, CodingKey {
        case id
        case displayName
        case enabledPlaceTypeRawValues
        case customCategories
        case displayMode
        case completedAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        displayName = try container.decodeIfPresent(String.self, forKey: .displayName) ?? ""
        enabledPlaceTypeRawValues = try container.decodeIfPresent([String].self, forKey: .enabledPlaceTypeRawValues) ?? PlaceType.allCases.map(\.rawValue)
        customCategories = try container.decodeIfPresent([CustomPlaceCategory].self, forKey: .customCategories) ?? []
        displayMode = try container.decodeIfPresent(DisplayMode.self, forKey: .displayMode) ?? .automatic
        completedAt = try container.decodeIfPresent(Date.self, forKey: .completedAt)
    }
}

struct UserProfileState: Codable {
    var profiles: [UserProfile]
    var activeUserID: UUID?
}

@Observable
final class UserProfileStore {
    private let storageKey = "travelPin.userProfile"

    var profiles: [UserProfile]
    var activeUserID: UUID?
    var isCreatingNewUser = false

    init() {
        if let data = UserDefaults.standard.data(forKey: storageKey),
           let decoded = try? JSONDecoder().decode(UserProfileState.self, from: data) {
            profiles = decoded.profiles
            activeUserID = decoded.activeUserID
        } else if let data = UserDefaults.standard.data(forKey: storageKey),
                  let legacyProfile = try? JSONDecoder().decode(UserProfile.self, from: data),
                  legacyProfile.completedAt != nil {
            profiles = [legacyProfile]
            activeUserID = legacyProfile.id
            save()
        } else {
            profiles = []
            activeUserID = nil
        }
    }

    var hasCompletedOnboarding: Bool {
        activeProfile != nil
    }

    var shouldShowOnboarding: Bool {
        profiles.isEmpty || isCreatingNewUser
    }

    var shouldShowUserSelection: Bool {
        !profiles.isEmpty && activeProfile == nil && !isCreatingNewUser
    }

    var activeProfile: UserProfile? {
        guard let activeUserID else { return nil }
        return profiles.first { $0.id == activeUserID }
    }

    var profile: UserProfile {
        get { activeProfile ?? .empty }
        set {
            guard let index = profiles.firstIndex(where: { $0.id == newValue.id }) else { return }
            profiles[index] = newValue
            save()
        }
    }

    var displayName: String {
        profile.displayName
    }

    var displayNameBindingValue: String {
        get { profile.displayName }
        set {
            updateActiveProfile { $0.displayName = newValue }
            save()
        }
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
            updateActiveProfile { $0.displayMode = newValue }
        }
    }

    func updateDisplayName(_ displayName: String) {
        updateActiveProfile { $0.displayName = displayName.trimmingCharacters(in: .whitespacesAndNewlines) }
    }

    func completeOnboarding(
        displayName: String,
        enabledPlaceTypes: [PlaceType],
        customCategories: [CustomPlaceCategory]
    ) {
        let newProfile = UserProfile(
            displayName: displayName.trimmingCharacters(in: .whitespacesAndNewlines),
            enabledPlaceTypeRawValues: enabledPlaceTypes.map(\.rawValue),
            customCategories: customCategories,
            displayMode: profile.displayMode,
            completedAt: Date()
        )
        profiles.append(newProfile)
        activeUserID = newProfile.id
        isCreatingNewUser = false
        save()
    }

    func updatePersonalization(
        enabledPlaceTypes: [PlaceType],
        customCategories: [CustomPlaceCategory]
    ) {
        updateActiveProfile {
            $0.enabledPlaceTypeRawValues = enabledPlaceTypes.map(\.rawValue)
            $0.customCategories = customCategories
        }
    }

    func customCategory(id: UUID?) -> CustomPlaceCategory? {
        guard let id else { return nil }
        return profile.customCategories.first { $0.id == id }
    }

    func categoryName(for checkIn: CheckIn) -> String {
        customCategory(id: checkIn.customPlaceCategoryID)?.name ?? checkIn.placeType.rawValue
    }

    func categoryIcon(for checkIn: CheckIn) -> String {
        customCategory(id: checkIn.customPlaceCategoryID)?.systemIconName ?? checkIn.placeType.icon
    }

    func startNewUserSetup() {
        isCreatingNewUser = true
    }

    func showUserSelection() {
        activeUserID = nil
        isCreatingNewUser = false
        save()
    }

    func selectUser(_ user: UserProfile) {
        activeUserID = user.id
        isCreatingNewUser = false
        save()
    }

    private func updateActiveProfile(_ update: (inout UserProfile) -> Void) {
        guard let activeUserID,
              let index = profiles.firstIndex(where: { $0.id == activeUserID }) else { return }
        update(&profiles[index])
        save()
    }

    private func save() {
        let state = UserProfileState(profiles: profiles, activeUserID: activeUserID)
        guard let data = try? JSONEncoder().encode(state) else { return }
        UserDefaults.standard.set(data, forKey: storageKey)
    }
}
