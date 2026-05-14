//
//  StorageService.swift
//  TravelPin
//
//  Created by longanh on 14/5/26.
//

import Foundation

// Protocol — dễ swap khi test
protocol StorageServiceProtocol {
    func load() -> [CheckIn]
    func save(_ items: [CheckIn])
    func delete(_ item: CheckIn)
}

class StorageService: StorageServiceProtocol {

    // MARK: - File URL
    private var fileURL: URL {
        FileManager.default
            .urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("checkins.json")
    }

    // MARK: - Load
    func load() -> [CheckIn] {
        do {
            let data = try Data(contentsOf: fileURL)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            return try decoder.decode([CheckIn].self, from: data)
        } catch {
            // File chưa tồn tại hoặc lỗi decode → trả về rỗng
            print("StorageService load error: \(error)")
            return []
        }
    }

    // MARK: - Save
    func save(_ items: [CheckIn]) {
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            encoder.outputFormatting = .prettyPrinted
            let data = try encoder.encode(items)
            try data.write(to: fileURL, options: .atomic)
        } catch {
            print("StorageService save error: \(error)")
        }
    }

    // MARK: - Delete
    func delete(_ item: CheckIn) {
        var current = load()
        current.removeAll { $0.id == item.id }
        save(current)
    }
}
