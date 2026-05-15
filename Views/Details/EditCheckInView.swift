//
//  EditCheckInView.swift
//  TravelPin
//
//  Created by longanh on 14/5/26.
//

import SwiftUI
import MapKit

struct EditCheckInView: View {
    @Environment(CheckInViewModel.self) var viewModel
    @Environment(LocationService.self) var locationService
    @Environment(\.dismiss) var dismiss

    private let imageService = ImageStorageService()
    private let geocodingService = GeocodingService()

    let original: CheckIn

    @State private var name: String
    @State private var note: String
    @State private var visitedAt: Date?
    @State private var category: PlaceCategory
    @State private var transportationMode: TransportationMode?
    @State private var latitudeText: String
    @State private var longitudeText: String
    @State private var city: String
    @State private var country: String
    @State private var isVisited: Bool
    @State private var selectedImage: UIImage?     // ảnh mới chọn
    @State private var showValidationError = false
    @State private var showMapPicker = false
    @State private var isGeocoding = false
    @State private var geocodeTask: Task<Void, Never>? = nil

    init(checkIn: CheckIn) {
        self.original      = checkIn
        _name              = State(initialValue: checkIn.name)
        _note              = State(initialValue: checkIn.note)
        _visitedAt         = State(initialValue: checkIn.isVisited ? checkIn.visitedAt : nil)
        _category          = State(initialValue: checkIn.category)
        _transportationMode = State(initialValue: checkIn.isVisited ? checkIn.transportationMode : nil)
        _latitudeText      = State(initialValue: String(checkIn.latitude))
        _longitudeText     = State(initialValue: String(checkIn.longitude))
        _city              = State(initialValue: checkIn.city)
        _country           = State(initialValue: checkIn.country)
        _isVisited         = State(initialValue: checkIn.isVisited)
        // Load ảnh cũ vào preview nếu có
        if let path = checkIn.photoPath {
            let service = ImageStorageService()
            _selectedImage = State(initialValue: service.load(filename: path))
        }
    }

    var isValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty &&
        Double(latitudeText) != nil &&
        Double(longitudeText) != nil
    }

    var currentCoordinate: CLLocationCoordinate2D? {
        guard let latitude = Double(latitudeText),
              let longitude = Double(longitudeText) else { return nil }

        return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    var body: some View {
        NavigationStack {
            Form {
                // MARK: - Ảnh
                Section("Ảnh") {
                    ImageSectionView(selectedImage: $selectedImage)
                        .listRowInsets(EdgeInsets(
                            top: 8, leading: 8,
                            bottom: 8, trailing: 8
                        ))
                }

                // MARK: - Thông tin
                Section("Thông tin") {
                    TextField("Tên địa điểm *", text: $name)
                        .autocorrectionDisabled()

                    if isVisited {
                        DatePicker(
                            "Ngày tham quan",
                            selection: visitedAtBinding,
                            displayedComponents: [.date]
                        )
                    } else {
                        LabeledContent("Ngày tham quan", value: "Trống")
                    }

                    Toggle(isVisited ? "Đã tham quan" : "Chưa đi", isOn: $isVisited)
                }

                // MARK: - Category
                Section("Tham gia cùng") {
                    CategoryPickerView(selected: $category)
                        .listRowInsets(EdgeInsets(
                            top: 8, leading: 0,
                            bottom: 8, trailing: 0
                        ))
                }

                Section("Phương tiện di chuyển") {
                    Picker("Phương tiện", selection: $transportationMode) {
                        Text("Chưa chọn")
                            .tag(Optional<TransportationMode>.none)

                        ForEach(TransportationMode.allCases, id: \.self) { mode in
                            Label(mode.rawValue, systemImage: mode.icon)
                                .tag(Optional(mode))
                        }
                    }
                    .disabled(!isVisited)
                }

                // MARK: - Vị trí
                Section {
                    Button {
                        showMapPicker = true
                    } label: {
                        Label("Chọn lại trên bản đồ", systemImage: "map")
                            .lineLimit(1)
                            .minimumScaleFactor(0.85)
                            .frame(minWidth: 180, maxWidth: 220)
                            .padding(.vertical, 10)
                            .background(Color(.systemGray5))
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                            .foregroundStyle(.primary)
                    }
                    .buttonStyle(.plain)
                    .listRowInsets(EdgeInsets(
                        top: 8, leading: 12,
                        bottom: 8, trailing: 12
                    ))

                    HStack {
                        Text("Vĩ độ")
                            .foregroundStyle(.secondary)
                        Spacer()
                        TextField("vd: 21.0285", text: $latitudeText)
                            .keyboardType(.numbersAndPunctuation)
                            .multilineTextAlignment(.trailing)
                    }
                    HStack {
                        Text("Kinh độ")
                            .foregroundStyle(.secondary)
                        Spacer()
                        TextField("vd: 105.8542", text: $longitudeText)
                            .keyboardType(.numbersAndPunctuation)
                            .multilineTextAlignment(.trailing)
                    }
                } header: {
                    Text("Vị trí")
                } footer: {
                    if isGeocoding {
                        HStack(spacing: 6) {
                            ProgressView().scaleEffect(0.8)
                            Text("Đang tìm địa chỉ...")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    } else if !city.isEmpty || !country.isEmpty {
                        Label(
                            "\(city)\(city.isEmpty ? "" : ", ")\(country)",
                            systemImage: "mappin.circle.fill"
                        )
                        .font(.caption)
                        .foregroundStyle(.green)
                    }
                }
                // MARK: - Ghi chú
                Section("Ghi chú") {
                    TextEditor(text: $note)
                        .frame(minHeight: 100)
                }
            }
            .navigationTitle("Chỉnh sửa")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Huỷ") {
                        geocodeTask?.cancel()
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Lưu") { saveChanges() }
                        .fontWeight(.semibold)
                        .disabled(!isValid)
                }
            }
            .onChange(of: latitudeText) { _, _ in triggerGeocode() }
            .onChange(of: longitudeText) { _, _ in triggerGeocode() }
            .onChange(of: isVisited) { _, newValue in
                updateVisitDefaults(isVisited: newValue)
            }
            .sheet(isPresented: $showMapPicker) {
                MapPickerView(initialCoordinate: currentCoordinate) { coord in
                    latitudeText = String(format: "%.6f", coord.latitude)
                    longitudeText = String(format: "%.6f", coord.longitude)
                    triggerGeocode()
                }
            }
        }
    }

    private var visitedAtBinding: Binding<Date> {
        Binding(
            get: { visitedAt ?? Date() },
            set: { visitedAt = $0 }
        )
    }

    private func triggerGeocode() {
        geocodeTask?.cancel()

        guard let latitude = Double(latitudeText),
              let longitude = Double(longitudeText) else { return }

        geocodeTask = Task {
            try? await Task.sleep(for: .seconds(0.8))
            guard !Task.isCancelled else { return }

            isGeocoding = true

            var result = await locationService.reverseGeocode(
                latitude: latitude,
                longitude: longitude
            )

            if result.city.isEmpty && result.country.isEmpty {
                result = await geocodingService.reverseGeocode(
                    latitude: latitude,
                    longitude: longitude
                )
            }

            guard !Task.isCancelled else { return }
            isGeocoding = false
            city = result.city
            country = result.country
        }
    }

    private func updateVisitDefaults(isVisited: Bool) {
        if isVisited {
            visitedAt = visitedAt ?? Date()
            transportationMode = transportationMode ?? .car
        } else {
            visitedAt = nil
            transportationMode = nil
        }
    }

    // MARK: - Save
    private func saveChanges() {
        showValidationError = true
        guard isValid else { return }

        geocodeTask?.cancel()

        // Xử lý ảnh
        var newPhotoPath: String? = original.photoPath

        if let newImage = selectedImage {
            // Kiểm tra có phải ảnh mới không
            // bằng cách so sánh với ảnh cũ
            let oldImage = original.photoPath.flatMap {
                imageService.load(filename: $0)
            }

            if newImage !== oldImage {
                // Xoá ảnh cũ nếu có
                if let oldPath = original.photoPath {
                    imageService.delete(filename: oldPath)
                }
                // Lưu ảnh mới
                newPhotoPath = imageService.save(newImage)
            }
        } else {
            // User đã xoá ảnh (selectedImage = nil)
            if let oldPath = original.photoPath {
                imageService.delete(filename: oldPath)
            }
            newPhotoPath = nil
        }

        var updated          = original
        updated.name         = name.trimmingCharacters(in: .whitespaces)
        updated.note         = note
        updated.visitedAt    = isVisited ? (visitedAt ?? Date()) : Date()
        updated.category     = category
        updated.transportationMode = isVisited ? (transportationMode ?? .other) : .other
        updated.latitude     = Double(latitudeText) ?? original.latitude
        updated.longitude    = Double(longitudeText) ?? original.longitude
        updated.city         = city
        updated.country      = country
        updated.isVisited    = isVisited
        updated.photoPath    = newPhotoPath

        viewModel.update(updated)
        dismiss()
    }
}
