//
//  ChatRowView.swift
//  Margiogram
//
//  Created by Andrea Margiovanni on 2024.
//

import SwiftUI

// MARK: - Chat Row View

/// A row view displaying a single chat in the chat list.
///
/// Shows avatar, title, last message preview, time, and status indicators.
struct ChatRowView: View {
    // MARK: - Properties

    let chat: Chat
    let action: ((User, ChatAction))?
    let onTap: () -> Void

    // MARK: - Environment

    @Environment(\.colorScheme) private var colorScheme

    // MARK: - Body

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: Spacing.sm) {
                // Avatar
                avatarView

                // Content
                VStack(alignment: .leading, spacing: Spacing.xxxs) {
                    // Top row: Title and time
                    HStack {
                        titleView
                        Spacer()
                        timeView
                    }

                    // Bottom row: Preview and badges
                    HStack {
                        previewView
                        Spacer()
                        badgesView
                    }
                }
            }
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.sm)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    // MARK: - Avatar View

    private var avatarView: some View {
        AvatarView(chat: chat, size: AvatarSize.chatList)
    }

    // MARK: - Title View

    private var titleView: some View {
        HStack(spacing: Spacing.xxs) {
            // Chat type icon
            if chat.isChannel {
                Image(systemName: "megaphone.fill")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else if chat.isBot {
                Image(systemName: "cpu.fill")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            // Title
            Text(chat.title)
                .font(Typography.chatTitle)
                .foregroundStyle(.primary)
                .lineLimit(1)

            // Muted indicator
            if chat.isMuted {
                Image(systemName: "speaker.slash.fill")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
    }

    // MARK: - Time View

    private var timeView: some View {
        Group {
            if let date = chat.lastMessageDate {
                Text(formatTime(date))
                    .font(Typography.caption)
                    .foregroundStyle(chat.hasUnread ? .accentColor : .secondary)
            }
        }
    }

    // MARK: - Preview View

    @ViewBuilder
    private var previewView: some View {
        if let actionInfo = action {
            // Typing indicator
            typingIndicatorView(user: actionInfo.0, action: actionInfo.1)
        } else if let draft = chat.draftMessage {
            // Draft message
            draftView(draft)
        } else if let lastMessage = chat.lastMessage {
            // Last message preview
            lastMessageView(lastMessage)
        } else {
            Text("No messages yet")
                .font(Typography.chatPreview)
                .foregroundStyle(.tertiary)
        }
    }

    private func typingIndicatorView(user: User, action: ChatAction) -> some View {
        HStack(spacing: Spacing.xxs) {
            if chat.isGroup || chat.isChannel {
                Text(user.firstName + ":")
                    .font(Typography.chatPreview)
                    .foregroundStyle(.accentColor)
            }

            Text(action.description)
                .font(Typography.chatPreview)
                .foregroundStyle(.accentColor)
                .italic()

            TypingDotsView()
        }
        .lineLimit(1)
    }

    private func draftView(_ draft: DraftMessage) -> some View {
        HStack(spacing: Spacing.xxs) {
            Text("Draft:")
                .font(Typography.chatPreview)
                .foregroundStyle(.error)

            Text(draftPreview(draft))
                .font(Typography.chatPreview)
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
    }

    private func lastMessageView(_ message: Message) -> some View {
        HStack(spacing: Spacing.xxs) {
            // Sender name for groups
            if (chat.isGroup || chat.isChannel) && !message.isOutgoing {
                if let sender = message.sender {
                    Text(sender.firstName + ":")
                        .font(Typography.chatPreview)
                        .foregroundStyle(.accentColor)
                }
            } else if message.isOutgoing {
                // Outgoing message status
                messageStatusIcon(message)
            }

            // Message content preview
            Text(messagePreview(message))
                .font(Typography.chatPreview)
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
    }

    @ViewBuilder
    private func messageStatusIcon(_ message: Message) -> some View {
        switch message.sendingState {
        case .pending:
            Image(systemName: "clock")
                .font(.caption2)
                .foregroundStyle(.tertiary)
        case .failed:
            Image(systemName: "exclamationmark.circle.fill")
                .font(.caption2)
                .foregroundStyle(.error)
        case .sent:
            if message.isRead {
                Image(systemName: "checkmark.circle.fill")
                    .font(.caption2)
                    .foregroundStyle(.accentColor)
            } else {
                Image(systemName: "checkmark")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - Badges View

    private var badgesView: some View {
        HStack(spacing: Spacing.xxs) {
            // Pinned indicator
            if chat.isPinned {
                Image(systemName: "pin.fill")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            // Unread badge
            if chat.unreadCount > 0 {
                UnreadBadge(count: chat.unreadCount, isMuted: chat.isMuted)
            } else if chat.isMarkedAsUnread {
                Circle()
                    .fill(chat.isMuted ? Color.secondary : Color.accentColor)
                    .frame(width: 10, height: 10)
            }

            // Mention badge
            if chat.unreadMentionCount > 0 {
                MentionBadge()
            }
        }
    }

    // MARK: - Helpers

    private func formatTime(_ date: Date) -> String {
        let calendar = Calendar.current
        let now = Date()

        if calendar.isDateInToday(date) {
            return date.formatted(date: .omitted, time: .shortened)
        } else if calendar.isDateInYesterday(date) {
            return String(localized: "Yesterday")
        } else if calendar.isDate(date, equalTo: now, toGranularity: .weekOfYear) {
            return date.formatted(.dateTime.weekday(.abbreviated))
        } else if calendar.isDate(date, equalTo: now, toGranularity: .year) {
            return date.formatted(.dateTime.day().month(.abbreviated))
        } else {
            return date.formatted(.dateTime.day().month(.abbreviated).year(.twoDigits))
        }
    }

    private func messagePreview(_ message: Message) -> String {
        switch message.content {
        case .text(let text, _):
            return text
        case .photo(let photo):
            return photo.caption?.isEmpty == false ? photo.caption! : String(localized: "Photo")
        case .video(let video):
            return video.caption?.isEmpty == false ? video.caption! : String(localized: "Video")
        case .audio(let audio):
            return audio.title ?? String(localized: "Audio")
        case .voice:
            return String(localized: "Voice message")
        case .videoNote:
            return String(localized: "Video message")
        case .document(let doc):
            return doc.fileName ?? String(localized: "Document")
        case .sticker(let sticker):
            return sticker.emoji + " " + String(localized: "Sticker")
        case .animation:
            return String(localized: "GIF")
        case .location:
            return String(localized: "Location")
        case .contact(let contact):
            return String(localized: "Contact: \(contact.firstName)")
        case .poll(let poll):
            return String(localized: "Poll: \(poll.question)")
        case .unsupported:
            return String(localized: "Unsupported message")
        }
    }

    private func draftPreview(_ draft: DraftMessage) -> String {
        switch draft.content {
        case .text(let text, _):
            return text
        default:
            return String(localized: "Message")
        }
    }
}

// MARK: - Chat Action Description

extension ChatAction {
    var description: String {
        switch self {
        case .typing:
            return String(localized: "typing")
        case .recordingVoiceNote:
            return String(localized: "recording voice")
        case .uploadingVoiceNote:
            return String(localized: "sending voice")
        case .recordingVideoNote:
            return String(localized: "recording video")
        case .uploadingVideoNote:
            return String(localized: "sending video message")
        case .uploadingPhoto:
            return String(localized: "sending photo")
        case .uploadingDocument:
            return String(localized: "sending file")
        case .uploadingVideo:
            return String(localized: "sending video")
        case .choosingLocation:
            return String(localized: "choosing location")
        case .choosingContact:
            return String(localized: "choosing contact")
        case .startPlayingGame:
            return String(localized: "playing")
        case .watchingAnimations(let emoji):
            return String(localized: "watching \(emoji)")
        case .cancel:
            return ""
        }
    }
}

// MARK: - Unread Badge

/// Badge showing unread message count.
struct UnreadBadge: View {
    let count: Int32
    let isMuted: Bool

    var body: some View {
        Text(formattedCount)
            .font(Typography.badge)
            .foregroundStyle(.white)
            .padding(.horizontal, Spacing.xs)
            .padding(.vertical, Spacing.xxxs)
            .background(
                Capsule()
                    .fill(isMuted ? Color.secondary : Color.accentColor)
            )
    }

    private var formattedCount: String {
        if count > 999 {
            return "999+"
        }
        return String(count)
    }
}

// MARK: - Mention Badge

/// Badge indicating unread mentions.
struct MentionBadge: View {
    var body: some View {
        Text("@")
            .font(Typography.badge)
            .foregroundStyle(.white)
            .frame(width: 20, height: 20)
            .background(Circle().fill(Color.accentColor))
    }
}

// MARK: - Typing Dots View

/// Animated typing indicator dots.
struct TypingDotsView: View {
    @State private var animationOffset: Int = 0

    var body: some View {
        HStack(spacing: 2) {
            ForEach(0..<3, id: \.self) { index in
                Circle()
                    .fill(Color.accentColor)
                    .frame(width: 4, height: 4)
                    .offset(y: animationOffset == index ? -2 : 0)
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 0.3).repeatForever(autoreverses: true)) {
                animationOffset = (animationOffset + 1) % 3
            }
        }
    }
}

// MARK: - Preview

#Preview("Chat Row") {
    VStack(spacing: 0) {
        ForEach(Chat.mockList) { chat in
            ChatRowView(chat: chat, action: nil) {
                print("Tapped \(chat.title)")
            }
            Divider()
                .padding(.leading, Spacing.md + AvatarSize.chatList + Spacing.sm)
        }
    }
}
