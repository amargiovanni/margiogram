//
//  MediaViewerViewModel.swift
//  Margiogram
//
//  Created by Andrea Margiovanni on 2024.
//

import Foundation
import SwiftUI
import Photos

// MARK: - Media Viewer ViewModel

@Observable
@MainActor
final class MediaViewerViewModel {
    // MARK: - Properties

    var mediaItems: [MediaItem] = []
    var currentIndex: Int = 0
    var isLoading: Bool = false
    var error: Error?

    // UI State
    var showControls: Bool = true
    var isPlaying: Bool = false
    var playbackProgress: Double = 0
    var currentTime: TimeInterval = 0
    var duration: TimeInterval = 0

    // Zoom State
    var scale: CGFloat = 1.0
    var offset: CGSize = .zero
    var lastScale: CGFloat = 1.0
    var lastOffset: CGSize = .zero

    // Save/Share State
    var isSaving: Bool = false
    var showSaveSuccess: Bool = false
    var showShareSheet: Bool = false

    // MARK: - Computed Properties

    var currentItem: MediaItem? {
        guard mediaItems.indices.contains(currentIndex) else { return nil }
        return mediaItems[currentIndex]
    }

    var hasNext: Bool {
        currentIndex < mediaItems.count - 1
    }

    var hasPrevious: Bool {
        currentIndex > 0
    }

    var indexLabel: String {
        "\(currentIndex + 1) / \(mediaItems.count)"
    }

    var formattedCurrentTime: String {
        formatTime(currentTime)
    }

    var formattedDuration: String {
        formatTime(duration)
    }

    // MARK: - Navigation

    func goToNext() {
        guard hasNext else { return }
        withAnimation(.easeInOut(duration: 0.3)) {
            currentIndex += 1
            resetZoom()
            stopPlayback()
        }
    }

    func goToPrevious() {
        guard hasPrevious else { return }
        withAnimation(.easeInOut(duration: 0.3)) {
            currentIndex -= 1
            resetZoom()
            stopPlayback()
        }
    }

    func goToIndex(_ index: Int) {
        guard mediaItems.indices.contains(index) else { return }
        withAnimation(.easeInOut(duration: 0.3)) {
            currentIndex = index
            resetZoom()
            stopPlayback()
        }
    }

    // MARK: - Controls

    func toggleControls() {
        withAnimation(.easeInOut(duration: 0.2)) {
            showControls.toggle()
        }
    }

    func hideControlsAfterDelay() {
        Task {
            try? await Task.sleep(for: .seconds(3))
            if showControls {
                withAnimation(.easeInOut(duration: 0.2)) {
                    showControls = false
                }
            }
        }
    }

    // MARK: - Playback (Video/Audio)

    func togglePlayback() {
        isPlaying.toggle()
        if isPlaying {
            hideControlsAfterDelay()
        }
    }

    func stopPlayback() {
        isPlaying = false
        playbackProgress = 0
        currentTime = 0
    }

    func seek(to progress: Double) {
        playbackProgress = progress
        currentTime = duration * progress
    }

    // MARK: - Zoom/Pan

    func resetZoom() {
        withAnimation(.spring(duration: 0.3)) {
            scale = 1.0
            offset = .zero
            lastScale = 1.0
            lastOffset = .zero
        }
    }

    func updateZoom(_ newScale: CGFloat) {
        let clampedScale = max(1.0, min(newScale * lastScale, 5.0))
        scale = clampedScale

        // Reset offset if zoomed out
        if clampedScale <= 1.0 {
            offset = .zero
            lastOffset = .zero
        }
    }

    func endZoom() {
        lastScale = scale
        if scale <= 1.0 {
            resetZoom()
        }
    }

    func updateOffset(_ newOffset: CGSize) {
        guard scale > 1.0 else { return }
        offset = CGSize(
            width: lastOffset.width + newOffset.width,
            height: lastOffset.height + newOffset.height
        )
    }

    func endOffset() {
        lastOffset = offset
    }

    // MARK: - Save to Photos

    func saveToPhotos() async {
        guard let item = currentItem else { return }

        isSaving = true
        defer { isSaving = false }

        do {
            // Request authorization
            let status = await PHPhotoLibrary.requestAuthorization(for: .addOnly)
            guard status == .authorized || status == .limited else {
                error = MediaViewerError.photoLibraryAccessDenied
                return
            }

            // Save based on type
            try await PHPhotoLibrary.shared().performChanges {
                switch item.type {
                case .photo:
                    if let url = item.localURL {
                        PHAssetChangeRequest.creationRequestForAssetFromImage(atFileURL: url)
                    }
                case .video:
                    if let url = item.localURL {
                        PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: url)
                    }
                default:
                    break
                }
            }

            showSaveSuccess = true

            // Hide success message after delay
            Task {
                try? await Task.sleep(for: .seconds(2))
                showSaveSuccess = false
            }

        } catch {
            self.error = error
        }
    }

    // MARK: - Share

    func share() {
        showShareSheet = true
    }

    var shareItems: [Any] {
        guard let item = currentItem else { return [] }

        if let url = item.localURL {
            return [url]
        } else if let remoteURL = item.remoteURL {
            return [remoteURL]
        }

        return []
    }

    // MARK: - Download

    func downloadIfNeeded() async {
        guard let item = currentItem,
              item.localURL == nil,
              item.remoteURL != nil else { return }

        isLoading = true
        defer { isLoading = false }

        // In real implementation: download from TDLib
        // For now, simulate loading
        try? await Task.sleep(for: .seconds(1))
    }

    // MARK: - Private Methods

    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

// MARK: - Media Item

struct MediaItem: Identifiable, Equatable, Hashable, Sendable {
    let id: String
    let type: MediaType
    let localURL: URL?
    let remoteURL: URL?
    let thumbnail: URL?
    let caption: String?
    let width: Int?
    let height: Int?
    let duration: TimeInterval?
    let fileSize: Int64?
    let senderName: String?
    let date: Date

    init(
        id: String = UUID().uuidString,
        type: MediaType,
        localURL: URL? = nil,
        remoteURL: URL? = nil,
        thumbnail: URL? = nil,
        caption: String? = nil,
        width: Int? = nil,
        height: Int? = nil,
        duration: TimeInterval? = nil,
        fileSize: Int64? = nil,
        senderName: String? = nil,
        date: Date = Date()
    ) {
        self.id = id
        self.type = type
        self.localURL = localURL
        self.remoteURL = remoteURL
        self.thumbnail = thumbnail
        self.caption = caption
        self.width = width
        self.height = height
        self.duration = duration
        self.fileSize = fileSize
        self.senderName = senderName
        self.date = date
    }

    var aspectRatio: CGFloat? {
        guard let width, let height, height > 0 else { return nil }
        return CGFloat(width) / CGFloat(height)
    }

    var formattedDuration: String? {
        guard let duration else { return nil }
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    var formattedSize: String? {
        guard let fileSize else { return nil }
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB, .useGB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: fileSize)
    }
}

// MARK: - Media Type

enum MediaType: String, CaseIterable, Sendable {
    case photo
    case video
    case gif
    case document

    var icon: String {
        switch self {
        case .photo:
            return "photo"
        case .video:
            return "video"
        case .gif:
            return "play.square"
        case .document:
            return "doc"
        }
    }
}

// MARK: - Media Viewer Error

enum MediaViewerError: LocalizedError {
    case photoLibraryAccessDenied
    case downloadFailed
    case fileNotFound

    var errorDescription: String? {
        switch self {
        case .photoLibraryAccessDenied:
            return "Photo library access denied"
        case .downloadFailed:
            return "Failed to download media"
        case .fileNotFound:
            return "File not found"
        }
    }
}

// MARK: - Mock Data

extension MediaItem {
    static func mock() -> MediaItem {
        MediaItem(
            type: .photo,
            caption: "Test photo",
            width: 1920,
            height: 1080,
            senderName: "John Doe"
        )
    }

    static var mockGallery: [MediaItem] {
        [
            MediaItem(type: .photo, caption: "Photo 1", width: 1920, height: 1080, senderName: "Alice"),
            MediaItem(type: .photo, caption: "Photo 2", width: 1080, height: 1920, senderName: "Bob"),
            MediaItem(type: .video, caption: "Video 1", width: 1920, height: 1080, duration: 120, senderName: "Alice"),
            MediaItem(type: .gif, width: 480, height: 480, senderName: "Charlie"),
            MediaItem(type: .photo, caption: "Photo 3", width: 1080, height: 1080, senderName: "David"),
        ]
    }
}
