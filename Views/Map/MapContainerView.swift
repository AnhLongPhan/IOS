import SwiftUI
import MapKit

struct MapContainerView: View {
    @Environment(CheckInViewModel.self) var viewModel
    @Environment(LocationService.self) var locationService

    @State private var cameraPosition: MapCameraPosition = .region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(
                latitude: 14.0583,
                longitude: 108.2772
            ),
            span: MKCoordinateSpan(
                latitudeDelta: 12,
                longitudeDelta: 12
            )
        )
    )
    @State private var showUserLocation = false
    @State private var showAddSheet = false
    @State private var selectedCoordinate: CLLocationCoordinate2D? = nil

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            // MARK: - Bản đồ
            MapReader { proxy in
                Map(position: $cameraPosition) {
                    ForEach(viewModel.checkIns) { checkIn in
                        Annotation(
                            checkIn.name,
                            coordinate: CLLocationCoordinate2D(
                                latitude: checkIn.latitude,
                                longitude: checkIn.longitude
                            )
                        ) {
                            CheckInAnnotationView(checkIn: checkIn)
                        }
                    }

                    if showUserLocation {
                        UserAnnotation()
                    }
                }
                .mapStyle(.standard(elevation: .realistic))
                .mapControls {
                    MapCompass()
                    MapScaleView()
                }
                .ignoresSafeArea()
                // Long press để chọn tọa độ
                .onLongPressGesture(minimumDuration: 0.5) {
                    selectedCoordinate = nil
                    showAddSheet = true
                }
            }

            // MARK: - Nút điều khiển
            VStack(spacing: 12) {
                // Nút + thêm checkin
                Button {
                    selectedCoordinate = nil
                    showAddSheet = true
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: 50, height: 50)
                        .background(.blue)
                        .clipShape(Circle())
                        .shadow(radius: 4)
                }

                // Nút vị trí hiện tại
                Button {
                    moveToUserLocation()
                } label: {
                    Image(systemName: "location.fill")
                        .font(.system(size: 18))
                        .foregroundStyle(.blue)
                        .frame(width: 44, height: 44)
                        .background(.white)
                        .clipShape(Circle())
                        .shadow(radius: 3)
                }

                // Nút về Việt Nam
                Button {
                    moveToVietnam()
                } label: {
                    Text("🇻🇳")
                        .font(.system(size: 22))
                        .frame(width: 44, height: 44)
                        .background(.white)
                        .clipShape(Circle())
                        .shadow(radius: 3)
                }
            }
            .padding(.trailing, 16)
            .padding(.bottom, 32)
        }
        .sheet(isPresented: $showAddSheet) {
            AddCheckInView(initialCoordinate: selectedCoordinate)
                .environment(viewModel)
        }
        .onAppear {
            locationService.requestPermission()
        }
        .onChange(of: locationService.authorizationStatus) { _, status in
            if status == .authorizedWhenInUse {
                showUserLocation = true
                moveToUserLocation()
            }
        }
    }

    // MARK: - Camera
    private func moveToVietnam() {
        withAnimation(.easeInOut(duration: 1.0)) {
            cameraPosition = .region(
                MKCoordinateRegion(
                    center: CLLocationCoordinate2D(
                        latitude: 14.0583,
                        longitude: 108.2772
                    ),
                    span: MKCoordinateSpan(
                        latitudeDelta: 12,
                        longitudeDelta: 12
                    )
                )
            )
        }
    }

    private func moveToUserLocation() {
        guard let location = locationService.userLocation else { return }
        withAnimation(.easeInOut(duration: 1.0)) {
            cameraPosition = .region(
                MKCoordinateRegion(
                    center: location,
                    span: MKCoordinateSpan(
                        latitudeDelta: 0.1,
                        longitudeDelta: 0.1
                    )
                )
            )
        }
    }
}

#Preview {
    MapContainerView()
        .environment(CheckInViewModel())
        .environment(LocationService())
}
