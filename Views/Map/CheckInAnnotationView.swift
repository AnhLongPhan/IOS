//
//  CheckINAnnotationView.swift
//  TravelPin
//
//  Created by longanh on 13/5/26.
//

import SwiftUI

struct CheckInAnnotationView: View {
    let checkIn: CheckIn
    @State private var showTitle = false

    var body: some View {
        VStack(spacing: 0) {
            // Label hiện khi tap
            if showTitle {
                Text(checkIn.name)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .shadow(radius: 2)
                    .transition(.scale.combined(with: .opacity))
            }

            // Pin icon
            ZStack {
                Circle()
                    .fill(categoryColor)
                    .frame(width: 36, height: 36)
                    .shadow(radius: 3)

                Image(systemName: checkIn.category.icon)
                    .font(.system(size: 16))
                    .foregroundStyle(.white)
            }
            .onTapGesture {
                withAnimation(.spring(duration: 0.3)) {
                    showTitle.toggle()
                }
            }

            // Mũi tên nhọn phía dưới pin
            Triangle()
                .fill(categoryColor)
                .frame(width: 12, height: 8)
        }
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
