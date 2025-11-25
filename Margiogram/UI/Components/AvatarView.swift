//
//  AvatarView.swift
//  Margiogram
//
//  Created by Andrea Margiovanni on 2024.
//

import SwiftUI

// MARK: - Avatar View

/// A view that displays a user or chat avatar.
///
/// The avatar can display:
/// - A photo from a URL
/// - A placeholder with initials and gradient background
/// - An optional online status indicator
struct AvatarView: View {
    // MARK: - Properties

    /// URL of the avatar image.
    let imageURL: URL?

    /// Name used for initials and gradient color.
    let name: String

    /// Size of the avatar.
    let size: CGFloat

    /// Whether to show the online status indicator.
    let showOnlineIndicator: Bool

    /// Whether the user is currently online.
    let isOnline: Bool

    /// Whether to show verification badge.
    let isVerified: Bool

    /// Whether the user is premium.
    let isPremium: Bool

    // MARK: - Initialization

    init(
        imageURL: URL? = nil,
        name: String,
        size: CGFloat = AvatarSize.large,
        showOnlineIndicator: Bool = false,
        isOnline: Bool = false,
        isVerified: Bool = false,
        isPremium: Bool = false
    ) {
        self.imageURL = imageURL
        self.name = name
        self.size = size
        self.showOnlineIndicator = showOnlineIndicator
        self.isOnline = isOnline
        self.isVerified = isVerified
        self.isPremium = isPremium
    }

    // MARK: - Body

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            avatarImage
                .frame(width: size, height: size)
                .clipShape(Circle())
                .overlay(borderOverlay)
                .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)

            if showOnlineIndicator {
                onlineIndicator
            }

            if isVerified || isPremium {
                badgeIndicator
            }
        }
    }

    // MARK: - Avatar Image

    @ViewBuilder
    private var avatarImage: some View {
        if let url = imageURL {
            AsyncImage(url: url) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)

                case .failure:
                    placeholderAvatar

                case .empty:
                    placeholderAvatar
                        .overlay {
                            ProgressView()
                                .scaleEffect(0.5)
                        }

                @unknown default:
                    placeholderAvatar
                }
            }
        } else {
            placeholderAvatar
        }
    }

    private var placeholderAvatar: some View {
        ZStack {
            LinearGradient.avatar(for: name)

            Text(initials)
                .font(.system(size: size * 0.4, weight: .semibold))
                .foregroundStyle(.white)
        }
    }

    // MARK: - Border Overlay

    private var borderOverlay: some View {
        Circle()
            .stroke(
                LinearGradient(
                    colors: [.white.opacity(0.3), .white.opacity(0.1)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                lineWidth: 1
            )
    }

    // MARK: - Online Indicator

    private var onlineIndicator: some View {
        Circle()
            .fill(isOnline ? Color.statusOnline : Color.statusOffline)
            .frame(width: indicatorSize, height: indicatorSize)
            .overlay(
                Circle()
                    .stroke(Color(.systemBackground), lineWidth: indicatorBorderWidth)
            )
            .offset(x: -indicatorOffset, y: -indicatorOffset)
    }

    // MARK: - Badge Indicator

    private var badgeIndicator: some View {
        Group {
            if isVerified {
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: badgeSize))
                    .foregroundStyle(.blue)
            } else if isPremium {
                Image(systemName: "star.fill")
                    .font(.system(size: badgeSize))
                    .foregroundStyle(.purple)
            }
        }
        .background(
            Circle()
                .fill(Color(.systemBackground))
                .frame(width: badgeSize + 4, height: badgeSize + 4)
        )
        .offset(x: -badgeOffset, y: -badgeOffset)
    }

    // MARK: - Computed Properties

    private var initials: String {
        let components = name.split(separator: " ").prefix(2)
        return components.map { String($0.prefix(1)) }.joined().uppercased()
    }

    private var indicatorSize: CGFloat {
        max(size * 0.25, 10)
    }

    private var indicatorBorderWidth: CGFloat {
        max(size * 0.04, 2)
    }

    private var indicatorOffset: CGFloat {
        size * 0.04
    }

    private var badgeSize: CGFloat {
        max(size * 0.3, 14)
    }

    private var badgeOffset: CGFloat {
        size * 0.02
    }
}

// MARK: - Avatar Group View

/// A view that displays a group of overlapping avatars.
struct AvatarGroupView: View {
    let avatars: [(url: URL?, name: String)]
    let size: CGFloat
    let maxDisplay: Int
    let overlap: CGFloat

    init(
        avatars: [(url: URL?, name: String)],
        size: CGFloat = AvatarSize.small,
        maxDisplay: Int = 3,
        overlap: CGFloat = 0.3
    ) {
        self.avatars = avatars
        self.size = size
        self.maxDisplay = maxDisplay
        self.overlap = overlap
    }

    var body: some View {
        HStack(spacing: -size * overlap) {
            ForEach(Array(displayAvatars.enumerated()), id: \.offset) { index, avatar in
                AvatarView(
                    imageURL: avatar.url,
                    name: avatar.name,
                    size: size
                )
                .zIndex(Double(displayAvatars.count - index))
            }

            if remainingCount > 0 {
                remainingIndicator
                    .zIndex(-1)
            }
        }
    }

    private var displayAvatars: [(url: URL?, name: String)] {
        Array(avatars.prefix(maxDisplay))
    }

    private var remainingCount: Int {
        max(0, avatars.count - maxDisplay)
    }

    private var remainingIndicator: some View {
        ZStack {
            Circle()
                .fill(Color(.systemGray4))

            Text("+\(remainingCount)")
                .font(.system(size: size * 0.35, weight: .semibold))
                .foregroundStyle(.secondary)
        }
        .frame(width: size, height: size)
    }
}

// MARK: - Convenience Initializers

extension AvatarView {
    /// Creates an avatar view for a User.
    init(user: User, size: CGFloat = AvatarSize.large, showOnlineIndicator: Bool = true) {
        self.init(
            imageURL: user.profilePhoto?.smallURL,
            name: user.fullName,
            size: size,
            showOnlineIndicator: showOnlineIndicator,
            isOnline: user.isOnline,
            isVerified: user.isVerified,
            isPremium: user.isPremium
        )
    }

    /// Creates an avatar view for a Chat.
    init(chat: Chat, size: CGFloat = AvatarSize.large) {
        self.init(
            imageURL: chat.photo?.smallURL,
            name: chat.title,
            size: size,
            showOnlineIndicator: false,
            isOnline: false,
            isVerified: false,
            isPremium: false
        )
    }
}

// MARK: - Preview

#Preview("Avatar Views") {
    VStack(spacing: Spacing.lg) {
        // Different sizes
        HStack(spacing: Spacing.md) {
            AvatarView(name: "John Doe", size: AvatarSize.small)
            AvatarView(name: "John Doe", size: AvatarSize.medium)
            AvatarView(name: "John Doe", size: AvatarSize.large)
            AvatarView(name: "John Doe", size: AvatarSize.xlarge)
        }

        // With online indicator
        HStack(spacing: Spacing.md) {
            AvatarView(name: "Online User", showOnlineIndicator: true, isOnline: true)
            AvatarView(name: "Offline User", showOnlineIndicator: true, isOnline: false)
        }

        // With badges
        HStack(spacing: Spacing.md) {
            AvatarView(name: "Verified", isVerified: true)
            AvatarView(name: "Premium", isPremium: true)
        }

        // Different names (colors)
        HStack(spacing: Spacing.md) {
            AvatarView(name: "Alice")
            AvatarView(name: "Bob")
            AvatarView(name: "Charlie")
            AvatarView(name: "Diana")
        }

        // Group
        AvatarGroupView(avatars: [
            (nil, "Alice"),
            (nil, "Bob"),
            (nil, "Charlie"),
            (nil, "Diana"),
            (nil, "Eve")
        ])
    }
    .padding()
}
