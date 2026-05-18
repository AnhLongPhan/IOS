//
//  ImageStorageService.swift
//  TravelPin
//
//  Created by longanh on 14/5/26.
//

import UIKit

class ImageStorageService {

    // Lưu UIImage → disk, trả về filename
    func save(_ image: UIImage) -> String? {
        guard let data = image.jpegData(compressionQuality: 0.8) else {
            return nil
        }

        let filename = UUID().uuidString + ".jpg"
        let url = fileURL(for: filename)

        do {
            try data.write(to: url, options: .atomic)
            return filename
        } catch {
            print("ImageStorageService save error: \(error)")
            return nil
        }
    }

    // Load UIImage từ filename
    func load(filename: String) -> UIImage? {
        let url = fileURL(for: filename)
        return UIImage(contentsOfFile: url.path)
    }

    func saveIcon(_ image: UIImage) -> String? {
        guard let data = image.jpegData(compressionQuality: 0.85) else {
            return nil
        }

        let filename = UUID().uuidString + ".jpg"
        let url = iconFileURL(for: filename)

        do {
            try FileManager.default.createDirectory(
                at: iconDirectoryURL,
                withIntermediateDirectories: true
            )
            try data.write(to: url, options: .atomic)
            return filename
        } catch {
            print("ImageStorageService save icon error: \(error)")
            return nil
        }
    }

    func loadIcon(filename: String) -> UIImage? {
        let url = iconFileURL(for: filename)
        return UIImage(contentsOfFile: url.path)
    }

    // Xoá ảnh khỏi disk
    func delete(filename: String) {
        let url = fileURL(for: filename)
        try? FileManager.default.removeItem(at: url)
    }

    func write(_ data: Data, filename: String) throws {
        try data.write(to: fileURL(for: filename), options: .atomic)
    }

    // Build URL từ filename
    func fileURL(for filename: String) -> URL {
        FileManager.default
            .urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent(filename)
    }

    private var iconDirectoryURL: URL {
        FileManager.default
            .urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("CategoryIcons", isDirectory: true)
    }

    private func iconFileURL(for filename: String) -> URL {
        iconDirectoryURL.appendingPathComponent(filename)
    }
}
