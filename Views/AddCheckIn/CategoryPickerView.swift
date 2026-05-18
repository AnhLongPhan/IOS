//
//  CategoryPickerView.swift
//  TravelPin
//
//  Created by longanh on 14/5/26.
//

import SwiftUI

struct PlaceTypePickerView: View {
    @Environment(UserProfileStore.self) private var userProfileStore
    @Binding var selected: PlaceType
    @Binding var selectedCustomCategoryID: UUID?

    private var visiblePlaceTypes: [PlaceType] {
        let enabled = userProfileStore.enabledPlaceTypes
        if enabled.contains(selected) {
            return enabled
        }
        return [selected] + enabled
    }

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(visiblePlaceTypes, id: \.self) { placeType in
                    Button {
                        selected = placeType
                        selectedCustomCategoryID = nil
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: placeType.icon)
                            Text(placeType.rawValue)
                                .font(.subheadline)
                                .fontWeight(.medium)
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(
                            selected == placeType
                            ? placeTypeColor(placeType)
                            : Color(.systemGray5)
                        )
                        .foregroundStyle(
                            selected == placeType ? .white : .primary
                        )
                        .clipShape(Capsule())
                    }
                }

                ForEach(userProfileStore.profile.customCategories) { category in
                    Button {
                        selected = .other
                        selectedCustomCategoryID = category.id
                    } label: {
                        HStack(spacing: 6) {
                            if let iconFilename = category.iconFilename,
                               let icon = ImageStorageService().loadIcon(filename: iconFilename) {
                                Image(uiImage: icon)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 18, height: 18)
                                    .clipShape(Circle())
                            } else {
                                Image(systemName: category.systemIconName)
                            }

                            Text(category.name)
                                .font(.subheadline)
                                .fontWeight(.medium)
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(
                            selectedCustomCategoryID == category.id
                            ? placeTypeColor(.other)
                            : Color(.systemGray5)
                        )
                        .foregroundStyle(
                            selectedCustomCategoryID == category.id ? .white : .primary
                        )
                        .clipShape(Capsule())
                    }
                }
            }
            .padding(.horizontal, 16)
        }
    }

    func placeTypeColor(_ placeType: PlaceType) -> Color {
        switch placeType {
        case .travel: return .blue
        case .food: return .red
        case .checkIn: return .purple
        case .coffee: return .brown
        case .other: return .gray
        }
    }
}

struct CategoryPickerView: View {
    @Binding var selected: PlaceCategory

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(PlaceCategory.allCases, id: \.self) { category in
                    Button {
                        selected = category
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: category.icon)
                            Text(category.rawValue)
                                .font(.subheadline)
                                .fontWeight(.medium)
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(
                            selected == category
                            ? categoryColor(category)
                            : Color(.systemGray5)
                        )
                        .foregroundStyle(
                            selected == category ? .white : .primary
                        )
                        .clipShape(Capsule())
                    }
                }
            }
            .padding(.horizontal, 16)
        }
    }

    func categoryColor(_ category: PlaceCategory) -> Color {
        switch category {
        case .extendedFamily: return .purple
        case .family:         return .green
        case .couple:         return .pink
        case .solo:           return .blue
        case .other:          return .gray
        }
    }
}

#Preview {
    CategoryPickerView(selected: .constant(.family))
        .environment(UserProfileStore())
}
