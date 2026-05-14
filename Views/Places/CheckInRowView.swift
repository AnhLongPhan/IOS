//
//  CheckInRowView.swift
//  TravelPin
//
//  Created by longanh on 14/5/26.
//

import SwiftUI

struct CheckInRowView: View {
    let checkIn: CheckIn

    var body: some View {
        HStack(spacing: 12) {
            // Category icon
            ZStack {
                Circle()
                    .fill(categoryColor.opacity(0.15))
                    .frame(width: 44, height: 44)

                Image(systemName: checkIn.category.icon)
                    .font(.system(size: 18))
                    .foregroundStyle(categoryColor)
            }

            // Info
            VStack(alignment: .leading, spacing: 3) {
                HStack {
                    Text(checkIn.name)
                        .font(.headline)
                        .lineLimit(1)

                    Spacer()

                    Text(checkIn.formattedDate)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Text(checkIn.locationDisplay)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)

                if !checkIn.note.isEmpty {
                    Text(checkIn.note)
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                        .lineLimit(1)
                }
            }
        }
        .padding(.vertical, 4)
    }

    var categoryColor: Color {
        switch checkIn.category {
        case .nature:    return .green
        case .food:      return .orange
        case .culture:   return .blue
        case .adventure: return .red
        case .other:     return .gray
        }
    }
}

#Preview {
    List {
        CheckInRowView(checkIn: CheckIn.mockData[0])
        CheckInRowView(checkIn: CheckIn.mockData[1])
    }
}
