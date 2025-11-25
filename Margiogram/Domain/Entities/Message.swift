//
//  Message.swift
//  Margiogram
//
//  Created by Andrea Margiovanni on 2024.
//

import Foundation

// MARK: - Message

/// Represents a message in a Telegram chat.
///
/// Messages can contain various types of content including text, media,
/// stickers, and more. Each message has a unique identifier within its chat.
struct Message: Identifiable, Equatable, Hashable, Sendable {
    // MARK: - Properties

    /// Unique message identifier within the chat.
    let id: Int64

    /// Chat identifier this message belongs to.
    let chatId: Int64

    /// Sender of the message.
    let sender: MessageSender

    /// Message content.
    let content: MessageContent

    /// Date when the message was sent.
    let date: Date

    /// Date when the message was last edited, if edited.
    let editDate: Date?

    /// Whether this message was sent by the current user.
    let isOutgoing: Bool

    /// Whether this message can be edited.
    let canBeEdited: Bool

    /// Whether this message can be forwarded.
    let canBeForwarded: Bool

    /// Whether this message can be deleted for all users.
    let canBeDeletedForAllUsers: Bool

    /// Reply information if this is a reply.
    let replyTo: ReplyInfo?

    /// Forward information if this was forwarded.
    let forwardInfo: ForwardInfo?

    /// Reactions to this message.
    var reactions: [MessageReaction]

    /// Whether this message has been read by the recipient.
    var isRead: Bool

    /// Interaction info (views, forwards).
    let interactionInfo: MessageInteractionInfo?

    // MARK: - Computed Properties

    /// Formatted time string for display.
    var formattedTime: String {
        let formatter = DateFormatter()
        if Calendar.current.isDateInToday(date) {
            formatter.dateFormat = "HH:mm"
        } else if Calendar.current.isDateInYesterday(date) {
            return "Yesterday"
        } else {
            formatter.dateFormat = "dd/MM/yy"
        }
        return formatter.string(from: date)
    }

    /// Whether this message is a text message.
    var isTextMessage: Bool {
        if case .text = content { return true }
        return false
    }

    /// Whether this message contains media.
    var hasMedia: Bool {
        switch content {
        case .photo, .video, .animation, .audio, .document, .sticker, .videoNote, .voiceNote:
            return true
        default:
            return false
        }
    }
}

// MARK: - Message Sender

/// Represents the sender of a message.
enum MessageSender: Equatable, Hashable, Sendable {
    case user(userId: Int64)
    case chat(chatId: Int64)

    var isUser: Bool {
        if case .user = self { return true }
        return false
    }
}

// MARK: - Message Content

/// The content of a message.
enum MessageContent: Equatable, Hashable, Sendable {
    case text(FormattedText)
    case photo(Photo)
    case video(Video)
    case animation(Animation)
    case audio(Audio)
    case document(Document)
    case sticker(Sticker)
    case voiceNote(VoiceNote)
    case videoNote(VideoNote)
    case location(Location)
    case contact(Contact)
    case poll(Poll)
    case game(Game)
    case invoice(Invoice)
    case unsupported

    /// Text preview for display in chat list.
    var previewText: String {
        switch self {
        case .text(let formatted):
            return formatted.text
        case .photo:
            return "📷 Photo"
        case .video:
            return "🎬 Video"
        case .animation:
            return "GIF"
        case .audio(let audio):
            return "🎵 \(audio.title ?? "Audio")"
        case .document(let doc):
            return "📎 \(doc.fileName)"
        case .sticker(let sticker):
            return "\(sticker.emoji) Sticker"
        case .voiceNote:
            return "🎤 Voice message"
        case .videoNote:
            return "📹 Video message"
        case .location:
            return "📍 Location"
        case .contact(let contact):
            return "👤 \(contact.firstName)"
        case .poll(let poll):
            return "📊 \(poll.question)"
        case .game(let game):
            return "🎮 \(game.title)"
        case .invoice(let invoice):
            return "💳 \(invoice.title)"
        case .unsupported:
            return "Unsupported message"
        }
    }
}

// MARK: - Formatted Text

/// Text with formatting entities.
struct FormattedText: Equatable, Hashable, Sendable {
    let text: String
    let entities: [TextEntity]

    init(text: String, entities: [TextEntity] = []) {
        self.text = text
        self.entities = entities
    }
}

// MARK: - Reply Info

/// Information about a replied message.
struct ReplyInfo: Equatable, Hashable, Sendable {
    let messageId: Int64
    let senderId: MessageSender?
    let content: MessageContent?
}

// MARK: - Forward Info

/// Information about a forwarded message.
struct ForwardInfo: Equatable, Hashable, Sendable {
    let origin: ForwardOrigin
    let date: Date
    let fromChatId: Int64?
    let fromMessageId: Int64?
}

/// Origin of a forwarded message.
enum ForwardOrigin: Equatable, Hashable, Sendable {
    case user(userId: Int64, name: String)
    case chat(chatId: Int64, title: String)
    case hiddenUser(name: String)
    case channel(chatId: Int64, title: String, authorSignature: String?)
}

// MARK: - Message Reaction

/// A reaction to a message.
struct MessageReaction: Equatable, Hashable, Sendable {
    let type: ReactionType
    let count: Int32
    let isChosen: Bool
    let recentSenderIds: [MessageSender]
}

/// Type of reaction.
enum ReactionType: Equatable, Hashable, Sendable {
    case emoji(String)
    case customEmoji(id: Int64)
}

// MARK: - Message Interaction Info

/// Information about message interactions.
struct MessageInteractionInfo: Equatable, Hashable, Sendable {
    let viewCount: Int32
    let forwardCount: Int32
    let replyCount: Int32?
}

// MARK: - Media Types

struct Photo: Equatable, Hashable, Sendable {
    let id: String
    let sizes: [PhotoSize]
    let caption: FormattedText?
    let hasSpoiler: Bool

    var thumbnailURL: URL? {
        sizes.first?.file.localPath.flatMap { URL(fileURLWithPath: $0) }
    }
}

struct PhotoSize: Equatable, Hashable, Sendable {
    let type: String
    let width: Int32
    let height: Int32
    let file: File
}

struct Video: Equatable, Hashable, Sendable {
    let id: String
    let duration: Int32
    let width: Int32
    let height: Int32
    let fileName: String
    let mimeType: String
    let caption: FormattedText?
    let thumbnail: PhotoSize?
    let file: File
    let hasSpoiler: Bool
    let supportsStreaming: Bool
}

struct Animation: Equatable, Hashable, Sendable {
    let id: String
    let duration: Int32
    let width: Int32
    let height: Int32
    let fileName: String
    let mimeType: String
    let thumbnail: PhotoSize?
    let file: File
}

struct Audio: Equatable, Hashable, Sendable {
    let id: String
    let duration: Int32
    let title: String?
    let performer: String?
    let fileName: String
    let mimeType: String
    let albumCoverThumbnail: PhotoSize?
    let file: File
}

struct Document: Equatable, Hashable, Sendable {
    let id: String
    let fileName: String
    let mimeType: String
    let caption: FormattedText?
    let thumbnail: PhotoSize?
    let file: File
}

struct Sticker: Equatable, Hashable, Sendable {
    let id: String
    let setId: Int64
    let width: Int32
    let height: Int32
    let emoji: String
    let type: StickerType
    let thumbnail: PhotoSize?
    let file: File

    enum StickerType: Equatable, Hashable, Sendable {
        case regular
        case animated
        case video
    }
}

struct VoiceNote: Equatable, Hashable, Sendable {
    let id: String
    let duration: Int32
    let waveform: Data
    let mimeType: String
    let file: File
    let isListened: Bool
}

struct VideoNote: Equatable, Hashable, Sendable {
    let id: String
    let duration: Int32
    let length: Int32
    let thumbnail: PhotoSize?
    let file: File
    let isViewed: Bool
}

struct Location: Equatable, Hashable, Sendable {
    let latitude: Double
    let longitude: Double
    let horizontalAccuracy: Double?
    let livePeriod: Int32?
    let expirationDate: Date?
}

struct Contact: Equatable, Hashable, Sendable {
    let phoneNumber: String
    let firstName: String
    let lastName: String
    let vcard: String
    let userId: Int64?
}

struct Poll: Equatable, Hashable, Sendable {
    let id: Int64
    let question: String
    let options: [PollOption]
    let totalVoterCount: Int32
    let isAnonymous: Bool
    let type: PollType
    let isClosed: Bool

    struct PollOption: Equatable, Hashable, Sendable {
        let text: String
        let voterCount: Int32
        let votePercentage: Int32
        let isChosen: Bool
    }

    enum PollType: Equatable, Hashable, Sendable {
        case regular(allowMultipleAnswers: Bool)
        case quiz(correctOptionId: Int32, explanation: FormattedText?)
    }
}

struct Game: Equatable, Hashable, Sendable {
    let id: Int64
    let shortName: String
    let title: String
    let description: String
    let photo: Photo?
}

struct Invoice: Equatable, Hashable, Sendable {
    let title: String
    let description: String
    let currency: String
    let totalAmount: Int64
    let photo: Photo?
}

// MARK: - File

/// Represents a file in Telegram.
struct File: Equatable, Hashable, Sendable {
    let id: Int32
    let size: Int64
    let expectedSize: Int64
    let localPath: String?
    let isDownloadingActive: Bool
    let isDownloadingCompleted: Bool
    let downloadedSize: Int64

    var isDownloaded: Bool {
        isDownloadingCompleted && localPath != nil
    }
}

// MARK: - Mock Data

#if DEBUG
extension Message {
    static func mock(
        id: Int64 = Int64.random(in: 1...1000000),
        chatId: Int64 = 1,
        text: String = "Hello, World!",
        isOutgoing: Bool = false,
        date: Date = Date()
    ) -> Message {
        Message(
            id: id,
            chatId: chatId,
            sender: .user(userId: Int64.random(in: 1...1000)),
            content: .text(FormattedText(text: text)),
            date: date,
            editDate: nil,
            isOutgoing: isOutgoing,
            canBeEdited: isOutgoing,
            canBeForwarded: true,
            canBeDeletedForAllUsers: isOutgoing,
            replyTo: nil,
            forwardInfo: nil,
            reactions: [],
            isRead: true,
            interactionInfo: nil
        )
    }
}
#endif
