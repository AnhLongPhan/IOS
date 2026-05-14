//
//  CheckInRowView.swift
//  TravelPin
//
//  Created by longanh on 14/5/26.
//

import SwiftUI

struct CheckInRowView: View {
    let checkIn: CheckIn
    var index: Int? = nil
    private let imageService = ImageStorageService() // thêm dòng này

    var body: some View {
        HStack(spacing: 12) {
            if let index {
                Text("\(index)")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)
                    .frame(width: 24, height: 24)
                    .background(Color(.systemGray5))
                    .clipShape(Circle())
            }

            // Thay ZStack cũ bằng đoạn này
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(categoryColor.opacity(0.15))
                    .frame(width: 52, height: 52)

                if let path = checkIn.photoPath,
                   let image = imageService.load(filename: path) {
                    // Có ảnh → hiện thumbnail
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 52, height: 52)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                } else {
                    // Không có ảnh → hiện icon category
                    Image(systemName: checkIn.category.icon)
                        .font(.system(size: 20))
                        .foregroundStyle(categoryColor)
                }
            }

            // Phần info giữ nguyên như cũ
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
        case .extendedFamily: return .purple
        case .family:         return .green
        case .couple:         return .pink
        case .solo:           return .blue
        case .other:          return .gray
        }
    }
}

#Preview {
    List {
        CheckInRowView(checkIn: CheckIn.mockData[0])
        CheckInRowView(checkIn: CheckIn.mockData[1])
    }
}
