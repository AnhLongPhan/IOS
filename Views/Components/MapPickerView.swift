import SwiftUI
import MapKit

struct MapPickerView: View {
    @Environment(\.dismiss) var dismiss

    var initialCoordinate: CLLocationCoordinate2D? = nil
    var onSelect: (CLLocationCoordinate2D) -> Void

    @State private var cameraPosition: MapCameraPosition
    @State private var selectedCoord: CLLocationCoordinate2D?
    @State private var isMapReady = false

    init(
        initialCoordinate: CLLocationCoordinate2D? = nil,
        onSelect: @escaping (CLLocationCoordinate2D) -> Void
    ) {
        self.initialCoordinate = initialCoordinate
        self.onSelect = onSelect

        let center = initialCoordinate ?? CLLocationCoordinate2D(
            latitude: 14.0583,
            longitude: 108.2772
        )
        let span = MKCoordinateSpan(
            latitudeDelta: initialCoordinate == nil ? 12 : 0.02,
            longitudeDelta: initialCoordinate == nil ? 12 : 0.02
        )

        _cameraPosition = State(initialValue: .region(
            MKCoordinateRegion(center: center, span: span)
        ))
        _selectedCoord = State(initialValue: initialCoordinate)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                // Map
                MapReader { proxy in
                    Map(position: $cameraPosition) {
                        // Hiện pin tại vị trí đã chọn
                        if let coord = selectedCoord {
                            Annotation("", coordinate: coord) {
                                ZStack {
                                    Circle()
                                        .fill(.white)
                                        .frame(width: 36, height: 36)
                                        .shadow(radius: 4)
                                    Image(systemName: "mappin.fill")
                                        .foregroundStyle(.red)
                                        .font(.system(size: 18))
                                }
                            }
                        }
                    }
                    .ignoresSafeArea()
                    .onTapGesture { screenPoint in
                        if let coord = proxy.convert(
                            screenPoint, from: .local
                        ) {
                            withAnimation(.spring(duration: 0.3)) {
                                selectedCoord = coord
                            }
                        }
                    }
                }

                // Hướng dẫn phía trên
                VStack {
                    Text(selectedCoord == nil
                         ? "Tap vào bản đồ để chọn vị trí"
                         : String(format: "%.4f, %.4f",
                                  selectedCoord!.latitude,
                                  selectedCoord!.longitude))
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(.ultraThinMaterial)
                        .clipShape(Capsule())
                        .padding(.top, 12)

                    Spacer()
                }

                if !isMapReady {
                    ProgressView("Đang tải bản đồ...")
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
            .navigationTitle("Chọn vị trí")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Huỷ") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Chọn") {
                        if let coord = selectedCoord {
                            onSelect(coord)
                            dismiss()
                        }
                    }
                    .fontWeight(.semibold)
                    .disabled(selectedCoord == nil || !isMapReady)
                }
            }
            .interactiveDismissDisabled(!isMapReady)
            .task {
                try? await Task.sleep(for: .milliseconds(500))
                isMapReady = true
            }
        }
    }
}

#Preview {
    MapPickerView { coord in
        print("Selected: \(coord)")
    }
}
