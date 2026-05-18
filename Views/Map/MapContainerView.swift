import MapKit
import SwiftUI
import UIKit

struct MapContainerView: View {
    @Environment(CheckInViewModel.self) var viewModel
    @Environment(LocationService.self) var locationService
    @Environment(UserProfileStore.self) private var userProfileStore
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
    @State private var selectedClusterID: CheckInCluster.ID? = nil
    @State private var navigationPath: [CheckIn] = []
    @State private var showRouteLine = false
    @State private var visiblePlaceTypeFilterLabel: String? = nil
    @State private var hidePlaceTypeFilterLabelTask: Task<Void, Never>? = nil
    @State private var showNewUserConfirmation = false
    @State private var visibleRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 14.0583, longitude: 108.2772),
        span: MKCoordinateSpan(latitudeDelta: 12, longitudeDelta: 12)
    )

    private var routeCheckIns: [CheckIn] {
        viewModel.checkIns
            .filter { checkIn in
                checkIn.isVisited &&
                (viewModel.selectedPlaceType == nil || checkIn.placeType == viewModel.selectedPlaceType)
            }
            .sorted { $0.visitedAt < $1.visitedAt }
    }

    private var routeCoordinates: [CLLocationCoordinate2D] {
        NationalHighway1APath.coordinates(for: routeCheckIns)
    }

    private var checkInClusters: [CheckInCluster] {
        CheckInCluster.build(from: viewModel.filteredCheckIns, in: visibleRegion)
    }

    private var selectedCheckIn: CheckIn? {
        guard let selectedAnnotationID else { return nil }
        return viewModel.checkIns.first { $0.id == selectedAnnotationID }
    }

    private var selectedCluster: CheckInCluster? {
        guard let selectedClusterID else { return nil }
        return checkInClusters.first { $0.id == selectedClusterID }
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
                                        selectedClusterID = nil
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
                        ForEach(checkInClusters) { cluster in
                            Annotation(
                                cluster.title,
                                coordinate: cluster.coordinate
                            ) {
                                if cluster.isCluster {
                                    ClusterAnnotationView(
                                        count: cluster.checkIns.count,
                                        isSelected: selectedClusterID == cluster.id
                                    ) {
                                        withAnimation(.spring(duration: 0.3)) {
                                            selectedAnnotationID = nil
                                            selectedClusterID = selectedClusterID == cluster.id ? nil : cluster.id
                                        }

                                        if selectedClusterID == cluster.id {
                                            moveToCluster(cluster)
                                        }
                                    }
                                } else if let checkIn = cluster.checkIns.first {
                                    CheckInAnnotationView(
                                        checkIn: checkIn,
                                        isTitleVisible: selectedAnnotationID == checkIn.id,
                                        onTap: {
                                            withAnimation(.spring(duration: 0.3)) {
                                                selectedClusterID = nil
                                                selectedAnnotationID = selectedAnnotationID == checkIn.id ? nil : checkIn.id
                                            }
                                        },
                                        onDoubleTap: {
                                            selectedAnnotationID = nil
                                            selectedClusterID = nil
                                            navigationPath.append(checkIn)
                                        }
                                    )
                                }
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
                .onMapCameraChange(frequency: .onEnd) { context in
                    visibleRegion = context.region
                }
                .ignoresSafeArea()
                // Long press để chọn tọa độ
                .onLongPressGesture(minimumDuration: 0.5) {
                    selectedCoordinate = nil
                    selectedAnnotationID = nil
                    selectedClusterID = nil
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

            VStack {
                MapPlaceTypeFilterRail(
                    selectedPlaceType: viewModel.selectedPlaceType,
                    visibleLabel: visiblePlaceTypeFilterLabel,
                    placeTypes: userProfileStore.enabledPlaceTypes,
                    onSelect: updateMapPlaceTypeFilter
                )
                .padding(.top, 12)
                .padding(.leading, 12)

                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)

            // MARK: - Nút điều khiển
            VStack(spacing: 12) {
                // Nút + thêm checkin
                Button {
                    selectedCoordinate = nil
                    selectedAnnotationID = nil
                    selectedClusterID = nil
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

                Button {
                    showNewUserConfirmation = true
                } label: {
                    Text(userProfileStore.displayInitial)
                        .font(.system(size: 17, weight: .bold))
                        .foregroundStyle(.blue)
                        .frame(width: 44, height: 44)
                        .background(.white)
                        .clipShape(Circle())
                        .shadow(radius: 3)
                }

                // Nút bật/tắt đường đi
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        showRouteLine.toggle()
                        selectedAnnotationID = nil
                        selectedClusterID = nil
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
            .padding(.bottom, selectedCheckIn != nil || selectedCluster != nil ? 168 : 32)

            if let selectedCheckIn {
                CheckInPreviewSheet(
                    checkIn: selectedCheckIn,
                    onClose: clearSelection,
                    onOpenDetail: {
                        clearSelection()
                        navigationPath.append(selectedCheckIn)
                    }
                )
                .transition(.move(edge: .bottom).combined(with: .opacity))
            } else if let selectedCluster {
                ClusterPreviewSheet(
                    cluster: selectedCluster,
                    onClose: clearSelection,
                    onZoomIn: {
                        moveToCluster(selectedCluster)
                    },
                    onOpenFirst: {
                        guard let firstCheckIn = selectedCluster.checkIns.sorted(by: { $0.visitedAt > $1.visitedAt }).first else { return }
                        clearSelection()
                        navigationPath.append(firstCheckIn)
                    }
                )
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
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
            .confirmationDialog(
                "Tạo user mới?",
                isPresented: $showNewUserConfirmation,
                titleVisibility: .visible
            ) {
                Button("Thiết lập user mới") {
                    userProfileStore.startNewUserSetup()
                }
                Button("Huỷ", role: .cancel) {}
            } message: {
                Text("Bạn sẽ quay lại màn hình thiết lập ban đầu. Dữ liệu check-in hiện có vẫn được giữ nguyên.")
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

        if let selectedCluster {
            moveToCluster(selectedCluster)
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

    private func moveToCluster(_ cluster: CheckInCluster) {
        withAnimation(.easeInOut(duration: 0.8)) {
            cameraPosition = .region(cluster.zoomRegion)
        }
    }

    private func clearSelection() {
        withAnimation(.spring(duration: 0.25)) {
            selectedAnnotationID = nil
            selectedClusterID = nil
        }
    }

    private func updateMapPlaceTypeFilter(_ placeType: PlaceType?) {
        viewModel.selectedPlaceType = viewModel.selectedPlaceType == placeType ? nil : placeType
        let label = viewModel.selectedPlaceType?.rawValue ?? "Tất cả"

        withAnimation(.easeInOut(duration: 0.2)) {
            visiblePlaceTypeFilterLabel = label
            selectedAnnotationID = nil
            selectedClusterID = nil
        }

        hidePlaceTypeFilterLabelTask?.cancel()
        hidePlaceTypeFilterLabelTask = Task {
            try? await Task.sleep(for: .seconds(1.2))
            guard !Task.isCancelled else { return }

            await MainActor.run {
                withAnimation(.easeInOut(duration: 0.2)) {
                    visiblePlaceTypeFilterLabel = nil
                }
            }
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

struct CheckInCluster: Identifiable {
    let id: String
    let checkIns: [CheckIn]
    let coordinate: CLLocationCoordinate2D

    var isCluster: Bool {
        checkIns.count > 1
    }

    var title: String {
        if isCluster {
            return "\(checkIns.count) địa điểm"
        }

        return checkIns.first?.name ?? "Địa điểm"
    }

    var zoomRegion: MKCoordinateRegion {
        let latitudes = checkIns.map(\.latitude)
        let longitudes = checkIns.map(\.longitude)
        guard let minLatitude = latitudes.min(),
              let maxLatitude = latitudes.max(),
              let minLongitude = longitudes.min(),
              let maxLongitude = longitudes.max() else {
            return MKCoordinateRegion(
                center: coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
            )
        }

        let latitudeDelta = max((maxLatitude - minLatitude) * 2.4, 0.02)
        let longitudeDelta = max((maxLongitude - minLongitude) * 2.4, 0.02)

        return MKCoordinateRegion(
            center: coordinate,
            span: MKCoordinateSpan(latitudeDelta: latitudeDelta, longitudeDelta: longitudeDelta)
        )
    }

    static func build(from checkIns: [CheckIn], in region: MKCoordinateRegion) -> [CheckInCluster] {
        guard checkIns.count > 1 else {
            return checkIns.map { checkIn in
                CheckInCluster(
                    id: checkIn.id.uuidString,
                    checkIns: [checkIn],
                    coordinate: CLLocationCoordinate2D(latitude: checkIn.latitude, longitude: checkIn.longitude)
                )
            }
        }

        let cellLatitude = max(region.span.latitudeDelta / 8, 0.004)
        let cellLongitude = max(region.span.longitudeDelta / 8, 0.004)
        let buckets = Dictionary(grouping: checkIns) { checkIn in
            ClusterGridKey(
                latitude: Int((checkIn.latitude / cellLatitude).rounded(.down)),
                longitude: Int((checkIn.longitude / cellLongitude).rounded(.down))
            )
        }

        return buckets.values.map { bucket in
            let sortedBucket = bucket.sorted { $0.visitedAt > $1.visitedAt }
            let latitude = sortedBucket.map(\.latitude).reduce(0, +) / Double(sortedBucket.count)
            let longitude = sortedBucket.map(\.longitude).reduce(0, +) / Double(sortedBucket.count)
            let id = sortedBucket.map { $0.id.uuidString }.sorted().joined(separator: "-")

            return CheckInCluster(
                id: id,
                checkIns: sortedBucket,
                coordinate: CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
            )
        }
        .sorted { lhs, rhs in
            if lhs.isCluster != rhs.isCluster {
                return lhs.isCluster && !rhs.isCluster
            }

            return lhs.title < rhs.title
        }
    }
}

private struct ClusterGridKey: Hashable {
    let latitude: Int
    let longitude: Int
}

struct MapPlaceTypeFilterRail: View {
    let selectedPlaceType: PlaceType?
    let visibleLabel: String?
    let placeTypes: [PlaceType]
    let onSelect: (PlaceType?) -> Void

    private var visiblePlaceTypes: [PlaceType] {
        if let selectedPlaceType {
            return [selectedPlaceType]
        }

        return placeTypes
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            filterButton(
                label: "Tất cả",
                icon: "mappin.fill",
                isSelected: selectedPlaceType == nil
            ) {
                onSelect(nil)
            }

            ForEach(visiblePlaceTypes, id: \.self) { placeType in
                filterButton(
                    label: placeType.rawValue,
                    icon: placeType.icon,
                    isSelected: selectedPlaceType == placeType
                ) {
                    onSelect(placeType)
                }
            }
        }
    }

    private func filterButton(
        label: String,
        icon: String,
        isSelected: Bool,
        action: @escaping () -> Void
    ) -> some View {
        HStack(spacing: 8) {
            Button(action: action) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(isSelected ? .white : .blue)
                    .frame(width: 38, height: 38)
                    .background(isSelected ? .blue : Color(.systemBackground))
                    .clipShape(Circle())
                    .shadow(radius: 3)
            }
            .buttonStyle(.plain)

            if visibleLabel == label {
                Text(label)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 7)
                    .background(.thinMaterial)
                    .clipShape(Capsule())
                    .transition(.move(edge: .leading).combined(with: .opacity))
            }
        }
        .frame(height: 38, alignment: .leading)
        .fixedSize(horizontal: true, vertical: false)
    }
}

struct ClusterAnnotationView: View {
    let count: Int
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            ZStack {
                Circle()
                    .fill(isSelected ? .blue : .white)
                    .frame(width: isSelected ? 58 : 52, height: isSelected ? 58 : 52)
                    .shadow(radius: 4)

                Circle()
                    .stroke(isSelected ? .white : .blue, lineWidth: 3)
                    .frame(width: isSelected ? 50 : 44, height: isSelected ? 50 : 44)

                Text("\(count)")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundStyle(isSelected ? .white : .blue)
                    .minimumScaleFactor(0.7)
            }
        }
        .buttonStyle(.plain)
    }
}

struct CheckInPreviewSheet: View {
    let checkIn: CheckIn
    let onClose: () -> Void
    let onOpenDetail: () -> Void

    private let imageService = ImageStorageService()

    var body: some View {
        HStack(spacing: 14) {
            thumbnail

            VStack(alignment: .leading, spacing: 6) {
                Text(checkIn.name.isEmpty ? checkIn.locationDisplay : checkIn.name)
                    .font(.headline)
                    .lineLimit(1)

                Label(checkIn.addressDisplay, systemImage: "mappin.circle")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)

                HStack(spacing: 8) {
                    Label(checkIn.formattedDate, systemImage: "calendar")
                    Label(checkIn.isVisited ? "Đã đi" : "Muốn đi", systemImage: checkIn.isVisited ? "checkmark.circle.fill" : "bookmark.fill")
                        .foregroundStyle(statusColor)
                    Label(checkIn.placeType.rawValue, systemImage: checkIn.placeType.icon)
                }
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
            }

            Spacer(minLength: 8)

            VStack(spacing: 10) {
                Button(action: onClose) {
                    Image(systemName: "xmark")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundStyle(.secondary)
                        .frame(width: 30, height: 30)
                        .background(.thinMaterial)
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)

                Button(action: onOpenDetail) {
                    Image(systemName: "chevron.right")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                        .frame(width: 34, height: 34)
                        .background(.blue)
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(14)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(radius: 8)
        .padding(.horizontal, 16)
        .padding(.bottom, 24)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
    }

    @ViewBuilder
    private var thumbnail: some View {
        if let path = checkIn.photoPath,
           let image = imageService.load(filename: path) {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(width: 68, height: 68)
                .clipShape(RoundedRectangle(cornerRadius: 12))
        } else {
            RoundedRectangle(cornerRadius: 12)
                .fill(statusColor.opacity(0.16))
                .frame(width: 68, height: 68)
                .overlay {
                    Image(systemName: checkIn.isVisited ? checkIn.placeType.icon : "bookmark.fill")
                        .font(.title2)
                        .foregroundStyle(statusColor)
                }
        }
    }

    private var statusColor: Color {
        checkIn.isVisited ? placeTypeColor : .orange
    }

    private var placeTypeColor: Color {
        switch checkIn.placeType {
        case .travel: return .blue
        case .food: return .red
        case .checkIn: return .purple
        case .coffee: return .brown
        case .other: return .gray
        }
    }
}

struct ClusterPreviewSheet: View {
    let cluster: CheckInCluster
    let onClose: () -> Void
    let onZoomIn: () -> Void
    let onOpenFirst: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(cluster.checkIns.count) địa điểm gần nhau")
                        .font(.headline)

                    Text(cluster.checkIns.prefix(3).map(\.name).joined(separator: ", "))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                Spacer()

                Button(action: onClose) {
                    Image(systemName: "xmark")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundStyle(.secondary)
                        .frame(width: 30, height: 30)
                        .background(.thinMaterial)
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
            }

            HStack(spacing: 10) {
                Button(action: onZoomIn) {
                    Label("Phóng to", systemImage: "plus.magnifyingglass")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                }
                .buttonStyle(.borderedProminent)

                Button(action: onOpenFirst) {
                    Label("Mở gần nhất", systemImage: "chevron.right")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                }
                .buttonStyle(.bordered)
            }
        }
        .padding(14)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(radius: 8)
        .padding(.horizontal, 16)
        .padding(.bottom, 24)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
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
        .environment(UserProfileStore())
}
