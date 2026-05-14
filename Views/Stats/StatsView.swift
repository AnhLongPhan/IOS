import SwiftUI

struct StatsView: View {
    @Environment(CheckInViewModel.self) var viewModel

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
                        StatCard(
                            icon: "mappin.circle.fill",
                            label: "Địa điểm",
                            value: "\(viewModel.checkIns.count)",
                            color: .blue
                        )
                        StatCard(
                            icon: "globe.asia.australia.fill",
                            label: "Quốc gia",
                            value: "\(viewModel.totalCountries)",
                            color: .green
                        )
                        StatCard(
                            icon: "building.2.fill",
                            label: "Thành phố",
                            value: "\(viewModel.totalCities)",
                            color: .orange
                        )
                        StatCard(
                            icon: "checkmark.circle.fill",
                            label: "Đã đến",
                            value: "\(viewModel.checkIns.filter { $0.isVisited }.count)",
                            color: .teal
                        )
                    }
                    .padding(.horizontal)

                    // MARK: - Phân loại theo category
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Theo loại địa điểm")
                            .font(.headline)
                            .padding(.horizontal)

                        ForEach(PlaceCategory.allCases, id: \.self) { category in
                            let count = viewModel.checkIns.filter {
                                $0.category == category
                            }.count

                            if count > 0 {
                                CategoryStatRow(
                                    category: category,
                                    count: count,
                                    total: viewModel.checkIns.count
                                )
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

                            HStack(spacing: 12) {
                                Image(systemName: latest.category.icon)
                                    .font(.title2)
                                    .foregroundStyle(.blue)
                                    .frame(width: 44, height: 44)
                                    .background(Color.blue.opacity(0.1))
                                    .clipShape(Circle())

                                VStack(alignment: .leading, spacing: 4) {
                                    Text(latest.name)
                                        .font(.headline)
                                    Text(latest.locationDisplay)
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                    Text(latest.formattedDate)
                                        .font(.caption)
                                        .foregroundStyle(.tertiary)
                                }
                                Spacer()
                            }
                            .padding(.horizontal)
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
        }
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

            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(color.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - CategoryStatRow
struct CategoryStatRow: View {
    let category: PlaceCategory
    let count: Int
    let total: Int

    var percentage: Double {
        total > 0 ? Double(count) / Double(total) : 0
    }

    var categoryColor: Color {
        switch category {
        case .extendedFamily: return .purple
        case .family:         return .green
        case .couple:         return .pink
        case .solo:           return .blue
        case .other:          return .gray
        }
    }

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: category.icon)
                .frame(width: 24)
                .foregroundStyle(categoryColor)

            Text(category.rawValue)
                .font(.subheadline)

            Spacer()

            // Progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(categoryColor.opacity(0.15))
                        .frame(height: 8)

                    RoundedRectangle(cornerRadius: 4)
                        .fill(categoryColor)
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
                .frame(width: 24, alignment: .trailing)
        }
        .padding(.horizontal)
        .padding(.vertical, 6)
    }
}

#Preview {
    StatsView()
        .environment(CheckInViewModel())
}
