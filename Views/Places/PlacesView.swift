import SwiftUI

struct PlacesView: View {
    @Environment(CheckInViewModel.self) var viewModel

    var sortedCheckIns: [CheckIn] {
        viewModel.checkIns
            .filter { checkIn in
                let matchesSearch = viewModel.searchText.isEmpty ||
                    checkIn.name.localizedCaseInsensitiveContains(viewModel.searchText) ||
                    checkIn.note.localizedCaseInsensitiveContains(viewModel.searchText) ||
                    checkIn.city.localizedCaseInsensitiveContains(viewModel.searchText)

                let matchesCategory = viewModel.selectedCategory == nil ||
                    checkIn.category == viewModel.selectedCategory

                return matchesSearch && matchesCategory
            }
            .sorted { $0.visitedAt < $1.visitedAt }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Filter bar
                CategoryFilterView(
                    selectedCategory: Bindable(viewModel).selectedCategory
                )
                .background(Color(.systemBackground))

                Divider()

                // List
                if sortedCheckIns.isEmpty {
                    emptyStateView
                } else {
                    List {
                        ForEach(Array(sortedCheckIns.enumerated()), id: \.element.id) { index, checkIn in
                            NavigationLink(value: checkIn) {
                                CheckInRowView(checkIn: checkIn, index: index + 1)
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                Button(role: .destructive) {
                                    viewModel.delete(checkIn)
                                } label: {
                                    Label("Xoá", systemImage: "trash")
                                }
                            }
                        }
                    }
                    .listStyle(.plain)
                    .refreshable {
                        // Day 8 sẽ gọi API ở đây
                        try? await Task.sleep(for: .seconds(1))
                    }
                }
            }
            .navigationTitle("Places")
            .navigationBarTitleDisplayMode(.large)
            .searchable(
                text: Bindable(viewModel).searchText,
                prompt: "Tìm địa điểm..."
            )
            .navigationDestination(for: CheckIn.self) { checkIn in
                // Day 7 sẽ tạo DetailView
                DetailView(checkIn: checkIn)
                    .environment(viewModel)
            }
        }
    }

    // MARK: - Empty state
    var emptyStateView: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "mappin.slash")
                .font(.system(size: 56))
                .foregroundStyle(.secondary)
            Text(viewModel.searchText.isEmpty
                 ? "Chưa có địa điểm nào"
                 : "Không tìm thấy kết quả")
                .font(.headline)
                .foregroundStyle(.secondary)
            if viewModel.searchText.isEmpty {
                Text("Thêm địa điểm bằng cách bấm + trên bản đồ")
                    .font(.subheadline)
                    .foregroundStyle(.tertiary)
                    .multilineTextAlignment(.center)
            }
            Spacer()
        }
        .padding()
    }
}

#Preview {
    PlacesView()
        .environment(CheckInViewModel())
}
