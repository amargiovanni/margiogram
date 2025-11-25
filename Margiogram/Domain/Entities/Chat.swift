//
//  Chat.swift
//  Margiogram
//
//  Created by Andrea Margiovanni on 2024.
//

import Foundation

// MARK: - Chat

/// Represents a Telegram chat (private, group, supergroup, or channel).
struct Chat: Identifiable, Equatable, Hashable, Sendable {
    // MARK: - Properties

    /// Unique chat identifier.
    let id: Int64

    /// Type of the chat.
    let type: ChatType

    /// Chat title or user name.
    let title: String

    /// Chat photo.
    let photo: ChatPhoto?

    /// Number of unread messages.
    var unreadCount: Int32

    /// Last message in the chat.
    var lastMessage: Message?

    /// Date of the last message or last update.
    var lastMessageDate: Date?

    /// Whether the chat is pinned.
    var isPinned: Bool

    /// Whether the chat is marked as unread.
    var isMarkedAsUnread: Bool

    /// Whether notifications are muted.
    var isMuted: Bool

    /// Mute expiration date if temporarily muted.
    var muteUntil: Date?

    /// Draft message if any.
    var draftMessage: DraftMessage?

    /// Number of unread mentions.
    var unreadMentionCount: Int32

    /// Number of unread reactions.
    var unreadReactionCount: Int32

    /// Chat permissions.
    let permissions: ChatPermissions

    /// Position in chat list.
    var position: ChatPosition

    /// Available reactions in this chat.
    let availableReactions: AvailableReactions

    // MARK: - Computed Properties

    /// Whether this is a private chat.
    var isPrivate: Bool {
        if case .private = type { return true }
        return false
    }

    /// Whether this is a group chat.
    var isGroup: Bool {
        switch type {
        case .basicGroup, .supergroup:
            return true
        default:
            return false
        }
    }

    /// Whether this is a channel.
    var isChannel: Bool {
        if case .supergroup(_, let isChannel, _) = type {
            return isChannel
        }
        return false
    }

    /// Whether this is a bot chat.
    var isBot: Bool {
        if case .private(let userId, let isBot) = type {
            return isBot
        }
        return false
    }

    /// User ID for private chats.
    var userId: Int64? {
        if case .private(let userId, _) = type {
            return userId
        }
        return nil
    }

    /// Display subtitle based on chat type.
    var subtitle: String {
        switch type {
        case .private(_, let isBot):
            return isBot ? "Bot" : ""
        case .basicGroup(_, let memberCount):
            return "\(memberCount) members"
        case .supergroup(_, let isChannel, let memberCount):
            if isChannel {
                return "\(memberCount) subscribers"
            } else {
                return "\(memberCount) members"
            }
        case .secret(_, let userId):
            return "Secret chat"
        }
    }

    /// Whether the chat has unread content.
    var hasUnread: Bool {
        unreadCount > 0 || isMarkedAsUnread
    }
}

// MARK: - Chat Type

/// Type of a Telegram chat.
enum ChatType: Equatable, Hashable, Sendable {
    case `private`(userId: Int64, isBot: Bool)
    case basicGroup(groupId: Int64, memberCount: Int32)
    case supergroup(supergroupId: Int64, isChannel: Bool, memberCount: Int32)
    case secret(secretChatId: Int32, userId: Int64)
}

// MARK: - Chat Photo

/// Photo of a chat.
struct ChatPhoto: Equatable, Hashable, Sendable {
    let id: Int64
    let small: File
    let big: File
    let minithumbnail: Data?
    let hasAnimation: Bool

    var smallURL: URL? {
        small.localPath.flatMap { URL(fileURLWithPath: $0) }
    }

    var bigURL: URL? {
        big.localPath.flatMap { URL(fileURLWithPath: $0) }
    }
}

// MARK: - Draft Message

/// A draft message.
struct DraftMessage: Equatable, Hashable, Sendable {
    let replyToMessageId: Int64?
    let date: Date
    let content: InputMessageContent
}

// MARK: - Chat Permissions

/// Permissions in a chat.
struct ChatPermissions: Equatable, Hashable, Sendable {
    let canSendMessages: Bool
    let canSendMediaMessages: Bool
    let canSendPolls: Bool
    let canSendOtherMessages: Bool
    let canAddWebPagePreviews: Bool
    let canChangeInfo: Bool
    let canInviteUsers: Bool
    let canPinMessages: Bool
    let canManageTopics: Bool

    static let full = ChatPermissions(
        canSendMessages: true,
        canSendMediaMessages: true,
        canSendPolls: true,
        canSendOtherMessages: true,
        canAddWebPagePreviews: true,
        canChangeInfo: true,
        canInviteUsers: true,
        canPinMessages: true,
        canManageTopics: true
    )

    static let readOnly = ChatPermissions(
        canSendMessages: false,
        canSendMediaMessages: false,
        canSendPolls: false,
        canSendOtherMessages: false,
        canAddWebPagePreviews: false,
        canChangeInfo: false,
        canInviteUsers: false,
        canPinMessages: false,
        canManageTopics: false
    )
}

// MARK: - Chat Position

/// Position of a chat in a chat list.
struct ChatPosition: Equatable, Hashable, Sendable {
    let list: ChatList
    let order: Int64
    let isPinned: Bool
    let source: ChatSource?
}

/// Source of a chat appearing in a list.
enum ChatSource: Equatable, Hashable, Sendable {
    case mtprotoProxy
    case publicServiceAnnouncement(type: String, text: String)
}

// MARK: - Chat List

/// Type of chat list.
enum ChatList: Equatable, Hashable, Sendable {
    case main
    case archive
    case folder(folderId: Int32)
}

// MARK: - Available Reactions

/// Available reactions in a chat.
enum AvailableReactions: Equatable, Hashable, Sendable {
    case all
    case some([ReactionType])
    case none
}

// MARK: - Chat Action

/// Action being performed in a chat (typing, uploading, etc.).
enum ChatAction: Equatable, Hashable, Sendable {
    case typing
    case recordingVoiceNote
    case uploadingVoiceNote(progress: Int32)
    case recordingVideoNote
    case uploadingVideoNote(progress: Int32)
    case uploadingPhoto(progress: Int32)
    case uploadingDocument(progress: Int32)
    case uploadingVideo(progress: Int32)
    case choosingLocation
    case choosingContact
    case startPlayingGame
    case watchingAnimations(emoji: String)
    case cancel
}

// MARK: - Chat Folder

/// A chat folder (filter).
struct ChatFolder: Identifiable, Equatable, Hashable, Sendable {
    let id: Int32
    let title: String
    let icon: ChatFolderIcon
    let includedChatIds: [Int64]
    let excludedChatIds: [Int64]
    let includeContacts: Bool
    let includeNonContacts: Bool
    let includeGroups: Bool
    let includeChannels: Bool
    let includeBots: Bool
    let excludeMuted: Bool
    let excludeRead: Bool
    let excludeArchived: Bool
}

/// Icon for a chat folder.
enum ChatFolderIcon: String, Equatable, Hashable, Sendable {
    case all = "All"
    case unread = "Unread"
    case unmuted = "Unmuted"
    case bots = "Bots"
    case channels = "Channels"
    case groups = "Groups"
    case `private` = "Private"
    case custom = "Custom"
    case setup = "Setup"
    case cat = "Cat"
    case crown = "Crown"
    case favorite = "Favorite"
    case flower = "Flower"
    case game = "Game"
    case home = "Home"
    case love = "Love"
    case mask = "Mask"
    case party = "Party"
    case sport = "Sport"
    case study = "Study"
    case trade = "Trade"
    case travel = "Travel"
    case work = "Work"

    var systemImage: String {
        switch self {
        case .all: return "tray.fill"
        case .unread: return "circle.fill"
        case .unmuted: return "bell.fill"
        case .bots: return "cpu.fill"
        case .channels: return "megaphone.fill"
        case .groups: return "person.3.fill"
        case .private: return "person.fill"
        case .custom: return "folder.fill"
        case .setup: return "gearshape.fill"
        case .cat: return "cat.fill"
        case .crown: return "crown.fill"
        case .favorite: return "star.fill"
        case .flower: return "leaf.fill"
        case .game: return "gamecontroller.fill"
        case .home: return "house.fill"
        case .love: return "heart.fill"
        case .mask: return "theatermasks.fill"
        case .party: return "party.popper.fill"
        case .sport: return "sportscourt.fill"
        case .study: return "book.fill"
        case .trade: return "chart.line.uptrend.xyaxis"
        case .travel: return "airplane"
        case .work: return "briefcase.fill"
        }
    }
}

// MARK: - Mock Data

#if DEBUG
extension Chat {
    static func mock(
        id: Int64 = Int64.random(in: 1...1000000),
        title: String = "Test Chat",
        type: ChatType = .private(userId: 1, isBot: false),
        unreadCount: Int32 = 0,
        isPinned: Bool = false
    ) -> Chat {
        Chat(
            id: id,
            type: type,
            title: title,
            photo: nil,
            unreadCount: unreadCount,
            lastMessage: .mock(chatId: id),
            lastMessageDate: Date(),
            isPinned: isPinned,
            isMarkedAsUnread: false,
            isMuted: false,
            muteUntil: nil,
            draftMessage: nil,
            unreadMentionCount: 0,
            unreadReactionCount: 0,
            permissions: .full,
            position: ChatPosition(list: .main, order: 0, isPinned: isPinned, source: nil),
            availableReactions: .all
        )
    }

    static var mockList: [Chat] {
        [
            .mock(id: 1, title: "John Doe", unreadCount: 3),
            .mock(id: 2, title: "Family Group", type: .basicGroup(groupId: 1, memberCount: 5), unreadCount: 12),
            .mock(id: 3, title: "Work Team", type: .supergroup(supergroupId: 1, isChannel: false, memberCount: 45)),
            .mock(id: 4, title: "News Channel", type: .supergroup(supergroupId: 2, isChannel: true, memberCount: 1500), isPinned: true),
            .mock(id: 5, title: "Support Bot", type: .private(userId: 5, isBot: true)),
        ]
    }
}
#endif
