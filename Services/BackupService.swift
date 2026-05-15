import Foundation

struct BackupService {
    private let imageService: ImageStorageService
    private let fileManager: FileManager

    init(
        imageService: ImageStorageService = ImageStorageService(),
        fileManager: FileManager = .default
    ) {
        self.imageService = imageService
        self.fileManager = fileManager
    }

    func exportBackup(checkIns: [CheckIn]) throws -> URL {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let checkInData = try encoder.encode(checkIns)

        var entries = [StoredZipEntry(name: "checkins.json", data: checkInData)]
        let imageNames = Set(checkIns.compactMap(\.photoPath))

        for imageName in imageNames.sorted() {
            let imageURL = imageService.fileURL(for: imageName)
            guard fileManager.fileExists(atPath: imageURL.path) else { continue }
            let imageData = try Data(contentsOf: imageURL)
            entries.append(StoredZipEntry(name: "images/\(imageName)", data: imageData))
        }

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd-HHmmss"
        let filename = "TravelPinBackup-\(formatter.string(from: Date())).zip"
        let exportURL = fileManager.temporaryDirectory.appendingPathComponent(filename)
        try? fileManager.removeItem(at: exportURL)
        try StoredZipArchive.write(entries: entries, to: exportURL)
        return exportURL
    }

    func importBackup(from url: URL, currentCheckIns: [CheckIn]) throws -> [CheckIn] {
        let didStartAccessing = url.startAccessingSecurityScopedResource()
        defer {
            if didStartAccessing {
                url.stopAccessingSecurityScopedResource()
            }
        }

        let entries = try StoredZipArchive.read(from: url)
        guard let checkInEntry = entries.first(where: { $0.name == "checkins.json" }) else {
            throw BackupError.missingCheckInsFile
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let importedCheckIns = try decoder.decode([CheckIn].self, from: checkInEntry.data)

        for entry in entries where entry.name.hasPrefix("images/") {
            let filename = URL(fileURLWithPath: entry.name).lastPathComponent
            guard !filename.isEmpty else { continue }
            try imageService.write(entry.data, filename: filename)
        }

        var mergedByID = Dictionary(uniqueKeysWithValues: currentCheckIns.map { ($0.id, $0) })
        for checkIn in importedCheckIns {
            mergedByID[checkIn.id] = checkIn
        }

        return mergedByID.values.sorted { $0.visitedAt > $1.visitedAt }
    }
}

enum BackupError: LocalizedError {
    case missingCheckInsFile
    case unsupportedZipMethod
    case invalidArchive
    case invalidEntryName

    var errorDescription: String? {
        switch self {
        case .missingCheckInsFile:
            return "Không tìm thấy checkins.json trong file backup."
        case .unsupportedZipMethod:
            return "File ZIP này dùng kiểu nén chưa được hỗ trợ."
        case .invalidArchive:
            return "File backup không hợp lệ hoặc đã bị lỗi."
        case .invalidEntryName:
            return "File backup chứa đường dẫn không an toàn."
        }
    }
}

private struct StoredZipEntry {
    let name: String
    let data: Data
}

private enum StoredZipArchive {
    static func write(entries: [StoredZipEntry], to url: URL) throws {
        var archive = Data()
        var centralDirectory = Data()

        for entry in entries {
            try validate(entryName: entry.name)
            guard let nameData = entry.name.data(using: .utf8) else {
                throw BackupError.invalidEntryName
            }

            let offset = UInt32(archive.count)
            let crc = CRC32.checksum(entry.data)
            let size = UInt32(entry.data.count)
            let nameLength = UInt16(nameData.count)

            archive.appendUInt32(0x04034b50)
            archive.appendUInt16(20)
            archive.appendUInt16(0)
            archive.appendUInt16(0)
            archive.appendUInt16(0)
            archive.appendUInt16(0)
            archive.appendUInt32(crc)
            archive.appendUInt32(size)
            archive.appendUInt32(size)
            archive.appendUInt16(nameLength)
            archive.appendUInt16(0)
            archive.append(nameData)
            archive.append(entry.data)

            centralDirectory.appendUInt32(0x02014b50)
            centralDirectory.appendUInt16(20)
            centralDirectory.appendUInt16(20)
            centralDirectory.appendUInt16(0)
            centralDirectory.appendUInt16(0)
            centralDirectory.appendUInt16(0)
            centralDirectory.appendUInt16(0)
            centralDirectory.appendUInt32(crc)
            centralDirectory.appendUInt32(size)
            centralDirectory.appendUInt32(size)
            centralDirectory.appendUInt16(nameLength)
            centralDirectory.appendUInt16(0)
            centralDirectory.appendUInt16(0)
            centralDirectory.appendUInt16(0)
            centralDirectory.appendUInt16(0)
            centralDirectory.appendUInt32(0)
            centralDirectory.appendUInt32(offset)
            centralDirectory.append(nameData)
        }

        let centralDirectoryOffset = UInt32(archive.count)
        archive.append(centralDirectory)
        archive.appendUInt32(0x06054b50)
        archive.appendUInt16(0)
        archive.appendUInt16(0)
        archive.appendUInt16(UInt16(entries.count))
        archive.appendUInt16(UInt16(entries.count))
        archive.appendUInt32(UInt32(centralDirectory.count))
        archive.appendUInt32(centralDirectoryOffset)
        archive.appendUInt16(0)

        try archive.write(to: url, options: .atomic)
    }

    static func read(from url: URL) throws -> [StoredZipEntry] {
        let data = try Data(contentsOf: url)
        var offset = 0
        var entries: [StoredZipEntry] = []

        while offset + 4 <= data.count {
            let signature = try data.uint32(at: offset)
            if signature == 0x02014b50 || signature == 0x06054b50 {
                break
            }

            guard signature == 0x04034b50 else {
                throw BackupError.invalidArchive
            }

            let method = try data.uint16(at: offset + 8)
            guard method == 0 else {
                throw BackupError.unsupportedZipMethod
            }

            let compressedSize = Int(try data.uint32(at: offset + 18))
            let fileNameLength = Int(try data.uint16(at: offset + 26))
            let extraLength = Int(try data.uint16(at: offset + 28))
            let nameStart = offset + 30
            let nameEnd = nameStart + fileNameLength
            let dataStart = nameEnd + extraLength
            let dataEnd = dataStart + compressedSize

            guard dataEnd <= data.count,
                  let name = String(data: data[nameStart..<nameEnd], encoding: .utf8) else {
                throw BackupError.invalidArchive
            }

            try validate(entryName: name)
            entries.append(StoredZipEntry(name: name, data: Data(data[dataStart..<dataEnd])))
            offset = dataEnd
        }

        return entries
    }

    private static func validate(entryName: String) throws {
        guard !entryName.hasPrefix("/"),
              !entryName.contains(".."),
              !entryName.contains("\\") else {
            throw BackupError.invalidEntryName
        }
    }
}

private enum CRC32 {
    private static let table: [UInt32] = (0..<256).map { value in
        var crc = UInt32(value)
        for _ in 0..<8 {
            if crc & 1 == 1 {
                crc = (crc >> 1) ^ 0xedb88320
            } else {
                crc >>= 1
            }
        }
        return crc
    }

    static func checksum(_ data: Data) -> UInt32 {
        var crc: UInt32 = 0xffffffff
        for byte in data {
            let index = Int((crc ^ UInt32(byte)) & 0xff)
            crc = (crc >> 8) ^ table[index]
        }
        return crc ^ 0xffffffff
    }
}

private extension Data {
    mutating func appendUInt16(_ value: UInt16) {
        append(UInt8(value & 0xff))
        append(UInt8((value >> 8) & 0xff))
    }

    mutating func appendUInt32(_ value: UInt32) {
        append(UInt8(value & 0xff))
        append(UInt8((value >> 8) & 0xff))
        append(UInt8((value >> 16) & 0xff))
        append(UInt8((value >> 24) & 0xff))
    }

    func uint16(at offset: Int) throws -> UInt16 {
        guard offset + 2 <= count else { throw BackupError.invalidArchive }
        return UInt16(self[offset]) | (UInt16(self[offset + 1]) << 8)
    }

    func uint32(at offset: Int) throws -> UInt32 {
        guard offset + 4 <= count else { throw BackupError.invalidArchive }
        return UInt32(self[offset]) |
            (UInt32(self[offset + 1]) << 8) |
            (UInt32(self[offset + 2]) << 16) |
            (UInt32(self[offset + 3]) << 24)
    }
}
