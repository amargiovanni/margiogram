//
//  ChatRepository.swift
//  Margiogram
//
//  Created by Andrea Margiovanni on 2024.
//

import Foundation

// MARK: - Chat Repository Protocol

/// Repository for managing chats.
protocol ChatRepository: Actor {
    /// Gets the list of chats.
    func getChats(chatList: ChatList, limit: Int, offsetOrder: Int64, offsetChatId: Int64) async throws -> [Chat]

    /// Gets a specific chat by ID.
    func getChat(chatId: Int64) async throws -> Chat

    /// Creates a private chat with a user.
    func createPrivateChat(userId: Int64) async throws -> Chat

    /// Searches for chats.
    func searchChats(query: String, limit: Int) async throws -> [Chat]

    /// Searches for public chats.
    func searchPublicChats(query: String) async throws -> [Chat]

    /// Sets chat notification settings.
    func setChatNotificationSettings(chatId: Int64, muteFor: Int32, sound: String?) async throws

    /// Pins or unpins a chat.
    func toggleChatIsPinned(chatId: Int64, chatList: ChatList, isPinned: Bool) async throws

    /// Marks a chat as read/unread.
    func toggleChatIsMarkedAsUnread(chatId: Int64, isMarkedAsUnread: Bool) async throws

    /// Adds a chat to a list.
    func addChatToList(chatId: Int64, chatList: ChatList) async throws

    /// Leaves a chat.
    func leaveChat(chatId: Int64) async throws

    /// Deletes a chat.
    func deleteChat(chatId: Int64) async throws

    /// Gets chat folders.
    func getChatFolders() async throws -> [ChatFolder]

    /// Creates a chat folder.
    func createChatFolder(_ folder: ChatFolder) async throws -> Int32

    /// Edits a chat folder.
    func editChatFolder(folderId: Int32, folder: ChatFolder) async throws

    /// Deletes a chat folder.
    func deleteChatFolder(folderId: Int32) async throws

    /// Clears chat history.
    func clearChatHistory(chatId: Int64, removeFromChatList: Bool) async throws
}

// MARK: - Chat Update

/// Represents an update to a chat.
enum ChatUpdate {
    case newChat(Chat)
    case chatUpdated(Chat)
    case chatDeleted(chatId: Int64)
    case chatPositionChanged(chatId: Int64, position: ChatPosition)
    case unreadCountChanged(chatId: Int64, count: Int32)
    case lastMessageChanged(chatId: Int64, message: Message?)
    case draftMessageChanged(chatId: Int64, draft: DraftMessage?)
}

// MARK: - Message Repository Protocol

/// Repository for managing messages.
protocol MessageRepository: Actor {
    /// Gets chat history.
    func getChatHistory(
        chatId: Int64,
        fromMessageId: Int64,
        offset: Int32,
        limit: Int32
    ) async throws -> [Message]

    /// Sends a text message.
    func sendTextMessage(
        chatId: Int64,
        text: String,
        replyToMessageId: Int64?
    ) async throws -> Message

    /// Sends a media message.
    func sendMediaMessage(
        chatId: Int64,
        content: InputMessageContent,
        replyToMessageId: Int64?
    ) async throws -> Message

    /// Edits a text message.
    func editMessageText(
        chatId: Int64,
        messageId: Int64,
        text: String
    ) async throws

    /// Deletes messages.
    func deleteMessages(
        chatId: Int64,
        messageIds: [Int64],
        revoke: Bool
    ) async throws

    /// Forwards messages.
    func forwardMessages(
        chatId: Int64,
        fromChatId: Int64,
        messageIds: [Int64]
    ) async throws -> [Message]

    /// Views messages (marks as read).
    func viewMessages(
        chatId: Int64,
        messageIds: [Int64]
    ) async throws

    /// Searches messages in a chat.
    func searchChatMessages(
        chatId: Int64,
        query: String,
        fromMessageId: Int64,
        limit: Int32
    ) async throws -> [Message]

    /// Searches messages globally.
    func searchMessages(
        query: String,
        offset: String?,
        limit: Int32
    ) async throws -> (messages: [Message], nextOffset: String?)

    /// Gets a message.
    func getMessage(chatId: Int64, messageId: Int64) async throws -> Message

    /// Adds a reaction.
    func addMessageReaction(
        chatId: Int64,
        messageId: Int64,
        reaction: ReactionType
    ) async throws

    /// Removes a reaction.
    func removeMessageReaction(
        chatId: Int64,
        messageId: Int64,
        reaction: ReactionType
    ) async throws
}

// MARK: - Message Update

/// Represents an update to messages.
enum MessageUpdate {
    case newMessage(Message)
    case messageEdited(chatId: Int64, messageId: Int64, content: MessageContent)
    case messagesDeleted(chatId: Int64, messageIds: [Int64])
    case messageReadStatusChanged(chatId: Int64, messageId: Int64, isRead: Bool)
    case messageReactionsChanged(chatId: Int64, messageId: Int64, reactions: [MessageReaction])
}

// MARK: - Message Search Filter

/// Filter for searching messages.
enum MessageSearchFilter {
    case animation
    case audio
    case document
    case photo
    case video
    case voiceNote
    case photoAndVideo
    case url
    case chatPhoto
    case videoNote
    case voiceAndVideoNote
    case mention
    case unreadMention
    case unreadReaction
    case failedToSend
    case pinned
}

// MARK: - User Repository Protocol

/// Repository for managing users.
protocol UserRepository: Actor {
    /// Gets a user by ID.
    func getUser(userId: Int64) async throws -> User

    /// Gets the current user.
    func getCurrentUser() async throws -> User

    /// Gets contacts.
    func getContacts() async throws -> [User]

    /// Searches contacts.
    func searchContacts(query: String, limit: Int32) async throws -> [User]

    /// Adds a contact.
    func addContact(
        phoneNumber: String,
        firstName: String,
        lastName: String
    ) async throws -> User

    /// Removes contacts.
    func removeContacts(userIds: [Int64]) async throws

    /// Blocks a user.
    func blockUser(userId: Int64) async throws

    /// Unblocks a user.
    func unblockUser(userId: Int64) async throws

    /// Gets blocked users.
    func getBlockedUsers(offset: Int32, limit: Int32) async throws -> [User]

    /// Updates current user profile.
    func updateProfile(firstName: String, lastName: String, bio: String) async throws

    /// Sets profile photo.
    func setProfilePhoto(photoData: Data) async throws

    /// Deletes profile photo.
    func deleteProfilePhoto() async throws

    /// Sets username.
    func setUsername(_ username: String?) async throws

    /// Gets user full info.
    func getUserFullInfo(userId: Int64) async throws -> UserFullInfo
}
