//
//  ChatListViewModel.swift
//  Margiogram
//
//  Created by Andrea Margiovanni on 2024.
//

import Foundation
import SwiftUI
import OSLog

// MARK: - Chat List View Model

/// ViewModel for the chat list screen.
///
/// Handles loading, filtering, and managing the list of chats.
@MainActor
@Observable
final class ChatListViewModel {
    // MARK: - Properties

    /// All loaded chats.
    private(set) var chats: [Chat] = []

    /// Current search query.
    var searchQuery: String = ""

    /// Selected chat folder.
    var selectedFolder: ChatFolder?

    /// Available chat folders.
    private(set) var folders: [ChatFolder] = []

    /// Whether chats are being loaded.
    private(set) var isLoading = false

    /// Whether more chats are being loaded.
    private(set) var isLoadingMore = false

    /// Whether there are more chats to load.
    private(set) var hasMoreChats = true

    /// Current error if any.
    private(set) var error: ChatListError?

    /// Currently active chat actions (typing indicators, etc.).
    private(set) var chatActions: [Int64: (User, ChatAction)] = [:]

    /// Logger for debugging.
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "ChatListViewModel")

    /// The TDLib client.
    private let client: TDLibClient

    /// Update listener task.
    nonisolated(unsafe) private var updateTask: Task<Void, Never>?

    // MARK: - Computed Properties

    /// Filtered chats based on search query and folder.
    var filteredChats: [Chat] {
        var result = chats

        // Apply folder filter
        if let folder = selectedFolder {
            result = result.filter { chat in
                // Check if chat is in folder's included chats
                if folder.includedChatIds.contains(chat.id) {
                    return true
                }

                // Check if chat is excluded
                if folder.excludedChatIds.contains(chat.id) {
                    return false
                }

                // Check type-based inclusion
                switch chat.type {
                case .private(_, let isBot):
                    if isBot && folder.includeBots { return true }
                    if !isBot && folder.includeContacts { return true }
                case .basicGroup, .supergroup(_, false, _):
                    if folder.includeGroups { return true }
                case .supergroup(_, true, _):
                    if folder.includeChannels { return true }
                case .secret:
                    return folder.includeContacts
                }

                return false
            }
        }

        // Apply search filter
        if !searchQuery.isEmpty {
            let query = searchQuery.lowercased()
            result = result.filter { chat in
                chat.title.lowercased().contains(query) ||
                chat.lastMessage?.textContent?.lowercased().contains(query) == true
            }
        }

        return result
    }

    /// Pinned chats.
    var pinnedChats: [Chat] {
        filteredChats.filter { $0.isPinned }
    }

    /// Non-pinned chats.
    var regularChats: [Chat] {
        filteredChats.filter { !$0.isPinned }
    }

    /// Whether the chat list is empty.
    var isEmpty: Bool {
        filteredChats.isEmpty && !isLoading
    }

    /// Whether search is active.
    var isSearching: Bool {
        !searchQuery.isEmpty
    }

    // MARK: - Initialization

    init(client: TDLibClient = .shared) {
        self.client = client
    }

    deinit {
        updateTask?.cancel()
    }

    // MARK: - Public Methods

    /// Loads the initial chat list.
    func loadChats() async {
        guard !isLoading else { return }

        logger.info("Loading chats")
        isLoading = true
        error = nil

        do {
            // Start listening for updates
            startListeningForUpdates()

            // Load chats from TDLib
            let loadedChats = try await fetchChats(limit: 30)
            chats = loadedChats
            hasMoreChats = loadedChats.count >= 30

            // Load folders
            folders = try await fetchFolders()

            logger.info("Loaded \(loadedChats.count) chats")
        } catch {
            self.error = .loadFailed(error)
            logger.error("Failed to load chats: \(error.localizedDescription)")
        }

        isLoading = false
    }

    /// Loads more chats (pagination).
    func loadMoreChats() async {
        guard !isLoadingMore, hasMoreChats, let lastChat = chats.last else { return }

        logger.info("Loading more chats")
        isLoadingMore = true

        do {
            let moreChats = try await fetchChats(
                fromChatId: lastChat.id,
                fromOrder: lastChat.position.order,
                limit: 30
            )

            chats.append(contentsOf: moreChats)
            hasMoreChats = moreChats.count >= 30

            logger.info("Loaded \(moreChats.count) more chats")
        } catch {
            logger.error("Failed to load more chats: \(error.localizedDescription)")
        }

        isLoadingMore = false
    }

    /// Refreshes the chat list.
    func refresh() async {
        logger.info("Refreshing chats")
        chats = []
        hasMoreChats = true
        await loadChats()
    }

    /// Selects a chat folder.
    func selectFolder(_ folder: ChatFolder?) {
        logger.info("Selected folder: \(folder?.title ?? "All")")
        selectedFolder = folder
    }

    /// Pins or unpins a chat.
    func togglePin(for chat: Chat) async {
        logger.info("Toggling pin for chat: \(chat.id)")

        if let index = chats.firstIndex(where: { $0.id == chat.id }) {
            chats[index].isPinned.toggle()
        }

        // In real implementation: await client.send(ToggleChatIsPinned(...))
    }

    /// Marks a chat as read or unread.
    func toggleRead(for chat: Chat) async {
        logger.info("Toggling read for chat: \(chat.id)")

        if let index = chats.firstIndex(where: { $0.id == chat.id }) {
            if chats[index].unreadCount > 0 {
                chats[index].unreadCount = 0
                chats[index].isMarkedAsUnread = false
            } else {
                chats[index].isMarkedAsUnread.toggle()
            }
        }

        // In real implementation: await client.send(ToggleChatIsMarkedAsUnread(...))
    }

    /// Mutes or unmutes a chat.
    func toggleMute(for chat: Chat) async {
        logger.info("Toggling mute for chat: \(chat.id)")

        if let index = chats.firstIndex(where: { $0.id == chat.id }) {
            chats[index].isMuted.toggle()
        }

        // In real implementation: await client.send(SetChatNotificationSettings(...))
    }

    /// Archives a chat.
    func archive(chat: Chat) async {
        logger.info("Archiving chat: \(chat.id)")

        chats.removeAll { $0.id == chat.id }

        // In real implementation: await client.send(AddChatToList(...))
    }

    /// Deletes a chat.
    func delete(chat: Chat) async {
        logger.info("Deleting chat: \(chat.id)")

        chats.removeAll { $0.id == chat.id }

        // In real implementation: await client.send(DeleteChat(...))
    }

    /// Clears the current error.
    func clearError() {
        error = nil
    }

    // MARK: - Private Methods

    private func startListeningForUpdates() {
        updateTask?.cancel()

        updateTask = Task {
            for await update in await client.updates {
                await handleUpdate(update)
            }
        }
    }

    private func handleUpdate(_ update: TDUpdate) async {
        switch update {
        case .chatUpdated(let chat):
            if let index = chats.firstIndex(where: { $0.id == chat.id }) {
                chats[index] = chat
                sortChats()
            } else {
                chats.insert(chat, at: 0)
                sortChats()
            }

        case .newMessage(let message):
            // Update last message in chat
            if let index = chats.firstIndex(where: { $0.id == message.chatId }) {
                chats[index].lastMessage = message
                chats[index].lastMessageDate = message.date
                sortChats()
            }

        default:
            break
        }
    }

    private func sortChats() {
        chats.sort { lhs, rhs in
            // Pinned chats first
            if lhs.isPinned != rhs.isPinned {
                return lhs.isPinned
            }

            // Then by last message date
            let lhsDate = lhs.lastMessageDate ?? .distantPast
            let rhsDate = rhs.lastMessageDate ?? .distantPast
            return lhsDate > rhsDate
        }
    }

    private func fetchChats(
        fromChatId: Int64 = 0,
        fromOrder: Int64 = Int64.max,
        limit: Int = 30
    ) async throws -> [Chat] {
        // In real implementation, this would call TDLib's getChats
        // For now, return mock data
        #if DEBUG
        try? await Task.sleep(for: .milliseconds(500))
        return Chat.mockList
        #else
        return []
        #endif
    }

    private func fetchFolders() async throws -> [ChatFolder] {
        // In real implementation, this would call TDLib's getChatFolders
        return []
    }
}

// MARK: - Chat List Error

/// Errors that can occur in the chat list.
enum ChatListError: LocalizedError {
    case loadFailed(Error)
    case actionFailed(Error)

    var errorDescription: String? {
        switch self {
        case .loadFailed(let error):
            return "Failed to load chats: \(error.localizedDescription)"
        case .actionFailed(let error):
            return "Action failed: \(error.localizedDescription)"
        }
    }
}

// MARK: - Message Extension

private extension Message {
    /// Text content of the message for search.
    var textContent: String? {
        switch content {
        case .text(let formatted):
            return formatted.text
        case .photo(let photo):
            return photo.caption?.text
        case .video(let video):
            return video.caption?.text
        case .document(let doc):
            return doc.caption?.text ?? doc.fileName
        default:
            return nil
        }
    }
}
