import SwiftUI
import UniformTypeIdentifiers

struct SettingsView: View {
    @Environment(CheckInViewModel.self) var viewModel

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

                // MARK: - Thống kê
                Section("Thống kê") {
                    LabeledContent("Tổng địa điểm") {
                        Text("\(viewModel.checkIns.count)")
                            .foregroundStyle(.secondary)
                    }
                    LabeledContent("Quốc gia") {
                        Text("\(viewModel.totalCountries)")
                            .foregroundStyle(.secondary)
                    }
                    LabeledContent("Thành phố") {
                        Text("\(viewModel.totalCities)")
                            .foregroundStyle(.secondary)
                    }
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
}
