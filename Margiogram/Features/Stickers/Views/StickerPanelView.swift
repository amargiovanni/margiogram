//
//  StickerPanelView.swift
//  Margiogram
//
//  Created by Andrea Margiovanni on 2024.
//

import SwiftUI

// MARK: - Sticker Panel View

struct StickerPanelView: View {
    // MARK: - Properties

    @Environment(\.dismiss) private var dismiss
    @State private var viewModel = StickerPanelViewModel()

    var onStickerSelected: ((Sticker) -> Void)?
    var onGifSelected: ((GifItem) -> Void)?
    var onEmojiSelected: ((String) -> Void)?

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            // Tab Picker
            tabPicker

            // Search Bar
            searchBar

            // Content
            TabView(selection: $viewModel.selectedTab) {
                stickersContent
                    .tag(StickerTab.stickers)

                gifsContent
                    .tag(StickerTab.gifs)

                emojiContent
                    .tag(StickerTab.emoji)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
        }
        .background(Color(.systemGroupedBackground))
        .task {
            await viewModel.loadInitialData()
        }
    }

    // MARK: - Tab Picker

    private var tabPicker: some View {
        HStack(spacing: 0) {
            ForEach(StickerTab.allCases, id: \.self) { tab in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        viewModel.selectedTab = tab
                    }
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: tab.icon)
                            .font(.title3)

                        Text(tab.rawValue)
                            .font(.caption2)
                    }
                    .foregroundColor(viewModel.selectedTab == tab ? .accentColor : .secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(
                        viewModel.selectedTab == tab ?
                        Color.accentColor.opacity(0.1) : Color.clear
                    )
                }
            }
        }
        .background(Color(.systemBackground))
    }

    // MARK: - Search Bar

    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)

            TextField(searchPlaceholder, text: $viewModel.searchText)
                .textFieldStyle(.plain)

            if !viewModel.searchText.isEmpty {
                Button {
                    viewModel.searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(10)
        .background(Color(.tertiarySystemGroupedBackground))
        .cornerRadius(10)
        .padding(.horizontal)
        .padding(.vertical, 8)
        .onChange(of: viewModel.searchText) {
            Task {
                switch viewModel.selectedTab {
                case .stickers:
                    await viewModel.searchStickers()
                case .gifs:
                    await viewModel.searchGifs()
                case .emoji:
                    break
                }
            }
        }
    }

    private var searchPlaceholder: String {
        switch viewModel.selectedTab {
        case .stickers:
            return "Search stickers..."
        case .gifs:
            return "Search GIFs..."
        case .emoji:
            return "Search emoji..."
        }
    }

    // MARK: - Stickers Content

    private var stickersContent: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 16, pinnedViews: [.sectionHeaders]) {
                // Recent Section
                if !viewModel.recentStickers.isEmpty {
                    Section {
                        stickerGrid(stickers: viewModel.recentStickers)
                    } header: {
                        sectionHeader("Recent")
                    }
                }

                // Favorites Section
                if !viewModel.favoriteStickers.isEmpty {
                    Section {
                        stickerGrid(stickers: viewModel.favoriteStickers)
                    } header: {
                        sectionHeader("Favorites")
                    }
                }

                // Sticker Sets
                ForEach(viewModel.filteredStickerSets) { set in
                    Section {
                        stickerGrid(stickers: set.stickers)
                    } header: {
                        stickerSetHeader(set: set)
                    }
                }
            }
            .padding(.bottom, 20)
        }
    }

    private func stickerGrid(stickers: [Sticker]) -> some View {
        LazyVGrid(
            columns: [GridItem(.adaptive(minimum: 70, maximum: 90), spacing: 8)],
            spacing: 8
        ) {
            ForEach(stickers) { sticker in
                StickerCell(sticker: sticker) {
                    viewModel.sendSticker(sticker)
                    onStickerSelected?(sticker)
                }
                .contextMenu {
                    Button {
                        if viewModel.favoriteStickers.contains(sticker) {
                            viewModel.removeFromFavorites(sticker)
                        } else {
                            viewModel.addToFavorites(sticker)
                        }
                    } label: {
                        Label(
                            viewModel.favoriteStickers.contains(sticker) ? "Remove from Favorites" : "Add to Favorites",
                            systemImage: viewModel.favoriteStickers.contains(sticker) ? "star.slash" : "star"
                        )
                    }
                }
            }
        }
        .padding(.horizontal)
    }

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.subheadline)
            .fontWeight(.semibold)
            .foregroundColor(.secondary)
            .padding(.horizontal)
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(.systemGroupedBackground))
    }

    private func stickerSetHeader(set: StickerSet) -> some View {
        HStack {
            // Thumbnail
            if let thumbnail = set.thumbnail {
                AsyncImage(url: thumbnail) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                } placeholder: {
                    Color.gray.opacity(0.2)
                }
                .frame(width: 24, height: 24)
            }

            Text(set.title)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)

            if set.isAnimated {
                Image(systemName: "sparkles")
                    .font(.caption)
                    .foregroundColor(.accentColor)
            }

            Spacer()

            Text("\(set.stickers.count)")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemGroupedBackground))
    }

    // MARK: - GIFs Content

    private var gifsContent: some View {
        ScrollView {
            if viewModel.isSearching {
                ProgressView()
                    .padding()
            } else if viewModel.displayGifs.isEmpty && !viewModel.searchText.isEmpty {
                ContentUnavailableView.search(text: viewModel.searchText)
            } else {
                LazyVGrid(
                    columns: [GridItem(.adaptive(minimum: 100, maximum: 150), spacing: 4)],
                    spacing: 4
                ) {
                    ForEach(viewModel.displayGifs) { gif in
                        GifCell(gif: gif) {
                            viewModel.sendGif(gif)
                            onGifSelected?(gif)
                        }
                    }
                }
                .padding(4)
            }
        }
    }

    // MARK: - Emoji Content

    private var emojiContent: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 16, pinnedViews: [.sectionHeaders]) {
                // Recent
                if !viewModel.recentEmoji.isEmpty {
                    Section {
                        emojiGrid(emoji: viewModel.recentEmoji)
                    } header: {
                        sectionHeader("Recent")
                    }
                }

                // Frequently Used
                Section {
                    emojiGrid(emoji: viewModel.frequentEmoji)
                } header: {
                    sectionHeader("Frequently Used")
                }

                // Categories
                ForEach(EmojiData.categories, id: \.name) { category in
                    Section {
                        emojiGrid(emoji: category.emoji)
                    } header: {
                        HStack(spacing: 8) {
                            Image(systemName: category.icon)
                                .font(.caption)
                            Text(category.name)
                        }
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                        .padding(.horizontal)
                        .padding(.vertical, 8)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(.systemGroupedBackground))
                    }
                }
            }
            .padding(.bottom, 20)
        }
    }

    private func emojiGrid(emoji: [String]) -> some View {
        LazyVGrid(
            columns: [GridItem(.adaptive(minimum: 40, maximum: 50), spacing: 4)],
            spacing: 4
        ) {
            ForEach(emoji, id: \.self) { emojiChar in
                Button {
                    viewModel.selectEmoji(emojiChar)
                    onEmojiSelected?(emojiChar)
                } label: {
                    Text(emojiChar)
                        .font(.system(size: 28))
                        .frame(width: 44, height: 44)
                }
            }
        }
        .padding(.horizontal)
    }
}

// MARK: - Sticker Cell

private struct StickerCell: View {
    let sticker: Sticker
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            ZStack {
                if let thumbnail = sticker.thumbnail {
                    AsyncImage(url: thumbnail) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                    } placeholder: {
                        placeholderView
                    }
                } else {
                    placeholderView
                }

                // Premium indicator
                if sticker.isPremium {
                    VStack {
                        HStack {
                            Spacer()
                            Image(systemName: "star.fill")
                                .font(.caption2)
                                .foregroundColor(.yellow)
                                .padding(4)
                        }
                        Spacer()
                    }
                }
            }
            .frame(width: 70, height: 70)
        }
    }

    private var placeholderView: some View {
        Text(sticker.emoji)
            .font(.system(size: 40))
            .frame(width: 70, height: 70)
            .background(Color.gray.opacity(0.1))
            .cornerRadius(8)
    }
}

// MARK: - GIF Cell

private struct GifCell: View {
    let gif: GifItem
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            ZStack {
                if let thumbnail = gif.thumbnail {
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
            .aspectRatio(gif.aspectRatio, contentMode: .fill)
            .clipped()
            .cornerRadius(4)
        }
    }

    private var placeholderView: some View {
        Rectangle()
            .fill(Color.gray.opacity(0.2))
            .overlay {
                Image(systemName: "play.square")
                    .foregroundColor(.gray)
            }
    }
}

// MARK: - Sticker Store View

struct StickerStoreView: View {
    @State private var viewModel = StickerPanelViewModel()
    @State private var searchText: String = ""

    var body: some View {
        List {
            // Trending Section
            Section("Trending") {
                ForEach(viewModel.trendingStickerSets) { set in
                    StickerSetRow(set: set) {
                        Task {
                            await viewModel.installStickerSet(set)
                        }
                    }
                }
            }

            // Installed Section
            Section("Installed") {
                ForEach(viewModel.installedStickerSets) { set in
                    StickerSetRow(set: set, isInstalled: true) {
                        Task {
                            await viewModel.removeStickerSet(set)
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Sticker Store")
        .searchable(text: $searchText, prompt: "Search sticker sets")
        .task {
            await viewModel.loadInitialData()
        }
    }
}

// MARK: - Sticker Set Row

private struct StickerSetRow: View {
    let set: StickerSet
    var isInstalled: Bool = false
    let action: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            // Preview
            HStack(spacing: 2) {
                ForEach(set.stickers.prefix(3)) { sticker in
                    if let thumbnail = sticker.thumbnail {
                        AsyncImage(url: thumbnail) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                        } placeholder: {
                            Text(sticker.emoji)
                        }
                        .frame(width: 24, height: 24)
                    } else {
                        Text(sticker.emoji)
                            .font(.title3)
                    }
                }
            }
            .frame(width: 80)

            // Info
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(set.title)
                        .font(.body)
                        .fontWeight(.medium)

                    if set.isAnimated {
                        Image(systemName: "sparkles")
                            .font(.caption)
                            .foregroundColor(.accentColor)
                    }
                }

                Text("\(set.stickers.count) stickers")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            // Action Button
            Button(action: action) {
                Text(isInstalled ? "Remove" : "Add")
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            .buttonStyle(.bordered)
            .tint(isInstalled ? .red : .accentColor)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Preview

#Preview {
    StickerPanelView()
        .frame(height: 400)
}

#Preview("Sticker Store") {
    NavigationStack {
        StickerStoreView()
    }
}
