import SwiftUI
import MapKit

struct AddCheckInView: View {
    @Environment(CheckInViewModel.self) var viewModel
    @Environment(LocationService.self) var locationService
    @Environment(\.dismiss) var dismiss

    private let imageService    = ImageStorageService()
    private let geocodingService = GeocodingService()

    var initialCoordinate: CLLocationCoordinate2D? = nil

    // Form fields
    @State private var name: String = ""
    @State private var note: String = ""
    @State private var visitedAt: Date? = Date()
    @State private var placeType: PlaceType = .travel
    @State private var customPlaceCategoryID: UUID? = nil
    @State private var category: PlaceCategory = .other
    @State private var transportationMode: TransportationMode? = .car
    @State private var latitudeText: String = ""
    @State private var longitudeText: String = ""
    @State private var city: String = ""
    @State private var country: String = ""
    @State private var formattedAddress: String = ""
    @State private var isVisited: Bool = true
    @State private var selectedImage: UIImage? = nil
    @State private var showValidationError = false
    @State private var showSearchSheet  = false
    @State private var showMapPicker    = false

    // Geocoding state
    @State private var isGeocoding = false
    @State private var geocodeTask: Task<Void, Never>? = nil

    var isValid: Bool {
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
                    ImageSectionView(
                        selectedImage: $selectedImage,
                        onCoordinateFound: applyPhotoCoordinate
                    )
                        .listRowInsets(EdgeInsets(
                            top: 8, leading: 8,
                            bottom: 8, trailing: 8
                        ))
                }

                // MARK: - Thông tin
                Section("Thông tin") {
                    TextField("Tên lưu (tuỳ chọn)", text: $name)
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

                // MARK: - Place type
                Section("Phân loại") {
                    PlaceTypePickerView(
                        selected: $placeType,
                        selectedCustomCategoryID: $customPlaceCategoryID
                    )
                        .listRowInsets(EdgeInsets(
                            top: 8, leading: 0,
                            bottom: 8, trailing: 0
                        ))
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

                // MARK: - Tọa độ + auto-fill
                Section {
                    // Nút chọn vị trí
                    HStack(spacing: 10) {
                        // Tìm kiếm địa điểm
                        Button {
                            showSearchSheet = true
                        } label: {
                            Label("Tìm kiếm", systemImage: "magnifyingglass")
                                .lineLimit(1)
                                .minimumScaleFactor(0.85)
                                .frame(minWidth: 105, maxWidth: 130)
                                .padding(.vertical, 10)
                                .background(Color(.systemGray5))
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                                .foregroundStyle(.primary)
                        }

                        // Chọn trên map
                        Button {
                            showMapPicker = true
                        } label: {
                            Label("Trên map", systemImage: "map")
                                .lineLimit(1)
                                .minimumScaleFactor(0.85)
                                .frame(minWidth: 105, maxWidth: 130)
                                .padding(.vertical, 10)
                                .background(Color(.systemGray5))
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                                .foregroundStyle(.primary)
                        }

                        // GPS hiện tại
                        Button {
                            useCurrentLocation()
                        } label: {
                            Image(systemName: "location.fill")
                                .padding(.vertical, 10)
                                .padding(.horizontal, 14)
                                .background(Color(.systemGray5))
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                                .foregroundStyle(.blue)
                        }
                    }
                    .listRowInsets(EdgeInsets(
                        top: 8, leading: 12,
                        bottom: 8, trailing: 12
                    ))
                    .buttonStyle(.plain)

                    // Hiện tọa độ đã chọn
                    if !latitudeText.isEmpty {
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
                    } else if !addressSummary.isEmpty {
                        Label(
                            addressSummary,
                            systemImage: "mappin.circle.fill"
                        )
                        .font(.caption)
                        .foregroundStyle(.green)
                    }
                }
                // MARK: - Ghi chú
                Section("Ghi chú") {
                    TextEditor(text: $note)
                        .frame(minHeight: 80)
                }

                // Validation error
                if showValidationError && !isValid {
                    Section {
                        Text("Vui lòng chọn tọa độ hợp lệ")
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
                        geocodeTask?.cancel()
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Lưu") { saveCheckIn() }
                        .fontWeight(.semibold)
                        .disabled(!isValid)
                }
            }
            .onAppear {
                if let coord = initialCoordinate {
                    latitudeText  = String(format: "%.6f", coord.latitude)
                    longitudeText = String(format: "%.6f", coord.longitude)
                    triggerGeocode()
                }
            }
            // Auto-geocode khi nhập tọa độ xong
            .onChange(of: latitudeText)  { _, _ in triggerGeocode() }
            .onChange(of: longitudeText) { _, _ in triggerGeocode() }
            .onChange(of: isVisited) { _, newValue in
                updateVisitDefaults(isVisited: newValue)
            }
            .sheet(isPresented: $showSearchSheet) {
                LocationSearchView { result in
                    latitudeText  = String(format: "%.6f", result.latitude)
                    longitudeText = String(format: "%.6f", result.longitude)
                    city             = result.city
                    country          = result.country
                    formattedAddress = result.formattedAddress.isEmpty ? result.address : result.formattedAddress
                    if name.isEmpty {
                        name = result.name
                    }
                }
            }
            .sheet(isPresented: $showMapPicker) {
                MapPickerView(initialCoordinate: currentCoordinate) { coord in
                    latitudeText  = String(format: "%.6f", coord.latitude)
                    longitudeText = String(format: "%.6f", coord.longitude)
                    triggerGeocode()
                }
            }
        }
    }

    private var addressSummary: String {
        if !formattedAddress.isEmpty {
            return formattedAddress
        }

        return [city, country]
            .filter { !$0.isEmpty }
            .joined(separator: ", ")
    }

    private var saveTitle: String {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedName.isEmpty {
            return trimmedName
        }

        if !addressSummary.isEmpty {
            return addressSummary
        }

        return placeType.rawValue
    }

    private var visitedAtBinding: Binding<Date> {
        Binding(
            get: { visitedAt ?? Date() },
            set: { visitedAt = $0 }
        )
    }

    private func applyPhotoCoordinate(_ coordinate: CLLocationCoordinate2D) {
        latitudeText = String(format: "%.6f", coordinate.latitude)
        longitudeText = String(format: "%.6f", coordinate.longitude)
        triggerGeocode()
    }

    // MARK: - Dùng vị trí GPS hiện tại
    private func useCurrentLocation() {
        guard let coord = locationService.userLocation else { return }
        latitudeText  = String(format: "%.6f", coord.latitude)
        longitudeText = String(format: "%.6f", coord.longitude)
        triggerGeocode()
    }

    // MARK: - Trigger geocode với debounce
    private func triggerGeocode() {
        // Huỷ task cũ nếu user đang gõ tiếp
        geocodeTask?.cancel()

        guard let lat = Double(latitudeText),
              let lon = Double(longitudeText) else { return }

        geocodeTask = Task {
            // Debounce 0.8s — chờ user gõ xong
            try? await Task.sleep(for: .seconds(0.8))
            guard !Task.isCancelled else { return }

            isGeocoding = true

            // Thử CLGeocoder trước
            var result = await locationService.reverseGeocode(
                latitude: lat,
                longitude: lon
            )

            // Nếu CLGeocoder thất bại → thử Nominatim
            if result.city.isEmpty && result.country.isEmpty {
                result = await geocodingService.reverseGeocode(
                    latitude: lat,
                    longitude: lon
                )
            }

            isGeocoding = false
            city = result.city
            country = result.country
            formattedAddress = result.formattedAddress
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
    private func saveCheckIn() {
        showValidationError = true
        guard isValid else { return }

        geocodeTask?.cancel()

        var photoFilename: String? = nil
        if let image = selectedImage {
            photoFilename = imageService.save(image)
        }

        let newCheckIn = CheckIn(
            name: saveTitle,
            note: note,
            latitude: Double(latitudeText) ?? 0,
            longitude: Double(longitudeText) ?? 0,
            visitedAt: isVisited ? (visitedAt ?? Date()) : Date(),
            city: city,
            country: country,
            formattedAddress: formattedAddress,
            placeType: placeType,
            customPlaceCategoryID: customPlaceCategoryID,
            category: category,
            transportationMode: isVisited ? (transportationMode ?? .other) : .other,
            photoPath: photoFilename,
            isVisited: isVisited
        )

        viewModel.add(newCheckIn)
        dismiss()
    }
}

#Preview {
    AddCheckInView()
        .environment(CheckInViewModel())
        .environment(LocationService())
        .environment(UserProfileStore())
}
