//
//  PhotoPickerView.swift
//  TravelPin
//
//  Created by longanh on 14/5/26.
//

import CoreLocation
import PhotosUI
import SwiftUI

struct PhotoPickerView: View {
    @Binding var image: UIImage?
    var onCoordinateFound: (CLLocationCoordinate2D) -> Void = { _ in }

    @State private var selectedItem: PhotosPickerItem? = nil
    private let metadataService = ImageMetadataService()

    var body: some View {
        PhotosPicker(
            selection: $selectedItem,
            matching: .images,
            photoLibrary: .shared()
        ) {
            Label("Chọn từ thư viện", systemImage: "photo.on.rectangle")
        }
        .onChange(of: selectedItem) { _, newItem in
            Task {
                guard let data = try? await newItem?.loadTransferable(type: Data.self),
                      let uiImage = UIImage(data: data) else { return }

                let coordinate = metadataService.coordinate(from: data)

                await MainActor.run {
                    image = uiImage
                    if let coordinate {
                        onCoordinateFound(coordinate)
                    }
                    selectedItem = nil
                }
            }
        }
    }
}
