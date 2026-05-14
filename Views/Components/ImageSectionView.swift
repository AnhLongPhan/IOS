//
//  ImageSectionView.swift
//  TravelPin
//
//  Created by longanh on 14/5/26.
//

import SwiftUI

struct ImageSectionView: View {
    @Binding var selectedImage: UIImage?
    @State private var showCamera = false
    @State private var showCameraUnavailable = false
    @State private var hasSelectedImage = false

    var body: some View {
        VStack(spacing: 12) {
            // Preview ảnh đã chọn
            if let image = selectedImage {
                ZStack(alignment: .topTrailing) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(maxWidth: .infinity)
                        .frame(height: 200)
                        .clipShape(RoundedRectangle(cornerRadius: 12))

                    // Nút xoá ảnh
                    Button {
                        selectedImage = nil
                        hasSelectedImage = false
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundStyle(.white)
                            .shadow(radius: 2)
                    }
                    .padding(8)
                }
            }

            // Nút chọn ảnh
            if !hasSelectedImage {
                HStack(spacing: 12) {
                    // Camera
                    Button {
                        if UIImagePickerController.isSourceTypeAvailable(.camera) {
                            showCamera = true
                        } else {
                            showCameraUnavailable = true
                        }
                    } label: {
                        Label("Chụp ảnh", systemImage: "camera.fill")
                            .lineLimit(1)
                            .minimumScaleFactor(0.85)
                            .frame(minWidth: 110, maxWidth: 135)
                            .padding(.vertical, 10)
                            .background(Color(.systemGray5))
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    }

                    // Thư viện
                    PhotoPickerView(image: $selectedImage)
                        .lineLimit(1)
                        .minimumScaleFactor(0.85)
                        .frame(minWidth: 145, maxWidth: 170)
                        .padding(.vertical, 10)
                        .background(Color(.systemGray5))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
            }
        }
        .sheet(isPresented: $showCamera) {
            ImagePickerView(image: $selectedImage, sourceType: .camera)
                .ignoresSafeArea()
        }
        .onAppear {
            hasSelectedImage = selectedImage != nil
        }
        .onChange(of: selectedImage != nil) { _, hasImage in
            hasSelectedImage = hasImage
            if hasImage {
                showCamera = false
            }
        }
        .alert("Camera không khả dụng",
               isPresented: $showCameraUnavailable) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Simulator không có camera. Hãy dùng thiết bị thật.")
        }
    }
}

#Preview {
    ImageSectionView(selectedImage: .constant(nil))
        .padding()
}
