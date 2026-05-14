import SwiftUI

struct PlacesView: View {
    @Environment(CheckInViewModel.self) var viewModel
    @State private var showSortMenu = false

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
                if viewModel.filteredCheckIns.isEmpty {
                    emptyStateView
                } else {
                    List {
                        ForEach(viewModel.filteredCheckIns) { checkIn in
                            NavigationLink(value: checkIn) {
                                CheckInRowView(checkIn: checkIn)
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
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    // Sort menu
                    Menu {
                        ForEach(SortOption.allCases, id: \.self) { option in
                            Button {
                                viewModel.sortOption = option
                            } label: {
                                Label(
                                    option.rawValue,
                                    systemImage: option.icon
                                )
                            }
                        }
                    } label: {
                        Image(systemName: "arrow.up.arrow.down")
                    }
                }
            }
            .searchable(
                text: Bindable(viewModel).searchText,
                prompt: "Tìm địa điểm..."
            )
            .navigationDestination(for: CheckIn.self) { checkIn in
                // Day 7 sẽ tạo DetailView
                Text("Detail: \(checkIn.name)")
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
