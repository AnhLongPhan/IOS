//
//  DetailView.swift
//  TravelPin
//
//  Created by longanh on 14/5/26.
//

import SwiftUI

struct DetailView: View {
    @Environment(CheckInViewModel.self) var viewModel
    @Environment(\.dismiss) var dismiss
    private let imageService = ImageStorageService()

    let checkIn: CheckIn

    @State private var showDeleteConfirm = false
    @State private var showEditSheet = false
    
    @State private var animateIcon = false

    // Lấy bản mới nhất từ viewModel (vì checkIn có thể đã edit)
    var currentCheckIn: CheckIn {
        viewModel.checkIns.first { $0.id == checkIn.id } ?? checkIn
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {

                // MARK: - Ảnh hoặc placeholder
                photoSection

                // MARK: - Nội dung
                VStack(alignment: .leading, spacing: 20) {

                    // Tên + category
                    VStack(alignment: .leading, spacing: 8) {
                        Text(currentCheckIn.name)
                            .font(.title)
                            .fontWeight(.bold)

                        HStack {
                            Image(systemName: currentCheckIn.category.icon)
                            Text(currentCheckIn.category.rawValue)
                        }
                        .font(.subheadline)
                        .foregroundStyle(categoryColor)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(categoryColor.opacity(0.12))
                        .clipShape(Capsule())
                    }

                    Divider()

                    // Thông tin
                    infoSection

                    Divider()

                    // Ghi chú
                    if !currentCheckIn.note.isEmpty {
                        noteSection
                        Divider()
                    }

                    // Mini map
                    mapSection

                    // Nút xoá
                    deleteButton
                }
                .padding(20)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {

                Button {
                    showEditSheet = true
                } label: {
                    Image(systemName: "pencil")
                }
                ShareLink(
                    item: "\(currentCheckIn.name)\n\(currentCheckIn.locationDisplay)",
                    subject: Text("TravelPin")
                ) {
                    Image(systemName: "square.and.arrow.up")
                }
            }
        }
        .sheet(isPresented: $showEditSheet) {
            
            EditCheckInView(checkIn: currentCheckIn)
                .environment(viewModel)
        }
        .confirmationDialog(
            "Xoá địa điểm này?",
            isPresented: $showDeleteConfirm,
            titleVisibility: .visible
        ) {
            Button("Xoá", role: .destructive) {
                viewModel.delete(checkIn)
                dismiss()
            }
            Button("Huỷ", role: .cancel) { }
        } message: {
            Text("Hành động này không thể hoàn tác.")
        }
        .onAppear {
            withAnimation(.spring(response: 0.4,
                                  dampingFraction: 0.5)) {
                animateIcon = true
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                animateIcon = false
            }
        }
    }

    // MARK: - Photo section
    var photoSection: some View {
        ZStack {
            if let path = currentCheckIn.photoPath,
               let image = loadImage(path: path) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: .infinity)
                    .frame(height: 260)
                    .clipped()
            } else {
                // Placeholder gradient
                LinearGradient(
                    colors: [categoryColor.opacity(0.7), categoryColor.opacity(0.3)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .frame(height: 260)

                Image(systemName: currentCheckIn.category.icon)
                    .font(.system(size: 64))
                    .foregroundStyle(.white.opacity(0.8))
            }
        }
    }

    // MARK: - Info section
    var infoSection: some View {
        VStack(spacing: 12) {
            InfoRow(
                icon: "calendar",
                label: "Ngày tham quan",
                value: currentCheckIn.formattedDate
            )

            InfoRow(
                icon: "mappin.circle",
                label: "Địa điểm",
                value: currentCheckIn.locationDisplay
            )

            InfoRow(
                icon: "location.circle",
                label: "Tọa độ",
                value: String(format: "%.4f, %.4f",
                    currentCheckIn.latitude,
                    currentCheckIn.longitude)
            )

            InfoRow(
                icon: currentCheckIn.transportationMode.icon,
                label: "Phương tiện di chuyển",
                value: currentCheckIn.transportationMode.rawValue
            )

            InfoRow(
                icon: currentCheckIn.isVisited
                    ? "checkmark.circle.fill"
                    : "clock.circle",
                label: "Trạng thái",
                value: currentCheckIn.isVisited
                    ? "Đã tham quan"
                    : "Muốn đến"
            )
        }
    }

    // MARK: - Note section
    var noteSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Ghi chú", systemImage: "note.text")
                .font(.headline)

            Text(currentCheckIn.note)
                .font(.body)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Map section
    var mapSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Vị trí trên bản đồ", systemImage: "map")
                .font(.headline)

            MiniMapView(
                latitude: currentCheckIn.latitude,
                longitude: currentCheckIn.longitude
            )
            .frame(height: 200)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    // MARK: - Delete button
    var deleteButton: some View {
        Button(role: .destructive) {
            showDeleteConfirm = true
        } label: {
            Label("Xoá địa điểm này", systemImage: "trash")
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.red.opacity(0.1))
                .foregroundStyle(.red)
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .padding(.top, 8)
    }

    // MARK: - Helpers
    var categoryColor: Color {
        switch currentCheckIn.category {
        case .extendedFamily: return .purple
        case .family:         return .green
        case .couple:         return .pink
        case .solo:           return .blue
        case .other:          return .gray
        }
    }

    func loadImage(path: String) -> UIImage? {
        imageService.load(filename: path)
    }
}

// MARK: - InfoRow component
struct InfoRow: View {
    let icon: String
    let label: String
    let value: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .frame(width: 20)
                .foregroundStyle(.blue)

            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(value)
                    .font(.subheadline)
            }

            Spacer()
        }
    }
}

#Preview {
    NavigationStack {
        DetailView(checkIn: CheckIn.mockData[0])
            .environment(CheckInViewModel())
    }
}
