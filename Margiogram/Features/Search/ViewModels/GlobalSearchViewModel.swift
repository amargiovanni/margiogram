//
//  GlobalSearchViewModel.swift
//  Margiogram
//
//  Created by Andrea Margiovanni on 2024.
//

import Foundation
import SwiftUI

// MARK: - Global Search ViewModel

@Observable
@MainActor
final class GlobalSearchViewModel {
    // MARK: - Properties

    var searchText: String = "" {
        didSet {
            if searchText != oldValue {
                scheduleSearch()
            }
        }
    }

    var selectedScope: SearchScope = .all
    var isSearching: Bool = false

    // Results
    var chatResults: [Chat] = []
    var messageResults: [SearchMessageResult] = []
    var contactResults: [User] = []
    var globalResults: [SearchGlobalResult] = []

    // Filters
    var dateFilter: DateFilter = .anytime
    var chatFilter: Chat?

    // Recent Searches
    var recentSearches: [String] = []

    // Error
    var error: Error?

    // MARK: - Private Properties

    private var searchTask: Task<Void, Never>?
    private let debounceDelay: UInt64 = 300_000_000 // 300ms

    // MARK: - Computed Properties

    var hasResults: Bool {
        !chatResults.isEmpty ||
        !messageResults.isEmpty ||
        !contactResults.isEmpty ||
        !globalResults.isEmpty
    }

    var showRecentSearches: Bool {
        searchText.isEmpty && !recentSearches.isEmpty
    }

    // MARK: - Search

    func search() async {
        guard !searchText.isEmpty else {
            clearResults()
            return
        }

        isSearching = true
        error = nil

        do {
            switch selectedScope {
            case .all:
                await searchAll()
            case .chats:
                await searchChats()
            case .messages:
                await searchMessages()
            case .contacts:
                await searchContacts()
            case .global:
                await searchGlobal()
            }

            // Add to recent searches
            addToRecentSearches(searchText)

        } catch {
            self.error = error
        }

        isSearching = false
    }

    private func searchAll() async {
        // Search all categories in parallel
        async let chats = performChatSearch()
        async let messages = performMessageSearch()
        async let contacts = performContactSearch()
        async let global = performGlobalSearch()

        chatResults = await chats
        messageResults = await messages
        contactResults = await contacts
        globalResults = await global
    }

    private func searchChats() async {
        chatResults = await performChatSearch()
        messageResults = []
        contactResults = []
        globalResults = []
    }

    private func searchMessages() async {
        chatResults = []
        messageResults = await performMessageSearch()
        contactResults = []
        globalResults = []
    }

    private func searchContacts() async {
        chatResults = []
        messageResults = []
        contactResults = await performContactSearch()
        globalResults = []
    }

    private func searchGlobal() async {
        chatResults = []
        messageResults = []
        contactResults = []
        globalResults = await performGlobalSearch()
    }

    // MARK: - Search Implementations

    private func performChatSearch() async -> [Chat] {
        // In real implementation: call TDLib's searchChats
        #if DEBUG
        try? await Task.sleep(for: .milliseconds(200))
        return Chat.mockList.filter {
            $0.title.lowercased().contains(searchText.lowercased())
        }
        #else
        return []
        #endif
    }

    private func performMessageSearch() async -> [SearchMessageResult] {
        // In real implementation: call TDLib's searchMessages
        #if DEBUG
        try? await Task.sleep(for: .milliseconds(300))
        return SearchMessageResult.mockResults.filter {
            $0.message.text?.lowercased().contains(searchText.lowercased()) ?? false
        }
        #else
        return []
        #endif
    }

    private func performContactSearch() async -> [User] {
        // In real implementation: call TDLib's searchContacts
        #if DEBUG
        try? await Task.sleep(for: .milliseconds(150))
        return User.mockContacts.filter {
            $0.fullName.lowercased().contains(searchText.lowercased())
        }
        #else
        return []
        #endif
    }

    private func performGlobalSearch() async -> [SearchGlobalResult] {
        // In real implementation: call TDLib's searchPublicChats
        #if DEBUG
        try? await Task.sleep(for: .milliseconds(400))
        return SearchGlobalResult.mockResults.filter {
            $0.title.lowercased().contains(searchText.lowercased())
        }
        #else
        return []
        #endif
    }

    // MARK: - Debounced Search

    private func scheduleSearch() {
        searchTask?.cancel()

        searchTask = Task {
            try? await Task.sleep(nanoseconds: debounceDelay)
            guard !Task.isCancelled else { return }
            await search()
        }
    }

    // MARK: - Clear

    func clearResults() {
        chatResults = []
        messageResults = []
        contactResults = []
        globalResults = []
    }

    func clearSearch() {
        searchText = ""
        clearResults()
    }

    // MARK: - Recent Searches

    private func addToRecentSearches(_ query: String) {
        let trimmed = query.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }

        // Remove if already exists
        recentSearches.removeAll { $0 == trimmed }

        // Add to beginning
        recentSearches.insert(trimmed, at: 0)

        // Keep only last 10
        if recentSearches.count > 10 {
            recentSearches = Array(recentSearches.prefix(10))
        }

        // Persist
        UserDefaults.standard.set(recentSearches, forKey: "recentSearches")
    }

    func loadRecentSearches() {
        recentSearches = UserDefaults.standard.stringArray(forKey: "recentSearches") ?? []
    }

    func removeRecentSearch(_ query: String) {
        recentSearches.removeAll { $0 == query }
        UserDefaults.standard.set(recentSearches, forKey: "recentSearches")
    }

    func clearRecentSearches() {
        recentSearches = []
        UserDefaults.standard.removeObject(forKey: "recentSearches")
    }

    func selectRecentSearch(_ query: String) {
        searchText = query
    }

    // MARK: - Filters

    func applyDateFilter(_ filter: DateFilter) {
        dateFilter = filter
        Task {
            await search()
        }
    }

    func applyChatFilter(_ chat: Chat?) {
        chatFilter = chat
        Task {
            await search()
        }
    }
}

// MARK: - Search Scope

enum SearchScope: String, CaseIterable {
    case all = "All"
    case chats = "Chats"
    case messages = "Messages"
    case contacts = "Contacts"
    case global = "Global"

    var icon: String {
        switch self {
        case .all:
            return "magnifyingglass"
        case .chats:
            return "bubble.left.and.bubble.right"
        case .messages:
            return "text.bubble"
        case .contacts:
            return "person.2"
        case .global:
            return "globe"
        }
    }
}

// MARK: - Date Filter

enum DateFilter: String, CaseIterable {
    case anytime = "Anytime"
    case today = "Today"
    case yesterday = "Yesterday"
    case thisWeek = "This Week"
    case thisMonth = "This Month"
    case custom = "Custom"

    var dateRange: (start: Date, end: Date)? {
        let calendar = Calendar.current
        let now = Date()

        switch self {
        case .anytime:
            return nil
        case .today:
            let start = calendar.startOfDay(for: now)
            return (start, now)
        case .yesterday:
            guard let yesterday = calendar.date(byAdding: .day, value: -1, to: now) else { return nil }
            let start = calendar.startOfDay(for: yesterday)
            let end = calendar.startOfDay(for: now)
            return (start, end)
        case .thisWeek:
            guard let start = calendar.dateInterval(of: .weekOfYear, for: now)?.start else { return nil }
            return (start, now)
        case .thisMonth:
            guard let start = calendar.dateInterval(of: .month, for: now)?.start else { return nil }
            return (start, now)
        case .custom:
            return nil
        }
    }
}

// MARK: - Search Message Result

struct SearchMessageResult: Identifiable, Equatable, Hashable, Sendable {
    let id: String
    let message: Message
    let chat: Chat
    let highlightRanges: [Range<String.Index>]

    init(
        id: String = UUID().uuidString,
        message: Message,
        chat: Chat,
        highlightRanges: [Range<String.Index>] = []
    ) {
        self.id = id
        self.message = message
        self.chat = chat
        self.highlightRanges = highlightRanges
    }

    static func == (lhs: SearchMessageResult, rhs: SearchMessageResult) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

// MARK: - Search Global Result

struct SearchGlobalResult: Identifiable, Equatable, Hashable, Sendable {
    let id: String
    let type: GlobalResultType
    let title: String
    let username: String?
    let description: String?
    let memberCount: Int?
    let isVerified: Bool

    init(
        id: String = UUID().uuidString,
        type: GlobalResultType,
        title: String,
        username: String? = nil,
        description: String? = nil,
        memberCount: Int? = nil,
        isVerified: Bool = false
    ) {
        self.id = id
        self.type = type
        self.title = title
        self.username = username
        self.description = description
        self.memberCount = memberCount
        self.isVerified = isVerified
    }
}

// MARK: - Global Result Type

enum GlobalResultType: String, Sendable {
    case user
    case channel
    case group
    case bot

    var icon: String {
        switch self {
        case .user:
            return "person"
        case .channel:
            return "megaphone"
        case .group:
            return "person.3"
        case .bot:
            return "cpu"
        }
    }
}

// MARK: - Mock Data

extension SearchMessageResult {
    static var mockResults: [SearchMessageResult] {
        let chat = Chat.mock()
        return [
            SearchMessageResult(message: Message.mock(text: "Hey, how are you doing today?"), chat: chat),
            SearchMessageResult(message: Message.mock(text: "Let's meet tomorrow at 3pm"), chat: chat),
            SearchMessageResult(message: Message.mock(text: "Check out this amazing photo!"), chat: chat),
        ]
    }
}

extension SearchGlobalResult {
    static var mockResults: [SearchGlobalResult] {
        [
            SearchGlobalResult(type: .channel, title: "Tech News", username: "technews", memberCount: 150000, isVerified: true),
            SearchGlobalResult(type: .group, title: "iOS Developers", username: "iosdev", memberCount: 5000),
            SearchGlobalResult(type: .bot, title: "Translation Bot", username: "translatebot", isVerified: true),
            SearchGlobalResult(type: .user, title: "John Developer", username: "johndev"),
        ]
    }
}
