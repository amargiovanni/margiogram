//
//  ConversationViewModel.swift
//  Margiogram
//
//  Created by Andrea Margiovanni on 2024.
//

import Foundation
import SwiftUI
import OSLog

// MARK: - Conversation View Model

/// ViewModel for the conversation/chat screen.
///
/// Manages messages, sending, receiving, and chat state.
@MainActor
@Observable
final class ConversationViewModel {
    // MARK: - Properties

    /// The current chat.
    let chat: Chat

    /// All messages in the conversation.
    private(set) var messages: [Message] = []

    /// Grouped messages by date.
    private(set) var groupedMessages: [MessageGroup] = []

    /// Current input text.
    var inputText: String = ""

    /// Reply-to message if replying.
    var replyingTo: Message?

    /// Message being edited.
    var editingMessage: Message?

    /// Currently selected messages for multi-select.
    var selectedMessages: Set<Int64> = []

    /// Whether in selection mode.
    var isSelectionMode = false

    /// Whether messages are being loaded.
    private(set) var isLoading = false

    /// Whether more messages are being loaded.
    private(set) var isLoadingMore = false

    /// Whether there are more messages to load.
    private(set) var hasMoreMessages = true

    /// Current error if any.
    private(set) var error: ConversationError?

    /// Typing users in this chat.
    private(set) var typingUsers: [User] = []

    /// Whether the current user is typing.
    private(set) var isTyping = false

    /// Send button state.
    var sendButtonState: SendButtonState {
        if !inputText.isEmpty {
            return .send
        } else if isRecordingVoice {
            return .stop
        } else {
            return .microphone
        }
    }

    /// Voice recording state.
    private(set) var isRecordingVoice = false
    private(set) var voiceRecordingDuration: TimeInterval = 0

    /// Attachment state.
    var showAttachmentPicker = false
    var selectedAttachments: [Attachment] = []

    /// Logger for debugging.
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "ConversationViewModel")

    /// The TDLib client.
    private let client: TDLibClient

    /// Update listener task.
    nonisolated(unsafe) private var updateTask: Task<Void, Never>?

    /// Typing indicator task.
    nonisolated(unsafe) private var typingTask: Task<Void, Never>?

    /// Voice recording timer.
    nonisolated(unsafe) private var voiceRecordingTimer: Task<Void, Never>?

    // MARK: - Computed Properties

    /// Whether the chat is a group/channel.
    var isGroupChat: Bool {
        chat.isGroup || chat.isChannel
    }

    /// Whether input is enabled.
    var canSendMessages: Bool {
        chat.permissions.canSendMessages
    }

    /// Placeholder text for input.
    var inputPlaceholder: String {
        if editingMessage != nil {
            return String(localized: "Edit message...")
        } else if replyingTo != nil {
            return String(localized: "Reply...")
        } else if !canSendMessages {
            return String(localized: "You can't send messages here")
        } else {
            return String(localized: "Message")
        }
    }

    /// Chat title for display.
    var title: String {
        chat.title
    }

    /// Chat subtitle for display.
    var subtitle: String {
        if !typingUsers.isEmpty {
            return typingIndicatorText
        }
        return chat.subtitle
    }

    /// Typing indicator text.
    private var typingIndicatorText: String {
        if typingUsers.count == 1 {
            return String(localized: "\(typingUsers[0].firstName) is typing...")
        } else if typingUsers.count == 2 {
            return String(localized: "\(typingUsers[0].firstName) and \(typingUsers[1].firstName) are typing...")
        } else {
            return String(localized: "\(typingUsers.count) people are typing...")
        }
    }

    // MARK: - Initialization

    init(chat: Chat, client: TDLibClient = .shared) {
        self.chat = chat
        self.client = client
    }

    deinit {
        updateTask?.cancel()
        typingTask?.cancel()
        voiceRecordingTimer?.cancel()
    }

    // MARK: - Public Methods

    /// Loads initial messages.
    func loadMessages() async {
        guard !isLoading else { return }

        logger.info("Loading messages for chat: \(self.chat.id)")
        isLoading = true
        error = nil

        do {
            startListeningForUpdates()

            let loadedMessages = try await fetchMessages(limit: 50)
            messages = loadedMessages
            groupMessages()
            hasMoreMessages = loadedMessages.count >= 50

            // Mark as read
            await markAsRead()

            logger.info("Loaded \(loadedMessages.count) messages")
        } catch {
            self.error = .loadFailed(error)
            logger.error("Failed to load messages: \(error.localizedDescription)")
        }

        isLoading = false
    }

    /// Loads more messages (pagination).
    func loadMoreMessages() async {
        guard !isLoadingMore, hasMoreMessages, let firstMessage = messages.first else { return }

        logger.info("Loading more messages")
        isLoadingMore = true

        do {
            let moreMessages = try await fetchMessages(
                fromMessageId: firstMessage.id,
                limit: 50
            )

            messages.insert(contentsOf: moreMessages, at: 0)
            groupMessages()
            hasMoreMessages = moreMessages.count >= 50

            logger.info("Loaded \(moreMessages.count) more messages")
        } catch {
            logger.error("Failed to load more messages: \(error.localizedDescription)")
        }

        isLoadingMore = false
    }

    /// Sends the current message.
    func sendMessage() async {
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }

        logger.info("Sending message")

        // Clear input
        let replyTo = replyingTo
        let editing = editingMessage
        inputText = ""
        replyingTo = nil
        editingMessage = nil

        do {
            if let editingMessage = editing {
                // Edit existing message
                try await editMessage(editingMessage.id, newText: text)
            } else {
                // Send new message
                let message = try await sendTextMessage(text, replyTo: replyTo?.id)
                messages.append(message)
                groupMessages()
            }
        } catch {
            self.error = .sendFailed(error)
            logger.error("Failed to send message: \(error.localizedDescription)")
        }
    }

    /// Cancels the current reply.
    func cancelReply() {
        replyingTo = nil
    }

    /// Cancels editing.
    func cancelEditing() {
        editingMessage = nil
        inputText = ""
    }

    /// Starts replying to a message.
    func replyTo(_ message: Message) {
        editingMessage = nil
        replyingTo = message
    }

    /// Starts editing a message.
    func edit(_ message: Message) {
        guard message.canBeEdited else { return }
        replyingTo = nil
        editingMessage = message

        if case .text(let formattedText) = message.content {
            inputText = formattedText.text
        }
    }

    /// Deletes messages.
    func deleteMessages(_ messageIds: [Int64], forAll: Bool) async {
        logger.info("Deleting \(messageIds.count) messages")

        do {
            try await performDelete(messageIds: messageIds, forAll: forAll)
            messages.removeAll { messageIds.contains($0.id) }
            groupMessages()
            selectedMessages.removeAll()
            isSelectionMode = false
        } catch {
            self.error = .deleteFailed(error)
            logger.error("Failed to delete messages: \(error.localizedDescription)")
        }
    }

    /// Forwards messages to another chat.
    func forwardMessages(_ messageIds: [Int64], to chatId: Int64) async {
        logger.info("Forwarding \(messageIds.count) messages to chat: \(chatId)")

        do {
            try await performForward(messageIds: messageIds, toChatId: chatId)
            selectedMessages.removeAll()
            isSelectionMode = false
        } catch {
            self.error = .forwardFailed(error)
            logger.error("Failed to forward messages: \(error.localizedDescription)")
        }
    }

    /// Toggles message selection.
    func toggleSelection(for messageId: Int64) {
        if selectedMessages.contains(messageId) {
            selectedMessages.remove(messageId)
        } else {
            selectedMessages.insert(messageId)
        }

        if selectedMessages.isEmpty {
            isSelectionMode = false
        }
    }

    /// Starts selection mode with a message.
    func startSelection(with messageId: Int64) {
        isSelectionMode = true
        selectedMessages.insert(messageId)
    }

    /// Exits selection mode.
    func exitSelectionMode() {
        isSelectionMode = false
        selectedMessages.removeAll()
    }

    /// Adds a reaction to a message.
    func addReaction(_ reaction: ReactionType, to messageId: Int64) async {
        logger.info("Adding reaction to message: \(messageId)")

        do {
            try await performAddReaction(reaction, to: messageId)
        } catch {
            logger.error("Failed to add reaction: \(error.localizedDescription)")
        }
    }

    /// Removes a reaction from a message.
    func removeReaction(_ reaction: ReactionType, from messageId: Int64) async {
        logger.info("Removing reaction from message: \(messageId)")

        do {
            try await performRemoveReaction(reaction, from: messageId)
        } catch {
            logger.error("Failed to remove reaction: \(error.localizedDescription)")
        }
    }

    /// Updates typing indicator.
    func updateTypingIndicator() {
        typingTask?.cancel()

        typingTask = Task {
            isTyping = true
            // In real implementation: await client.send(SendChatAction(chatId: chat.id, action: .typing))

            try? await Task.sleep(for: .seconds(5))

            if !Task.isCancelled {
                isTyping = false
            }
        }
    }

    /// Starts voice recording.
    func startVoiceRecording() {
        guard !isRecordingVoice else { return }

        logger.info("Starting voice recording")
        isRecordingVoice = true
        voiceRecordingDuration = 0

        voiceRecordingTimer = Task {
            while !Task.isCancelled {
                try? await Task.sleep(for: .milliseconds(100))
                voiceRecordingDuration += 0.1
            }
        }

        // In real implementation: Start actual audio recording
    }

    /// Stops voice recording and sends.
    func stopVoiceRecording(send: Bool) async {
        guard isRecordingVoice else { return }

        logger.info("Stopping voice recording, send: \(send)")
        voiceRecordingTimer?.cancel()
        isRecordingVoice = false

        if send && voiceRecordingDuration >= 1.0 {
            // In real implementation: Send voice note
        }

        voiceRecordingDuration = 0
    }

    /// Sends attachment.
    func sendAttachment(_ attachment: Attachment) async {
        logger.info("Sending attachment")

        // In real implementation: Upload and send attachment
    }

    /// Clears error.
    func clearError() {
        error = nil
    }

    /// Marks chat as read.
    func markAsRead() async {
        // In real implementation: await client.send(ViewMessages(...))
    }

    // MARK: - Private Methods

    private func startListeningForUpdates() {
        updateTask?.cancel()

        updateTask = Task {
            for await update in await client.updates {
                await handleUpdate(update)
            }
        }
    }

    private func handleUpdate(_ update: TDUpdate) async {
        switch update {
        case .newMessage(let message) where message.chatId == chat.id:
            messages.append(message)
            groupMessages()
            await markAsRead()

        case .messageEdited(let chatId, let messageId, let content) where chatId == chat.id:
            if let index = messages.firstIndex(where: { $0.id == messageId }) {
                // Update message content - create new message with updated content
                let existingMessage = messages[index]
                messages[index] = Message(
                    id: existingMessage.id,
                    chatId: existingMessage.chatId,
                    sender: existingMessage.sender,
                    content: content,
                    date: existingMessage.date,
                    editDate: Date(),
                    isOutgoing: existingMessage.isOutgoing,
                    canBeEdited: existingMessage.canBeEdited,
                    canBeForwarded: existingMessage.canBeForwarded,
                    canBeDeletedForAllUsers: existingMessage.canBeDeletedForAllUsers,
                    replyTo: existingMessage.replyTo,
                    forwardInfo: existingMessage.forwardInfo,
                    reactions: existingMessage.reactions,
                    isRead: existingMessage.isRead,
                    interactionInfo: existingMessage.interactionInfo
                )
            }

        case .messagesDeleted(let chatId, let messageIds) where chatId == chat.id:
            messages.removeAll { messageIds.contains($0.id) }
            groupMessages()

        default:
            break
        }
    }

    private func groupMessages() {
        let calendar = Calendar.current

        var groups: [Date: [Message]] = [:]

        for message in messages {
            let startOfDay = calendar.startOfDay(for: message.date)
            groups[startOfDay, default: []].append(message)
        }

        groupedMessages = groups.map { date, messages in
            MessageGroup(date: date, messages: messages.sorted { $0.date < $1.date })
        }.sorted { $0.date < $1.date }
    }

    private func fetchMessages(
        fromMessageId: Int64 = 0,
        limit: Int = 50
    ) async throws -> [Message] {
        // In real implementation, call TDLib's getChatHistory
        #if DEBUG
        try? await Task.sleep(for: .milliseconds(300))
        return Message.mockConversation
        #else
        return []
        #endif
    }

    private func sendTextMessage(_ text: String, replyTo: Int64?) async throws -> Message {
        // In real implementation, call TDLib's sendMessage
        #if DEBUG
        try? await Task.sleep(for: .milliseconds(200))
        return Message.mock(
            chatId: chat.id,
            text: text,
            isOutgoing: true,
            date: Date()
        )
        #else
        throw ConversationError.sendFailed(NSError(domain: "Not implemented", code: 0))
        #endif
    }

    private func editMessage(_ messageId: Int64, newText: String) async throws {
        // In real implementation, call TDLib's editMessageText
        if let index = messages.firstIndex(where: { $0.id == messageId }) {
            // Update local message
            _ = index
        }
    }

    private func performDelete(messageIds: [Int64], forAll: Bool) async throws {
        // In real implementation, call TDLib's deleteMessages
    }

    private func performForward(messageIds: [Int64], toChatId: Int64) async throws {
        // In real implementation, call TDLib's forwardMessages
    }

    private func performAddReaction(_ reaction: ReactionType, to messageId: Int64) async throws {
        // In real implementation, call TDLib's addMessageReaction
    }

    private func performRemoveReaction(_ reaction: ReactionType, from messageId: Int64) async throws {
        // In real implementation, call TDLib's removeMessageReaction
    }
}

// MARK: - Message Group

/// A group of messages for a specific date.
struct MessageGroup: Identifiable {
    let id = UUID()
    let date: Date
    let messages: [Message]

    var formattedDate: String {
        let calendar = Calendar.current
        let now = Date()

        if calendar.isDateInToday(date) {
            return String(localized: "Today")
        } else if calendar.isDateInYesterday(date) {
            return String(localized: "Yesterday")
        } else if calendar.isDate(date, equalTo: now, toGranularity: .year) {
            return date.formatted(.dateTime.day().month(.wide))
        } else {
            return date.formatted(.dateTime.day().month(.wide).year())
        }
    }
}

// MARK: - Send Button State

/// State of the send button.
enum SendButtonState {
    case send
    case microphone
    case stop
}

// MARK: - Attachment

/// An attachment to send.
struct Attachment: Identifiable {
    let id = UUID()
    let type: AttachmentType
    let url: URL
    let thumbnail: Data?
    let caption: String?

    enum AttachmentType {
        case photo
        case video
        case document
        case audio
    }
}

// MARK: - Conversation Error

/// Errors that can occur in a conversation.
enum ConversationError: LocalizedError {
    case loadFailed(Error)
    case sendFailed(Error)
    case deleteFailed(Error)
    case forwardFailed(Error)

    var errorDescription: String? {
        switch self {
        case .loadFailed(let error):
            return "Failed to load messages: \(error.localizedDescription)"
        case .sendFailed(let error):
            return "Failed to send message: \(error.localizedDescription)"
        case .deleteFailed(let error):
            return "Failed to delete messages: \(error.localizedDescription)"
        case .forwardFailed(let error):
            return "Failed to forward messages: \(error.localizedDescription)"
        }
    }
}

// MARK: - Mock Data

#if DEBUG
extension Message {
    static var mockConversation: [Message] {
        let calendar = Calendar.current
        let now = Date()

        return [
            .mock(id: 1, chatId: 1, text: "Hey! How's it going?", isOutgoing: false, date: calendar.date(byAdding: .hour, value: -2, to: now)!),
            .mock(id: 2, chatId: 1, text: "Pretty good! Just working on this new app.", isOutgoing: true, date: calendar.date(byAdding: .hour, value: -2, to: now)!.addingTimeInterval(60)),
            .mock(id: 3, chatId: 1, text: "Oh nice! What kind of app?", isOutgoing: false, date: calendar.date(byAdding: .hour, value: -2, to: now)!.addingTimeInterval(120)),
            .mock(id: 4, chatId: 1, text: "A Telegram client with a beautiful glass design! 🎨", isOutgoing: true, date: calendar.date(byAdding: .hour, value: -1, to: now)!),
            .mock(id: 5, chatId: 1, text: "That sounds awesome! Can't wait to see it.", isOutgoing: false, date: calendar.date(byAdding: .minute, value: -30, to: now)!),
            .mock(id: 6, chatId: 1, text: "Thanks! I'll share some screenshots soon.", isOutgoing: true, date: calendar.date(byAdding: .minute, value: -25, to: now)!),
        ]
    }
}
#endif
