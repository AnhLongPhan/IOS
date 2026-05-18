//
//  CategoryFilterView.swift
//  TravelPin
//
//  Created by longanh on 14/5/26.
//

import SwiftUI

struct CategoryFilterView: View {
    @Environment(UserProfileStore.self) private var userProfileStore
    @Binding var selectedPlaceType: PlaceType?

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                FilterChip(
                    label: "Tất cả",
                    icon: "mappin.fill",
                    isSelected: selectedPlaceType == nil
                ) {
                    selectedPlaceType = nil
                }

                ForEach(userProfileStore.enabledPlaceTypes, id: \.self) { placeType in
                    FilterChip(
                        label: placeType.rawValue,
                        icon: placeType.icon,
                        isSelected: selectedPlaceType == placeType
                    ) {
                        if selectedPlaceType == placeType {
                            selectedPlaceType = nil
                        } else {
                            selectedPlaceType = placeType
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
    }
}

// MARK: - FilterChip component
struct FilterChip: View {
    let label: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.caption)
                Text(label)
                    .font(.subheadline)
                    .fontWeight(isSelected ? .semibold : .regular)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(isSelected ? Color.blue : Color(.systemGray5))
            .foregroundStyle(isSelected ? .white : .primary)
            .clipShape(Capsule())
        }
    }
}

#Preview {
    CategoryFilterView(selectedPlaceType: .constant(nil))
        .environment(UserProfileStore())
}
