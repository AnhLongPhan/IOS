//
//  CategoryFilterView.swift
//  TravelPin
//
//  Created by longanh on 14/5/26.
//

import SwiftUI

struct CategoryFilterView: View {
    @Binding var selectedCategory: PlaceCategory?

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                // Nút "Tất cả"
                FilterChip(
                    label: "Tất cả",
                    icon: "mappin.fill",
                    isSelected: selectedCategory == nil
                ) {
                    selectedCategory = nil
                }

                // Nút từng category
                ForEach(PlaceCategory.allCases, id: \.self) { category in
                    FilterChip(
                        label: category.rawValue,
                        icon: category.icon,
                        isSelected: selectedCategory == category
                    ) {
                        if selectedCategory == category {
                            selectedCategory = nil // deselect
                        } else {
                            selectedCategory = category
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
    CategoryFilterView(selectedCategory: .constant(nil))
}
