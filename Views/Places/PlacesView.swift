import SwiftUI

struct PlacesView: View {
    @Environment(CheckInViewModel.self) var viewModel

    var sortedCheckIns: [CheckIn] {
        viewModel.filteredCheckIns
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Filter bar
                VStack(spacing: 10) {
                    Picker("Trạng thái", selection: Bindable(viewModel).visitStatusFilter) {
                        ForEach(VisitStatusFilter.allCases, id: \.self) { filter in
                            Label(filter.rawValue, systemImage: filter.icon)
                                .tag(filter)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)
                    .padding(.top, 8)

                    CategoryFilterView(
                        selectedPlaceType: Bindable(viewModel).selectedPlaceType
                    )
                }
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
            Image(systemName: viewModel.visitStatusFilter == .wishlist ? "bookmark.slash" : "mappin.slash")
                .font(.system(size: 56))
                .foregroundStyle(.secondary)
            Text(emptyStateTitle)
                .font(.headline)
                .foregroundStyle(.secondary)
            if viewModel.searchText.isEmpty {
                Text(emptyStateMessage)
                    .font(.subheadline)
                    .foregroundStyle(.tertiary)
                    .multilineTextAlignment(.center)
            }
            Spacer()
        }
        .padding()
    }

    private var emptyStateTitle: String {
        if !viewModel.searchText.isEmpty {
            return "Không tìm thấy kết quả"
        }

        switch viewModel.visitStatusFilter {
        case .all: return "Chưa có địa điểm nào"
        case .visited: return "Chưa có địa điểm đã đi"
        case .wishlist: return "Chưa có wishlist"
        }
    }

    private var emptyStateMessage: String {
        switch viewModel.visitStatusFilter {
        case .all: return "Thêm địa điểm bằng cách bấm + trên bản đồ"
        case .visited: return "Đổi trạng thái địa điểm thành đã tham quan khi bạn hoàn tất chuyến đi"
        case .wishlist: return "Tắt Đã tham quan khi thêm địa điểm để lưu vào wishlist"
        }
    }
}

#Preview {
    PlacesView()
        .environment(CheckInViewModel())
}
