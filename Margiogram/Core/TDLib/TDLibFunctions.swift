//
//  TDLibFunctions.swift
//  Margiogram
//
//  Created by Andrea Margiovanni on 2024.
//

import Foundation

// MARK: - Authentication Functions

/// Requests a QR code for authentication.
struct RequestQrCodeAuthentication: TDFunction {
    typealias Result = Ok

    let otherUserIds: [Int64]

    init(otherUserIds: [Int64] = []) {
        self.otherUserIds = otherUserIds
    }

    func encode() throws -> [String: Any] {
        [
            "@type": "requestQrCodeAuthentication",
            "other_user_ids": otherUserIds
        ]
    }
}

/// Logs out the user.
struct LogOut: TDFunction {
    typealias Result = Ok

    func encode() throws -> [String: Any] {
        ["@type": "logOut"]
    }
}

/// Closes the TDLib instance.
struct Close: TDFunction {
    typealias Result = Ok

    func encode() throws -> [String: Any] {
        ["@type": "close"]
    }
}

/// Gets current user information.
struct GetMe: TDFunction {
    typealias Result = User

    func encode() throws -> [String: Any] {
        ["@type": "getMe"]
    }
}

// MARK: - User Functions

/// Gets information about a user.
struct GetUser: TDFunction {
    typealias Result = User

    let userId: Int64

    func encode() throws -> [String: Any] {
        [
            "@type": "getUser",
            "user_id": userId
        ]
    }
}

/// Gets full information about a user.
struct GetUserFullInfo: TDFunction {
    typealias Result = UserFullInfo

    let userId: Int64

    func encode() throws -> [String: Any] {
        [
            "@type": "getUserFullInfo",
            "user_id": userId
        ]
    }
}

/// Searches contacts by query.
struct SearchContacts: TDFunction {
    typealias Result = Users

    let query: String
    let limit: Int32

    init(query: String, limit: Int32 = 50) {
        self.query = query
        self.limit = limit
    }

    func encode() throws -> [String: Any] {
        [
            "@type": "searchContacts",
            "query": query,
            "limit": limit
        ]
    }
}

/// Gets all contacts.
struct GetContacts: TDFunction {
    typealias Result = Users

    func encode() throws -> [String: Any] {
        ["@type": "getContacts"]
    }
}

/// Adds a contact.
struct AddContact: TDFunction {
    typealias Result = Ok

    let contact: Contact
    let sharePhoneNumber: Bool

    func encode() throws -> [String: Any] {
        [
            "@type": "addContact",
            "contact": [
                "@type": "contact",
                "phone_number": contact.phoneNumber,
                "first_name": contact.firstName,
                "last_name": contact.lastName
            ],
            "share_phone_number": sharePhoneNumber
        ]
    }
}

/// Removes contacts.
struct RemoveContacts: TDFunction {
    typealias Result = Ok

    let userIds: [Int64]

    func encode() throws -> [String: Any] {
        [
            "@type": "removeContacts",
            "user_ids": userIds
        ]
    }
}

// MARK: - Chat Functions

/// Creates a private chat with a user.
struct CreatePrivateChat: TDFunction {
    typealias Result = Chat

    let userId: Int64
    let force: Bool

    init(userId: Int64, force: Bool = false) {
        self.userId = userId
        self.force = force
    }

    func encode() throws -> [String: Any] {
        [
            "@type": "createPrivateChat",
            "user_id": userId,
            "force": force
        ]
    }
}

/// Opens a chat to enable updates.
struct OpenChat: TDFunction {
    typealias Result = Ok

    let chatId: Int64

    func encode() throws -> [String: Any] {
        [
            "@type": "openChat",
            "chat_id": chatId
        ]
    }
}

/// Closes a chat.
struct CloseChat: TDFunction {
    typealias Result = Ok

    let chatId: Int64

    func encode() throws -> [String: Any] {
        [
            "@type": "closeChat",
            "chat_id": chatId
        ]
    }
}

/// Gets chat history.
struct GetChatHistory: TDFunction {
    typealias Result = Messages

    let chatId: Int64
    let fromMessageId: Int64
    let offset: Int32
    let limit: Int32
    let onlyLocal: Bool

    init(
        chatId: Int64,
        fromMessageId: Int64 = 0,
        offset: Int32 = 0,
        limit: Int32 = 50,
        onlyLocal: Bool = false
    ) {
        self.chatId = chatId
        self.fromMessageId = fromMessageId
        self.offset = offset
        self.limit = limit
        self.onlyLocal = onlyLocal
    }

    func encode() throws -> [String: Any] {
        [
            "@type": "getChatHistory",
            "chat_id": chatId,
            "from_message_id": fromMessageId,
            "offset": offset,
            "limit": limit,
            "only_local": onlyLocal
        ]
    }
}

/// Searches messages in a chat.
struct SearchChatMessages: TDFunction {
    typealias Result = FoundChatMessages

    let chatId: Int64
    let query: String
    let senderId: MessageSender?
    let fromMessageId: Int64
    let offset: Int32
    let limit: Int32
    let filter: SearchMessagesFilter?

    init(
        chatId: Int64,
        query: String = "",
        senderId: MessageSender? = nil,
        fromMessageId: Int64 = 0,
        offset: Int32 = 0,
        limit: Int32 = 50,
        filter: SearchMessagesFilter? = nil
    ) {
        self.chatId = chatId
        self.query = query
        self.senderId = senderId
        self.fromMessageId = fromMessageId
        self.offset = offset
        self.limit = limit
        self.filter = filter
    }

    func encode() throws -> [String: Any] {
        var dict: [String: Any] = [
            "@type": "searchChatMessages",
            "chat_id": chatId,
            "query": query,
            "from_message_id": fromMessageId,
            "offset": offset,
            "limit": limit
        ]

        if let filter = filter {
            dict["filter"] = filter.encode()
        }

        return dict
    }
}

/// Toggles chat pinned state.
struct ToggleChatIsPinned: TDFunction {
    typealias Result = Ok

    let chatList: ChatList
    let chatId: Int64
    let isPinned: Bool

    func encode() throws -> [String: Any] {
        [
            "@type": "toggleChatIsPinned",
            "chat_list": chatList.encode(),
            "chat_id": chatId,
            "is_pinned": isPinned
        ]
    }
}

/// Sets chat notification settings.
struct SetChatNotificationSettings: TDFunction {
    typealias Result = Ok

    let chatId: Int64
    let notificationSettings: ChatNotificationSettings

    func encode() throws -> [String: Any] {
        [
            "@type": "setChatNotificationSettings",
            "chat_id": chatId,
            "notification_settings": notificationSettings.encode()
        ]
    }
}

/// Marks chat messages as read.
struct ViewMessages: TDFunction {
    typealias Result = Ok

    let chatId: Int64
    let messageIds: [Int64]
    let forceRead: Bool

    init(chatId: Int64, messageIds: [Int64], forceRead: Bool = true) {
        self.chatId = chatId
        self.messageIds = messageIds
        self.forceRead = forceRead
    }

    func encode() throws -> [String: Any] {
        [
            "@type": "viewMessages",
            "chat_id": chatId,
            "message_ids": messageIds,
            "force_read": forceRead
        ]
    }
}

// MARK: - Message Functions

/// Gets a message by ID.
struct GetMessage: TDFunction {
    typealias Result = Message

    let chatId: Int64
    let messageId: Int64

    func encode() throws -> [String: Any] {
        [
            "@type": "getMessage",
            "chat_id": chatId,
            "message_id": messageId
        ]
    }
}

/// Edits a text message.
struct EditMessageText: TDFunction {
    typealias Result = Message

    let chatId: Int64
    let messageId: Int64
    let inputMessageContent: InputMessageContent

    func encode() throws -> [String: Any] {
        [
            "@type": "editMessageText",
            "chat_id": chatId,
            "message_id": messageId,
            "input_message_content": inputMessageContent.encode()
        ]
    }
}

/// Deletes messages.
struct DeleteMessages: TDFunction {
    typealias Result = Ok

    let chatId: Int64
    let messageIds: [Int64]
    let revoke: Bool

    func encode() throws -> [String: Any] {
        [
            "@type": "deleteMessages",
            "chat_id": chatId,
            "message_ids": messageIds,
            "revoke": revoke
        ]
    }
}

/// Forwards messages.
struct ForwardMessages: TDFunction {
    typealias Result = Messages

    let chatId: Int64
    let fromChatId: Int64
    let messageIds: [Int64]
    let sendCopy: Bool
    let removeCaption: Bool

    init(
        chatId: Int64,
        fromChatId: Int64,
        messageIds: [Int64],
        sendCopy: Bool = false,
        removeCaption: Bool = false
    ) {
        self.chatId = chatId
        self.fromChatId = fromChatId
        self.messageIds = messageIds
        self.sendCopy = sendCopy
        self.removeCaption = removeCaption
    }

    func encode() throws -> [String: Any] {
        [
            "@type": "forwardMessages",
            "chat_id": chatId,
            "from_chat_id": fromChatId,
            "message_ids": messageIds,
            "send_copy": sendCopy,
            "remove_caption": removeCaption
        ]
    }
}

/// Adds a reaction to a message.
struct AddMessageReaction: TDFunction {
    typealias Result = Ok

    let chatId: Int64
    let messageId: Int64
    let reactionType: ReactionType
    let isBig: Bool
    let updateRecentReactions: Bool

    init(
        chatId: Int64,
        messageId: Int64,
        reactionType: ReactionType,
        isBig: Bool = false,
        updateRecentReactions: Bool = true
    ) {
        self.chatId = chatId
        self.messageId = messageId
        self.reactionType = reactionType
        self.isBig = isBig
        self.updateRecentReactions = updateRecentReactions
    }

    func encode() throws -> [String: Any] {
        [
            "@type": "addMessageReaction",
            "chat_id": chatId,
            "message_id": messageId,
            "reaction_type": reactionType.encode(),
            "is_big": isBig,
            "update_recent_reactions": updateRecentReactions
        ]
    }
}

// MARK: - File Functions

/// Downloads a file.
struct DownloadFile: TDFunction {
    typealias Result = File

    let fileId: Int32
    let priority: Int32
    let offset: Int64
    let limit: Int64
    let synchronous: Bool

    init(
        fileId: Int32,
        priority: Int32 = 1,
        offset: Int64 = 0,
        limit: Int64 = 0,
        synchronous: Bool = false
    ) {
        self.fileId = fileId
        self.priority = priority
        self.offset = offset
        self.limit = limit
        self.synchronous = synchronous
    }

    func encode() throws -> [String: Any] {
        [
            "@type": "downloadFile",
            "file_id": fileId,
            "priority": priority,
            "offset": offset,
            "limit": limit,
            "synchronous": synchronous
        ]
    }
}

/// Cancels a file download.
struct CancelDownloadFile: TDFunction {
    typealias Result = Ok

    let fileId: Int32
    let onlyIfPending: Bool

    init(fileId: Int32, onlyIfPending: Bool = false) {
        self.fileId = fileId
        self.onlyIfPending = onlyIfPending
    }

    func encode() throws -> [String: Any] {
        [
            "@type": "cancelDownloadFile",
            "file_id": fileId,
            "only_if_pending": onlyIfPending
        ]
    }
}

// MARK: - Call Functions

/// Creates a call.
struct CreateCall: TDFunction {
    typealias Result = CallId

    let userId: Int64
    let isVideo: Bool

    func encode() throws -> [String: Any] {
        [
            "@type": "createCall",
            "user_id": userId,
            "protocol": [
                "@type": "callProtocol",
                "udp_p2p": true,
                "udp_reflector": true,
                "min_layer": 65,
                "max_layer": 65
            ],
            "is_video": isVideo
        ]
    }
}

/// Accepts an incoming call.
struct AcceptCall: TDFunction {
    typealias Result = Ok

    let callId: Int32

    func encode() throws -> [String: Any] {
        [
            "@type": "acceptCall",
            "call_id": callId,
            "protocol": [
                "@type": "callProtocol",
                "udp_p2p": true,
                "udp_reflector": true,
                "min_layer": 65,
                "max_layer": 65
            ]
        ]
    }
}

/// Discards a call.
struct DiscardCall: TDFunction {
    typealias Result = Ok

    let callId: Int32
    let isDisconnected: Bool
    let duration: Int32
    let isVideo: Bool

    func encode() throws -> [String: Any] {
        [
            "@type": "discardCall",
            "call_id": callId,
            "is_disconnected": isDisconnected,
            "duration": duration,
            "is_video": isVideo
        ]
    }
}

// MARK: - Sticker Functions

/// Gets installed sticker sets.
struct GetInstalledStickerSets: TDFunction {
    typealias Result = StickerSets

    let stickerType: StickerType

    init(stickerType: StickerType = .regular) {
        self.stickerType = stickerType
    }

    func encode() throws -> [String: Any] {
        [
            "@type": "getInstalledStickerSets",
            "sticker_type": stickerType.encode()
        ]
    }
}

/// Gets saved animations (GIFs).
struct GetSavedAnimations: TDFunction {
    typealias Result = Animations

    func encode() throws -> [String: Any] {
        ["@type": "getSavedAnimations"]
    }
}

/// Gets recent stickers.
struct GetRecentStickers: TDFunction {
    typealias Result = Stickers

    let isAttached: Bool

    init(isAttached: Bool = false) {
        self.isAttached = isAttached
    }

    func encode() throws -> [String: Any] {
        [
            "@type": "getRecentStickers",
            "is_attached": isAttached
        ]
    }
}

/// Gets favorite stickers.
struct GetFavoriteStickers: TDFunction {
    typealias Result = Stickers

    func encode() throws -> [String: Any] {
        ["@type": "getFavoriteStickers"]
    }
}

// MARK: - Profile Functions

/// Sets the user's name.
struct SetName: TDFunction {
    typealias Result = Ok

    let firstName: String
    let lastName: String

    func encode() throws -> [String: Any] {
        [
            "@type": "setName",
            "first_name": firstName,
            "last_name": lastName
        ]
    }
}

/// Sets the user's bio.
struct SetBio: TDFunction {
    typealias Result = Ok

    let bio: String

    func encode() throws -> [String: Any] {
        [
            "@type": "setBio",
            "bio": bio
        ]
    }
}

/// Sets the username.
struct SetUsername: TDFunction {
    typealias Result = Ok

    let username: String

    func encode() throws -> [String: Any] {
        [
            "@type": "setUsername",
            "username": username
        ]
    }
}

/// Sets the profile photo.
struct SetProfilePhoto: TDFunction {
    typealias Result = Ok

    let photo: InputChatPhoto

    func encode() throws -> [String: Any] {
        [
            "@type": "setProfilePhoto",
            "photo": photo.encode()
        ]
    }
}

// MARK: - Supporting Types

struct Users {
    let totalCount: Int32
    let userIds: [Int64]
}

struct Messages {
    let totalCount: Int32
    let messages: [Message]
}

struct FoundChatMessages {
    let totalCount: Int32
    let messages: [Message]
    let nextFromMessageId: Int64
}

struct CallId {
    let id: Int32
}

struct StickerSets {
    let totalCount: Int32
    let sets: [StickerSetInfo]
}

struct StickerSetInfo: Identifiable {
    let id: Int64
    let title: String
    let name: String
    let stickerCount: Int32
    let isInstalled: Bool
}

struct Stickers {
    let stickers: [StickerInfo]
}

struct StickerInfo: Identifiable {
    let id: Int32
    let setId: Int64
    let emoji: String
}

struct Animations {
    let animations: [AnimationInfo]
}

struct AnimationInfo: Identifiable {
    let id: Int32
    let duration: Int32
    let width: Int32
    let height: Int32
}

struct Contact: Sendable {
    let phoneNumber: String
    let firstName: String
    let lastName: String
}

struct ChatNotificationSettings {
    let muteFor: Int32
    let showPreview: Bool

    func encode() -> [String: Any] {
        [
            "@type": "chatNotificationSettings",
            "mute_for": muteFor,
            "show_preview": showPreview
        ]
    }
}

enum SearchMessagesFilter {
    case empty
    case animation
    case audio
    case document
    case photo
    case video
    case voiceNote
    case photoAndVideo
    case url
    case chatPhoto
    case mention
    case unreadMention

    func encode() -> [String: Any] {
        let type: String
        switch self {
        case .empty: type = "searchMessagesFilterEmpty"
        case .animation: type = "searchMessagesFilterAnimation"
        case .audio: type = "searchMessagesFilterAudio"
        case .document: type = "searchMessagesFilterDocument"
        case .photo: type = "searchMessagesFilterPhoto"
        case .video: type = "searchMessagesFilterVideo"
        case .voiceNote: type = "searchMessagesFilterVoiceNote"
        case .photoAndVideo: type = "searchMessagesFilterPhotoAndVideo"
        case .url: type = "searchMessagesFilterUrl"
        case .chatPhoto: type = "searchMessagesFilterChatPhoto"
        case .mention: type = "searchMessagesFilterMention"
        case .unreadMention: type = "searchMessagesFilterUnreadMention"
        }
        return ["@type": type]
    }
}

enum StickerType {
    case regular
    case mask
    case customEmoji

    func encode() -> [String: Any] {
        let type: String
        switch self {
        case .regular: type = "stickerTypeRegular"
        case .mask: type = "stickerTypeMask"
        case .customEmoji: type = "stickerTypeCustomEmoji"
        }
        return ["@type": type]
    }
}

enum ReactionType {
    case emoji(String)
    case customEmoji(Int64)

    func encode() -> [String: Any] {
        switch self {
        case .emoji(let emoji):
            return ["@type": "reactionTypeEmoji", "emoji": emoji]
        case .customEmoji(let customEmojiId):
            return ["@type": "reactionTypeCustomEmoji", "custom_emoji_id": customEmojiId]
        }
    }
}

enum MessageSender {
    case user(Int64)
    case chat(Int64)
}

enum InputChatPhoto {
    case previous(Int64)
    case still(InputFile)
    case animation(InputFile, Double)

    func encode() -> [String: Any] {
        switch self {
        case .previous(let id):
            return ["@type": "inputChatPhotoPrevious", "chat_photo_id": id]
        case .still(let file):
            return ["@type": "inputChatPhotoStill", "photo": file.encode()]
        case .animation(let file, let mainFrameTimestamp):
            return [
                "@type": "inputChatPhotoAnimation",
                "animation": file.encode(),
                "main_frame_timestamp": mainFrameTimestamp
            ]
        }
    }
}

enum InputFile {
    case id(Int32)
    case remote(String)
    case local(String)
    case generated(String, String?, Int64?)

    func encode() -> [String: Any] {
        switch self {
        case .id(let id):
            return ["@type": "inputFileId", "id": id]
        case .remote(let remoteId):
            return ["@type": "inputFileRemote", "id": remoteId]
        case .local(let path):
            return ["@type": "inputFileLocal", "path": path]
        case .generated(let originalPath, let conversion, let expectedSize):
            var dict: [String: Any] = [
                "@type": "inputFileGenerated",
                "original_path": originalPath
            ]
            if let conversion = conversion {
                dict["conversion"] = conversion
            }
            if let size = expectedSize {
                dict["expected_size"] = size
            }
            return dict
        }
    }
}
