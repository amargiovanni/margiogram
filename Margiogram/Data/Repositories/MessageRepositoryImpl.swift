//
//  MessageRepositoryImpl.swift
//  Margiogram
//
//  Created by Andrea Margiovanni on 2024.
//

import Foundation

// MARK: - Message Repository Implementation

/// Implementation of MessageRepository using TDLib.
actor MessageRepositoryImpl: MessageRepository {
    // MARK: - Properties

    private var messageCache: [Int64: [Int64: Message]] = [:] // chatId -> (messageId -> Message)

    // MARK: - Initialization

    init() {}

    // MARK: - MessageRepository

    func getChatHistory(
        chatId: Int64,
        fromMessageId: Int64,
        offset: Int32,
        limit: Int32
    ) async throws -> [Message] {
        // In real implementation: call TDLib's getChatHistory
        #if DEBUG
        return Message.mockConversation
        #else
        return []
        #endif
    }

    func sendTextMessage(
        chatId: Int64,
        text: String,
        replyToMessageId: Int64?
    ) async throws -> Message {
        // In real implementation: call TDLib's sendMessage with inputMessageText
        #if DEBUG
        let message = Message.mock(
            chatId: chatId,
            text: text,
            isOutgoing: true,
            date: Date()
        )
        cacheMessage(message)
        return message
        #else
        throw MessageRepositoryError.sendFailed("Not implemented")
        #endif
    }

    func sendMediaMessage(
        chatId: Int64,
        content: InputMessageContent,
        replyToMessageId: Int64?
    ) async throws -> Message {
        // In real implementation: call TDLib's sendMessage with appropriate content
        #if DEBUG
        return Message.mock(chatId: chatId, isOutgoing: true)
        #else
        throw MessageRepositoryError.sendFailed("Not implemented")
        #endif
    }

    func editMessageText(
        chatId: Int64,
        messageId: Int64,
        text: String
    ) async throws {
        // In real implementation: call TDLib's editMessageText
    }

    func deleteMessages(
        chatId: Int64,
        messageIds: [Int64],
        revoke: Bool
    ) async throws {
        // In real implementation: call TDLib's deleteMessages
        for messageId in messageIds {
            messageCache[chatId]?.removeValue(forKey: messageId)
        }
    }

    func forwardMessages(
        chatId: Int64,
        fromChatId: Int64,
        messageIds: [Int64]
    ) async throws -> [Message] {
        // In real implementation: call TDLib's forwardMessages
        return []
    }

    func viewMessages(
        chatId: Int64,
        messageIds: [Int64]
    ) async throws {
        // In real implementation: call TDLib's viewMessages
    }

    func searchChatMessages(
        chatId: Int64,
        query: String,
        fromMessageId: Int64,
        limit: Int32
    ) async throws -> [Message] {
        // In real implementation: call TDLib's searchChatMessages
        return []
    }

    func searchMessages(
        query: String,
        offset: String?,
        limit: Int32
    ) async throws -> (messages: [Message], nextOffset: String?) {
        // In real implementation: call TDLib's searchMessages
        return ([], nil)
    }

    func getMessage(chatId: Int64, messageId: Int64) async throws -> Message {
        if let cached = messageCache[chatId]?[messageId] {
            return cached
        }

        // In real implementation: call TDLib's getMessage
        throw MessageRepositoryError.messageNotFound(messageId)
    }

    func addMessageReaction(
        chatId: Int64,
        messageId: Int64,
        reaction: ReactionType
    ) async throws {
        // In real implementation: call TDLib's addMessageReaction
    }

    func removeMessageReaction(
        chatId: Int64,
        messageId: Int64,
        reaction: ReactionType
    ) async throws {
        // In real implementation: call TDLib's removeMessageReaction
    }

    // MARK: - Cache Management

    private func cacheMessage(_ message: Message) {
        if messageCache[message.chatId] == nil {
            messageCache[message.chatId] = [:]
        }
        messageCache[message.chatId]?[message.id] = message
    }

    func invalidateCache(for chatId: Int64) {
        messageCache.removeValue(forKey: chatId)
    }

    func invalidateAllCache() {
        messageCache.removeAll()
    }
}

// MARK: - Message Repository Error

enum MessageRepositoryError: LocalizedError {
    case messageNotFound(Int64)
    case sendFailed(String)
    case editFailed(String)
    case deleteFailed(String)

    var errorDescription: String? {
        switch self {
        case .messageNotFound(let id):
            return "Message not found: \(id)"
        case .sendFailed(let reason):
            return "Failed to send message: \(reason)"
        case .editFailed(let reason):
            return "Failed to edit message: \(reason)"
        case .deleteFailed(let reason):
            return "Failed to delete message: \(reason)"
        }
    }
}
