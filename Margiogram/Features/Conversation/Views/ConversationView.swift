//
//  ConversationView.swift
//  Margiogram
//
//  Created by Andrea Margiovanni on 2024.
//

import SwiftUI

// MARK: - Conversation View

/// Main view for a chat conversation.
///
/// Features:
/// - Message list with date separators
/// - Scroll to bottom button
/// - Pull to load more
/// - Message selection mode
/// - Reply/edit/forward actions
struct ConversationView: View {
    // MARK: - Properties

    @State private var viewModel: ConversationViewModel

    // MARK: - State

    @State private var scrollProxy: ScrollViewProxy?
    @State private var showScrollToBottom = false
    @State private var contentHeight: CGFloat = 0

    // MARK: - Environment

    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    // MARK: - Namespace

    @Namespace private var bottomAnchor

    // MARK: - Initialization

    init(chat: Chat) {
        _viewModel = State(initialValue: ConversationViewModel(chat: chat))
    }

    init(viewModel: ConversationViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            // Background
            chatBackground

            // Main content
            VStack(spacing: 0) {
                // Message list
                messageList

                // Input area
                MessageInputView(viewModel: viewModel)
            }

            // Scroll to bottom button
            if showScrollToBottom {
                scrollToBottomButton
            }

            // Selection toolbar
            if viewModel.isSelectionMode {
                selectionToolbar
            }
        }
        .navigationTitle(viewModel.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            toolbarContent
        }
        .task {
            await viewModel.loadMessages()
        }
        .sheet(isPresented: $viewModel.showAttachmentPicker) {
            AttachmentPickerView(isPresented: $viewModel.showAttachmentPicker) { type in
                // Handle attachment selection
            }
        }
        .alert(
            "Error",
            isPresented: .constant(viewModel.error != nil),
            presenting: viewModel.error
        ) { _ in
            Button("OK") {
                viewModel.clearError()
            }
        } message: { error in
            Text(error.localizedDescription)
        }
    }

    // MARK: - Chat Background

    private var chatBackground: some View {
        ZStack {
            // Base color
            Color(.systemBackground)

            // Pattern overlay (optional)
            GeometryReader { geometry in
                Image(systemName: "bubble.left.and.bubble.right")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: geometry.size.width * 0.6)
                    .foregroundStyle(.primary.opacity(0.02))
                    .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
            }
        }
        .ignoresSafeArea()
    }

    // MARK: - Message List

    private var messageList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 0) {
                    // Load more indicator
                    if viewModel.hasMoreMessages {
                        loadMoreIndicator
                            .onAppear {
                                Task {
                                    await viewModel.loadMoreMessages()
                                }
                            }
                    }

                    // Grouped messages by date
                    ForEach(viewModel.groupedMessages) { group in
                        dateSeparator(for: group.date, text: group.formattedDate)

                        ForEach(Array(group.messages.enumerated()), id: \.element.id) { index, message in
                            messageRow(
                                message: message,
                                previousMessage: index > 0 ? group.messages[index - 1] : nil,
                                nextMessage: index < group.messages.count - 1 ? group.messages[index + 1] : nil
                            )
                        }
                    }

                    // Bottom anchor
                    Color.clear
                        .frame(height: 1)
                        .id(bottomAnchor)
                }
                .padding(.vertical, Spacing.sm)
                .background(
                    GeometryReader { geometry in
                        Color.clear
                            .preference(key: ScrollOffsetPreferenceKey.self, value: geometry.frame(in: .named("scroll")).maxY)
                    }
                )
            }
            .coordinateSpace(name: "scroll")
            .scrollDismissesKeyboard(.interactively)
            .onPreferenceChange(ScrollOffsetPreferenceKey.self) { value in
                // Show scroll to bottom button when not at bottom
                showScrollToBottom = value > 100
            }
            .onAppear {
                scrollProxy = proxy
                scrollToBottom(animated: false)
            }
            .onChange(of: viewModel.messages.count) { _, _ in
                scrollToBottom(animated: true)
            }
        }
    }

    // MARK: - Message Row

    private func messageRow(
        message: Message,
        previousMessage: Message?,
        nextMessage: Message?
    ) -> some View {
        let showTail = shouldShowTail(message: message, next: nextMessage)
        let showSenderName = shouldShowSenderName(message: message, previous: previousMessage)

        return MessageBubble(
            message: message,
            isFromMe: message.isOutgoing,
            showTail: showTail,
            showSenderName: showSenderName && viewModel.isGroupChat,
            senderName: senderName(for: message)
        )
        .id(message.id)
        .padding(.vertical, messagePadding(message: message, previous: previousMessage))
        .background(
            viewModel.selectedMessages.contains(message.id)
            ? Color.accentColor.opacity(0.1)
            : Color.clear
        )
        .onTapGesture {
            if viewModel.isSelectionMode {
                viewModel.toggleSelection(for: message.id)
            }
        }
        .onLongPressGesture {
            if !viewModel.isSelectionMode {
                showMessageActions(for: message)
            }
        }
        .contextMenu {
            messageContextMenu(for: message)
        }
    }

    private func shouldShowTail(message: Message, next: Message?) -> Bool {
        guard let next else { return true }
        return message.isOutgoing != next.isOutgoing ||
               message.date.timeIntervalSince(next.date) > 60
    }

    private func shouldShowSenderName(message: Message, previous: Message?) -> Bool {
        guard !message.isOutgoing else { return false }
        guard let previous else { return true }
        return message.sender != previous.sender
    }

    private func messagePadding(message: Message, previous: Message?) -> CGFloat {
        guard let previous else { return Spacing.xxxs }

        if message.isOutgoing != previous.isOutgoing {
            return Spacing.sm
        } else if message.sender != previous.sender {
            return Spacing.xs
        } else {
            return Spacing.xxxs
        }
    }

    private func senderName(for message: Message) -> String? {
        // In real implementation, get user name from sender
        switch message.sender {
        case .user:
            return "User"
        case .chat:
            return "Channel"
        }
    }

    // MARK: - Date Separator

    private func dateSeparator(for date: Date, text: String) -> some View {
        HStack {
            Spacer()
            Text(text)
                .font(Typography.captionBold)
                .foregroundStyle(.secondary)
                .padding(.horizontal, Spacing.sm)
                .padding(.vertical, Spacing.xxs)
                .background(
                    Capsule()
                        .fill(.ultraThinMaterial)
                )
            Spacer()
        }
        .padding(.vertical, Spacing.sm)
    }

    // MARK: - Load More Indicator

    private var loadMoreIndicator: some View {
        HStack {
            Spacer()
            if viewModel.isLoadingMore {
                ProgressView()
                    .padding()
            }
            Spacer()
        }
    }

    // MARK: - Scroll To Bottom Button

    private var scrollToBottomButton: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                Button {
                    scrollToBottom(animated: true)
                } label: {
                    ZStack {
                        Circle()
                            .fill(.ultraThinMaterial)
                            .frame(width: 40, height: 40)
                            .shadow(color: .black.opacity(0.1), radius: 4, y: 2)

                        Image(systemName: "chevron.down")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(.primary)
                    }
                }
                .buttonStyle(.plain)
                .padding(.trailing, Spacing.md)
                .padding(.bottom, Spacing.md)
            }
        }
        .transition(.opacity)
    }

    // MARK: - Selection Toolbar

    private var selectionToolbar: some View {
        VStack {
            Spacer()

            HStack(spacing: Spacing.xl) {
                // Forward
                Button {
                    // TODO: Show chat picker for forwarding
                } label: {
                    VStack(spacing: Spacing.xxs) {
                        Image(systemName: "arrowshape.turn.up.right.fill")
                            .font(.system(size: 20))
                        Text("Forward")
                            .font(Typography.caption)
                    }
                }
                .disabled(viewModel.selectedMessages.isEmpty)

                // Copy
                Button {
                    copySelectedMessages()
                } label: {
                    VStack(spacing: Spacing.xxs) {
                        Image(systemName: "doc.on.doc.fill")
                            .font(.system(size: 20))
                        Text("Copy")
                            .font(Typography.caption)
                    }
                }
                .disabled(viewModel.selectedMessages.isEmpty)

                // Delete
                Button(role: .destructive) {
                    Task {
                        await viewModel.deleteMessages(Array(viewModel.selectedMessages), forAll: false)
                    }
                } label: {
                    VStack(spacing: Spacing.xxs) {
                        Image(systemName: "trash.fill")
                            .font(.system(size: 20))
                        Text("Delete")
                            .font(Typography.caption)
                    }
                }
                .disabled(viewModel.selectedMessages.isEmpty)
            }
            .foregroundStyle(.primary)
            .padding(.vertical, Spacing.md)
            .frame(maxWidth: .infinity)
            .background(.ultraThickMaterial)
        }
        .transition(.move(edge: .bottom))
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .principal) {
            headerView
        }

        ToolbarItem(placement: .topBarTrailing) {
            if viewModel.isSelectionMode {
                Button("Done") {
                    viewModel.exitSelectionMode()
                }
            } else {
                Menu {
                    Button {
                        // TODO: Search in chat
                    } label: {
                        Label("Search", systemImage: "magnifyingglass")
                    }

                    Button {
                        // TODO: Show chat info
                    } label: {
                        Label("Info", systemImage: "info.circle")
                    }

                    Divider()

                    Button {
                        // TODO: Mute chat
                    } label: {
                        Label(
                            viewModel.chat.isMuted ? "Unmute" : "Mute",
                            systemImage: viewModel.chat.isMuted ? "bell" : "bell.slash"
                        )
                    }

                    Button {
                        // TODO: Clear history
                    } label: {
                        Label("Clear History", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
    }

    // MARK: - Header View

    private var headerView: some View {
        Button {
            // TODO: Navigate to chat info
        } label: {
            HStack(spacing: Spacing.xs) {
                AvatarView(chat: viewModel.chat, size: AvatarSize.small)

                VStack(alignment: .leading, spacing: 0) {
                    Text(viewModel.title)
                        .font(Typography.headingSmall)
                        .foregroundStyle(.primary)

                    Text(viewModel.subtitle)
                        .font(Typography.caption)
                        .foregroundStyle(viewModel.typingUsers.isEmpty ? Color.secondary : Color.accentColor)
                }
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: - Message Context Menu

    @ViewBuilder
    private func messageContextMenu(for message: Message) -> some View {
        // Reply
        Button {
            viewModel.replyTo(message)
        } label: {
            Label("Reply", systemImage: "arrowshape.turn.up.left")
        }

        // Copy
        if case .text(let formattedText) = message.content {
            Button {
                UIPasteboard.general.string = formattedText.text
            } label: {
                Label("Copy", systemImage: "doc.on.doc")
            }
        }

        // Forward
        if message.canBeForwarded {
            Button {
                viewModel.startSelection(with: message.id)
                // TODO: Show chat picker
            } label: {
                Label("Forward", systemImage: "arrowshape.turn.up.right")
            }
        }

        // Edit
        if message.canBeEdited {
            Button {
                viewModel.edit(message)
            } label: {
                Label("Edit", systemImage: "pencil")
            }
        }

        // Select
        Button {
            viewModel.startSelection(with: message.id)
        } label: {
            Label("Select", systemImage: "checkmark.circle")
        }

        Divider()

        // Delete
        Button(role: .destructive) {
            Task {
                await viewModel.deleteMessages([message.id], forAll: message.canBeDeletedForAllUsers)
            }
        } label: {
            Label("Delete", systemImage: "trash")
        }
    }

    // MARK: - Actions

    private func scrollToBottom(animated: Bool) {
        if animated {
            withAnimation(.easeOut(duration: 0.3)) {
                scrollProxy?.scrollTo(bottomAnchor, anchor: .bottom)
            }
        } else {
            scrollProxy?.scrollTo(bottomAnchor, anchor: .bottom)
        }
    }

    private func showMessageActions(for message: Message) {
        // Haptic feedback
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
    }

    private func copySelectedMessages() {
        let selectedTexts = viewModel.messages
            .filter { viewModel.selectedMessages.contains($0.id) }
            .compactMap { message -> String? in
                if case .text(let formatted) = message.content {
                    return formatted.text
                }
                return nil
            }

        UIPasteboard.general.string = selectedTexts.joined(separator: "\n")
        viewModel.exitSelectionMode()
    }
}

// MARK: - Scroll Offset Preference Key

struct ScrollOffsetPreferenceKey: PreferenceKey {
    nonisolated(unsafe) static var defaultValue: CGFloat = 0

    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

// MARK: - Preview

#Preview("Conversation") {
    NavigationStack {
        ConversationView(chat: .mock(title: "John Doe"))
    }
}

#Preview("Conversation - Group") {
    NavigationStack {
        ConversationView(chat: .mock(
            title: "Family Group",
            type: .basicGroup(groupId: 1, memberCount: 5)
        ))
    }
}
