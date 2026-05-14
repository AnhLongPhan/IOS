import Foundation
import Observation

// Sort options
enum SortOption: String, CaseIterable {
    case newest  = "Mới nhất"
    case oldest  = "Cũ nhất"
    case name    = "Tên A-Z"

    var icon: String {
        switch self {
        case .newest: return "arrow.down.circle"
        case .oldest: return "arrow.up.circle"
        case .name:   return "textformat.abc"
        }
    }
}

@Observable
class CheckInViewModel {

    var checkIns: [CheckIn] = []
    var isLoading: Bool = false
    var errorMessage: String? = nil
    var searchText: String = ""
    var selectedCategory: PlaceCategory? = nil
    var sortOption: SortOption = .newest  // thêm mới

    private let storage: StorageServiceProtocol
    private let imageService = ImageStorageService()

    init(storage: StorageServiceProtocol = StorageService()) {
        self.storage = storage
        self.checkIns = storage.load()
    }

    // MARK: - Filtered + Sorted
    var filteredCheckIns: [CheckIn] {
        let filtered = checkIns.filter { item in
            let matchSearch = searchText.isEmpty ||
                item.name.localizedCaseInsensitiveContains(searchText) ||
                item.note.localizedCaseInsensitiveContains(searchText) ||
                item.city.localizedCaseInsensitiveContains(searchText)

            let matchCategory = selectedCategory == nil ||
                item.category == selectedCategory

            return matchSearch && matchCategory
        }

        switch sortOption {
        case .newest: return filtered.sorted { $0.visitedAt > $1.visitedAt }
        case .oldest: return filtered.sorted { $0.visitedAt < $1.visitedAt }
        case .name:   return filtered.sorted { $0.name < $1.name }
        }
    }

    var totalCountries: Int {
        Set(checkIns.map { $0.country }).count
    }

    var totalCities: Int {
        Set(checkIns.map { $0.city }).count
    }

    func add(_ checkIn: CheckIn) {
        checkIns.append(checkIn)
        storage.save(checkIns)
    }

    func delete(_ checkIn: CheckIn) {
        if let path = checkIn.photoPath {
            imageService.delete(filename: path)
        }
        checkIns.removeAll { $0.id == checkIn.id }
        storage.save(checkIns)
    }

    func update(_ checkIn: CheckIn) {
        if let index = checkIns.firstIndex(where: { $0.id == checkIn.id }) {
            checkIns[index] = checkIn
            storage.save(checkIns)
        }
    }

    func clearError() {
        errorMessage = nil
    }
}
