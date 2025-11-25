//
//  ContactsViewModel.swift
//  Margiogram
//
//  Created by Andrea Margiovanni on 2024.
//

import Foundation
import SwiftUI
import OSLog

// MARK: - Contacts View Model

/// ViewModel for the contacts screen.
///
/// Handles loading, searching, and managing contacts.
@MainActor
@Observable
final class ContactsViewModel {
    // MARK: - Properties

    /// All contacts.
    private(set) var contacts: [User] = []

    /// Search query.
    var searchQuery: String = ""

    /// Whether contacts are loading.
    private(set) var isLoading = false

    /// Current error if any.
    private(set) var error: ContactsError?

    /// Logger for debugging.
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "ContactsViewModel")

    /// The TDLib client.
    private let client: TDLibClient

    // MARK: - Computed Properties

    /// Filtered contacts based on search.
    var filteredContacts: [User] {
        if searchQuery.isEmpty {
            return contacts
        }
        let query = searchQuery.lowercased()
        return contacts.filter {
            $0.fullName.lowercased().contains(query) ||
            $0.username?.lowercased().contains(query) == true ||
            $0.phoneNumber?.contains(query) == true
        }
    }

    /// Contacts grouped by first letter.
    var groupedContacts: [(letter: String, contacts: [User])] {
        let grouped = Dictionary(grouping: filteredContacts) { user -> String in
            let firstChar = user.firstName.prefix(1).uppercased()
            return firstChar.isEmpty ? "#" : (firstChar.first?.isLetter == true ? firstChar : "#")
        }

        return grouped
            .map { (letter: $0.key, contacts: $0.value.sorted { $0.fullName < $1.fullName }) }
            .sorted { $0.letter < $1.letter }
    }

    /// Section index titles.
    var sectionIndexTitles: [String] {
        groupedContacts.map { $0.letter }
    }

    /// Online contacts.
    var onlineContacts: [User] {
        contacts.filter { $0.isOnline }
    }

    /// Whether contacts list is empty.
    var isEmpty: Bool {
        filteredContacts.isEmpty && !isLoading
    }

    /// Whether search is active.
    var isSearching: Bool {
        !searchQuery.isEmpty
    }

    // MARK: - Initialization

    init(client: TDLibClient = .shared) {
        self.client = client
    }

    // MARK: - Public Methods

    /// Loads contacts.
    func loadContacts() async {
        guard !isLoading else { return }

        logger.info("Loading contacts")
        isLoading = true
        error = nil

        do {
            contacts = try await fetchContacts()
            logger.info("Loaded \(self.contacts.count) contacts")
        } catch {
            self.error = .loadFailed(error)
            logger.error("Failed to load contacts: \(error.localizedDescription)")
        }

        isLoading = false
    }

    /// Refreshes contacts.
    func refresh() async {
        logger.info("Refreshing contacts")
        await loadContacts()
    }

    /// Adds a contact.
    func addContact(
        phoneNumber: String,
        firstName: String,
        lastName: String
    ) async -> User? {
        logger.info("Adding contact: \(firstName) \(lastName)")

        do {
            let user = try await performAddContact(
                phoneNumber: phoneNumber,
                firstName: firstName,
                lastName: lastName
            )
            contacts.append(user)
            contacts.sort { $0.fullName < $1.fullName }
            return user
        } catch {
            self.error = .addFailed(error)
            logger.error("Failed to add contact: \(error.localizedDescription)")
            return nil
        }
    }

    /// Deletes a contact.
    func deleteContact(_ user: User) async {
        logger.info("Deleting contact: \(user.id)")

        do {
            try await performDeleteContact(user.id)
            contacts.removeAll { $0.id == user.id }
        } catch {
            self.error = .deleteFailed(error)
            logger.error("Failed to delete contact: \(error.localizedDescription)")
        }
    }

    /// Shares contact.
    func shareContact(_ user: User) {
        // In real implementation: Create share sheet
        logger.info("Sharing contact: \(user.id)")
    }

    /// Opens chat with contact.
    func openChat(with user: User) async -> Chat? {
        logger.info("Opening chat with: \(user.id)")

        do {
            return try await getOrCreatePrivateChat(userId: user.id)
        } catch {
            logger.error("Failed to open chat: \(error.localizedDescription)")
            return nil
        }
    }

    /// Clears error.
    func clearError() {
        error = nil
    }

    // MARK: - Private Methods

    private func fetchContacts() async throws -> [User] {
        // In real implementation, call TDLib's getContacts
        #if DEBUG
        try? await Task.sleep(for: .milliseconds(300))
        return User.mockContacts
        #else
        return []
        #endif
    }

    private func performAddContact(
        phoneNumber: String,
        firstName: String,
        lastName: String
    ) async throws -> User {
        // In real implementation, call TDLib's addContact
        #if DEBUG
        return User.mock(firstName: firstName, lastName: lastName)
        #else
        throw ContactsError.addFailed(NSError(domain: "Not implemented", code: 0))
        #endif
    }

    private func performDeleteContact(_ userId: Int64) async throws {
        // In real implementation, call TDLib's removeContacts
    }

    private func getOrCreatePrivateChat(userId: Int64) async throws -> Chat {
        // In real implementation, call TDLib's createPrivateChat
        #if DEBUG
        return Chat.mock(type: .private(userId: userId, isBot: false))
        #else
        throw ContactsError.loadFailed(NSError(domain: "Not implemented", code: 0))
        #endif
    }
}

// MARK: - Contacts Error

/// Errors that can occur with contacts.
enum ContactsError: LocalizedError {
    case loadFailed(Error)
    case addFailed(Error)
    case deleteFailed(Error)

    var errorDescription: String? {
        switch self {
        case .loadFailed(let error):
            return "Failed to load contacts: \(error.localizedDescription)"
        case .addFailed(let error):
            return "Failed to add contact: \(error.localizedDescription)"
        case .deleteFailed(let error):
            return "Failed to delete contact: \(error.localizedDescription)"
        }
    }
}

// MARK: - Mock Data

#if DEBUG
extension User {
    static var mockContacts: [User] {
        [
            .mock(firstName: "Alice", lastName: "Anderson", isOnline: true),
            .mock(firstName: "Bob", lastName: "Brown"),
            .mock(firstName: "Charlie", lastName: "Clark", isOnline: true),
            .mock(firstName: "Diana", lastName: "Davis"),
            .mock(firstName: "Edward", lastName: "Evans"),
            .mock(firstName: "Fiona", lastName: "Fisher", isOnline: true),
            .mock(firstName: "George", lastName: "Garcia"),
            .mock(firstName: "Hannah", lastName: "Harris"),
            .mock(firstName: "Ivan", lastName: "Ivanov"),
            .mock(firstName: "Julia", lastName: "Johnson", isOnline: true),
        ]
    }
}
#endif
