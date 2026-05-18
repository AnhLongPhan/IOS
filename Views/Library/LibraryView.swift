import AVKit
import SwiftUI
import UIKit

struct MomentGroup: Identifiable, Hashable {
    let id: String
    let title: String
    let subtitle: String
    let icon: String
    let checkIns: [CheckIn]

    var photoCount: Int {
        checkIns.filter { $0.photoPath != nil }.count
    }

    var coverPhotoPath: String? {
        checkIns.first { $0.photoPath != nil }?.photoPath
    }
}

struct LibraryView: View {
    @Environment(CheckInViewModel.self) private var viewModel
    @Environment(UserProfileStore.self) private var userProfileStore

    private let imageService = ImageStorageService()
    private let videoLibraryService = MomentVideoLibraryService()

    @State private var savedVideos: [SavedMomentVideo] = []
    @State private var shareItem: ShareItem? = nil
    @State private var showDeleteAllVideosConfirm = false
    @State private var alertMessage: AlertMessage? = nil
    @State private var creatingMomentID: MomentGroup.ID? = nil
    @State private var videoStatusMessage: String? = nil
    @State private var editingVideo: SavedMomentVideo? = nil
    @State private var editingVideoTitle = ""

    private var moments: [MomentGroup] {
        buildMoments()
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 16) {
                    if let videoStatusMessage {
                        HStack(spacing: 10) {
                            ProgressView()
                                .opacity(creatingMomentID == nil ? 0 : 1)

                            Text(videoStatusMessage)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .lineLimit(2)

                            Spacer()
                        }
                        .padding(12)
                        .background(Color(.systemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .padding(.horizontal)
                    }

                    if !savedVideos.isEmpty {
                        HStack {
                            Text("Video đã tạo")
                                .font(.headline)

                            Spacer()

                            Button(role: .destructive) {
                                showDeleteAllVideosConfirm = true
                            } label: {
                                Label("Xoá tất cả", systemImage: "trash")
                                    .font(.caption)
                            }
                        }
                        .padding(.horizontal)

                        ForEach(savedVideos) { video in
                            NavigationLink(value: video) {
                                SavedMomentVideoRow(
                                    video: video,
                                    onShare: {
                                        shareItem = ShareItem(url: video.url)
                                    },
                                    onEdit: {
                                        beginEditing(video)
                                    },
                                    onDelete: {
                                        deleteVideo(video)
                                    }
                                )
                            }
                            .buttonStyle(.plain)
                            .padding(.horizontal)
                        }
                    }

                    if moments.isEmpty {
                        ContentUnavailableView(
                            "Chưa có khoảnh khắc",
                            systemImage: "photo.stack",
                            description: Text("Thêm địa điểm có ảnh để tạo moment theo phân loại.")
                        )
                        .padding(.top, 60)
                    } else {
                        Text("Khoảnh khắc")
                            .font(.headline)
                            .padding(.horizontal)

                        LazyVStack(spacing: 14) {
                            ForEach(moments) { moment in
                                MomentCardView(
                                    moment: moment,
                                    isCreatingVideo: creatingMomentID == moment.id,
                                    isCreateDisabled: creatingMomentID != nil,
                                    onCreateVideo: {
                                        createVideo(for: moment)
                                    }
                                )
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.vertical, 12)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Library")
            .onAppear {
                reloadSavedVideos()
            }
            .sheet(item: $shareItem) { item in
                ShareSheet(items: [item.url])
            }
            .sheet(item: $editingVideo) { video in
                EditSavedVideoTitleView(
                    title: $editingVideoTitle,
                    videoTitle: video.title,
                    onCancel: {
                        editingVideo = nil
                    },
                    onSave: {
                        renameVideo(video)
                    }
                )
            }
            .confirmationDialog(
                "Xoá tất cả video?",
                isPresented: $showDeleteAllVideosConfirm,
                titleVisibility: .visible
            ) {
                Button("Xoá tất cả", role: .destructive) {
                    deleteAllVideos()
                }
                Button("Huỷ", role: .cancel) {}
            } message: {
                Text("Chỉ xoá các video đã tạo, không xoá ảnh hoặc địa điểm.")
            }
            .alert(item: $alertMessage) { message in
                Alert(
                    title: Text(message.title),
                    message: Text(message.detail),
                    dismissButton: .default(Text("OK"))
                )
            }
            .navigationDestination(for: MomentGroup.self) { moment in
                MomentDetailView(moment: moment)
            }
            .navigationDestination(for: SavedMomentVideo.self) { video in
                SavedMomentVideoPlayerView(video: video)
            }
        }
    }

    private func buildMoments() -> [MomentGroup] {
        let checkInsWithPhotos = viewModel.checkIns
            .filter { $0.photoPath != nil }
            .filter(isVisibleCategory)

        let grouped = Dictionary(grouping: checkInsWithPhotos) { checkIn in
            MomentKey(
                categoryID: categoryID(for: checkIn)
            )
        }

        return grouped.values.compactMap { items in
            let sorted = items.sorted { $0.visitedAt > $1.visitedAt }
            guard let first = sorted.first else { return nil }
            let category = userProfileStore.categoryName(for: first)
            let title = category
            let subtitle = "\(dateRangeTitle(for: sorted)) • \(locationsTitle(for: sorted)) • \(sorted.count) địa điểm"

            return MomentGroup(
                id: categoryID(for: first),
                title: title,
                subtitle: subtitle,
                icon: userProfileStore.categoryIcon(for: first),
                checkIns: sorted
            )
        }
        .sorted { lhs, rhs in
            guard let lhsDate = lhs.checkIns.first?.visitedAt,
                  let rhsDate = rhs.checkIns.first?.visitedAt else {
                return lhs.title < rhs.title
            }
            return lhsDate > rhsDate
        }
    }

    private func isVisibleCategory(_ checkIn: CheckIn) -> Bool {
        if let customPlaceCategoryID = checkIn.customPlaceCategoryID {
            return userProfileStore.customCategory(id: customPlaceCategoryID) != nil
        }

        return userProfileStore.enabledPlaceTypes.contains(checkIn.placeType)
    }

    private func categoryID(for checkIn: CheckIn) -> String {
        if let customPlaceCategoryID = checkIn.customPlaceCategoryID {
            return "custom-\(customPlaceCategoryID.uuidString)"
        }
        return "builtIn-\(checkIn.placeType.rawValue)"
    }

    private func momentLocation(for checkIn: CheckIn) -> String {
        if !checkIn.city.isEmpty { return checkIn.city }
        if !checkIn.country.isEmpty { return checkIn.country }
        return "Không rõ vị trí"
    }

    private func dateRangeTitle(for checkIns: [CheckIn]) -> String {
        guard let firstDate = checkIns.map(\.visitedAt).min(),
              let lastDate = checkIns.map(\.visitedAt).max() else {
            return "Không rõ thời gian"
        }
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "vi_VN")
        formatter.dateFormat = "MM/yyyy"

        if Calendar.current.isDate(firstDate, equalTo: lastDate, toGranularity: .month) {
            return formatter.string(from: firstDate)
        }

        return "\(formatter.string(from: firstDate)) - \(formatter.string(from: lastDate))"
    }

    private func locationsTitle(for checkIns: [CheckIn]) -> String {
        let locations = Array(Set(checkIns.map(momentLocation(for:)))).sorted()
        if locations.isEmpty {
            return "Không rõ vị trí"
        }
        if locations.count <= 2 {
            return locations.joined(separator: ", ")
        }
        return "\(locations[0]), \(locations[1]) +\(locations.count - 2)"
    }

    private func reloadSavedVideos() {
        savedVideos = videoLibraryService.loadVideos(for: userProfileStore.activeUserID)
    }

    private func beginEditing(_ video: SavedMomentVideo) {
        editingVideoTitle = video.title
        editingVideo = video
    }

    private func renameVideo(_ video: SavedMomentVideo) {
        do {
            _ = try videoLibraryService.rename(video, to: editingVideoTitle)
            editingVideo = nil
            editingVideoTitle = ""
            reloadSavedVideos()
        } catch {
            alertMessage = AlertMessage(title: "Không thể đổi tên video", detail: error.localizedDescription)
        }
    }

    private func deleteVideo(_ video: SavedMomentVideo) {
        do {
            try videoLibraryService.delete(video)
            reloadSavedVideos()
        } catch {
            alertMessage = AlertMessage(title: "Không thể xoá video", detail: error.localizedDescription)
        }
    }

    private func deleteAllVideos() {
        do {
            try videoLibraryService.deleteAll(for: userProfileStore.activeUserID)
            reloadSavedVideos()
        } catch {
            alertMessage = AlertMessage(title: "Không thể xoá video", detail: error.localizedDescription)
        }
    }

    private func createVideo(for moment: MomentGroup) {
        guard creatingMomentID == nil else { return }

        creatingMomentID = moment.id
        videoStatusMessage = "Đang tạo video \(moment.title)... Bạn vẫn có thể dùng các màn hình khác."

        let activeUserID = userProfileStore.activeUserID
        let title = moment.title
        let subtitle = moment.subtitle
        let checkIns = moment.checkIns

        Task.detached(priority: .background) {
            do {
                let temporaryURL = try await MomentVideoService().createVideo(
                    title: title,
                    subtitle: subtitle,
                    checkIns: checkIns
                )

                _ = try await MomentVideoLibraryService().saveVideo(
                    from: temporaryURL,
                    title: title,
                    for: activeUserID
                )

                await MainActor.run {
                    reloadSavedVideos()
                    let successMessage = "Đã tạo video \(title)."
                    videoStatusMessage = successMessage
                    creatingMomentID = nil

                    Task {
                        try? await Task.sleep(for: .seconds(3))
                        await MainActor.run {
                            if videoStatusMessage == successMessage {
                                videoStatusMessage = nil
                            }
                        }
                    }
                }
            } catch {
                await MainActor.run {
                    alertMessage = AlertMessage(
                        title: "Không thể tạo video",
                        detail: error.localizedDescription
                    )
                    videoStatusMessage = nil
                    creatingMomentID = nil
                }
            }
        }
    }
}

private struct MomentKey: Hashable {
    let categoryID: String
}

struct MomentCardView: View {
    let moment: MomentGroup
    let isCreatingVideo: Bool
    let isCreateDisabled: Bool
    let onCreateVideo: () -> Void

    private let imageService = ImageStorageService()

    var body: some View {
        VStack(spacing: 10) {
            NavigationLink(value: moment) {
                HStack(spacing: 12) {
                    ZStack(alignment: .bottomTrailing) {
                        if let coverPhotoPath = moment.coverPhotoPath,
                           let image = imageService.load(filename: coverPhotoPath) {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 92, height: 92)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                        } else {
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color.blue.opacity(0.12))
                                .frame(width: 92, height: 92)
                                .overlay {
                                    Image(systemName: moment.icon)
                                        .font(.title2)
                                        .foregroundStyle(.blue)
                                }
                        }

                        Text("\(moment.photoCount)")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundStyle(.white)
                            .padding(.horizontal, 7)
                            .padding(.vertical, 4)
                            .background(.black.opacity(0.55))
                            .clipShape(Capsule())
                            .padding(6)
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        Label(moment.title, systemImage: moment.icon)
                            .font(.headline)
                            .lineLimit(2)

                        Text(moment.subtitle)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                        Text(moment.checkIns.map(\.name).prefix(3).joined(separator: " • "))
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                            .lineLimit(1)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }
            .buttonStyle(.plain)

            Button(action: onCreateVideo) {
                HStack {
                    if isCreatingVideo {
                        ProgressView()
                    } else {
                        Image(systemName: "film.fill")
                    }
                    Text(isCreatingVideo ? "Đang tạo video..." : "Tạo video")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .disabled(isCreateDisabled || moment.photoCount == 0)
        }
        .padding(12)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct SavedMomentVideoRow: View {
    let video: SavedMomentVideo
    let onShare: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "play.rectangle.fill")
                .font(.title2)
                .foregroundStyle(.blue)
                .frame(width: 52, height: 52)
                .background(Color.blue.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 10))

            VStack(alignment: .leading, spacing: 4) {
                Text(video.title)
                    .font(.headline)
                    .lineLimit(1)

                Text(video.createdAt.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button(action: onShare) {
                Image(systemName: "square.and.arrow.up")
                    .frame(width: 32, height: 32)
            }
            .buttonStyle(.plain)

            Button(action: onEdit) {
                Image(systemName: "pencil")
                    .frame(width: 32, height: 32)
            }
            .buttonStyle(.plain)

            Button(role: .destructive, action: onDelete) {
                Image(systemName: "trash")
                    .frame(width: 32, height: 32)
            }
            .buttonStyle(.plain)
        }
        .padding(12)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct EditSavedVideoTitleView: View {
    @Binding var title: String
    let videoTitle: String
    let onCancel: () -> Void
    let onSave: () -> Void

    var body: some View {
        NavigationStack {
            Form {
                Section("Tên video") {
                    TextField("Nhập tên video", text: $title)
                        .textInputAutocapitalization(.words)
                }
            }
            .navigationTitle("Chỉnh sửa video")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Huỷ", action: onCancel)
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Cập nhật", action: onSave)
                        .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .onAppear {
                if title.isEmpty {
                    title = videoTitle
                }
            }
        }
        .presentationDetents([.height(220)])
    }
}

struct SavedMomentVideoPlayerView: View {
    let video: SavedMomentVideo

    @State private var player: AVPlayer
    @State private var shareItem: ShareItem? = nil

    init(video: SavedMomentVideo) {
        self.video = video
        _player = State(initialValue: AVPlayer(url: video.url))
    }

    var body: some View {
        VStack(spacing: 0) {
            VideoPlayer(player: player)
                .background(.black)
                .onAppear {
                    player.seek(to: .zero)
                    player.play()
                }
                .onDisappear {
                    player.pause()
                }

            VStack(alignment: .leading, spacing: 12) {
                Text(video.title)
                    .font(.headline)

                Text(video.createdAt.formatted(date: .abbreviated, time: .shortened))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Button {
                    shareItem = ShareItem(url: video.url)
                } label: {
                    Label("Chia sẻ video", systemImage: "square.and.arrow.up")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.blue)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
            }
            .padding()
            .background(Color(.systemBackground))
        }
        .navigationTitle("Video")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $shareItem) { item in
            ShareSheet(items: [item.url])
        }
    }
}

struct MomentDetailView: View {
    let moment: MomentGroup

    @State private var currentIndex = 0
    @State private var slideProgress: Double = 0
    @State private var isPlaying = true
    @State private var playbackTask: Task<Void, Never>? = nil

    private let imageService = ImageStorageService()
    private let slideDuration: Double = 2.0

    private var playableCheckIns: [CheckIn] {
        moment.checkIns.filter { $0.photoPath != nil }
    }

    private var currentCheckIn: CheckIn? {
        guard !playableCheckIns.isEmpty else { return nil }
        return playableCheckIns[min(currentIndex, playableCheckIns.count - 1)]
    }

    var body: some View {
        VStack(spacing: 0) {
            ZStack(alignment: .top) {
                if let currentCheckIn {
                    MomentSlideView(checkIn: currentCheckIn)
                        .id(currentCheckIn.id)
                        .transition(.opacity)
                } else {
                    Color.black
                }

                MomentProgressBar(
                    count: playableCheckIns.count,
                    currentIndex: currentIndex,
                    progress: slideProgress
                )
                .padding(.horizontal, 14)
                .padding(.top, 12)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 420)
            .clipShape(RoundedRectangle(cornerRadius: 18))
            .padding(.horizontal)
            .padding(.top, 12)
            .animation(.easeInOut(duration: 0.25), value: currentIndex)
            .background(Color(.systemGroupedBackground))
            .contentShape(Rectangle())
            .onTapGesture {
                togglePlayback()
            }

            VStack(alignment: .leading, spacing: 12) {
                Label(moment.title, systemImage: moment.icon)
                    .font(.headline)

                Text(moment.subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                HStack(spacing: 14) {
                    Button {
                        previousSlide()
                    } label: {
                        Image(systemName: "backward.fill")
                            .font(.system(size: 16, weight: .semibold))
                            .frame(width: 46, height: 42)
                    }
                    .buttonStyle(.bordered)
                    .disabled(playableCheckIns.count < 2)

                    Button {
                        togglePlayback()
                    } label: {
                        Label(isPlaying ? "Tạm dừng" : "Phát", systemImage: isPlaying ? "pause.fill" : "play.fill")
                            .font(.system(.body, weight: .semibold))
                            .frame(maxWidth: .infinity)
                            .frame(height: 42)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(isPlaying ? .orange : .blue)

                    Button {
                        nextSlide(resetProgress: true)
                    } label: {
                        Image(systemName: "forward.fill")
                            .font(.system(size: 16, weight: .semibold))
                            .frame(width: 46, height: 42)
                    }
                    .buttonStyle(.bordered)
                    .disabled(playableCheckIns.count < 2)
                }
            }
            .padding()
            .background(Color(.systemBackground))
        }
        .navigationTitle("Moment")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            startPlayback()
        }
        .onDisappear {
            stopPlayback()
        }
    }

    private func togglePlayback() {
        isPlaying.toggle()
        if isPlaying {
            startPlayback()
        } else {
            stopPlayback()
        }
    }

    private func startPlayback() {
        guard playbackTask == nil, playableCheckIns.count > 0 else { return }
        isPlaying = true
        playbackTask = Task {
            while !Task.isCancelled {
                try? await Task.sleep(for: .milliseconds(50))
                guard !Task.isCancelled else { break }

                await MainActor.run {
                    guard isPlaying else { return }
                    slideProgress += 0.05 / slideDuration

                    if slideProgress >= 1 {
                        nextSlide(resetProgress: true)
                    }
                }
            }
        }
    }

    private func stopPlayback() {
        playbackTask?.cancel()
        playbackTask = nil
    }

    private func previousSlide() {
        guard !playableCheckIns.isEmpty else { return }
        currentIndex = currentIndex == 0 ? playableCheckIns.count - 1 : currentIndex - 1
        slideProgress = 0
    }

    private func nextSlide(resetProgress: Bool) {
        guard !playableCheckIns.isEmpty else { return }
        currentIndex = (currentIndex + 1) % playableCheckIns.count
        if resetProgress {
            slideProgress = 0
        }
    }

}

struct MomentProgressBar: View {
    let count: Int
    let currentIndex: Int
    let progress: Double

    var body: some View {
        HStack(spacing: 5) {
            ForEach(0..<max(count, 1), id: \.self) { index in
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(.white.opacity(0.28))

                        Capsule()
                            .fill(.white)
                            .frame(width: geometry.size.width * fillAmount(for: index))
                    }
                }
                .frame(height: 4)
            }
        }
    }

    private func fillAmount(for index: Int) -> Double {
        if index < currentIndex { return 1 }
        if index == currentIndex { return min(max(progress, 0), 1) }
        return 0
    }
}

struct MomentSlideView: View {
    let checkIn: CheckIn
    private let imageService = ImageStorageService()

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            Color.black
            if let photoPath = checkIn.photoPath,
               let image = imageService.load(filename: photoPath) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                Color.black
            }

            LinearGradient(
                colors: [.clear, .black.opacity(0.75)],
                startPoint: .center,
                endPoint: .bottom
            )

            VStack(alignment: .leading, spacing: 6) {
                Text(checkIn.name)
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
                    .lineLimit(2)

                Text("\(checkIn.formattedDate) • \(checkIn.locationDisplay)")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.85))
                    .lineLimit(2)
            }
            .padding()
        }
    }
}

#Preview {
    LibraryView()
        .environment(CheckInViewModel())
        .environment(UserProfileStore())
}
