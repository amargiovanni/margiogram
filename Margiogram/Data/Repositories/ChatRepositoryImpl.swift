//
//  ChatRepositoryImpl.swift
//  Margiogram
//
//  Created by Andrea Margiovanni on 2024.
//

import Foundation

// MARK: - Chat Repository Implementation

/// Implementation of ChatRepository using TDLib.
actor ChatRepositoryImpl: ChatRepository {
    // MARK: - Properties

    private var chatCache: [Int64: Chat] = [:]

    // MARK: - Initialization

    init() {}

    // MARK: - ChatRepository

    func getChats(
        chatList: ChatList,
        limit: Int,
        offsetOrder: Int64,
        offsetChatId: Int64
    ) async throws -> [Chat] {
        // In real implementation: call TDLib's getChats
        #if DEBUG
        return Chat.mockList
        #else
        return []
        #endif
    }

    func getChat(chatId: Int64) async throws -> Chat {
        if let cached = chatCache[chatId] {
            return cached
        }

        // In real implementation: call TDLib's getChat
        #if DEBUG
        let chat = Chat.mock(id: chatId)
        chatCache[chatId] = chat
        return chat
        #else
        throw ChatRepositoryError.chatNotFound(chatId)
        #endif
    }

    func createPrivateChat(userId: Int64) async throws -> Chat {
        // In real implementation: call TDLib's createPrivateChat
        #if DEBUG
        return Chat.mock(type: .private(userId: userId, isBot: false))
        #else
        throw ChatRepositoryError.operationFailed("Not implemented")
        #endif
    }

    func searchChats(query: String, limit: Int) async throws -> [Chat] {
        // In real implementation: call TDLib's searchChats
        #if DEBUG
        return Chat.mockList.filter { $0.title.lowercased().contains(query.lowercased()) }
        #else
        return []
        #endif
    }

    func searchPublicChats(query: String) async throws -> [Chat] {
        // In real implementation: call TDLib's searchPublicChats
        return []
    }

    func setChatNotificationSettings(
        chatId: Int64,
        muteFor: Int32,
        sound: String?
    ) async throws {
        // In real implementation: call TDLib's setChatNotificationSettings
    }

    func toggleChatIsPinned(
        chatId: Int64,
        chatList: ChatList,
        isPinned: Bool
    ) async throws {
        // In real implementation: call TDLib's toggleChatIsPinned
        if var chat = chatCache[chatId] {
            chat.isPinned = isPinned
            chatCache[chatId] = chat
        }
    }

    func toggleChatIsMarkedAsUnread(
        chatId: Int64,
        isMarkedAsUnread: Bool
    ) async throws {
        // In real implementation: call TDLib's toggleChatIsMarkedAsUnread
        if var chat = chatCache[chatId] {
            chat.isMarkedAsUnread = isMarkedAsUnread
            chatCache[chatId] = chat
        }
    }

    func addChatToList(chatId: Int64, chatList: ChatList) async throws {
        // In real implementation: call TDLib's addChatToList
    }

    func leaveChat(chatId: Int64) async throws {
        // In real implementation: call TDLib's leaveChat
        chatCache.removeValue(forKey: chatId)
    }

    func deleteChat(chatId: Int64) async throws {
        // In real implementation: call TDLib's deleteChat
        chatCache.removeValue(forKey: chatId)
    }

    func getChatFolders() async throws -> [ChatFolder] {
        // In real implementation: call TDLib's getChatFolders
        return []
    }

    func createChatFolder(_ folder: ChatFolder) async throws -> Int32 {
        // In real implementation: call TDLib's createChatFolder
        return folder.id
    }

    func editChatFolder(folderId: Int32, folder: ChatFolder) async throws {
        // In real implementation: call TDLib's editChatFolder
    }

    func deleteChatFolder(folderId: Int32) async throws {
        // In real implementation: call TDLib's deleteChatFolder
    }

    func clearChatHistory(chatId: Int64, removeFromChatList: Bool) async throws {
        // In real implementation: call TDLib's deleteChatHistory
    }

    // MARK: - Cache Management

    func updateChatCache(_ chat: Chat) {
        chatCache[chat.id] = chat
    }

    func invalidateCache() {
        chatCache.removeAll()
    }
}

// MARK: - Chat Repository Error

enum ChatRepositoryError: LocalizedError {
    case chatNotFound(Int64)
    case operationFailed(String)

    var errorDescription: String? {
        switch self {
        case .chatNotFound(let id):
            return "Chat not found: \(id)"
        case .operationFailed(let reason):
            return "Operation failed: \(reason)"
        }
    }
}
