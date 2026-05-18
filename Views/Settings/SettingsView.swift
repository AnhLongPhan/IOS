import SwiftUI
import UniformTypeIdentifiers

struct SettingsView: View {
    @Environment(CheckInViewModel.self) var viewModel
    @Environment(UserProfileStore.self) private var userProfileStore

    // @AppStorage — lưu UserDefaults tự động
    @AppStorage("userName")       var userName: String = ""
    @AppStorage("defaultMapVN")   var defaultMapVN: Bool = true
    @AppStorage("showVisitedOnly") var showVisitedOnly: Bool = false

    @State private var showClearConfirm = false
    @State private var showImportPicker = false
    @State private var shareItem: ShareItem? = nil
    @State private var alertMessage: AlertMessage? = nil
    @State private var isProcessingBackup = false

    var body: some View {
        NavigationStack {
            Form {
                // MARK: - Cá nhân
                Section("Cá nhân") {
                    HStack {
                        Image(systemName: "person.circle.fill")
                            .font(.title2)
                            .foregroundStyle(.blue)

                        TextField("Tên của bạn", text: $userName)
                            .autocorrectionDisabled()
                    }
                }

                // MARK: - Bản đồ
                Section("Bản đồ") {
                    Toggle(isOn: $defaultMapVN) {
                        Label(
                            "Mở app về Việt Nam",
                            systemImage: "map.fill"
                        )
                    }
                }

                // MARK: - Cá nhân hoá
                Section("Cá nhân hoá") {
                    NavigationLink {
                        PlaceCategorySettingsView()
                    } label: {
                        Label("Phân loại", systemImage: "square.grid.2x2.fill")
                    }

                    Picker("Mode hiển thị", selection: displayModeBinding) {
                        Text("Dark").tag(DisplayMode.dark)
                        Text("Auto").tag(DisplayMode.automatic)
                        Text("Light").tag(DisplayMode.light)
                    }
                    .pickerStyle(.segmented)
                }

                // MARK: - Dữ liệu
                Section {
                    Button {
                        exportBackup()
                    } label: {
                        Label("Xuất backup ZIP", systemImage: "square.and.arrow.up")
                    }
                    .disabled(isProcessingBackup)

                    Button {
                        showImportPicker = true
                    } label: {
                        Label("Nhập backup ZIP", systemImage: "tray.and.arrow.down")
                    }
                    .disabled(isProcessingBackup)

                    Button(role: .destructive) {
                        showClearConfirm = true
                    } label: {
                        Label("Xoá tất cả dữ liệu", systemImage: "trash")
                            .foregroundStyle(.red)
                    }
                    .disabled(isProcessingBackup)
                } header: {
                    Text("Dữ liệu")
                } footer: {
                    Text("Import sẽ gộp dữ liệu theo ID. Nếu trùng địa điểm, bản trong file backup sẽ thay thế bản hiện tại.")
                }

                // MARK: - Về app
                Section("Về app") {
                    LabeledContent("Phiên bản", value: "1.0.0")
                    LabeledContent("Build", value: "MVP")
                    Link(
                        destination: URL(
                            string: "https://nominatim.openstreetmap.org"
                        )!
                    ) {
                        Label(
                            "Geocoding: OpenStreetMap",
                            systemImage: "globe"
                        )
                    }
                }
            }
            .navigationTitle("Settings")
            .confirmationDialog(
                "Xoá tất cả dữ liệu?",
                isPresented: $showClearConfirm,
                titleVisibility: .visible
            ) {
                Button("Xoá tất cả", role: .destructive) {
                    clearAllData()
                }
                Button("Huỷ", role: .cancel) { }
            } message: {
                Text("Tất cả địa điểm và ảnh sẽ bị xoá vĩnh viễn.")
            }
            .sheet(item: $shareItem) { item in
                ShareSheet(items: [item.url])
            }
            .fileImporter(
                isPresented: $showImportPicker,
                allowedContentTypes: [.zip],
                allowsMultipleSelection: false
            ) { result in
                importBackup(result: result)
            }
            .alert(item: $alertMessage) { message in
                Alert(
                    title: Text(message.title),
                    message: Text(message.detail),
                    dismissButton: .default(Text("OK"))
                )
            }
        }
    }

    private var displayModeBinding: Binding<DisplayMode> {
        Binding(
            get: { userProfileStore.displayMode },
            set: { userProfileStore.displayMode = $0 }
        )
    }

    // MARK: - Backup
    private func exportBackup() {
        isProcessingBackup = true
        defer { isProcessingBackup = false }

        do {
            shareItem = ShareItem(url: try viewModel.exportBackup())
        } catch {
            alertMessage = AlertMessage(
                title: "Không thể xuất backup",
                detail: error.localizedDescription
            )
        }
    }

    private func importBackup(result: Result<[URL], Error>) {
        isProcessingBackup = true
        defer { isProcessingBackup = false }

        do {
            guard let url = try result.get().first else { return }
            try viewModel.importBackup(from: url)
            alertMessage = AlertMessage(
                title: "Đã nhập backup",
                detail: "Dữ liệu và ảnh đã được gộp vào TravelPin."
            )
        } catch {
            alertMessage = AlertMessage(
                title: "Không thể nhập backup",
                detail: error.localizedDescription
            )
        }
    }

    // MARK: - Clear all
    private func clearAllData() {
        viewModel.clearAllData()
    }
}

struct ShareItem: Identifiable {
    let id = UUID()
    let url: URL
}

struct AlertMessage: Identifiable {
    let id = UUID()
    let title: String
    let detail: String
}

// MARK: - Personalization
struct PlaceCategorySettingsView: View {
    @Environment(UserProfileStore.self) private var userProfileStore

    @State private var selectedPlaceTypes = Set<PlaceType>()
    @State private var customCategories: [CustomPlaceCategory] = []

    private var canUpdate: Bool {
        !selectedPlaceTypes.isEmpty || !customCategories.isEmpty
    }

    var body: some View {
        List {
            Section("Loại có sẵn") {
                ForEach(PlaceType.allCases, id: \.self) { placeType in
                    Button {
                        toggle(placeType)
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: placeType.icon)
                                .frame(width: 28, height: 28)
                                .foregroundStyle(selectedPlaceTypes.contains(placeType) ? .blue : .secondary)

                            Text(placeType.rawValue)
                                .foregroundStyle(.primary)

                            Spacer()

                            if selectedPlaceTypes.contains(placeType) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.blue)
                            }
                        }
                    }
                }
            }

            Section {
                ForEach(customCategories) { category in
                    HStack(spacing: 12) {
                        Image(systemName: category.systemIconName)
                            .frame(width: 28, height: 28)
                            .foregroundStyle(.blue)

                        Text(category.name)
                        Spacer()
                    }
                }
                .onDelete { offsets in
                    customCategories.remove(atOffsets: offsets)
                }

                NavigationLink {
                    AddCustomPlaceCategoryView { category in
                        customCategories.append(category)
                    }
                } label: {
                    Label("Thêm", systemImage: "plus.circle.fill")
                }
            } header: {
                Text("Loại tự thêm")
            } footer: {
                Text("Bấm Cập nhật để áp dụng danh sách phân loại mới. Loại có sẵn không được chọn sẽ bị ẩn khỏi picker, map filter và stats.")
            }
        }
        .navigationTitle("Phân loại")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Cập nhật") {
                    userProfileStore.updatePersonalization(
                        enabledPlaceTypes: PlaceType.allCases.filter { selectedPlaceTypes.contains($0) },
                        customCategories: customCategories
                    )
                }
                .fontWeight(.semibold)
                .disabled(!canUpdate)
            }
        }
        .onAppear {
            selectedPlaceTypes = Set(userProfileStore.enabledPlaceTypes)
            customCategories = userProfileStore.profile.customCategories
        }
    }

    private func toggle(_ placeType: PlaceType) {
        if selectedPlaceTypes.contains(placeType) {
            selectedPlaceTypes.remove(placeType)
        } else {
            selectedPlaceTypes.insert(placeType)
        }
    }
}

struct AddCustomPlaceCategoryView: View {
    @Environment(\.dismiss) private var dismiss

    let onAdd: (CustomPlaceCategory) -> Void

    @State private var name = ""
    @State private var selectedIcon = "mappin.circle.fill"

    private let icons = [
        "mappin.circle.fill",
        "star.circle.fill",
        "heart.circle.fill",
        "camera.fill",
        "fork.knife.circle.fill",
        "cup.and.saucer.fill",
        "building.2.fill",
        "leaf.fill",
        "cart.fill",
        "bag.fill",
        "music.note",
        "paintpalette.fill",
        "figure.walk",
        "bicycle",
        "car.fill",
        "airplane",
        "tram.fill",
        "ellipsis.circle.fill"
    ]

    private var canAdd: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        Form {
            Section("Tên phân loại") {
                TextField("Nhập tên", text: $name)
                    .autocorrectionDisabled()
            }

            Section("Icon hệ thống") {
                LazyVGrid(
                    columns: Array(repeating: GridItem(.flexible()), count: 4),
                    spacing: 14
                ) {
                    ForEach(icons, id: \.self) { icon in
                        Button {
                            selectedIcon = icon
                        } label: {
                            Image(systemName: icon)
                                .font(.title3)
                                .foregroundStyle(selectedIcon == icon ? .white : .blue)
                                .frame(width: 48, height: 48)
                                .background(selectedIcon == icon ? Color.blue : Color(.systemGray5))
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.vertical, 6)
            }
        }
        .navigationTitle("Thêm phân loại")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Cập nhật") {
                    onAdd(
                        CustomPlaceCategory(
                            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
                            systemIconName: selectedIcon
                        )
                    )
                    dismiss()
                }
                .fontWeight(.semibold)
                .disabled(!canAdd)
            }
        }
    }
}

// MARK: - ShareSheet
struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(
            activityItems: items,
            applicationActivities: nil
        )
    }

    func updateUIViewController(
        _ uiViewController: UIActivityViewController,
        context: Context
    ) {}
}

#Preview {
    SettingsView()
        .environment(CheckInViewModel())
        .environment(UserProfileStore())
}
