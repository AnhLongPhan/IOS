//
//  AddCheckInView.swift
//  TravelPin
//
//  Created by longanh on 14/5/26.
//

import SwiftUI
import MapKit

struct AddCheckInView: View {
    @Environment(CheckInViewModel.self) var viewModel
    @Environment(\.dismiss) var dismiss
    @State private var isVisited: Bool = true;

    // Tọa độ được truyền vào từ bản đồ (nếu có)
    var initialCoordinate: CLLocationCoordinate2D? = nil

    // Form fields
    @State private var name: String = ""
    @State private var note: String = ""
    @State private var visitedAt: Date = Date()
    @State private var category: PlaceCategory = .other
    @State private var latitudeText: String = ""
    @State private var longitudeText: String = ""
    @State private var showValidationError = false

    // Validate
    var isValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty &&
        Double(latitudeText) != nil &&
        Double(longitudeText) != nil
    }

    var body: some View {
        NavigationStack {
            Form {
                // MARK: - Thông tin cơ bản
                Section("Thông tin") {
                    TextField("Tên địa điểm *", text: $name)
                        .autocorrectionDisabled()

                    DatePicker(
                        "Ngày tham quan",
                        selection: $visitedAt,
                        displayedComponents: [.date]
                    )
                    
                    Toggle(isVisited ? "Đã tham quan" : "Sẽ đi", isOn : $isVisited)
                }

                // MARK: - Category
                Section("Loại địa điểm") {
                    CategoryPickerView(selected: $category)
                        .listRowInsets(EdgeInsets(
                            top: 8, leading: 0,
                            bottom: 8, trailing: 0
                        ))
                }

                // MARK: - Tọa độ
                Section("Tọa độ") {
                    HStack {
                        Text("Vĩ độ")
                            .foregroundStyle(.secondary)
                        Spacer()
                        TextField("vd: 21.0285", text: $latitudeText)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                    HStack {
                        Text("Kinh độ")
                            .foregroundStyle(.secondary)
                        Spacer()
                        TextField("vd: 105.8542", text: $longitudeText)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }

                    if showValidationError &&
                       (Double(latitudeText) == nil || Double(longitudeText) == nil) {
                        Text("Tọa độ không hợp lệ")
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                }

                // MARK: - Ghi chú
                Section("Ghi chú") {
                    TextEditor(text: $note)
                        .frame(minHeight: 100)
                    Text("\(note.count) / 200")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                // MARK: - Validation error
                if showValidationError && name.trimmingCharacters(in: .whitespaces).isEmpty {
                    Section {
                        Text("Vui lòng nhập tên địa điểm")
                            .foregroundStyle(.red)
                            .font(.caption)
                    }
                }
            }
            .navigationTitle("Thêm địa điểm")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Huỷ") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Lưu") {
                        saveCheckIn()
                    }
                    .fontWeight(.semibold)
                    .disabled(!isValid)
                }
            }
            .onAppear {
                // Điền tọa độ nếu được truyền vào từ bản đồ
                if let coord = initialCoordinate {
                    latitudeText = String(format: "%.6f", coord.latitude)
                    longitudeText = String(format: "%.6f", coord.longitude)
                }
            }
        }
    }

    // MARK: - Save
    private func saveCheckIn() {
        showValidationError = true
        guard isValid else { return }

        let newCheckIn = CheckIn(
            name: name.trimmingCharacters(in: .whitespaces),
            note: note,
            latitude: Double(latitudeText) ?? 0,
            longitude: Double(longitudeText) ?? 0,
            visitedAt: visitedAt,
            category: category,
            isVisited: isVisited
        )

        viewModel.add(newCheckIn)
        dismiss()
    }
}

#Preview {
    AddCheckInView()
        .environment(CheckInViewModel())
}
