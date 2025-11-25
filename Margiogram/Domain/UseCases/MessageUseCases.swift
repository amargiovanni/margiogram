//
//  MessageUseCases.swift
//  Margiogram
//
//  Created by Andrea Margiovanni on 2024.
//

import Foundation

// MARK: - Get Messages Use Case

/// Use case for getting chat messages.
struct GetMessagesUseCase {
    private let repository: MessageRepository

    init(repository: MessageRepository) {
        self.repository = repository
    }

    func execute(
        chatId: Int64,
        fromMessageId: Int64 = 0,
        offset: Int32 = 0,
        limit: Int32 = 50
    ) async throws -> [Message] {
        try await repository.getChatHistory(
            chatId: chatId,
            fromMessageId: fromMessageId,
            offset: offset,
            limit: limit
        )
    }
}

// MARK: - Send Text Message Use Case

/// Use case for sending a text message.
struct SendTextMessageUseCase {
    private let repository: MessageRepository

    init(repository: MessageRepository) {
        self.repository = repository
    }

    func execute(
        chatId: Int64,
        text: String,
        replyToMessageId: Int64? = nil
    ) async throws -> Message {
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw MessageUseCaseError.emptyMessage
        }

        return try await repository.sendTextMessage(
            chatId: chatId,
            text: text,
            replyToMessageId: replyToMessageId
        )
    }
}

// MARK: - Send Media Message Use Case

/// Use case for sending media messages (photos, videos, etc.).
struct SendMediaMessageUseCase {
    private let repository: MessageRepository

    init(repository: MessageRepository) {
        self.repository = repository
    }

    func execute(
        chatId: Int64,
        content: InputMessageContent,
        replyToMessageId: Int64? = nil
    ) async throws -> Message {
        try await repository.sendMediaMessage(
            chatId: chatId,
            content: content,
            replyToMessageId: replyToMessageId
        )
    }
}

// MARK: - Edit Message Use Case

/// Use case for editing a message.
struct EditMessageUseCase {
    private let repository: MessageRepository

    init(repository: MessageRepository) {
        self.repository = repository
    }

    func execute(
        chatId: Int64,
        messageId: Int64,
        text: String
    ) async throws {
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw MessageUseCaseError.emptyMessage
        }

        try await repository.editMessageText(
            chatId: chatId,
            messageId: messageId,
            text: text
        )
    }
}

// MARK: - Delete Messages Use Case

/// Use case for deleting messages.
struct DeleteMessagesUseCase {
    private let repository: MessageRepository

    init(repository: MessageRepository) {
        self.repository = repository
    }

    func execute(
        chatId: Int64,
        messageIds: [Int64],
        forAll: Bool = false
    ) async throws {
        guard !messageIds.isEmpty else {
            throw MessageUseCaseError.noMessagesSelected
        }

        try await repository.deleteMessages(
            chatId: chatId,
            messageIds: messageIds,
            revoke: forAll
        )
    }
}

// MARK: - Forward Messages Use Case

/// Use case for forwarding messages.
struct ForwardMessagesUseCase {
    private let repository: MessageRepository

    init(repository: MessageRepository) {
        self.repository = repository
    }

    func execute(
        toChatId: Int64,
        fromChatId: Int64,
        messageIds: [Int64]
    ) async throws -> [Message] {
        guard !messageIds.isEmpty else {
            throw MessageUseCaseError.noMessagesSelected
        }

        return try await repository.forwardMessages(
            chatId: toChatId,
            fromChatId: fromChatId,
            messageIds: messageIds
        )
    }
}

// MARK: - Mark Messages Read Use Case

/// Use case for marking messages as read.
struct MarkMessagesReadUseCase {
    private let repository: MessageRepository

    init(repository: MessageRepository) {
        self.repository = repository
    }

    func execute(chatId: Int64, messageIds: [Int64]) async throws {
        try await repository.viewMessages(chatId: chatId, messageIds: messageIds)
    }
}

// MARK: - Search Messages Use Case

/// Use case for searching messages.
struct SearchMessagesUseCase {
    private let repository: MessageRepository

    init(repository: MessageRepository) {
        self.repository = repository
    }

    func execute(
        query: String,
        offset: String? = nil,
        limit: Int32 = 50
    ) async throws -> (messages: [Message], nextOffset: String?) {
        guard !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return ([], nil)
        }

        return try await repository.searchMessages(
            query: query,
            offset: offset,
            limit: limit
        )
    }

    func searchInChat(
        chatId: Int64,
        query: String,
        fromMessageId: Int64 = 0,
        limit: Int32 = 50
    ) async throws -> [Message] {
        guard !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return []
        }

        return try await repository.searchChatMessages(
            chatId: chatId,
            query: query,
            fromMessageId: fromMessageId,
            limit: limit
        )
    }
}

// MARK: - Add Reaction Use Case

/// Use case for adding a reaction to a message.
struct AddReactionUseCase {
    private let repository: MessageRepository

    init(repository: MessageRepository) {
        self.repository = repository
    }

    func execute(
        chatId: Int64,
        messageId: Int64,
        reaction: ReactionType
    ) async throws {
        try await repository.addMessageReaction(
            chatId: chatId,
            messageId: messageId,
            reaction: reaction
        )
    }
}

// MARK: - Remove Reaction Use Case

/// Use case for removing a reaction from a message.
struct RemoveReactionUseCase {
    private let repository: MessageRepository

    init(repository: MessageRepository) {
        self.repository = repository
    }

    func execute(
        chatId: Int64,
        messageId: Int64,
        reaction: ReactionType
    ) async throws {
        try await repository.removeMessageReaction(
            chatId: chatId,
            messageId: messageId,
            reaction: reaction
        )
    }
}

// MARK: - Message Use Case Error

enum MessageUseCaseError: LocalizedError {
    case emptyMessage
    case noMessagesSelected

    var errorDescription: String? {
        switch self {
        case .emptyMessage:
            return "Message cannot be empty"
        case .noMessagesSelected:
            return "No messages selected"
        }
    }
}
