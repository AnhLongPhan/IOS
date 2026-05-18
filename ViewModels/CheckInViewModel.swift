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

enum VisitStatusFilter: String, CaseIterable {
    case all = "Tất cả"
    case visited = "Đã đi"
    case wishlist = "Muốn đi"

    var icon: String {
        switch self {
        case .all: return "map"
        case .visited: return "checkmark.circle.fill"
        case .wishlist: return "bookmark.fill"
        }
    }

    func matches(_ checkIn: CheckIn) -> Bool {
        switch self {
        case .all: return true
        case .visited: return checkIn.isVisited
        case .wishlist: return !checkIn.isVisited
        }
    }
}

@Observable
class CheckInViewModel {

    var checkIns: [CheckIn] = []
    var isLoading: Bool = false
    var errorMessage: String? = nil
    var searchText: String = ""
    var selectedPlaceType: PlaceType? = nil
    var selectedCategory: PlaceCategory? = nil
    var visitStatusFilter: VisitStatusFilter = .all
    var sortOption: SortOption = .newest  // thêm mới

    private let storage: StorageServiceProtocol
    private let imageService = ImageStorageService()
    private let backupService = BackupService()

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
                item.city.localizedCaseInsensitiveContains(searchText) ||
                item.country.localizedCaseInsensitiveContains(searchText) ||
                item.formattedAddress.localizedCaseInsensitiveContains(searchText) ||
                item.placeType.rawValue.localizedCaseInsensitiveContains(searchText)

            let matchPlaceType = selectedPlaceType == nil ||
                item.placeType == selectedPlaceType

            let matchCategory = selectedCategory == nil ||
                item.category == selectedCategory

            let matchStatus = visitStatusFilter.matches(item)

            return matchSearch && matchPlaceType && matchCategory && matchStatus
        }

        switch sortOption {
        case .newest: return filtered.sorted { $0.visitedAt > $1.visitedAt }
        case .oldest: return filtered.sorted { $0.visitedAt < $1.visitedAt }
        case .name:   return filtered.sorted { $0.name < $1.name }
        }
    }

    var totalCountries: Int {
        Set(checkIns.map(\.country).filter { !$0.isEmpty }).count
    }

    var totalCities: Int {
        Set(checkIns.map(\.city).filter { !$0.isEmpty }).count
    }

    var totalVisited: Int {
        checkIns.filter(\.isVisited).count
    }

    var totalWishlist: Int {
        checkIns.filter { !$0.isVisited }.count
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

    func exportBackup() throws -> URL {
        try backupService.exportBackup(checkIns: checkIns)
    }

    func importBackup(from url: URL) throws {
        checkIns = try backupService.importBackup(from: url, currentCheckIns: checkIns)
        storage.save(checkIns)
    }

    func clearAllData() {
        checkIns.forEach { checkIn in
            if let path = checkIn.photoPath {
                imageService.delete(filename: path)
            }
        }
        checkIns.removeAll()
        storage.save(checkIns)
    }

    func clearError() {
        errorMessage = nil
    }
}
