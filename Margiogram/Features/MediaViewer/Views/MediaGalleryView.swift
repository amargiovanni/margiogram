//
//  MediaGalleryView.swift
//  Margiogram
//
//  Created by Andrea Margiovanni on 2024.
//

import SwiftUI

// MARK: - Media Gallery View

/// Grid view for browsing media in a chat.
struct MediaGalleryView: View {
    // MARK: - Properties

    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: MediaGalleryViewModel

    @State private var selectedItem: MediaItem?
    @State private var showMediaViewer: Bool = false

    private let chatId: Int64
    private let chatTitle: String

    // MARK: - Initialization

    init(chatId: Int64, chatTitle: String) {
        self.chatId = chatId
        self.chatTitle = chatTitle
        self._viewModel = State(initialValue: MediaGalleryViewModel(chatId: chatId))
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading && viewModel.mediaItems.isEmpty {
                    loadingView
                } else if viewModel.mediaItems.isEmpty {
                    emptyView
                } else {
                    mediaGrid
                }
            }
            .navigationTitle("Media")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    filterMenu
                }
            }
        }
        .fullScreenCover(isPresented: $showMediaViewer) {
            if let item = selectedItem,
               let index = viewModel.mediaItems.firstIndex(of: item) {
                MediaViewerView(items: viewModel.mediaItems, initialIndex: index)
            }
        }
        .task {
            await viewModel.loadMedia()
        }
    }

    // MARK: - Media Grid

    private var mediaGrid: some View {
        ScrollView {
            LazyVGrid(
                columns: [
                    GridItem(.adaptive(minimum: 100, maximum: 150), spacing: 2)
                ],
                spacing: 2
            ) {
                ForEach(viewModel.filteredItems) { item in
                    MediaGridCell(item: item)
                        .onTapGesture {
                            selectedItem = item
                            showMediaViewer = true
                        }
                        .onAppear {
                            if item == viewModel.filteredItems.last {
                                Task {
                                    await viewModel.loadMoreMedia()
                                }
                            }
                        }
                }
            }
            .padding(2)

            if viewModel.isLoading && !viewModel.mediaItems.isEmpty {
                ProgressView()
                    .padding()
            }
        }
    }

    // MARK: - Loading View

    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
            Text("Loading media...")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }

    // MARK: - Empty View

    private var emptyView: some View {
        ContentUnavailableView {
            Label("No Media", systemImage: "photo.on.rectangle.angled")
        } description: {
            Text("No photos or videos in this chat yet.")
        }
    }

    // MARK: - Filter Menu

    private var filterMenu: some View {
        Menu {
            ForEach(MediaFilter.allCases, id: \.self) { filter in
                Button {
                    withAnimation {
                        viewModel.currentFilter = filter
                    }
                } label: {
                    HStack {
                        Text(filter.title)
                        if viewModel.currentFilter == filter {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
        } label: {
            HStack(spacing: 4) {
                Text(viewModel.currentFilter.title)
                    .font(.subheadline)
                Image(systemName: "chevron.down")
                    .font(.caption)
            }
        }
    }
}

// MARK: - Media Grid Cell

private struct MediaGridCell: View {
    let item: MediaItem

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Thumbnail
                if let thumbnail = item.thumbnail {
                    AsyncImage(url: thumbnail) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        placeholderView
                    }
                } else {
                    placeholderView
                }
            }
            .frame(width: geometry.size.width, height: geometry.size.width)
            .clipped()
            .overlay(alignment: .bottomTrailing) {
                // Type indicator
                typeIndicator
            }
        }
        .aspectRatio(1, contentMode: .fill)
    }

    private var placeholderView: some View {
        Rectangle()
            .fill(Color.gray.opacity(0.2))
            .overlay {
                Image(systemName: item.type.icon)
                    .font(.title2)
                    .foregroundColor(.gray)
            }
    }

    @ViewBuilder
    private var typeIndicator: some View {
        switch item.type {
        case .video:
            HStack(spacing: 4) {
                Image(systemName: "play.fill")
                    .font(.caption2)
                if let duration = item.formattedDuration {
                    Text(duration)
                        .font(.caption2)
                }
            }
            .foregroundColor(.white)
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background(.black.opacity(0.6))
            .cornerRadius(4)
            .padding(4)

        case .gif:
            Text("GIF")
                .font(.caption2)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .padding(.horizontal, 6)
                .padding(.vertical, 3)
                .background(.black.opacity(0.6))
                .cornerRadius(4)
                .padding(4)

        default:
            EmptyView()
        }
    }
}

// MARK: - Media Gallery ViewModel

@Observable
@MainActor
final class MediaGalleryViewModel {
    // MARK: - Properties

    var mediaItems: [MediaItem] = []
    var isLoading: Bool = false
    var hasMoreItems: Bool = true
    var currentFilter: MediaFilter = .all

    private let chatId: Int64
    private var offset: Int32 = 0
    private let limit: Int32 = 50

    // MARK: - Computed Properties

    var filteredItems: [MediaItem] {
        switch currentFilter {
        case .all:
            return mediaItems
        case .photos:
            return mediaItems.filter { $0.type == .photo }
        case .videos:
            return mediaItems.filter { $0.type == .video }
        case .gifs:
            return mediaItems.filter { $0.type == .gif }
        case .files:
            return mediaItems.filter { $0.type == .document }
        }
    }

    // MARK: - Initialization

    init(chatId: Int64) {
        self.chatId = chatId
    }

    // MARK: - Methods

    func loadMedia() async {
        guard !isLoading else { return }

        isLoading = true
        defer { isLoading = false }

        // In real implementation: call TDLib's searchChatMessages with message filter
        #if DEBUG
        // Simulate loading
        try? await Task.sleep(for: .milliseconds(500))
        mediaItems = MediaItem.mockGallery + MediaItem.mockGallery + MediaItem.mockGallery
        #endif
    }

    func loadMoreMedia() async {
        guard !isLoading, hasMoreItems else { return }

        isLoading = true
        defer { isLoading = false }

        offset += limit

        // In real implementation: load next batch
        #if DEBUG
        try? await Task.sleep(for: .milliseconds(300))
        // Simulate end of data
        hasMoreItems = false
        #endif
    }

    func refresh() async {
        offset = 0
        hasMoreItems = true
        mediaItems.removeAll()
        await loadMedia()
    }
}

// MARK: - Media Filter

enum MediaFilter: String, CaseIterable {
    case all
    case photos
    case videos
    case gifs
    case files

    var title: String {
        switch self {
        case .all:
            return "All"
        case .photos:
            return "Photos"
        case .videos:
            return "Videos"
        case .gifs:
            return "GIFs"
        case .files:
            return "Files"
        }
    }
}

// MARK: - Preview

#Preview {
    MediaGalleryView(chatId: 1, chatTitle: "Test Chat")
}
