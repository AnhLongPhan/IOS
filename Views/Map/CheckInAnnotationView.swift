//
//  CheckINAnnotationView.swift
//  TravelPin
//
//  Created by longanh on 13/5/26.
//

import SwiftUI

struct CheckInAnnotationView: View {
    let checkIn: CheckIn
    var isTitleVisible: Bool = false
    var onTap: () -> Void = { }
    var onDoubleTap: () -> Void = { }

    private let imageService = ImageStorageService()

    var thumbnail: UIImage? {
        guard let path = checkIn.photoPath else { return nil }
        return imageService.load(filename: path)
    }

    var displayTitle: String {
        let trimmedName = checkIn.name.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmedName.isEmpty ? checkIn.locationDisplay : trimmedName
    }

    var body: some View {
        VStack(spacing: 0) {
            // Label hiện khi tap
            if isTitleVisible {
                Text(displayTitle)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .frame(width: 180)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .shadow(radius: 2)
                    .transition(.scale.combined(with: .opacity))
            }

            // Pin
            ZStack {
                // Viền ngoài đổi màu theo phân loại
                Circle()
                    .fill(.white)
                    .overlay(
                        Circle()
                            .stroke(categoryColor, lineWidth: 3)
                    )
                    .frame(width: 46, height: 46)
                    .shadow(radius: 4)

                if let image = thumbnail {
                    // Có ảnh → hiện thumbnail
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 40, height: 40)
                        .clipShape(Circle())
                } else {
                    // Không có ảnh → hiện icon category
                    Circle()
                        .fill(categoryColor)
                        .frame(width: 40, height: 40)

                    Image(systemName: checkIn.category.icon)
                        .font(.system(size: 16))
                        .foregroundStyle(.white)
                }
            }
            .highPriorityGesture(
                TapGesture(count: 2)
                    .onEnded {
                        onDoubleTap()
                    }
            )
            .onTapGesture {
                onTap()
            }

            // Mũi tên nhọn phía dưới
            Triangle()
                .fill(thumbnail != nil ? .white : categoryColor)
                .frame(width: 12, height: 8)
                .shadow(radius: 1)
        }
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
    VStack(spacing: 20) {
        // Pin có ảnh (dùng mock — sẽ hiện icon vì không có file thật)
        CheckInAnnotationView(checkIn: CheckIn.mockData[0])
        // Pin không có ảnh
        CheckInAnnotationView(checkIn: CheckIn.mockData[1])
    }
    .padding()
    .background(Color.gray.opacity(0.2))
}

// Hình tam giác nhọn làm đuôi pin
struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.closeSubpath()
        return path
    }
}
