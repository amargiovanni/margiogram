//
//  User.swift
//  Margiogram
//
//  Created by Andrea Margiovanni on 2024.
//

import Foundation

// MARK: - User

/// Represents a Telegram user.
struct User: Identifiable, Equatable, Hashable, Sendable {
    // MARK: - Properties

    /// Unique user identifier.
    let id: Int64

    /// User's first name.
    let firstName: String

    /// User's last name.
    let lastName: String

    /// User's username (without @).
    let username: String?

    /// User's phone number.
    let phoneNumber: String?

    /// User's profile photo.
    let profilePhoto: ChatPhoto?

    /// User's current status.
    var status: UserStatus

    /// Whether this user is a contact.
    let isContact: Bool

    /// Whether this user is a mutual contact.
    let isMutualContact: Bool

    /// Whether this user is verified.
    let isVerified: Bool

    /// Whether this user is a premium subscriber.
    let isPremium: Bool

    /// Whether this user is a bot.
    let isBot: Bool

    /// Whether this user can be called.
    let canBeCalled: Bool

    /// Whether this user supports video calls.
    let supportsVideoCalls: Bool

    /// Restriction reason if the user is restricted.
    let restrictionReason: String?

    /// User's bio/about text.
    let bio: String?

    /// Bot info if the user is a bot.
    let botInfo: BotInfo?

    /// Whether this user is blocked.
    var isBlocked: Bool

    /// Last seen date (for offline status).
    var lastSeenDate: Date?

    // MARK: - Computed Properties

    /// Full display name.
    var fullName: String {
        if lastName.isEmpty {
            return firstName
        }
        return "\(firstName) \(lastName)"
    }

    /// Username with @ prefix.
    var usernameWithAt: String? {
        username.map { "@\($0)" }
    }

    /// Initials for avatar placeholder.
    var initials: String {
        let first = firstName.prefix(1)
        let last = lastName.prefix(1)
        return "\(first)\(last)".uppercased()
    }

    /// Whether the user is currently online.
    var isOnline: Bool {
        if case .online = status { return true }
        return false
    }
}

// MARK: - User Status

/// Status of a user (online, offline, etc.).
enum UserStatus: Equatable, Hashable, Sendable {
    case empty
    case online(expires: Date)
    case offline(wasOnline: Date)
    case recently
    case lastWeek
    case lastMonth

    /// Formatted status text for display.
    var displayText: String {
        switch self {
        case .empty:
            return ""
        case .online:
            return "online"
        case .offline(let wasOnline):
            return formatLastSeen(wasOnline)
        case .recently:
            return "last seen recently"
        case .lastWeek:
            return "last seen within a week"
        case .lastMonth:
            return "last seen within a month"
        }
    }

    private func formatLastSeen(_ date: Date) -> String {
        let calendar = Calendar.current
        let now = Date()

        if calendar.isDateInToday(date) {
            let formatter = DateFormatter()
            formatter.dateFormat = "HH:mm"
            return "last seen today at \(formatter.string(from: date))"
        } else if calendar.isDateInYesterday(date) {
            let formatter = DateFormatter()
            formatter.dateFormat = "HH:mm"
            return "last seen yesterday at \(formatter.string(from: date))"
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "dd.MM.yy"
            return "last seen \(formatter.string(from: date))"
        }
    }
}

// MARK: - Bot Info

/// Information about a bot.
struct BotInfo: Equatable, Hashable, Sendable {
    let description: String
    let commands: [BotCommand]
    let menuButton: BotMenuButton?
}

/// A bot command.
struct BotCommand: Equatable, Hashable, Sendable {
    let command: String
    let description: String
}

/// Bot menu button type.
enum BotMenuButton: Equatable, Hashable, Sendable {
    case commands
    case webApp(text: String, url: String)
}

// MARK: - User Full Info

/// Extended information about a user.
struct UserFullInfo: Equatable, Hashable, Sendable {
    let userId: Int64
    let bio: FormattedText?
    let personalPhoto: ChatPhoto?
    let publicPhoto: ChatPhoto?
    let isBlocked: Bool
    let canBeCalled: Bool
    let supportsVideoCalls: Bool
    let hasPrivateCalls: Bool
    let needPhoneNumberPrivacyException: Bool
    let commonChatCount: Int32
    let botInfo: BotInfo?
}

// MARK: - Mock Data

#if DEBUG
extension User {
    static func mock(
        id: Int64 = Int64.random(in: 1...1000000),
        firstName: String = "John",
        lastName: String = "Doe",
        username: String? = "johndoe",
        isOnline: Bool = false,
        isVerified: Bool = false,
        isPremium: Bool = false,
        bio: String? = nil
    ) -> User {
        let lastSeen = Date().addingTimeInterval(-Double.random(in: 3600...86400))
        return User(
            id: id,
            firstName: firstName,
            lastName: lastName,
            username: username,
            phoneNumber: "+39 123 456 7890",
            profilePhoto: nil,
            status: isOnline ? .online(expires: Date().addingTimeInterval(300)) : .offline(wasOnline: lastSeen),
            isContact: true,
            isMutualContact: true,
            isVerified: isVerified,
            isPremium: isPremium,
            isBot: false,
            canBeCalled: true,
            supportsVideoCalls: true,
            restrictionReason: nil,
            bio: bio,
            botInfo: nil,
            isBlocked: false,
            lastSeenDate: isOnline ? nil : lastSeen
        )
    }
}
#endif
