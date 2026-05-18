import SwiftUI
import MapKit

private extension Array where Element == String {
    func removingDuplicates() -> [String] {
        var seen = Set<String>()
        return filter { seen.insert($0).inserted }
    }
}

// Model kết quả search
struct SearchResult: Identifiable {
    let id = UUID()
    let name: String
    let address: String
    let latitude: Double
    let longitude: Double
    let city: String
    let country: String
    let formattedAddress: String
}

struct LocationSearchView: View {
    @Environment(\.dismiss) var dismiss

    // Callback khi user chọn kết quả
    var onSelect: (SearchResult) -> Void

    @State private var searchText   = ""
    @State private var results      : [SearchResult] = []
    @State private var isSearching  = false
    @State private var searchTask   : Task<Void, Never>? = nil

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {

                // Search bar
                HStack(spacing: 10) {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(.secondary)

                    TextField("Tìm địa điểm...", text: $searchText)
                        .autocorrectionDisabled()
                        .onSubmit { triggerSearch() }

                    if !searchText.isEmpty {
                        Button {
                            searchText = ""
                            results    = []
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .padding(10)
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .padding()

                Divider()

                // Kết quả
                if isSearching {
                    Spacer()
                    ProgressView("Đang tìm...")
                    Spacer()

                } else if results.isEmpty && !searchText.isEmpty {
                    Spacer()
                    VStack(spacing: 12) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 40))
                            .foregroundStyle(.secondary)
                        Text("Không tìm thấy kết quả")
                            .foregroundStyle(.secondary)
                    }
                    Spacer()

                } else {
                    List(results) { result in
                        Button {
                            onSelect(result)
                            dismiss()
                        } label: {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(result.name)
                                    .font(.headline)
                                    .foregroundStyle(.primary)
                                Text(result.address)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(1)
                                HStack(spacing: 4) {
                                    Image(systemName: "location.circle")
                                        .font(.caption)
                                    Text(String(format: "%.4f, %.4f",
                                        result.latitude,
                                        result.longitude))
                                        .font(.caption)
                                }
                                .foregroundStyle(.tertiary)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Chọn địa điểm")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Huỷ") { dismiss() }
                }
            }
            .onChange(of: searchText) { _, newValue in
                guard !newValue.isEmpty else {
                    results = []
                    return
                }
                // Debounce 0.5s
                searchTask?.cancel()
                searchTask = Task {
                    try? await Task.sleep(for: .seconds(0.5))
                    guard !Task.isCancelled else { return }
                    await search(query: newValue)
                }
            }
        }
    }

    // MARK: - MKLocalSearch
    private func triggerSearch() {
        searchTask?.cancel()
        Task { await search(query: searchText) }
    }

    @MainActor
    private func search(query: String) async {
        isSearching = true

        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = query
        // Ưu tiên kết quả gần Việt Nam
        request.region = MKCoordinateRegion(
            center: CLLocationCoordinate2D(
                latitude: 14.0583,
                longitude: 108.2772
            ),
            span: MKCoordinateSpan(
                latitudeDelta: 30,
                longitudeDelta: 30
            )
        )

        do {
            let search   = MKLocalSearch(request: request)
            let response = try await search.start()

            results = response.mapItems.map { item in
                let placemark = item.placemark
                return SearchResult(
                    name: item.name ?? placemark.name ?? "",
                    address: [
                        placemark.thoroughfare,
                        placemark.locality,
                        placemark.country
                    ]
                    .compactMap { $0 }
                    .joined(separator: ", "),
                    latitude:  placemark.coordinate.latitude,
                    longitude: placemark.coordinate.longitude,
                    city:      placemark.locality
                                ?? placemark.administrativeArea
                                ?? "",
                    country:   placemark.country ?? "",
                    formattedAddress: [
                        placemark.name,
                        placemark.thoroughfare,
                        placemark.subLocality,
                        placemark.locality,
                        placemark.administrativeArea,
                        placemark.postalCode,
                        placemark.country
                    ]
                    .compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
                    .filter { !$0.isEmpty }
                    .removingDuplicates()
                    .joined(separator: ", ")
                )
            }
        } catch {
            results = []
        }

        isSearching = false
    }
}

#Preview {
    LocationSearchView { result in
        print("Selected: \(result.name)")
    }
}
