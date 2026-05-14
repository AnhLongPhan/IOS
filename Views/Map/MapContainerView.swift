import SwiftUI
import MapKit

struct MapContainerView: View {
    @Environment(CheckInViewModel.self) var viewModel
    @Environment(LocationService.self) var locationService
    @AppStorage("defaultMapVN") var defaultMapVN: Bool = true

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
    @State private var selectedAnnotationID: CheckIn.ID? = nil
    @State private var navigationPath: [CheckIn] = []
    @State private var showRouteLine = false

    private var routeCheckIns: [CheckIn] {
        viewModel.checkIns.sorted { $0.visitedAt < $1.visitedAt }
    }

    private var routeCoordinates: [CLLocationCoordinate2D] {
        NationalHighway1APath.coordinates(for: routeCheckIns)
    }

    var body: some View {
        NavigationStack(path: $navigationPath) {
            ZStack(alignment: .bottomTrailing) {
            // MARK: - Bản đồ
            MapReader { proxy in
                Map(position: $cameraPosition) {
                    if showRouteLine && routeCoordinates.count > 1 {
                        MapPolyline(coordinates: routeCoordinates)
                            .stroke(.blue, lineWidth: 4)
                    }

                    if showRouteLine {
                        ForEach(Array(routeCheckIns.enumerated()), id: \.element.id) { index, checkIn in
                            Annotation(
                                checkIn.name,
                                coordinate: CLLocationCoordinate2D(
                                    latitude: checkIn.latitude,
                                    longitude: checkIn.longitude
                                )
                            ) {
                                RouteNumberAnnotationView(
                                    number: index + 1,
                                    isSelected: selectedAnnotationID == checkIn.id
                                ) {
                                    withAnimation(.spring(duration: 0.3)) {
                                        selectedAnnotationID = selectedAnnotationID == checkIn.id ? nil : checkIn.id
                                    }
                                }
                                .highPriorityGesture(
                                    TapGesture(count: 2)
                                        .onEnded {
                                            selectedAnnotationID = nil
                                            navigationPath.append(checkIn)
                                        }
                                )
                            }
                        }
                    } else {
                        ForEach(viewModel.checkIns) { checkIn in
                            Annotation(
                                checkIn.name,
                                coordinate: CLLocationCoordinate2D(
                                    latitude: checkIn.latitude,
                                    longitude: checkIn.longitude
                                )
                            ) {
                                CheckInAnnotationView(
                                    checkIn: checkIn,
                                    isTitleVisible: selectedAnnotationID == checkIn.id,
                                    onTap: {
                                        withAnimation(.spring(duration: 0.3)) {
                                            selectedAnnotationID = selectedAnnotationID == checkIn.id ? nil : checkIn.id
                                        }
                                    },
                                    onDoubleTap: {
                                        selectedAnnotationID = nil
                                        navigationPath.append(checkIn)
                                    }
                                )
                            }
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
                    selectedAnnotationID = nil
                    showAddSheet = true
                }
                .onAppear {
                    locationService.requestPermission()
                    if !defaultMapVN {
                        // Zoom ra thế giới
                        withAnimation {
                            cameraPosition = .region(
                                MKCoordinateRegion(
                                    center: CLLocationCoordinate2D(
                                        latitude: 20,
                                        longitude: 0
                                    ),
                                    span: MKCoordinateSpan(
                                        latitudeDelta: 120,
                                        longitudeDelta: 120
                                    )
                                )
                            )
                        }
                    }
                }
            }

            // MARK: - Nút điều khiển
            VStack(spacing: 12) {
                // Nút + thêm checkin
                Button {
                    selectedCoordinate = nil
                    selectedAnnotationID = nil
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

                // Nút bật/tắt đường đi
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        showRouteLine.toggle()
                        selectedAnnotationID = nil
                    }
                } label: {
                    Image(systemName: "point.topleft.down.curvedto.point.bottomright.up")
                        .font(.system(size: 18))
                        .foregroundStyle(showRouteLine ? .white : .blue)
                        .frame(width: 44, height: 44)
                        .background(showRouteLine ? .blue : .white)
                        .clipShape(Circle())
                        .shadow(radius: 3)
                }

                // Nút điều hướng: zoom tới địa điểm đang chọn, hoặc về vị trí hiện tại
                Button {
                    moveToSelectedCheckInOrUserLocation()
                } label: {
                    Image(systemName: selectedAnnotationID == nil ? "location.fill" : "mappin.and.ellipse")
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
            .navigationDestination(for: CheckIn.self) { checkIn in
                DetailView(checkIn: checkIn)
                    .environment(viewModel)
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

    private func moveToSelectedCheckInOrUserLocation() {
        if let selectedAnnotationID,
           let selectedCheckIn = viewModel.checkIns.first(where: { $0.id == selectedAnnotationID }) {
            moveToCheckIn(selectedCheckIn)
            return
        }

        moveToUserLocation()
    }

    private func moveToCheckIn(_ checkIn: CheckIn) {
        withAnimation(.easeInOut(duration: 0.8)) {
            cameraPosition = .region(
                MKCoordinateRegion(
                    center: CLLocationCoordinate2D(
                        latitude: checkIn.latitude,
                        longitude: checkIn.longitude
                    ),
                    span: MKCoordinateSpan(
                        latitudeDelta: 0.02,
                        longitudeDelta: 0.02
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

struct NationalHighway1APath {
    private static let highwayCoordinates: [CLLocationCoordinate2D] = [
        CLLocationCoordinate2D(latitude: 21.8550, longitude: 106.7570), // Hữu Nghị, Lạng Sơn
        CLLocationCoordinate2D(latitude: 21.2730, longitude: 106.1940), // Bắc Giang
        CLLocationCoordinate2D(latitude: 21.0285, longitude: 105.8542), // Hà Nội
        CLLocationCoordinate2D(latitude: 20.5453, longitude: 105.9122), // Phủ Lý
        CLLocationCoordinate2D(latitude: 20.2506, longitude: 105.9745), // Ninh Bình
        CLLocationCoordinate2D(latitude: 19.8067, longitude: 105.7852), // Thanh Hóa
        CLLocationCoordinate2D(latitude: 18.6796, longitude: 105.6813), // Vinh
        CLLocationCoordinate2D(latitude: 18.3428, longitude: 105.9057), // Hà Tĩnh
        CLLocationCoordinate2D(latitude: 17.4689, longitude: 106.6223), // Đồng Hới
        CLLocationCoordinate2D(latitude: 16.8163, longitude: 107.1003), // Đông Hà
        CLLocationCoordinate2D(latitude: 16.4637, longitude: 107.5909), // Huế
        CLLocationCoordinate2D(latitude: 16.0544, longitude: 108.2022), // Đà Nẵng
        CLLocationCoordinate2D(latitude: 15.5736, longitude: 108.4740), // Tam Kỳ
        CLLocationCoordinate2D(latitude: 15.1205, longitude: 108.7923), // Quảng Ngãi
        CLLocationCoordinate2D(latitude: 13.7820, longitude: 109.2190), // Quy Nhơn
        CLLocationCoordinate2D(latitude: 13.0955, longitude: 109.3209), // Tuy Hòa
        CLLocationCoordinate2D(latitude: 12.2388, longitude: 109.1967), // Nha Trang
        CLLocationCoordinate2D(latitude: 11.5643, longitude: 108.9886), // Phan Rang
        CLLocationCoordinate2D(latitude: 10.9804, longitude: 108.2615), // Phan Thiết
        CLLocationCoordinate2D(latitude: 10.9408, longitude: 107.2467), // Long Khánh
        CLLocationCoordinate2D(latitude: 10.8231, longitude: 106.6297), // TP.HCM
        CLLocationCoordinate2D(latitude: 10.5330, longitude: 106.4050), // Tân An
        CLLocationCoordinate2D(latitude: 10.3600, longitude: 106.3600), // Mỹ Tho
        CLLocationCoordinate2D(latitude: 10.0452, longitude: 105.7469), // Cần Thơ
        CLLocationCoordinate2D(latitude: 9.2941, longitude: 105.7278),  // Bạc Liêu
        CLLocationCoordinate2D(latitude: 9.1768, longitude: 105.1524)   // Cà Mau
    ]

    static func coordinates(for checkIns: [CheckIn]) -> [CLLocationCoordinate2D] {
        let stops = checkIns.map {
            CLLocationCoordinate2D(latitude: $0.latitude, longitude: $0.longitude)
        }

        guard stops.count > 1 else { return stops }

        var route: [CLLocationCoordinate2D] = []

        for index in 0..<(stops.count - 1) {
            let start = stops[index]
            let end = stops[index + 1]
            let startHighwayIndex = nearestHighwayIndex(to: start)
            let endHighwayIndex = nearestHighwayIndex(to: end)

            append(start, to: &route)
            append(highwayCoordinates[startHighwayIndex], to: &route)

            let segment = highwaySegment(from: startHighwayIndex, to: endHighwayIndex)
            for coordinate in segment {
                append(coordinate, to: &route)
            }

            append(highwayCoordinates[endHighwayIndex], to: &route)
            append(end, to: &route)
        }

        return route
    }

    private static func nearestHighwayIndex(to coordinate: CLLocationCoordinate2D) -> Int {
        highwayCoordinates.indices.min { lhs, rhs in
            approximateDistanceSquared(from: coordinate, to: highwayCoordinates[lhs]) <
            approximateDistanceSquared(from: coordinate, to: highwayCoordinates[rhs])
        } ?? 0
    }

    private static func highwaySegment(from startIndex: Int, to endIndex: Int) -> [CLLocationCoordinate2D] {
        if startIndex <= endIndex {
            return Array(highwayCoordinates[startIndex...endIndex])
        }

        return Array(highwayCoordinates[endIndex...startIndex].reversed())
    }

    private static func append(
        _ coordinate: CLLocationCoordinate2D,
        to route: inout [CLLocationCoordinate2D]
    ) {
        guard let last = route.last else {
            route.append(coordinate)
            return
        }

        if approximateDistanceSquared(from: last, to: coordinate) > 0.000001 {
            route.append(coordinate)
        }
    }

    private static func approximateDistanceSquared(
        from lhs: CLLocationCoordinate2D,
        to rhs: CLLocationCoordinate2D
    ) -> Double {
        let latitudeDelta = lhs.latitude - rhs.latitude
        let longitudeDelta = lhs.longitude - rhs.longitude
        return latitudeDelta * latitudeDelta + longitudeDelta * longitudeDelta
    }
}

struct RouteNumberAnnotationView: View {
    let number: Int
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            Text("\(number)")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundStyle(isSelected ? .white : .blue)
                .frame(width: isSelected ? 34 : 30, height: isSelected ? 34 : 30)
                .background(isSelected ? .blue : .white)
                .clipShape(Circle())
                .overlay(
                    Circle()
                        .stroke(.blue, lineWidth: 2)
                )
                .shadow(radius: 3)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    MapContainerView()
        .environment(CheckInViewModel())
        .environment(LocationService())
}
