//
//  TDLibUpdateHandler.swift
//  Margiogram
//
//  Created by Andrea Margiovanni on 2024.
//

import Foundation
import OSLog

// MARK: - TDLib Update Handler

/// Handles TDLib updates and dispatches them to appropriate handlers.
actor TDLibUpdateHandler {
    // MARK: - Shared Instance

    static let shared = TDLibUpdateHandler()

    // MARK: - Properties

    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "TDLibUpdates")

    // Delegate references
    private var authorizationDelegate: AuthorizationUpdateDelegate?
    private var chatDelegate: ChatUpdateDelegate?
    private var messageDelegate: MessageUpdateDelegate?
    private var userDelegate: UserUpdateDelegate?
    private var fileDelegate: FileUpdateDelegate?
    private var callDelegate: CallUpdateDelegate?

    // MARK: - Initialization

    private init() {}

    // MARK: - Delegate Registration

    func setAuthorizationDelegate(_ delegate: AuthorizationUpdateDelegate?) {
        authorizationDelegate = delegate
    }

    func setChatDelegate(_ delegate: ChatUpdateDelegate?) {
        chatDelegate = delegate
    }

    func setMessageDelegate(_ delegate: MessageUpdateDelegate?) {
        messageDelegate = delegate
    }

    func setUserDelegate(_ delegate: UserUpdateDelegate?) {
        userDelegate = delegate
    }

    func setFileDelegate(_ delegate: FileUpdateDelegate?) {
        fileDelegate = delegate
    }

    func setCallDelegate(_ delegate: CallUpdateDelegate?) {
        callDelegate = delegate
    }

    // MARK: - Update Handling

    /// Handles an incoming TDLib update.
    func handleUpdate(_ update: TDUpdate) async {
        logger.debug("Handling update: \(String(describing: update))")

        switch update {
        case .connectionStateUpdate(let state):
            await handleConnectionStateUpdate(state)

        case .authorizationStateUpdate(let state):
            await handleAuthorizationStateUpdate(state)

        case .newMessage(let message):
            await handleNewMessage(message)

        case .messageEdited(let chatId, let messageId, let content):
            await handleMessageEdited(chatId: chatId, messageId: messageId, content: content)

        case .messagesDeleted(let chatId, let messageIds):
            await handleMessagesDeleted(chatId: chatId, messageIds: messageIds)

        case .chatUpdated(let chat):
            await handleChatUpdated(chat)

        case .userUpdated(let user):
            await handleUserUpdated(user)

        case .userStatusUpdated(let userId, let status):
            await handleUserStatusUpdated(userId: userId, status: status)

        case .fileUpdated(let file):
            await handleFileUpdated(file)
        }
    }

    // MARK: - Private Handlers

    private func handleConnectionStateUpdate(_ state: ConnectionState) async {
        await authorizationDelegate?.didUpdateConnectionState(state)
    }

    private func handleAuthorizationStateUpdate(_ state: AuthorizationState) async {
        await authorizationDelegate?.didUpdateAuthorizationState(state)
    }

    private func handleNewMessage(_ message: Message) async {
        await messageDelegate?.didReceiveNewMessage(message)
        await chatDelegate?.didUpdateChatLastMessage(chatId: message.chatId, message: message)
    }

    private func handleMessageEdited(chatId: Int64, messageId: Int64, content: MessageContent) async {
        await messageDelegate?.didEditMessage(chatId: chatId, messageId: messageId, newContent: content)
    }

    private func handleMessagesDeleted(chatId: Int64, messageIds: [Int64]) async {
        await messageDelegate?.didDeleteMessages(chatId: chatId, messageIds: messageIds)
    }

    private func handleChatUpdated(_ chat: Chat) async {
        await chatDelegate?.didUpdateChat(chat)
    }

    private func handleUserUpdated(_ user: User) async {
        await userDelegate?.didUpdateUser(user)
    }

    private func handleUserStatusUpdated(userId: Int64, status: UserStatus) async {
        await userDelegate?.didUpdateUserStatus(userId: userId, status: status)
    }

    private func handleFileUpdated(_ file: File) async {
        await fileDelegate?.didUpdateFile(file)
    }
}

// MARK: - Update Delegates

/// Protocol for receiving authorization-related updates.
protocol AuthorizationUpdateDelegate: AnyObject, Sendable {
    func didUpdateAuthorizationState(_ state: AuthorizationState) async
    func didUpdateConnectionState(_ state: ConnectionState) async
}

/// Protocol for receiving chat-related updates.
protocol ChatUpdateDelegate: AnyObject, Sendable {
    func didUpdateChat(_ chat: Chat) async
    func didUpdateChatLastMessage(chatId: Int64, message: Message) async
    func didUpdateChatReadInbox(chatId: Int64, lastReadMessageId: Int64, unreadCount: Int32) async
    func didUpdateChatPosition(chatId: Int64, position: ChatPosition) async
    func didUpdateChatNotificationSettings(chatId: Int64, settings: NotificationSettings) async
}

/// Protocol for receiving message-related updates.
protocol MessageUpdateDelegate: AnyObject, Sendable {
    func didReceiveNewMessage(_ message: Message) async
    func didEditMessage(chatId: Int64, messageId: Int64, newContent: MessageContent) async
    func didDeleteMessages(chatId: Int64, messageIds: [Int64]) async
    func didUpdateMessageSendSucceeded(oldMessageId: Int64, message: Message) async
    func didUpdateMessageSendFailed(messageId: Int64, error: TDLibError) async
}

/// Protocol for receiving user-related updates.
protocol UserUpdateDelegate: AnyObject, Sendable {
    func didUpdateUser(_ user: User) async
    func didUpdateUserStatus(userId: Int64, status: UserStatus) async
    func didUpdateUserFullInfo(userId: Int64, fullInfo: UserFullInfo) async
}

/// Protocol for receiving file-related updates.
protocol FileUpdateDelegate: AnyObject, Sendable {
    func didUpdateFile(_ file: File) async
}

/// Protocol for receiving call-related updates.
protocol CallUpdateDelegate: AnyObject, Sendable {
    func didUpdateCall(_ call: TDCall) async
    func didUpdateCallSignaling(callId: Int32, data: Data) async
}

// MARK: - Supporting Types

struct ChatPosition: Equatable, Sendable {
    let list: ChatList
    let order: Int64
    let isPinned: Bool
}

struct NotificationSettings: Equatable, Sendable {
    let muteFor: Int32
    let sound: String
    let showPreview: Bool
    let disablePinnedMessageNotifications: Bool
    let disableMentionNotifications: Bool
}

struct TDCall: Identifiable, Equatable, Sendable {
    let id: Int32
    let userId: Int64
    let isOutgoing: Bool
    let isVideo: Bool
    let state: TDCallState
}

enum TDCallState: Equatable, Sendable {
    case pending(isCreated: Bool, isReceived: Bool)
    case exchangingKeys
    case ready
    case hangingUp
    case discarded(reason: CallDiscardReason)
    case error(TDLibError)
}

enum CallDiscardReason: Equatable, Sendable {
    case empty
    case missed
    case declined
    case disconnected
    case hungUp
}

// MARK: - TDLib Update Parser

/// Parses raw JSON updates from TDLib into typed updates.
struct TDLibUpdateParser {
    static func parse(_ json: [String: Any]) -> TDUpdate? {
        guard let type = json["@type"] as? String else { return nil }

        switch type {
        case "updateAuthorizationState":
            guard let stateJson = json["authorization_state"] as? [String: Any],
                  let state = parseAuthorizationState(stateJson) else { return nil }
            return .authorizationStateUpdate(state)

        case "updateConnectionState":
            guard let stateJson = json["state"] as? [String: Any],
                  let state = parseConnectionState(stateJson) else { return nil }
            return .connectionStateUpdate(state)

        case "updateNewMessage":
            guard let messageJson = json["message"] as? [String: Any],
                  let message = parseMessage(messageJson) else { return nil }
            return .newMessage(message)

        case "updateMessageContent":
            guard let chatId = json["chat_id"] as? Int64,
                  let messageId = json["message_id"] as? Int64,
                  let contentJson = json["new_content"] as? [String: Any],
                  let content = parseMessageContent(contentJson) else { return nil }
            return .messageEdited(chatId: chatId, messageId: messageId, content: content)

        case "updateDeleteMessages":
            guard let chatId = json["chat_id"] as? Int64,
                  let messageIds = json["message_ids"] as? [Int64],
                  let isPermanent = json["is_permanent"] as? Bool,
                  isPermanent else { return nil }
            return .messagesDeleted(chatId: chatId, messageIds: messageIds)

        case "updateUser":
            guard let userJson = json["user"] as? [String: Any],
                  let user = parseUser(userJson) else { return nil }
            return .userUpdated(user)

        case "updateUserStatus":
            guard let userId = json["user_id"] as? Int64,
                  let statusJson = json["status"] as? [String: Any],
                  let status = parseUserStatus(statusJson) else { return nil }
            return .userStatusUpdated(userId: userId, status: status)

        case "updateFile":
            guard let fileJson = json["file"] as? [String: Any],
                  let file = parseFile(fileJson) else { return nil }
            return .fileUpdated(file)

        default:
            return nil
        }
    }

    // MARK: - Parser Helpers

    private static func parseAuthorizationState(_ json: [String: Any]) -> AuthorizationState? {
        guard let type = json["@type"] as? String else { return nil }

        switch type {
        case "authorizationStateWaitTdlibParameters":
            return .waitingForTdlibParameters
        case "authorizationStateWaitPhoneNumber":
            return .waitingForPhoneNumber
        case "authorizationStateWaitCode":
            return .waitingForCode(isRegistered: json["is_registered"] as? Bool ?? true)
        case "authorizationStateWaitPassword":
            return .waitingForPassword(hint: json["password_hint"] as? String)
        case "authorizationStateReady":
            return .ready
        case "authorizationStateLoggingOut":
            return .loggingOut
        case "authorizationStateClosing":
            return .closing
        case "authorizationStateClosed":
            return .closed
        default:
            return nil
        }
    }

    private static func parseConnectionState(_ json: [String: Any]) -> ConnectionState? {
        guard let type = json["@type"] as? String else { return nil }

        switch type {
        case "connectionStateWaitingForNetwork":
            return .waitingForNetwork
        case "connectionStateConnectingToProxy":
            return .connectingToProxy
        case "connectionStateConnecting":
            return .connecting
        case "connectionStateUpdating":
            return .updating
        case "connectionStateReady":
            return .ready
        default:
            return nil
        }
    }

    private static func parseMessage(_ json: [String: Any]) -> Message? {
        // Simplified parsing - in real implementation, parse all fields
        guard let id = json["id"] as? Int64,
              let chatId = json["chat_id"] as? Int64 else { return nil }

        return Message(
            id: id,
            chatId: chatId,
            senderId: json["sender_id"] as? Int64 ?? 0,
            isOutgoing: json["is_outgoing"] as? Bool ?? false,
            date: Date(timeIntervalSince1970: TimeInterval(json["date"] as? Int ?? 0)),
            content: .text(""),
            replyToMessageId: json["reply_to_message_id"] as? Int64
        )
    }

    private static func parseMessageContent(_ json: [String: Any]) -> MessageContent? {
        guard let type = json["@type"] as? String else { return nil }

        switch type {
        case "messageText":
            if let textJson = json["text"] as? [String: Any],
               let text = textJson["text"] as? String {
                return .text(text)
            }
        default:
            break
        }

        return nil
    }

    private static func parseUser(_ json: [String: Any]) -> User? {
        guard let id = json["id"] as? Int64 else { return nil }

        return User(
            id: id,
            firstName: json["first_name"] as? String ?? "",
            lastName: json["last_name"] as? String ?? "",
            username: json["username"] as? String,
            phoneNumber: json["phone_number"] as? String,
            status: .offline,
            profilePhoto: nil,
            isVerified: json["is_verified"] as? Bool ?? false,
            isPremium: json["is_premium"] as? Bool ?? false,
            isContact: json["is_contact"] as? Bool ?? false,
            isMutualContact: json["is_mutual_contact"] as? Bool ?? false
        )
    }

    private static func parseUserStatus(_ json: [String: Any]) -> UserStatus? {
        guard let type = json["@type"] as? String else { return nil }

        switch type {
        case "userStatusOnline":
            return .online
        case "userStatusOffline":
            return .offline
        case "userStatusRecently":
            return .recently
        case "userStatusLastWeek":
            return .lastWeek
        case "userStatusLastMonth":
            return .lastMonth
        case "userStatusEmpty":
            return .unknown
        default:
            return nil
        }
    }

    private static func parseFile(_ json: [String: Any]) -> File? {
        guard let id = json["id"] as? Int32 else { return nil }

        let localJson = json["local"] as? [String: Any]
        let remoteJson = json["remote"] as? [String: Any]

        return File(
            id: id,
            size: Int64(json["size"] as? Int ?? 0),
            expectedSize: Int64(json["expected_size"] as? Int ?? 0),
            localPath: localJson?["path"] as? String,
            isDownloadingActive: localJson?["is_downloading_active"] as? Bool ?? false,
            isDownloadingCompleted: localJson?["is_downloading_completed"] as? Bool ?? false,
            downloadedSize: Int64(localJson?["downloaded_size"] as? Int ?? 0),
            remoteId: remoteJson?["id"] as? String,
            isUploadingActive: remoteJson?["is_uploading_active"] as? Bool ?? false,
            isUploadingCompleted: remoteJson?["is_uploading_completed"] as? Bool ?? false,
            uploadedSize: Int64(remoteJson?["uploaded_size"] as? Int ?? 0)
        )
    }
}

// MARK: - File

struct File: Identifiable, Equatable, Sendable {
    let id: Int32
    let size: Int64
    let expectedSize: Int64
    let localPath: String?
    let isDownloadingActive: Bool
    let isDownloadingCompleted: Bool
    let downloadedSize: Int64
    let remoteId: String?
    let isUploadingActive: Bool
    let isUploadingCompleted: Bool
    let uploadedSize: Int64

    var downloadProgress: Double {
        guard expectedSize > 0 else { return 0 }
        return Double(downloadedSize) / Double(expectedSize)
    }

    var uploadProgress: Double {
        guard size > 0 else { return 0 }
        return Double(uploadedSize) / Double(size)
    }
}
