import Foundation
import Observation

@Observable
class CheckInViewModel {
    var checkIns: [CheckIn] = []
    var isLoading: Bool = false
    var errorMessage: String? = nil
    var searchText: String = ""
    var selectedCategory: PlaceCategory? = nil

    var filteredCheckIns: [CheckIn] {
        checkIns.filter { item in
            let matchSearch = searchText.isEmpty ||
                item.name.localizedCaseInsensitiveContains(searchText) ||
                item.note.localizedCaseInsensitiveContains(searchText) ||
                item.city.localizedCaseInsensitiveContains(searchText)

            let matchCategory = selectedCategory == nil ||
                item.category == selectedCategory

            return matchSearch && matchCategory
        }
        .sorted { $0.visitedAt > $1.visitedAt }
    }

    var totalCountries: Int {
        Set(checkIns.map { $0.country }).count
    }

    var totalCities: Int {
        Set(checkIns.map { $0.city }).count
    }

    init() {
        self.checkIns = CheckIn.mockData
    }

    func add(_ checkIn: CheckIn) {
        checkIns.append(checkIn)
    }

    func delete(_ checkIn: CheckIn) {
        checkIns.removeAll { $0.id == checkIn.id }
    }

    func update(_ checkIn: CheckIn) {
        if let index = checkIns.firstIndex(where: { $0.id == checkIn.id }) {
            checkIns[index] = checkIn
        }
    }

    func clearError() {
        errorMessage = nil
    }
}
