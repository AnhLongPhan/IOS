//
//  CategoryPickerView.swift
//  TravelPin
//
//  Created by longanh on 14/5/26.
//

import SwiftUI

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
}
