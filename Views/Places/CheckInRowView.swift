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
    private let imageService = ImageStorageService()

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

            ZStack(alignment: .bottomTrailing) {
                RoundedRectangle(cornerRadius: 8)
                    .fill(rowColor.opacity(0.15))
                    .frame(width: 52, height: 52)

                if let path = checkIn.photoPath,
                   let image = imageService.load(filename: path) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 52, height: 52)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                } else {
                    Image(systemName: checkIn.isVisited ? checkIn.placeType.icon : "bookmark.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(rowColor)
                }

                if !checkIn.isVisited {
                    Image(systemName: "clock.fill")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 18, height: 18)
                        .background(.orange)
                        .clipShape(Circle())
                        .overlay(
                            Circle()
                                .stroke(.white, lineWidth: 2)
                        )
                        .offset(x: 5, y: 5)
                }
            }

            VStack(alignment: .leading, spacing: 5) {
                HStack {
                    Text(checkIn.name)
                        .font(.headline)
                        .lineLimit(1)
                    Spacer()
                    Text(checkIn.formattedDate)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Text(checkIn.addressDisplay)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)

                HStack(spacing: 6) {
                    Label(checkIn.placeType.rawValue, systemImage: checkIn.placeType.icon)
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .foregroundStyle(rowColor)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 3)
                        .background(rowColor.opacity(0.12))
                        .clipShape(Capsule())

                    Label(checkIn.isVisited ? "Đã đi" : "Muốn đi", systemImage: checkIn.isVisited ? "checkmark.circle.fill" : "bookmark.fill")
                        .font(.caption2)
                        .foregroundStyle(.secondary)

                    if !checkIn.note.isEmpty {
                        Text(checkIn.note)
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                            .lineLimit(1)
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }

    var rowColor: Color {
        checkIn.isVisited ? placeTypeColor : .orange
    }

    var placeTypeColor: Color {
        switch checkIn.placeType {
        case .travel: return .blue
        case .food: return .red
        case .checkIn: return .purple
        case .coffee: return .brown
        case .other: return .gray
        }
    }
}

#Preview {
    List {
        CheckInRowView(checkIn: CheckIn.mockData[0])
        CheckInRowView(checkIn: CheckIn.mockData[1])
    }
}
