//
//  PhotoPickerView.swift
//  TravelPin
//
//  Created by longanh on 14/5/26.
//

import SwiftUI
import PhotosUI

struct PhotoPickerView: View {
    @Binding var image: UIImage?
    @State private var selectedItem: PhotosPickerItem? = nil

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

                await MainActor.run {
                    image = uiImage
                    selectedItem = nil
                }
            }
        }
    }
}
