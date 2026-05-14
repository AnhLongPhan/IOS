import SwiftUI

struct SettingsView: View {
    @Environment(CheckInViewModel.self) var viewModel

    // @AppStorage — lưu UserDefaults tự động
    @AppStorage("userName")       var userName: String = ""
    @AppStorage("defaultMapVN")   var defaultMapVN: Bool = true
    @AppStorage("showVisitedOnly") var showVisitedOnly: Bool = false

    @State private var showClearConfirm = false
    @State private var showExportSheet  = false
    @State private var exportText       = ""

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
                Section("Dữ liệu") {
                    Button {
                        exportData()
                    } label: {
                        Label("Xuất dữ liệu JSON", systemImage: "square.and.arrow.up")
                    }

                    Button(role: .destructive) {
                        showClearConfirm = true
                    } label: {
                        Label("Xoá tất cả dữ liệu", systemImage: "trash")
                            .foregroundStyle(.red)
                    }
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
            .sheet(isPresented: $showExportSheet) {
                ShareSheet(text: exportText)
            }
        }
    }

    // MARK: - Export JSON
    private func exportData() {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting     = .prettyPrinted

        if let data = try? encoder.encode(viewModel.checkIns),
           let json = String(data: data, encoding: .utf8) {
            exportText      = json
            showExportSheet = true
        }
    }

    // MARK: - Clear all
    private func clearAllData() {
        let imageService = ImageStorageService()
        viewModel.checkIns.forEach { checkIn in
            if let path = checkIn.photoPath {
                imageService.delete(filename: path)
            }
        }
        viewModel.checkIns.removeAll()
    }
}

// MARK: - ShareSheet
struct ShareSheet: UIViewControllerRepresentable {
    let text: String

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(
            activityItems: [text],
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
