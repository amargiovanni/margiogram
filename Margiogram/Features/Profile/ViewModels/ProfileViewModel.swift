//
//  ProfileViewModel.swift
//  Margiogram
//
//  Created by Andrea Margiovanni on 2024.
//

import Foundation
import SwiftUI
import OSLog

// MARK: - Profile View Model

/// ViewModel for the user profile screen.
///
/// Manages profile data, editing, and media loading.
@MainActor
@Observable
final class ProfileViewModel {
    // MARK: - Properties

    /// The user being displayed.
    private(set) var user: User

    /// Whether this is the current user's profile.
    let isCurrentUser: Bool

    /// Chat with this user (if not current user).
    private(set) var chat: Chat?

    /// Shared media.
    private(set) var sharedMedia: [SharedMediaItem] = []

    /// Shared media filter.
    var mediaFilter: SharedMediaFilter = .photos

    /// Whether profile is loading.
    private(set) var isLoading = false

    /// Whether media is loading.
    private(set) var isLoadingMedia = false

    /// Current error if any.
    private(set) var error: ProfileError?

    /// Editing state.
    var isEditing = false
    var editedFirstName: String = ""
    var editedLastName: String = ""
    var editedBio: String = ""

    /// Logger for debugging.
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "ProfileViewModel")

    /// The TDLib client.
    private let client: TDLibClient

    // MARK: - Computed Properties

    /// Profile sections to display.
    var sections: [ProfileSection] {
        var result: [ProfileSection] = []

        // Info section
        var infoItems: [ProfileInfoItem] = []

        if let phone = user.phoneNumber, !phone.isEmpty {
            infoItems.append(ProfileInfoItem(
                icon: "phone.fill",
                title: String(localized: "Phone"),
                value: phone,
                action: .call
            ))
        }

        if let username = user.username {
            infoItems.append(ProfileInfoItem(
                icon: "at",
                title: String(localized: "Username"),
                value: "@\(username)",
                action: .copy
            ))
        }

        if let bio = user.bio, !bio.isEmpty {
            infoItems.append(ProfileInfoItem(
                icon: "info.circle.fill",
                title: String(localized: "Bio"),
                value: bio,
                action: nil
            ))
        }

        if !infoItems.isEmpty {
            result.append(ProfileSection(title: nil, items: infoItems))
        }

        // Notifications (for other users)
        if !isCurrentUser {
            result.append(ProfileSection(
                title: String(localized: "Notifications"),
                items: [
                    ProfileInfoItem(
                        icon: "bell.fill",
                        title: String(localized: "Notifications"),
                        value: chat?.isMuted == true ? String(localized: "Disabled") : String(localized: "Enabled"),
                        action: .toggleNotifications
                    )
                ]
            ))
        }

        return result
    }

    /// Actions available for this profile.
    var availableActions: [ProfileAction] {
        if isCurrentUser {
            return [.editProfile, .shareProfile]
        } else {
            return [.sendMessage, .call, .videoCall, .shareContact, .block]
        }
    }

    // MARK: - Initialization

    init(user: User, isCurrentUser: Bool = false, chat: Chat? = nil, client: TDLibClient = .shared) {
        self.user = user
        self.isCurrentUser = isCurrentUser
        self.chat = chat
        self.client = client

        // Initialize edit fields
        editedFirstName = user.firstName
        editedLastName = user.lastName
        editedBio = user.bio ?? ""
    }

    // MARK: - Public Methods

    /// Loads full profile data.
    func loadProfile() async {
        guard !isLoading else { return }

        logger.info("Loading profile for user: \(self.user.id)")
        isLoading = true

        do {
            // Fetch full user info
            user = try await fetchFullUser(user.id)

            // Fetch chat if not current user
            if !isCurrentUser && chat == nil {
                chat = try? await getPrivateChat(userId: user.id)
            }

            logger.info("Profile loaded successfully")
        } catch {
            self.error = .loadFailed(error)
            logger.error("Failed to load profile: \(error.localizedDescription)")
        }

        isLoading = false
    }

    /// Loads shared media.
    func loadSharedMedia() async {
        guard !isLoadingMedia, let chat else { return }

        logger.info("Loading shared media")
        isLoadingMedia = true

        do {
            sharedMedia = try await fetchSharedMedia(chatId: chat.id, filter: mediaFilter)
            logger.info("Loaded \(self.sharedMedia.count) media items")
        } catch {
            logger.error("Failed to load shared media: \(error.localizedDescription)")
        }

        isLoadingMedia = false
    }

    /// Saves profile changes.
    func saveChanges() async {
        guard isCurrentUser else { return }

        logger.info("Saving profile changes")

        do {
            try await updateProfile(
                firstName: editedFirstName,
                lastName: editedLastName,
                bio: editedBio
            )

            // Update local user
            user = User(
                id: user.id,
                firstName: editedFirstName,
                lastName: editedLastName,
                username: user.username,
                phoneNumber: user.phoneNumber,
                profilePhoto: user.profilePhoto,
                status: user.status,
                isVerified: user.isVerified,
                isPremium: user.isPremium,
                isBot: user.isBot,
                bio: editedBio,
                lastSeenDate: user.lastSeenDate
            )

            isEditing = false
            logger.info("Profile saved successfully")
        } catch {
            self.error = .saveFailed(error)
            logger.error("Failed to save profile: \(error.localizedDescription)")
        }
    }

    /// Cancels editing.
    func cancelEditing() {
        editedFirstName = user.firstName
        editedLastName = user.lastName
        editedBio = user.bio ?? ""
        isEditing = false
    }

    /// Updates profile photo.
    func updatePhoto(_ imageData: Data) async {
        guard isCurrentUser else { return }

        logger.info("Updating profile photo")

        do {
            try await setProfilePhoto(imageData)
            await loadProfile()
        } catch {
            self.error = .photoUpdateFailed(error)
            logger.error("Failed to update photo: \(error.localizedDescription)")
        }
    }

    /// Deletes profile photo.
    func deletePhoto() async {
        guard isCurrentUser, user.profilePhoto != nil else { return }

        logger.info("Deleting profile photo")

        do {
            try await deleteProfilePhoto()
            await loadProfile()
        } catch {
            logger.error("Failed to delete photo: \(error.localizedDescription)")
        }
    }

    /// Blocks/unblocks user.
    func toggleBlock() async {
        guard !isCurrentUser else { return }

        logger.info("Toggling block for user: \(self.user.id)")

        do {
            if user.isBlocked {
                try await unblockUser(user.id)
            } else {
                try await blockUser(user.id)
            }
            await loadProfile()
        } catch {
            logger.error("Failed to toggle block: \(error.localizedDescription)")
        }
    }

    /// Toggles notifications for this chat.
    func toggleNotifications() async {
        guard let chat, !isCurrentUser else { return }

        logger.info("Toggling notifications for chat: \(chat.id)")

        // In real implementation: toggle mute settings
    }

    /// Clears error.
    func clearError() {
        error = nil
    }

    // MARK: - Private Methods

    private func fetchFullUser(_ userId: Int64) async throws -> User {
        // In real implementation, call TDLib's getUser and getUserFullInfo
        #if DEBUG
        try? await Task.sleep(for: .milliseconds(200))
        return user
        #else
        return user
        #endif
    }

    private func getPrivateChat(userId: Int64) async throws -> Chat {
        // In real implementation, call TDLib's createPrivateChat
        #if DEBUG
        return Chat.mock(type: .private(userId: userId, isBot: false))
        #else
        throw ProfileError.loadFailed(NSError(domain: "Not implemented", code: 0))
        #endif
    }

    private func fetchSharedMedia(chatId: Int64, filter: SharedMediaFilter) async throws -> [SharedMediaItem] {
        // In real implementation, call TDLib's searchChatMessages with filter
        #if DEBUG
        try? await Task.sleep(for: .milliseconds(300))
        return SharedMediaItem.mockItems(filter: filter)
        #else
        return []
        #endif
    }

    private func updateProfile(firstName: String, lastName: String, bio: String) async throws {
        // In real implementation, call TDLib's setName and setBio
    }

    private func setProfilePhoto(_ imageData: Data) async throws {
        // In real implementation, call TDLib's setProfilePhoto
    }

    private func deleteProfilePhoto() async throws {
        // In real implementation, call TDLib's deleteProfilePhoto
    }

    private func blockUser(_ userId: Int64) async throws {
        // In real implementation, call TDLib's toggleMessageSenderIsBlocked
    }

    private func unblockUser(_ userId: Int64) async throws {
        // In real implementation, call TDLib's toggleMessageSenderIsBlocked
    }
}

// MARK: - Profile Section

/// A section in the profile view.
struct ProfileSection: Identifiable {
    let id = UUID()
    let title: String?
    let items: [ProfileInfoItem]
}

// MARK: - Profile Info Item

/// An info item in the profile.
struct ProfileInfoItem: Identifiable {
    let id = UUID()
    let icon: String
    let title: String
    let value: String
    let action: ProfileItemAction?
}

/// Action for a profile info item.
enum ProfileItemAction {
    case call
    case copy
    case toggleNotifications
}

// MARK: - Profile Action

/// Actions available on a profile.
enum ProfileAction: CaseIterable {
    case editProfile
    case shareProfile
    case sendMessage
    case call
    case videoCall
    case shareContact
    case block

    var title: String {
        switch self {
        case .editProfile: return String(localized: "Edit")
        case .shareProfile: return String(localized: "Share")
        case .sendMessage: return String(localized: "Message")
        case .call: return String(localized: "Call")
        case .videoCall: return String(localized: "Video")
        case .shareContact: return String(localized: "Share")
        case .block: return String(localized: "Block")
        }
    }

    var icon: String {
        switch self {
        case .editProfile: return "pencil"
        case .shareProfile: return "square.and.arrow.up"
        case .sendMessage: return "message.fill"
        case .call: return "phone.fill"
        case .videoCall: return "video.fill"
        case .shareContact: return "person.crop.circle.badge.plus"
        case .block: return "hand.raised.fill"
        }
    }

    var isDestructive: Bool {
        self == .block
    }
}

// MARK: - Shared Media Filter

/// Filter for shared media.
enum SharedMediaFilter: CaseIterable {
    case photos
    case videos
    case files
    case links
    case audio
    case voice

    var title: String {
        switch self {
        case .photos: return String(localized: "Photos")
        case .videos: return String(localized: "Videos")
        case .files: return String(localized: "Files")
        case .links: return String(localized: "Links")
        case .audio: return String(localized: "Audio")
        case .voice: return String(localized: "Voice")
        }
    }

    var icon: String {
        switch self {
        case .photos: return "photo.fill"
        case .videos: return "video.fill"
        case .files: return "doc.fill"
        case .links: return "link"
        case .audio: return "music.note"
        case .voice: return "waveform"
        }
    }
}

// MARK: - Shared Media Item

/// A shared media item.
struct SharedMediaItem: Identifiable {
    let id: Int64
    let type: SharedMediaFilter
    let date: Date
    let thumbnail: URL?
    let title: String?
    let size: Int64?

    #if DEBUG
    static func mockItems(filter: SharedMediaFilter) -> [SharedMediaItem] {
        (0..<20).map { index in
            SharedMediaItem(
                id: Int64(index),
                type: filter,
                date: Date().addingTimeInterval(-Double(index) * 86400),
                thumbnail: nil,
                title: filter == .files ? "Document \(index).pdf" : nil,
                size: filter == .files ? Int64.random(in: 1000...10000000) : nil
            )
        }
    }
    #endif
}

// MARK: - Profile Error

/// Errors that can occur with profiles.
enum ProfileError: LocalizedError {
    case loadFailed(Error)
    case saveFailed(Error)
    case photoUpdateFailed(Error)

    var errorDescription: String? {
        switch self {
        case .loadFailed(let error):
            return "Failed to load profile: \(error.localizedDescription)"
        case .saveFailed(let error):
            return "Failed to save profile: \(error.localizedDescription)"
        case .photoUpdateFailed(let error):
            return "Failed to update photo: \(error.localizedDescription)"
        }
    }
}
