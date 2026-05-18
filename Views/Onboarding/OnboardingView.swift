import SwiftUI
import UIKit

struct OnboardingView: View {
    @Environment(UserProfileStore.self) private var userProfileStore

    @State private var displayName = ""
    @State private var selectedPlaceTypes = Set(PlaceType.allCases)
    @State private var customCategories: [CustomPlaceCategory] = []
    @State private var customCategoryName = ""
    @State private var customCategoryIcon: UIImage?
    @State private var showMissingIcon = false

    private let imageService = ImageStorageService()

    private var canFinish: Bool {
        !displayName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        (!selectedPlaceTypes.isEmpty || !customCategories.isEmpty)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Tên hiển thị") {
                    TextField("Nhập tên của bạn", text: $displayName)
                        .textInputAutocapitalization(.words)
                        .autocorrectionDisabled()
                }

                Section("Chọn loại cần dùng") {
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
                            if let iconFilename = category.iconFilename,
                               let icon = imageService.loadIcon(filename: iconFilename) {
                                Image(uiImage: icon)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 32, height: 32)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                            } else {
                                Image(systemName: category.systemIconName)
                                    .frame(width: 32, height: 32)
                                    .foregroundStyle(.secondary)
                            }

                            Text(category.name)
                            Spacer()
                        }
                    }
                    .onDelete { offsets in
                        customCategories.remove(atOffsets: offsets)
                    }

                    TextField("Tên loại mới", text: $customCategoryName)
                        .autocorrectionDisabled()

                    HStack {
                        PhotoPickerView(image: $customCategoryIcon)

                        Spacer()

                        if let customCategoryIcon {
                            Image(uiImage: customCategoryIcon)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 40, height: 40)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                    }

                    Button {
                        addCustomCategory()
                    } label: {
                        Label("Thêm loại", systemImage: "plus.circle.fill")
                    }
                    .disabled(customCategoryName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                } header: {
                    Text("Loại tự thêm")
                } footer: {
                    if showMissingIcon {
                        Text("Vui lòng chọn icon từ thư viện ảnh cho loại tự thêm.")
                            .foregroundStyle(.red)
                    }
                }

                Section {
                    Button {
                        finish()
                    } label: {
                        Text("Hoàn thành")
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                    }
                    .disabled(!canFinish)
                }
            }
            .navigationTitle("Thiết lập ban đầu")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private func toggle(_ placeType: PlaceType) {
        if selectedPlaceTypes.contains(placeType) {
            selectedPlaceTypes.remove(placeType)
        } else {
            selectedPlaceTypes.insert(placeType)
        }
    }

    private func addCustomCategory() {
        let name = customCategoryName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return }
        guard let customCategoryIcon,
              let filename = imageService.saveIcon(customCategoryIcon) else {
            showMissingIcon = true
            return
        }

        customCategories.append(CustomPlaceCategory(name: name, iconFilename: filename))
        customCategoryName = ""
        self.customCategoryIcon = nil
        showMissingIcon = false
    }

    private func finish() {
        userProfileStore.completeOnboarding(
            displayName: displayName,
            enabledPlaceTypes: PlaceType.allCases.filter { selectedPlaceTypes.contains($0) },
            customCategories: customCategories
        )
    }
}
