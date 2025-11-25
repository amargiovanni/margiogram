//
//  UserRepositoryImpl.swift
//  Margiogram
//
//  Created by Andrea Margiovanni on 2024.
//

import Foundation

// MARK: - User Repository Protocol

/// Repository for user operations.
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
    func updateProfile(
        firstName: String,
        lastName: String,
        bio: String
    ) async throws

    /// Sets profile photo.
    func setProfilePhoto(photoData: Data) async throws

    /// Deletes profile photo.
    func deleteProfilePhoto() async throws

    /// Sets username.
    func setUsername(_ username: String?) async throws

    /// Gets user full info.
    func getUserFullInfo(userId: Int64) async throws -> UserFullInfo
}

// MARK: - User Repository Implementation

/// Implementation of UserRepository using TDLib.
actor UserRepositoryImpl: UserRepository {
    // MARK: - Properties

    private let client: TDLibClient
    private var userCache: [Int64: User] = [:]
    private var currentUserId: Int64?

    // MARK: - Initialization

    init(client: TDLibClient = .shared) {
        self.client = client
    }

    // MARK: - UserRepository

    func getUser(userId: Int64) async throws -> User {
        if let cached = userCache[userId] {
            return cached
        }

        // In real implementation: call TDLib's getUser
        #if DEBUG
        let user = User.mock()
        userCache[userId] = user
        return user
        #else
        throw UserRepositoryError.userNotFound(userId)
        #endif
    }

    func getCurrentUser() async throws -> User {
        // In real implementation: call TDLib's getMe
        #if DEBUG
        return User.mock(firstName: "Andrea", lastName: "Margiovanni", username: "andream")
        #else
        throw UserRepositoryError.notAuthenticated
        #endif
    }

    func getContacts() async throws -> [User] {
        // In real implementation: call TDLib's getContacts
        #if DEBUG
        return User.mockContacts
        #else
        return []
        #endif
    }

    func searchContacts(query: String, limit: Int32) async throws -> [User] {
        // In real implementation: call TDLib's searchContacts
        #if DEBUG
        return User.mockContacts.filter {
            $0.fullName.lowercased().contains(query.lowercased())
        }
        #else
        return []
        #endif
    }

    func addContact(
        phoneNumber: String,
        firstName: String,
        lastName: String
    ) async throws -> User {
        // In real implementation: call TDLib's addContact
        #if DEBUG
        return User.mock(firstName: firstName, lastName: lastName)
        #else
        throw UserRepositoryError.operationFailed("Not implemented")
        #endif
    }

    func removeContacts(userIds: [Int64]) async throws {
        // In real implementation: call TDLib's removeContacts
        for userId in userIds {
            userCache.removeValue(forKey: userId)
        }
    }

    func blockUser(userId: Int64) async throws {
        // In real implementation: call TDLib's toggleMessageSenderIsBlocked
        if var user = userCache[userId] {
            user.isBlocked = true
            userCache[userId] = user
        }
    }

    func unblockUser(userId: Int64) async throws {
        // In real implementation: call TDLib's toggleMessageSenderIsBlocked
        if var user = userCache[userId] {
            user.isBlocked = false
            userCache[userId] = user
        }
    }

    func getBlockedUsers(offset: Int32, limit: Int32) async throws -> [User] {
        // In real implementation: call TDLib's getBlockedMessageSenders
        return []
    }

    func updateProfile(
        firstName: String,
        lastName: String,
        bio: String
    ) async throws {
        // In real implementation: call TDLib's setName and setBio
    }

    func setProfilePhoto(photoData: Data) async throws {
        // In real implementation: call TDLib's setProfilePhoto
    }

    func deleteProfilePhoto() async throws {
        // In real implementation: call TDLib's deleteProfilePhoto
    }

    func setUsername(_ username: String?) async throws {
        // In real implementation: call TDLib's setUsername
    }

    func getUserFullInfo(userId: Int64) async throws -> UserFullInfo {
        // In real implementation: call TDLib's getUserFullInfo
        #if DEBUG
        return UserFullInfo(
            userId: userId,
            bio: nil,
            personalPhoto: nil,
            publicPhoto: nil,
            isBlocked: false,
            canBeCalled: true,
            supportsVideoCalls: true,
            hasPrivateCalls: false,
            needPhoneNumberPrivacyException: false,
            commonChatCount: 0,
            botInfo: nil
        )
        #else
        throw UserRepositoryError.userNotFound(userId)
        #endif
    }

    // MARK: - Cache Management

    func updateUserCache(_ user: User) {
        userCache[user.id] = user
    }

    func invalidateCache() {
        userCache.removeAll()
    }
}

// MARK: - User Repository Error

enum UserRepositoryError: LocalizedError {
    case userNotFound(Int64)
    case notAuthenticated
    case operationFailed(String)

    var errorDescription: String? {
        switch self {
        case .userNotFound(let id):
            return "User not found: \(id)"
        case .notAuthenticated:
            return "Not authenticated"
        case .operationFailed(let reason):
            return "Operation failed: \(reason)"
        }
    }
}
