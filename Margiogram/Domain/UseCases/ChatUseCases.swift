//
//  ChatUseCases.swift
//  Margiogram
//
//  Created by Andrea Margiovanni on 2024.
//

import Foundation

// MARK: - Get Chats Use Case

/// Use case for getting the list of chats.
struct GetChatsUseCase {
    private let repository: ChatRepository

    init(repository: ChatRepository) {
        self.repository = repository
    }

    func execute(
        chatList: ChatList = .main,
        limit: Int = 30,
        offsetOrder: Int64 = Int64.max,
        offsetChatId: Int64 = 0
    ) async throws -> [Chat] {
        try await repository.getChats(
            chatList: chatList,
            limit: limit,
            offsetOrder: offsetOrder,
            offsetChatId: offsetChatId
        )
    }
}

// MARK: - Get Chat Use Case

/// Use case for getting a single chat.
struct GetChatUseCase {
    private let repository: ChatRepository

    init(repository: ChatRepository) {
        self.repository = repository
    }

    func execute(chatId: Int64) async throws -> Chat {
        try await repository.getChat(chatId: chatId)
    }
}

// MARK: - Create Private Chat Use Case

/// Use case for creating a private chat with a user.
struct CreatePrivateChatUseCase {
    private let repository: ChatRepository

    init(repository: ChatRepository) {
        self.repository = repository
    }

    func execute(userId: Int64) async throws -> Chat {
        try await repository.createPrivateChat(userId: userId)
    }
}

// MARK: - Search Chats Use Case

/// Use case for searching chats.
struct SearchChatsUseCase {
    private let repository: ChatRepository

    init(repository: ChatRepository) {
        self.repository = repository
    }

    func execute(query: String, limit: Int = 30) async throws -> [Chat] {
        try await repository.searchChats(query: query, limit: limit)
    }
}

// MARK: - Pin Chat Use Case

/// Use case for pinning/unpinning a chat.
struct ToggleChatPinUseCase {
    private let repository: ChatRepository

    init(repository: ChatRepository) {
        self.repository = repository
    }

    func execute(chatId: Int64, chatList: ChatList = .main, isPinned: Bool) async throws {
        try await repository.toggleChatIsPinned(chatId: chatId, chatList: chatList, isPinned: isPinned)
    }
}

// MARK: - Mute Chat Use Case

/// Use case for muting/unmuting a chat.
struct MuteChatUseCase {
    private let repository: ChatRepository

    init(repository: ChatRepository) {
        self.repository = repository
    }

    func execute(chatId: Int64, muteFor: Int32) async throws {
        try await repository.setChatNotificationSettings(chatId: chatId, muteFor: muteFor, sound: nil)
    }

    func mute(chatId: Int64) async throws {
        // Mute forever
        try await execute(chatId: chatId, muteFor: Int32.max)
    }

    func unmute(chatId: Int64) async throws {
        try await execute(chatId: chatId, muteFor: 0)
    }
}

// MARK: - Archive Chat Use Case

/// Use case for archiving a chat.
struct ArchiveChatUseCase {
    private let repository: ChatRepository

    init(repository: ChatRepository) {
        self.repository = repository
    }

    func execute(chatId: Int64, archive: Bool) async throws {
        let targetList: ChatList = archive ? .archive : .main
        try await repository.addChatToList(chatId: chatId, chatList: targetList)
    }
}

// MARK: - Leave Chat Use Case

/// Use case for leaving a chat.
struct LeaveChatUseCase {
    private let repository: ChatRepository

    init(repository: ChatRepository) {
        self.repository = repository
    }

    func execute(chatId: Int64) async throws {
        try await repository.leaveChat(chatId: chatId)
    }
}

// MARK: - Delete Chat Use Case

/// Use case for deleting a chat.
struct DeleteChatUseCase {
    private let repository: ChatRepository

    init(repository: ChatRepository) {
        self.repository = repository
    }

    func execute(chatId: Int64) async throws {
        try await repository.deleteChat(chatId: chatId)
    }
}

// MARK: - Clear Chat History Use Case

/// Use case for clearing chat history.
struct ClearChatHistoryUseCase {
    private let repository: ChatRepository

    init(repository: ChatRepository) {
        self.repository = repository
    }

    func execute(chatId: Int64, removeFromChatList: Bool = false) async throws {
        try await repository.clearChatHistory(chatId: chatId, removeFromChatList: removeFromChatList)
    }
}

// MARK: - Get Chat Folders Use Case

/// Use case for getting chat folders.
struct GetChatFoldersUseCase {
    private let repository: ChatRepository

    init(repository: ChatRepository) {
        self.repository = repository
    }

    func execute() async throws -> [ChatFolder] {
        try await repository.getChatFolders()
    }
}
