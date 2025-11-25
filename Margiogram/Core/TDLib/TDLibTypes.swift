//
//  TDLibTypes.swift
//  Margiogram
//
//  Created by Andrea Margiovanni on 2024.
//

import Foundation

// MARK: - TDLib Base Protocol

/// Protocol for TDLib functions that can be executed.
protocol TDFunction {
    associatedtype Result
    func encode() throws -> [String: Any]
}

// MARK: - Ok Result Type

/// Represents a successful TDLib operation with no return value.
struct Ok: Sendable {
    static let ok = Ok()
}

// MARK: - TDLib Update Enum

/// Enum representing different types of TDLib updates.
enum TDUpdate {
    case connectionStateUpdate(ConnectionState)
    case authorizationStateUpdate(AuthorizationState)
    case newMessage(Message)
    case messageEdited(chatId: Int64, messageId: Int64, content: MessageContent)
    case messagesDeleted(chatId: Int64, messageIds: [Int64])
    case chatUpdated(Chat)
    case userUpdated(User)
    case userStatusUpdated(userId: Int64, status: UserStatus)
    case fileUpdated(TDFile)
}
