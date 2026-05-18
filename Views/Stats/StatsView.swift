import SwiftUI

struct StatsView: View {
    @Environment(CheckInViewModel.self) var viewModel
    @Environment(UserProfileStore.self) private var userProfileStore

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {

                    // MARK: - Số liệu tổng quan
                    LazyVGrid(
                        columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ],
                        spacing: 12
                    ) {
                        NavigationLink(value: StatsListDestination.allPlaces) {
                            StatCard(
                                icon: "mappin.circle.fill",
                                label: "Địa điểm",
                                value: "\(viewModel.checkIns.count)",
                                color: .blue
                            )
                        }

                        NavigationLink(value: StatsListDestination.countries) {
                            StatCard(
                                icon: "globe.asia.australia.fill",
                                label: "Quốc gia",
                                value: "\(viewModel.totalCountries)",
                                color: .green
                            )
                        }

                        NavigationLink(value: StatsListDestination.cities) {
                            StatCard(
                                icon: "building.2.fill",
                                label: "Thành phố",
                                value: "\(viewModel.totalCities)",
                                color: .orange
                            )
                        }

                        NavigationLink(value: StatsListDestination.visited) {
                            StatCard(
                                icon: "checkmark.circle.fill",
                                label: "Đã đến",
                                value: "\(viewModel.totalVisited)",
                                color: .teal
                            )
                        }
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal)

                    // MARK: - Phân loại theo loại địa điểm
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Theo phân loại")
                            .font(.headline)
                            .padding(.horizontal)

                        ForEach(userProfileStore.enabledPlaceTypes, id: \.self) { placeType in
                            let count = viewModel.checkIns.filter {
                                $0.customPlaceCategoryID == nil && $0.placeType == placeType
                            }.count

                            if count > 0 {
                                NavigationLink(value: StatsListDestination.placeType(placeType)) {
                                    PlaceTypeStatRow(
                                        placeType: placeType,
                                        count: count,
                                        total: viewModel.checkIns.count
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }

                        ForEach(userProfileStore.profile.customCategories) { category in
                            let count = viewModel.checkIns.filter {
                                $0.customPlaceCategoryID == category.id
                            }.count

                            if count > 0 {
                                NavigationLink(
                                    value: StatsListDestination.customCategory(
                                        id: category.id,
                                        name: category.name
                                    )
                                ) {
                                    CategoryStatRow(
                                        icon: category.systemIconName,
                                        name: category.name,
                                        color: .blue,
                                        count: count,
                                        total: viewModel.checkIns.count
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .padding(.vertical, 8)
                    .background(Color(.systemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .padding(.horizontal)

                    // MARK: - Checkin gần nhất
                    if let latest = viewModel.checkIns
                        .sorted(by: { $0.visitedAt > $1.visitedAt })
                        .first {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Gần nhất")
                                .font(.headline)
                                .padding(.horizontal)

                            NavigationLink(value: latest) {
                                HStack(spacing: 12) {
                                    Image(systemName: userProfileStore.categoryIcon(for: latest))
                                        .font(.title2)
                                        .foregroundStyle(placeTypeColor(latest.placeType))
                                        .frame(width: 44, height: 44)
                                        .background(placeTypeColor(latest.placeType).opacity(0.1))
                                        .clipShape(Circle())

                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(latest.name)
                                            .font(.headline)
                                            .foregroundStyle(.primary)
                                        Text(latest.locationDisplay)
                                            .font(.subheadline)
                                            .foregroundStyle(.secondary)
                                        Text(latest.formattedDate)
                                            .font(.caption)
                                            .foregroundStyle(.tertiary)
                                    }
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .font(.caption)
                                        .foregroundStyle(.tertiary)
                                }
                                .padding(.horizontal)
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.vertical, 8)
                        .background(Color(.systemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .padding(.horizontal)
                    }

                    // Empty state
                    if viewModel.checkIns.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "chart.bar.xaxis")
                                .font(.system(size: 48))
                                .foregroundStyle(.secondary)
                            Text("Chưa có dữ liệu")
                                .font(.headline)
                                .foregroundStyle(.secondary)
                            Text("Thêm địa điểm để xem thống kê")
                                .font(.subheadline)
                                .foregroundStyle(.tertiary)
                        }
                        .padding(.top, 60)
                    }
                }
                .padding(.vertical)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Stats")
            .navigationDestination(for: StatsListDestination.self) { destination in
                StatsCheckInListView(
                    title: destination.title,
                    checkIns: checkIns(for: destination)
                )
            }
            .navigationDestination(for: CheckIn.self) { checkIn in
                DetailView(checkIn: checkIn)
                    .environment(viewModel)
            }
        }
    }

    private func checkIns(for destination: StatsListDestination) -> [CheckIn] {
        let items: [CheckIn]
        switch destination {
        case .allPlaces:
            items = viewModel.checkIns
        case .countries:
            items = viewModel.checkIns.filter { !$0.country.isEmpty }
        case .cities:
            items = viewModel.checkIns.filter { !$0.city.isEmpty }
        case .visited:
            items = viewModel.checkIns.filter(\.isVisited)
        case .placeType(let placeType):
            items = viewModel.checkIns.filter {
                $0.customPlaceCategoryID == nil && $0.placeType == placeType
            }
        case .customCategory(let id, _):
            items = viewModel.checkIns.filter { $0.customPlaceCategoryID == id }
        }

        return items.sorted { $0.visitedAt > $1.visitedAt }
    }
}

enum StatsListDestination: Hashable {
    case allPlaces
    case countries
    case cities
    case visited
    case placeType(PlaceType)
    case customCategory(id: UUID, name: String)

    var title: String {
        switch self {
        case .allPlaces: return "Tất cả địa điểm"
        case .countries: return "Địa điểm có quốc gia"
        case .cities: return "Địa điểm có thành phố"
        case .visited: return "Đã đến"
        case .placeType(let placeType): return placeType.rawValue
        case .customCategory(_, let name): return name
        }
    }
}

struct StatsCheckInListView: View {
    let title: String
    let checkIns: [CheckIn]

    var body: some View {
        Group {
            if checkIns.isEmpty {
                ContentUnavailableView(
                    "Không có địa điểm",
                    systemImage: "mappin.slash",
                    description: Text("Chưa có dữ liệu phù hợp với thống kê này.")
                )
            } else {
                List {
                    ForEach(Array(checkIns.enumerated()), id: \.element.id) { index, checkIn in
                        NavigationLink(value: checkIn) {
                            CheckInRowView(checkIn: checkIn, index: index + 1)
                        }
                    }
                }
                .listStyle(.plain)
            }
        }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - StatCard
struct StatCard: View {
    let icon: String
    let label: String
    let value: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)

            Text(value)
                .font(.system(size: 32, weight: .bold))
                .foregroundStyle(color)

            HStack(spacing: 4) {
                Text(label)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Image(systemName: "chevron.right")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(color.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - PlaceTypeStatRow
struct PlaceTypeStatRow: View {
    let placeType: PlaceType
    let count: Int
    let total: Int

    var percentage: Double {
        total > 0 ? Double(count) / Double(total) : 0
    }

    var rowColor: Color {
        placeTypeColor(placeType)
    }

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: placeType.icon)
                .frame(width: 24)
                .foregroundStyle(rowColor)

            Text(placeType.rawValue)
                .font(.subheadline)
                .foregroundStyle(.primary)

            Spacer()

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(rowColor.opacity(0.15))
                        .frame(height: 8)

                    RoundedRectangle(cornerRadius: 4)
                        .fill(rowColor)
                        .frame(
                            width: geo.size.width * percentage,
                            height: 8
                        )
                }
            }
            .frame(width: 100, height: 8)

            Text("\(count)")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(.primary)
                .frame(width: 24, alignment: .trailing)

            Image(systemName: "chevron.right")
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .padding(.horizontal)
        .padding(.vertical, 6)
    }
}

struct CategoryStatRow: View {
    let icon: String
    let name: String
    let color: Color
    let count: Int
    let total: Int

    var percentage: Double {
        total > 0 ? Double(count) / Double(total) : 0
    }

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .frame(width: 24)
                .foregroundStyle(color)

            Text(name)
                .font(.subheadline)
                .foregroundStyle(.primary)

            Spacer()

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(color.opacity(0.15))
                        .frame(height: 8)

                    RoundedRectangle(cornerRadius: 4)
                        .fill(color)
                        .frame(
                            width: geo.size.width * percentage,
                            height: 8
                        )
                }
            }
            .frame(width: 100, height: 8)

            Text("\(count)")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(.primary)
                .frame(width: 24, alignment: .trailing)

            Image(systemName: "chevron.right")
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .padding(.horizontal)
        .padding(.vertical, 6)
    }
}

func placeTypeColor(_ placeType: PlaceType) -> Color {
    switch placeType {
    case .travel: return .blue
    case .food: return .red
    case .checkIn: return .purple
    case .coffee: return .brown
    case .other: return .gray
    }
}

#Preview {
    StatsView()
        .environment(CheckInViewModel())
        .environment(UserProfileStore())
}
