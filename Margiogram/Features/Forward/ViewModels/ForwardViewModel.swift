//
//  ForwardViewModel.swift
//  Margiogram
//
//  Created by Andrea Margiovanni on 2024.
//

import Foundation
import SwiftUI

// MARK: - Forward ViewModel

@Observable
@MainActor
final class ForwardViewModel {
    // MARK: - Properties

    var searchText: String = "" {
        didSet {
            if searchText != oldValue {
                filterChats()
            }
        }
    }

    var selectedChats: Set<Int64> = []
    var recentChats: [Chat] = []
    var allChats: [Chat] = []
    var filteredChats: [Chat] = []
    var contacts: [User] = []
    var filteredContacts: [User] = []

    var isLoading: Bool = false
    var isForwarding: Bool = false
    var error: Error?

    // Forward Options
    var hideCaption: Bool = false
    var hideSender: Bool = false
    var sendAsCopy: Bool = false
    var comment: String = ""

    // Messages to forward
    private var messagesToForward: [Message] = []
    private var sourceChat: Chat?

    // MARK: - Computed Properties

    var hasSelection: Bool {
        !selectedChats.isEmpty
    }

    var selectionCount: Int {
        selectedChats.count
    }

    var canForward: Bool {
        hasSelection && !messagesToForward.isEmpty
    }

    var forwardTitle: String {
        if messagesToForward.count == 1 {
            return "Forward Message"
        } else {
            return "Forward \(messagesToForward.count) Messages"
        }
    }

    // MARK: - Initialization

    func configure(messages: [Message], from chat: Chat) {
        self.messagesToForward = messages
        self.sourceChat = chat
    }

    // MARK: - Loading

    func loadChats() async {
        isLoading = true
        defer { isLoading = false }

        // In real implementation: load from TDLib
        #if DEBUG
        try? await Task.sleep(for: .milliseconds(300))
        recentChats = Array(Chat.mockList.prefix(5))
        allChats = Chat.mockList
        filteredChats = allChats
        contacts = User.mockContacts
        filteredContacts = contacts
        #endif
    }

    // MARK: - Selection

    func toggleSelection(for chatId: Int64) {
        if selectedChats.contains(chatId) {
            selectedChats.remove(chatId)
        } else {
            selectedChats.insert(chatId)
        }
    }

    func isSelected(_ chatId: Int64) -> Bool {
        selectedChats.contains(chatId)
    }

    func clearSelection() {
        selectedChats.removeAll()
    }

    func selectAll() {
        selectedChats = Set(filteredChats.map { $0.id })
    }

    // MARK: - Filtering

    private func filterChats() {
        if searchText.isEmpty {
            filteredChats = allChats
            filteredContacts = contacts
        } else {
            let query = searchText.lowercased()
            filteredChats = allChats.filter { $0.title.lowercased().contains(query) }
            filteredContacts = contacts.filter { $0.fullName.lowercased().contains(query) }
        }
    }

    // MARK: - Forward Action

    func forward() async -> Bool {
        guard canForward else { return false }

        isForwarding = true
        defer { isForwarding = false }

        do {
            let messageIds = messagesToForward.map { $0.id }
            let sourceChatId = sourceChat?.id ?? 0

            for chatId in selectedChats {
                // In real implementation: call TDLib's forwardMessages
                try await forwardToChat(
                    chatId: chatId,
                    fromChatId: sourceChatId,
                    messageIds: messageIds
                )

                // Send comment if present
                if !comment.isEmpty {
                    try await sendComment(chatId: chatId, text: comment)
                }
            }

            return true
        } catch {
            self.error = error
            return false
        }
    }

    private func forwardToChat(chatId: Int64, fromChatId: Int64, messageIds: [Int64]) async throws {
        // In real implementation: call TDLib's forwardMessages
        #if DEBUG
        try await Task.sleep(for: .milliseconds(100))
        #endif
    }

    private func sendComment(chatId: Int64, text: String) async throws {
        // In real implementation: call TDLib's sendMessage
        #if DEBUG
        try await Task.sleep(for: .milliseconds(50))
        #endif
    }

    // MARK: - Share to New Message

    func shareToNewChat(userId: Int64) async {
        // Create private chat and forward
        // In real implementation: call TDLib's createPrivateChat then forward
    }
}

// MARK: - Forward Options

struct ForwardOptions: Equatable {
    var hideCaption: Bool = false
    var hideSender: Bool = false
    var sendAsCopy: Bool = false

    var sendOptions: SendOptions {
        SendOptions(
            disableNotification: false,
            fromBackground: false,
            protectContent: false,
            scheduledDate: nil
        )
    }
}

// MARK: - Send Options

struct SendOptions: Equatable, Sendable {
    var disableNotification: Bool = false
    var fromBackground: Bool = false
    var protectContent: Bool = false
    var scheduledDate: Date?
}

// MARK: - Forward Error

enum ForwardError: LocalizedError {
    case noMessages
    case noDestination
    case forwardFailed(String)

    var errorDescription: String? {
        switch self {
        case .noMessages:
            return "No messages to forward"
        case .noDestination:
            return "Please select at least one chat"
        case .forwardFailed(let reason):
            return "Forward failed: \(reason)"
        }
    }
}
