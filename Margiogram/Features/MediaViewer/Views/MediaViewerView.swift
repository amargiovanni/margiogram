//
//  MediaViewerView.swift
//  Margiogram
//
//  Created by Andrea Margiovanni on 2024.
//

import SwiftUI
import AVKit

// MARK: - Media Viewer View

struct MediaViewerView: View {
    // MARK: - Properties

    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: MediaViewerViewModel

    private let initialIndex: Int

    // MARK: - Initialization

    init(items: [MediaItem], initialIndex: Int = 0) {
        self._viewModel = State(initialValue: MediaViewerViewModel())
        self.initialIndex = initialIndex
        viewModel.mediaItems = items
        viewModel.currentIndex = initialIndex
    }

    // MARK: - Body

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background
                Color.black
                    .ignoresSafeArea()

                // Media Content
                TabView(selection: $viewModel.currentIndex) {
                    ForEach(Array(viewModel.mediaItems.enumerated()), id: \.element.id) { index, item in
                        MediaContentView(
                            item: item,
                            viewModel: viewModel,
                            geometry: geometry
                        )
                        .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .onChange(of: viewModel.currentIndex) {
                    viewModel.resetZoom()
                    viewModel.stopPlayback()
                }

                // Controls Overlay
                if viewModel.showControls {
                    MediaControlsOverlay(viewModel: viewModel, dismiss: dismiss)
                }

                // Loading Indicator
                if viewModel.isLoading {
                    ProgressView()
                        .scaleEffect(1.5)
                        .tint(.white)
                }

                // Save Success Toast
                if viewModel.showSaveSuccess {
                    SaveSuccessToast()
                }
            }
        }
        .statusBarHidden(!viewModel.showControls)
        .persistentSystemOverlays(viewModel.showControls ? .visible : .hidden)
        .onTapGesture {
            viewModel.toggleControls()
        }
        .gesture(
            MagnificationGesture()
                .onChanged { value in
                    viewModel.updateZoom(value)
                }
                .onEnded { _ in
                    viewModel.endZoom()
                }
        )
        .simultaneousGesture(
            DragGesture()
                .onChanged { value in
                    if viewModel.scale > 1.0 {
                        viewModel.updateOffset(value.translation)
                    }
                }
                .onEnded { _ in
                    viewModel.endOffset()
                }
        )
        .sheet(isPresented: $viewModel.showShareSheet) {
            ShareSheet(items: viewModel.shareItems)
        }
        .task {
            await viewModel.downloadIfNeeded()
        }
    }
}

// MARK: - Media Content View

private struct MediaContentView: View {
    let item: MediaItem
    let viewModel: MediaViewerViewModel
    let geometry: GeometryProxy

    var body: some View {
        Group {
            switch item.type {
            case .photo:
                PhotoContentView(item: item, viewModel: viewModel, geometry: geometry)
            case .video:
                VideoContentView(item: item, viewModel: viewModel)
            case .gif:
                GifContentView(item: item, viewModel: viewModel, geometry: geometry)
            case .document:
                DocumentContentView(item: item)
            }
        }
    }
}

// MARK: - Photo Content View

private struct PhotoContentView: View {
    let item: MediaItem
    let viewModel: MediaViewerViewModel
    let geometry: GeometryProxy

    var body: some View {
        Group {
            if let url = item.localURL, let image = loadImage(from: url) {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .scaleEffect(viewModel.scale)
                    .offset(viewModel.offset)
            } else {
                // Placeholder
                ZStack {
                    if let aspectRatio = item.aspectRatio {
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .aspectRatio(aspectRatio, contentMode: .fit)
                    } else {
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: geometry.size.width, height: geometry.size.width)
                    }

                    Image(systemName: "photo")
                        .font(.system(size: 60))
                        .foregroundColor(.gray)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func loadImage(from url: URL) -> UIImage? {
        guard let data = try? Data(contentsOf: url) else { return nil }
        return UIImage(data: data)
    }
}

// MARK: - Video Content View

private struct VideoContentView: View {
    let item: MediaItem
    let viewModel: MediaViewerViewModel

    @State private var player: AVPlayer?

    var body: some View {
        ZStack {
            if let url = item.localURL {
                VideoPlayer(player: player)
                    .onAppear {
                        player = AVPlayer(url: url)
                    }
                    .onDisappear {
                        player?.pause()
                        player = nil
                    }
            } else {
                // Thumbnail placeholder
                ZStack {
                    if let thumbnail = item.thumbnail {
                        AsyncImage(url: thumbnail) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                        } placeholder: {
                            Color.gray.opacity(0.3)
                        }
                    } else {
                        Color.gray.opacity(0.3)
                    }

                    // Play button
                    Image(systemName: "play.circle.fill")
                        .font(.system(size: 80))
                        .foregroundStyle(.white.opacity(0.9))
                }
            }

            // Duration badge
            if let duration = item.formattedDuration {
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Text(duration)
                            .font(.caption)
                            .fontWeight(.medium)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(.black.opacity(0.6))
                            .cornerRadius(4)
                            .padding()
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onChange(of: viewModel.isPlaying) { _, isPlaying in
            if isPlaying {
                player?.play()
            } else {
                player?.pause()
            }
        }
    }
}

// MARK: - GIF Content View

private struct GifContentView: View {
    let item: MediaItem
    let viewModel: MediaViewerViewModel
    let geometry: GeometryProxy

    var body: some View {
        Group {
            if let url = item.localURL {
                // In real app: use animated image view
                AsyncImage(url: url) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .scaleEffect(viewModel.scale)
                        .offset(viewModel.offset)
                } placeholder: {
                    ProgressView()
                }
            } else {
                ZStack {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .aspectRatio(item.aspectRatio ?? 1, contentMode: .fit)

                    Image(systemName: "play.square")
                        .font(.system(size: 60))
                        .foregroundColor(.gray)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Document Content View

private struct DocumentContentView: View {
    let item: MediaItem

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "doc.fill")
                .font(.system(size: 80))
                .foregroundColor(.gray)

            if let caption = item.caption {
                Text(caption)
                    .font(.headline)
                    .foregroundColor(.white)
            }

            if let size = item.formattedSize {
                Text(size)
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
        }
    }
}

// MARK: - Media Controls Overlay

private struct MediaControlsOverlay: View {
    let viewModel: MediaViewerViewModel
    let dismiss: DismissAction

    var body: some View {
        VStack {
            // Top Bar
            HStack {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .padding(12)
                        .background(.ultraThinMaterial.opacity(0.8))
                        .clipShape(Circle())
                }

                Spacer()

                Text(viewModel.indexLabel)
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(.ultraThinMaterial.opacity(0.8))
                    .clipShape(Capsule())

                Spacer()

                Menu {
                    Button {
                        Task {
                            await viewModel.saveToPhotos()
                        }
                    } label: {
                        Label("Save to Photos", systemImage: "square.and.arrow.down")
                    }

                    Button {
                        viewModel.share()
                    } label: {
                        Label("Share", systemImage: "square.and.arrow.up")
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .padding(12)
                        .background(.ultraThinMaterial.opacity(0.8))
                        .clipShape(Circle())
                }
            }
            .padding()

            Spacer()

            // Bottom Bar
            VStack(spacing: 16) {
                // Caption
                if let item = viewModel.currentItem, let caption = item.caption {
                    Text(caption)
                        .font(.body)
                        .foregroundColor(.white)
                        .padding(.horizontal)
                        .multilineTextAlignment(.center)
                }

                // Video Controls
                if viewModel.currentItem?.type == .video {
                    VideoProgressBar(viewModel: viewModel)
                        .padding(.horizontal)
                }

                // Sender & Date Info
                if let item = viewModel.currentItem {
                    HStack {
                        if let sender = item.senderName {
                            Text(sender)
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.white.opacity(0.8))
                        }

                        Spacer()

                        Text(item.date.formatted(date: .abbreviated, time: .shortened))
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.6))
                    }
                    .padding(.horizontal)
                }
            }
            .padding(.bottom, 30)
            .background(
                LinearGradient(
                    colors: [.clear, .black.opacity(0.7)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
        }
        .transition(.opacity)
    }
}

// MARK: - Video Progress Bar

private struct VideoProgressBar: View {
    let viewModel: MediaViewerViewModel

    var body: some View {
        VStack(spacing: 8) {
            // Progress Slider
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background Track
                    Rectangle()
                        .fill(Color.white.opacity(0.3))
                        .frame(height: 4)

                    // Progress Track
                    Rectangle()
                        .fill(Color.white)
                        .frame(width: geometry.size.width * viewModel.playbackProgress, height: 4)
                }
                .cornerRadius(2)
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            let progress = max(0, min(1, value.location.x / geometry.size.width))
                            viewModel.seek(to: progress)
                        }
                )
            }
            .frame(height: 4)

            // Time Labels
            HStack {
                Text(viewModel.formattedCurrentTime)
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.8))

                Spacer()

                // Play/Pause Button
                Button {
                    viewModel.togglePlayback()
                } label: {
                    Image(systemName: viewModel.isPlaying ? "pause.fill" : "play.fill")
                        .font(.title2)
                        .foregroundColor(.white)
                }

                Spacer()

                Text(viewModel.formattedDuration)
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.8))
            }
        }
    }
}

// MARK: - Save Success Toast

private struct SaveSuccessToast: View {
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)

            Text("Saved to Photos")
                .font(.subheadline)
                .fontWeight(.medium)
        }
        .foregroundColor(.white)
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(.ultraThinMaterial)
        .clipShape(Capsule())
        .transition(.scale.combined(with: .opacity))
    }
}

// MARK: - Share Sheet

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - Preview

#Preview {
    MediaViewerView(items: MediaItem.mockGallery, initialIndex: 0)
}
