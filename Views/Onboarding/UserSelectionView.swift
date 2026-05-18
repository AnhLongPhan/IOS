import SwiftUI

struct UserSelectionView: View {
    @Environment(UserProfileStore.self) private var userProfileStore

    var body: some View {
        NavigationStack {
            List {
                Section("Chọn user") {
                    ForEach(userProfileStore.profiles, id: \.id) { profile in
                        Button {
                            userProfileStore.selectUser(profile)
                        } label: {
                            HStack(spacing: 12) {
                                Text(initial(for: profile))
                                    .font(.system(size: 17, weight: .bold))
                                    .foregroundStyle(.white)
                                    .frame(width: 40, height: 40)
                                    .background(.blue)
                                    .clipShape(Circle())

                                VStack(alignment: .leading, spacing: 3) {
                                    Text(profile.displayName)
                                        .font(.headline)
                                        .foregroundStyle(.primary)

                                    Text("\(profile.enabledPlaceTypeRawValues.count + profile.customCategories.count) phân loại")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }

                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundStyle(.tertiary)
                            }
                        }
                    }
                }

                Section {
                    Button {
                        userProfileStore.startNewUserSetup()
                    } label: {
                        Label("Thêm user mới", systemImage: "person.badge.plus")
                    }
                }
            }
            .navigationTitle("Chọn user")
        }
    }

    private func initial(for profile: UserProfile) -> String {
        let trimmedName = profile.displayName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let first = trimmedName.first else { return "U" }
        return String(first).uppercased()
    }
}
