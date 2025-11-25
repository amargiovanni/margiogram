//
//  UserUseCases.swift
//  Margiogram
//
//  Created by Andrea Margiovanni on 2024.
//

import Foundation

// MARK: - Get Current User Use Case

/// Use case for getting the current user.
struct GetCurrentUserUseCase {
    private let repository: UserRepository

    init(repository: UserRepository) {
        self.repository = repository
    }

    func execute() async throws -> User {
        try await repository.getCurrentUser()
    }
}

// MARK: - Get User Use Case

/// Use case for getting a user by ID.
struct GetUserUseCase {
    private let repository: UserRepository

    init(repository: UserRepository) {
        self.repository = repository
    }

    func execute(userId: Int64) async throws -> User {
        try await repository.getUser(userId: userId)
    }
}

// MARK: - Get Contacts Use Case

/// Use case for getting contacts.
struct GetContactsUseCase {
    private let repository: UserRepository

    init(repository: UserRepository) {
        self.repository = repository
    }

    func execute() async throws -> [User] {
        try await repository.getContacts()
    }
}

// MARK: - Search Contacts Use Case

/// Use case for searching contacts.
struct SearchContactsUseCase {
    private let repository: UserRepository

    init(repository: UserRepository) {
        self.repository = repository
    }

    func execute(query: String, limit: Int32 = 50) async throws -> [User] {
        try await repository.searchContacts(query: query, limit: limit)
    }
}

// MARK: - Add Contact Use Case

/// Use case for adding a contact.
struct AddContactUseCase {
    private let repository: UserRepository

    init(repository: UserRepository) {
        self.repository = repository
    }

    func execute(
        phoneNumber: String,
        firstName: String,
        lastName: String = ""
    ) async throws -> User {
        guard !phoneNumber.isEmpty else {
            throw UserUseCaseError.invalidPhoneNumber
        }
        guard !firstName.isEmpty else {
            throw UserUseCaseError.invalidName
        }

        return try await repository.addContact(
            phoneNumber: phoneNumber,
            firstName: firstName,
            lastName: lastName
        )
    }
}

// MARK: - Remove Contact Use Case

/// Use case for removing a contact.
struct RemoveContactUseCase {
    private let repository: UserRepository

    init(repository: UserRepository) {
        self.repository = repository
    }

    func execute(userId: Int64) async throws {
        try await repository.removeContacts(userIds: [userId])
    }

    func execute(userIds: [Int64]) async throws {
        try await repository.removeContacts(userIds: userIds)
    }
}

// MARK: - Block User Use Case

/// Use case for blocking a user.
struct BlockUserUseCase {
    private let repository: UserRepository

    init(repository: UserRepository) {
        self.repository = repository
    }

    func execute(userId: Int64) async throws {
        try await repository.blockUser(userId: userId)
    }
}

// MARK: - Unblock User Use Case

/// Use case for unblocking a user.
struct UnblockUserUseCase {
    private let repository: UserRepository

    init(repository: UserRepository) {
        self.repository = repository
    }

    func execute(userId: Int64) async throws {
        try await repository.unblockUser(userId: userId)
    }
}

// MARK: - Get Blocked Users Use Case

/// Use case for getting blocked users.
struct GetBlockedUsersUseCase {
    private let repository: UserRepository

    init(repository: UserRepository) {
        self.repository = repository
    }

    func execute(offset: Int32 = 0, limit: Int32 = 50) async throws -> [User] {
        try await repository.getBlockedUsers(offset: offset, limit: limit)
    }
}

// MARK: - Update Profile Use Case

/// Use case for updating user profile.
struct UpdateProfileUseCase {
    private let repository: UserRepository

    init(repository: UserRepository) {
        self.repository = repository
    }

    func execute(firstName: String, lastName: String, bio: String) async throws {
        guard !firstName.isEmpty else {
            throw UserUseCaseError.invalidName
        }

        try await repository.updateProfile(
            firstName: firstName,
            lastName: lastName,
            bio: bio
        )
    }
}

// MARK: - Set Profile Photo Use Case

/// Use case for setting profile photo.
struct SetProfilePhotoUseCase {
    private let repository: UserRepository

    init(repository: UserRepository) {
        self.repository = repository
    }

    func execute(photoData: Data) async throws {
        guard !photoData.isEmpty else {
            throw UserUseCaseError.invalidPhoto
        }

        try await repository.setProfilePhoto(photoData: photoData)
    }
}

// MARK: - Delete Profile Photo Use Case

/// Use case for deleting profile photo.
struct DeleteProfilePhotoUseCase {
    private let repository: UserRepository

    init(repository: UserRepository) {
        self.repository = repository
    }

    func execute() async throws {
        try await repository.deleteProfilePhoto()
    }
}

// MARK: - Set Username Use Case

/// Use case for setting username.
struct SetUsernameUseCase {
    private let repository: UserRepository

    init(repository: UserRepository) {
        self.repository = repository
    }

    func execute(username: String?) async throws {
        if let username, !username.isEmpty {
            // Validate username format
            let pattern = "^[a-zA-Z][a-zA-Z0-9_]{4,31}$"
            let regex = try NSRegularExpression(pattern: pattern)
            let range = NSRange(location: 0, length: username.utf16.count)

            guard regex.firstMatch(in: username, range: range) != nil else {
                throw UserUseCaseError.invalidUsername
            }
        }

        try await repository.setUsername(username)
    }
}

// MARK: - User Use Case Error

enum UserUseCaseError: LocalizedError {
    case invalidPhoneNumber
    case invalidName
    case invalidUsername
    case invalidPhoto

    var errorDescription: String? {
        switch self {
        case .invalidPhoneNumber:
            return "Invalid phone number"
        case .invalidName:
            return "Name cannot be empty"
        case .invalidUsername:
            return "Invalid username format"
        case .invalidPhoto:
            return "Invalid photo data"
        }
    }
}
