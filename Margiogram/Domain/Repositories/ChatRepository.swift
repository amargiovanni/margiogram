//
//  ChatRepository.swift
//  Margiogram
//
//  Created by Andrea Margiovanni on 2024.
//

import Foundation

// MARK: - Chat Repository Protocol

/// Repository for managing chats.
protocol ChatRepository: Sendable {
    /// Gets the list of chats.
    ///
    /// - Parameters:
    ///   - list: The chat list to fetch from.
    ///   - limit: Maximum number of chats to return.
    /// - Returns: Array of chats.
    func getChats(list: ChatList, limit: Int) async throws -> [Chat]

    /// Gets a specific chat by ID.
    ///
    /// - Parameter chatId: The chat identifier.
    /// - Returns: The chat if found.
    func getChat(chatId: Int64) async throws -> Chat

    /// Marks a chat as read.
    ///
    /// - Parameter chatId: The chat identifier.
    func markChatAsRead(chatId: Int64) async throws

    /// Pins or unpins a chat.
    ///
    /// - Parameters:
    ///   - chatId: The chat identifier.
    ///   - isPinned: Whether to pin or unpin.
    func toggleChatPin(chatId: Int64, isPinned: Bool) async throws

    /// Mutes or unmutes a chat.
    ///
    /// - Parameters:
    ///   - chatId: The chat identifier.
    ///   - muteFor: Duration to mute in seconds (0 to unmute).
    func muteChat(chatId: Int64, muteFor: Int32) async throws

    /// Archives or unarchives a chat.
    ///
    /// - Parameters:
    ///   - chatId: The chat identifier.
    ///   - isArchived: Whether to archive or unarchive.
    func archiveChat(chatId: Int64, isArchived: Bool) async throws

    /// Deletes a chat.
    ///
    /// - Parameters:
    ///   - chatId: The chat identifier.
    ///   - removeFromList: Whether to remove from chat list.
    func deleteChat(chatId: Int64, removeFromList: Bool) async throws

    /// Searches for chats.
    ///
    /// - Parameters:
    ///   - query: Search query.
    ///   - limit: Maximum results.
    /// - Returns: Array of matching chats.
    func searchChats(query: String, limit: Int) async throws -> [Chat]

    /// Stream of chat updates.
    var chatUpdates: AsyncStream<ChatUpdate> { get }
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
protocol MessageRepository: Sendable {
    /// Gets messages from a chat.
    ///
    /// - Parameters:
    ///   - chatId: The chat identifier.
    ///   - fromMessageId: Start from this message ID (0 for latest).
    ///   - limit: Maximum number of messages.
    /// - Returns: Array of messages.
    func getMessages(chatId: Int64, fromMessageId: Int64, limit: Int) async throws -> [Message]

    /// Gets a specific message.
    ///
    /// - Parameters:
    ///   - chatId: The chat identifier.
    ///   - messageId: The message identifier.
    /// - Returns: The message if found.
    func getMessage(chatId: Int64, messageId: Int64) async throws -> Message

    /// Sends a message.
    ///
    /// - Parameters:
    ///   - chatId: The chat identifier.
    ///   - content: Message content.
    ///   - replyToMessageId: Optional message to reply to.
    /// - Returns: The sent message.
    func sendMessage(chatId: Int64, content: InputMessageContent, replyToMessageId: Int64?) async throws -> Message

    /// Edits a message.
    ///
    /// - Parameters:
    ///   - chatId: The chat identifier.
    ///   - messageId: The message identifier.
    ///   - content: New content.
    func editMessage(chatId: Int64, messageId: Int64, content: InputMessageContent) async throws

    /// Deletes messages.
    ///
    /// - Parameters:
    ///   - chatId: The chat identifier.
    ///   - messageIds: Messages to delete.
    ///   - forAll: Whether to delete for all users.
    func deleteMessages(chatId: Int64, messageIds: [Int64], forAll: Bool) async throws

    /// Forwards messages.
    ///
    /// - Parameters:
    ///   - chatId: Source chat.
    ///   - messageIds: Messages to forward.
    ///   - toChatId: Destination chat.
    /// - Returns: The forwarded messages.
    func forwardMessages(chatId: Int64, messageIds: [Int64], toChatId: Int64) async throws -> [Message]

    /// Adds a reaction to a message.
    ///
    /// - Parameters:
    ///   - chatId: The chat identifier.
    ///   - messageId: The message identifier.
    ///   - reaction: Reaction to add.
    func addReaction(chatId: Int64, messageId: Int64, reaction: ReactionType) async throws

    /// Removes a reaction from a message.
    ///
    /// - Parameters:
    ///   - chatId: The chat identifier.
    ///   - messageId: The message identifier.
    ///   - reaction: Reaction to remove.
    func removeReaction(chatId: Int64, messageId: Int64, reaction: ReactionType) async throws

    /// Searches messages in a chat.
    ///
    /// - Parameters:
    ///   - chatId: The chat identifier.
    ///   - query: Search query.
    ///   - filter: Message filter.
    ///   - limit: Maximum results.
    /// - Returns: Array of matching messages.
    func searchMessages(chatId: Int64, query: String, filter: MessageSearchFilter?, limit: Int) async throws -> [Message]

    /// Stream of message updates.
    var messageUpdates: AsyncStream<MessageUpdate> { get }
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
protocol UserRepository: Sendable {
    /// Gets a user by ID.
    ///
    /// - Parameter userId: The user identifier.
    /// - Returns: The user.
    func getUser(userId: Int64) async throws -> User

    /// Gets full info about a user.
    ///
    /// - Parameter userId: The user identifier.
    /// - Returns: Full user info.
    func getUserFullInfo(userId: Int64) async throws -> UserFullInfo

    /// Gets the current user.
    ///
    /// - Returns: The current user.
    func getCurrentUser() async throws -> User

    /// Updates the current user's profile.
    ///
    /// - Parameters:
    ///   - firstName: New first name.
    ///   - lastName: New last name.
    ///   - bio: New bio.
    func updateProfile(firstName: String, lastName: String, bio: String?) async throws

    /// Sets the current user's username.
    ///
    /// - Parameter username: New username.
    func setUsername(_ username: String) async throws

    /// Sets the current user's profile photo.
    ///
    /// - Parameter photoPath: Path to the photo file.
    func setProfilePhoto(photoPath: String) async throws

    /// Blocks a user.
    ///
    /// - Parameter userId: User to block.
    func blockUser(userId: Int64) async throws

    /// Unblocks a user.
    ///
    /// - Parameter userId: User to unblock.
    func unblockUser(userId: Int64) async throws

    /// Gets the list of contacts.
    ///
    /// - Returns: Array of contacts.
    func getContacts() async throws -> [User]

    /// Searches for users.
    ///
    /// - Parameters:
    ///   - query: Search query.
    ///   - limit: Maximum results.
    /// - Returns: Array of matching users.
    func searchUsers(query: String, limit: Int) async throws -> [User]

    /// Stream of user updates.
    var userUpdates: AsyncStream<UserUpdate> { get }
}

// MARK: - User Update

/// Represents an update to users.
enum UserUpdate {
    case userUpdated(User)
    case userStatusChanged(userId: Int64, status: UserStatus)
    case userPhotoChanged(userId: Int64, photo: ChatPhoto?)
}
