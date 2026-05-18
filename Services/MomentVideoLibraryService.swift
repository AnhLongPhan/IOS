import Foundation

struct SavedMomentVideo: Identifiable, Hashable {
    let id: String
    let title: String
    let createdAt: Date
    let url: URL
}

struct MomentVideoLibraryService {
    func loadVideos(for userID: UUID?) -> [SavedMomentVideo] {
        let directory = directoryURL(for: userID)
        guard let urls = try? FileManager.default.contentsOfDirectory(
            at: directory,
            includingPropertiesForKeys: [.creationDateKey],
            options: [.skipsHiddenFiles]
        ) else { return [] }

        return urls
            .filter { $0.pathExtension.lowercased() == "mp4" }
            .map { url in
                let values = try? url.resourceValues(forKeys: [.creationDateKey])
                return SavedMomentVideo(
                    id: url.lastPathComponent,
                    title: title(from: url),
                    createdAt: values?.creationDate ?? Date.distantPast,
                    url: url
                )
            }
            .sorted { $0.createdAt > $1.createdAt }
    }

    func saveVideo(from temporaryURL: URL, title: String, for userID: UUID?) throws -> SavedMomentVideo {
        let directory = directoryURL(for: userID)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)

        let filename = "\(timestampString())_\(UUID().uuidString)_\(slug(title)).mp4"
        let destination = directory.appendingPathComponent(filename)

        if FileManager.default.fileExists(atPath: destination.path) {
            try FileManager.default.removeItem(at: destination)
        }

        try FileManager.default.copyItem(at: temporaryURL, to: destination)

        return SavedMomentVideo(
            id: destination.lastPathComponent,
            title: title,
            createdAt: Date(),
            url: destination
        )
    }

    func rename(_ video: SavedMomentVideo, to title: String) throws -> SavedMomentVideo {
        let cleanedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let safeTitle = cleanedTitle.isEmpty ? video.title : cleanedTitle
        let parts = video.url.deletingPathExtension().lastPathComponent.split(separator: "_", maxSplits: 2).map(String.init)
        let prefix = parts.count >= 2 ? "\(parts[0])_\(parts[1])" : "\(timestampString())_\(UUID().uuidString)"
        let destination = video.url.deletingLastPathComponent()
            .appendingPathComponent("\(prefix)_\(slug(safeTitle)).mp4")

        if destination == video.url {
            return SavedMomentVideo(id: video.id, title: safeTitle, createdAt: video.createdAt, url: video.url)
        }

        if FileManager.default.fileExists(atPath: destination.path) {
            try FileManager.default.removeItem(at: destination)
        }

        try FileManager.default.moveItem(at: video.url, to: destination)

        return SavedMomentVideo(
            id: destination.lastPathComponent,
            title: safeTitle,
            createdAt: video.createdAt,
            url: destination
        )
    }

    func delete(_ video: SavedMomentVideo) throws {
        try FileManager.default.removeItem(at: video.url)
    }

    func deleteAll(for userID: UUID?) throws {
        let directory = directoryURL(for: userID)
        guard FileManager.default.fileExists(atPath: directory.path) else { return }
        try FileManager.default.removeItem(at: directory)
    }

    private func directoryURL(for userID: UUID?) -> URL {
        let base = FileManager.default
            .urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("MomentVideos", isDirectory: true)

        if let userID {
            return base.appendingPathComponent(userID.uuidString, isDirectory: true)
        }

        return base.appendingPathComponent("Shared", isDirectory: true)
    }

    private func title(from url: URL) -> String {
        let name = url.deletingPathExtension().lastPathComponent
        let parts = name.split(separator: "_", maxSplits: 2).map(String.init)
        guard parts.count == 3 else { return name }
        return parts[2].replacingOccurrences(of: "-", with: " ")
    }

    private func timestampString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMddHHmmss"
        return formatter.string(from: Date())
    }

    private func slug(_ text: String) -> String {
        let allowed = CharacterSet.alphanumerics.union(.whitespaces)
        return text
            .unicodeScalars
            .map { allowed.contains($0) ? Character($0) : " " }
            .reduce(into: "") { $0.append($1) }
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: " ", with: "-")
    }
}
