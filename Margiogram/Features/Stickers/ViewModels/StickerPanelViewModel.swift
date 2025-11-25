//
//  StickerPanelViewModel.swift
//  Margiogram
//
//  Created by Andrea Margiovanni on 2024.
//

import Foundation
import SwiftUI

// MARK: - Sticker Panel ViewModel

@Observable
@MainActor
final class StickerPanelViewModel {
    // MARK: - Properties

    var selectedTab: StickerTab = .stickers
    var searchText: String = ""
    var isSearching: Bool = false

    // Sticker Data
    var recentStickers: [StickerItem] = []
    var favoriteStickers: [StickerItem] = []
    var installedStickerSets: [StickerSet] = []
    var trendingStickerSets: [StickerSet] = []

    // GIF Data
    var recentGifs: [GifItem] = []
    var trendingGifs: [GifItem] = []
    var searchedGifs: [GifItem] = []

    // Emoji Data
    var recentEmoji: [String] = []
    var frequentEmoji: [String] = []

    // State
    var isLoading: Bool = false
    var error: Error?

    // MARK: - Computed Properties

    var filteredStickerSets: [StickerSet] {
        guard !searchText.isEmpty else { return installedStickerSets }
        return installedStickerSets.filter {
            $0.title.lowercased().contains(searchText.lowercased())
        }
    }

    var displayGifs: [GifItem] {
        if !searchText.isEmpty {
            return searchedGifs
        } else {
            return recentGifs.isEmpty ? trendingGifs : recentGifs
        }
    }

    // MARK: - Loading

    func loadInitialData() async {
        isLoading = true
        defer { isLoading = false }

        async let stickers = loadStickerSets()
        async let gifs = loadGifs()
        async let emoji = loadEmoji()

        await stickers
        await gifs
        await emoji
    }

    private func loadStickerSets() async {
        // In real implementation: call TDLib's getInstalledStickerSets
        #if DEBUG
        try? await Task.sleep(for: .milliseconds(300))
        installedStickerSets = StickerSet.mockSets
        recentStickers = StickerItem.mockRecent
        favoriteStickers = StickerItem.mockFavorites
        #endif
    }

    private func loadGifs() async {
        // In real implementation: call TDLib's getSavedAnimations and getTrendingAnimations
        #if DEBUG
        try? await Task.sleep(for: .milliseconds(200))
        recentGifs = GifItem.mockRecent
        trendingGifs = GifItem.mockTrending
        #endif
    }

    private func loadEmoji() async {
        // Load recent and frequent emoji from UserDefaults
        recentEmoji = UserDefaults.standard.stringArray(forKey: "recentEmoji") ?? []
        frequentEmoji = EmojiData.frequentlyUsed
    }

    // MARK: - Search

    func searchStickers() async {
        guard !searchText.isEmpty else { return }

        isSearching = true
        defer { isSearching = false }

        // In real implementation: call TDLib's searchStickers
        #if DEBUG
        try? await Task.sleep(for: .milliseconds(200))
        #endif
    }

    func searchGifs() async {
        guard !searchText.isEmpty else {
            searchedGifs = []
            return
        }

        isSearching = true
        defer { isSearching = false }

        // In real implementation: call TDLib's searchWebApp or Giphy API
        #if DEBUG
        try? await Task.sleep(for: .milliseconds(300))
        searchedGifs = GifItem.mockTrending.shuffled()
        #endif
    }

    // MARK: - Sticker Actions

    func sendSticker(_ sticker: StickerItem) {
        // Add to recent
        addToRecentStickers(sticker)
        // In real implementation: send sticker message
    }

    func addToFavorites(_ sticker: StickerItem) {
        guard !favoriteStickers.contains(sticker) else { return }
        favoriteStickers.insert(sticker, at: 0)
        // In real implementation: call TDLib's addFavoriteSticker
    }

    func removeFromFavorites(_ sticker: StickerItem) {
        favoriteStickers.removeAll { $0.id == sticker.id }
        // In real implementation: call TDLib's removeFavoriteSticker
    }

    private func addToRecentStickers(_ sticker: StickerItem) {
        recentStickers.removeAll { $0.id == sticker.id }
        recentStickers.insert(sticker, at: 0)
        if recentStickers.count > 20 {
            recentStickers = Array(recentStickers.prefix(20))
        }
        // In real implementation: call TDLib's addRecentSticker
    }

    // MARK: - GIF Actions

    func sendGif(_ gif: GifItem) {
        addToRecentGifs(gif)
        // In real implementation: send animation message
    }

    private func addToRecentGifs(_ gif: GifItem) {
        recentGifs.removeAll { $0.id == gif.id }
        recentGifs.insert(gif, at: 0)
        if recentGifs.count > 30 {
            recentGifs = Array(recentGifs.prefix(30))
        }
        // In real implementation: call TDLib's addSavedAnimation
    }

    // MARK: - Emoji Actions

    func selectEmoji(_ emoji: String) {
        addToRecentEmoji(emoji)
    }

    private func addToRecentEmoji(_ emoji: String) {
        recentEmoji.removeAll { $0 == emoji }
        recentEmoji.insert(emoji, at: 0)
        if recentEmoji.count > 50 {
            recentEmoji = Array(recentEmoji.prefix(50))
        }
        UserDefaults.standard.set(recentEmoji, forKey: "recentEmoji")
    }

    // MARK: - Sticker Set Actions

    func installStickerSet(_ set: StickerSet) async {
        // In real implementation: call TDLib's changeStickerSet
        guard !installedStickerSets.contains(set) else { return }
        installedStickerSets.append(set)
    }

    func removeStickerSet(_ set: StickerSet) async {
        // In real implementation: call TDLib's changeStickerSet
        installedStickerSets.removeAll { $0.id == set.id }
    }
}

// MARK: - Sticker Tab

enum StickerTab: String, CaseIterable {
    case stickers = "Stickers"
    case gifs = "GIFs"
    case emoji = "Emoji"

    var icon: String {
        switch self {
        case .stickers:
            return "face.smiling"
        case .gifs:
            return "play.square"
        case .emoji:
            return "smiley"
        }
    }
}

// MARK: - Sticker Item

struct StickerItem: Identifiable, Equatable, Hashable, Sendable {
    let id: String
    let setId: String
    let emoji: String
    let thumbnail: URL?
    let stickerURL: URL?
    let isAnimated: Bool
    let isPremium: Bool

    init(
        id: String = UUID().uuidString,
        setId: String = "",
        emoji: String = "😀",
        thumbnail: URL? = nil,
        stickerURL: URL? = nil,
        isAnimated: Bool = false,
        isPremium: Bool = false
    ) {
        self.id = id
        self.setId = setId
        self.emoji = emoji
        self.thumbnail = thumbnail
        self.stickerURL = stickerURL
        self.isAnimated = isAnimated
        self.isPremium = isPremium
    }
}

// MARK: - Sticker Set

struct StickerSet: Identifiable, Equatable, Hashable, Sendable {
    let id: String
    let title: String
    let name: String
    let thumbnail: URL?
    let stickers: [StickerItem]
    let isOfficial: Bool
    let isAnimated: Bool

    init(
        id: String = UUID().uuidString,
        title: String,
        name: String = "",
        thumbnail: URL? = nil,
        stickers: [StickerItem] = [],
        isOfficial: Bool = false,
        isAnimated: Bool = false
    ) {
        self.id = id
        self.title = title
        self.name = name
        self.thumbnail = thumbnail
        self.stickers = stickers
        self.isOfficial = isOfficial
        self.isAnimated = isAnimated
    }
}

// MARK: - GIF Item

struct GifItem: Identifiable, Equatable, Hashable, Sendable {
    let id: String
    let thumbnail: URL?
    let gifURL: URL?
    let width: Int
    let height: Int
    let fileSize: Int64

    init(
        id: String = UUID().uuidString,
        thumbnail: URL? = nil,
        gifURL: URL? = nil,
        width: Int = 200,
        height: Int = 200,
        fileSize: Int64 = 0
    ) {
        self.id = id
        self.thumbnail = thumbnail
        self.gifURL = gifURL
        self.width = width
        self.height = height
        self.fileSize = fileSize
    }

    var aspectRatio: CGFloat {
        guard height > 0 else { return 1 }
        return CGFloat(width) / CGFloat(height)
    }
}

// MARK: - Emoji Data

struct EmojiData {
    static let frequentlyUsed = ["😀", "😂", "🥲", "😍", "🤔", "👍", "❤️", "🎉", "🔥", "✨"]

    static let categories: [(name: String, icon: String, emoji: [String])] = [
        ("Smileys", "face.smiling", ["😀", "😃", "😄", "😁", "😆", "😅", "🤣", "😂", "🙂", "😊", "😇", "🥰", "😍", "🤩", "😘", "😗", "😚", "😙", "🥲", "😋"]),
        ("People", "person", ["👋", "🤚", "🖐️", "✋", "🖖", "👌", "🤌", "🤏", "✌️", "🤞", "🤟", "🤘", "🤙", "👈", "👉", "👆", "🖕", "👇", "👍", "👎"]),
        ("Animals", "pawprint", ["🐶", "🐱", "🐭", "🐹", "🐰", "🦊", "🐻", "🐼", "🐻‍❄️", "🐨", "🐯", "🦁", "🐮", "🐷", "🐸", "🐵", "🐔", "🐧", "🐦", "🐤"]),
        ("Food", "fork.knife", ["🍏", "🍎", "🍐", "🍊", "🍋", "🍌", "🍉", "🍇", "🍓", "🫐", "🍈", "🍒", "🍑", "🥭", "🍍", "🥥", "🥝", "🍅", "🍆", "🥑"]),
        ("Activities", "figure.run", ["⚽️", "🏀", "🏈", "⚾️", "🥎", "🎾", "🏐", "🏉", "🥏", "🎱", "🪀", "🏓", "🏸", "🏒", "🏑", "🥍", "🏏", "🪃", "🥅", "⛳️"]),
        ("Travel", "car", ["🚗", "🚕", "🚙", "🚌", "🚎", "🏎️", "🚓", "🚑", "🚒", "🚐", "🛻", "🚚", "🚛", "🚜", "🏍️", "🛵", "🚲", "🛴", "🛹", "🛼"]),
        ("Objects", "lightbulb", ["⌚️", "📱", "📲", "💻", "⌨️", "🖥️", "🖨️", "🖱️", "🖲️", "🕹️", "🗜️", "💽", "💾", "💿", "📀", "📼", "📷", "📸", "📹", "🎥"]),
        ("Symbols", "heart", ["❤️", "🧡", "💛", "💚", "💙", "💜", "🖤", "🤍", "🤎", "💔", "❤️‍🔥", "❤️‍🩹", "💕", "💞", "💓", "💗", "💖", "💘", "💝", "💟"]),
        ("Flags", "flag", ["🏳️", "🏴", "🏴‍☠️", "🏁", "🚩", "🎌", "🏳️‍🌈", "🏳️‍⚧️", "🇺🇳", "🇦🇫", "🇦🇽", "🇦🇱", "🇩🇿", "🇦🇸", "🇦🇩", "🇦🇴", "🇦🇮", "🇦🇶", "🇦🇬", "🇦🇷"])
    ]
}

// MARK: - Mock Data

extension StickerItem {
    static var mockRecent: [StickerItem] {
        (0..<10).map { StickerItem(id: "recent_\($0)", emoji: ["😀", "😎", "🥳", "🤔", "👍", "❤️", "🎉", "🔥", "✨", "💯"][$0]) }
    }

    static var mockFavorites: [StickerItem] {
        (0..<5).map { StickerItem(id: "fav_\($0)", emoji: ["⭐️", "💖", "🌟", "🎯", "🏆"][$0]) }
    }
}

extension StickerSet {
    static var mockSets: [StickerSet] {
        [
            StickerSet(title: "Cool Cats", stickers: (0..<20).map { StickerItem(id: "cat_\($0)") }, isAnimated: true),
            StickerSet(title: "Happy Dogs", stickers: (0..<15).map { StickerItem(id: "dog_\($0)") }),
            StickerSet(title: "Funny Faces", stickers: (0..<25).map { StickerItem(id: "face_\($0)") }, isAnimated: true),
            StickerSet(title: "Love Pack", stickers: (0..<18).map { StickerItem(id: "love_\($0)") }),
        ]
    }
}

extension GifItem {
    static var mockRecent: [GifItem] {
        (0..<10).map { GifItem(id: "recent_gif_\($0)", width: [200, 250, 180, 220][$0 % 4], height: [200, 180, 220, 200][$0 % 4]) }
    }

    static var mockTrending: [GifItem] {
        (0..<20).map { GifItem(id: "trending_gif_\($0)", width: [200, 250, 180, 220][$0 % 4], height: [200, 180, 220, 200][$0 % 4]) }
    }
}
