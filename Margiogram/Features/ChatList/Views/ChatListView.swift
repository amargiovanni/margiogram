//
//  ChatListView.swift
//  Margiogram
//
//  Created by Andrea Margiovanni on 2024.
//

import SwiftUI

// MARK: - Chat List View

/// Main view displaying the list of chats.
///
/// Features:
/// - Search bar with folder filters
/// - Pinned chats section
/// - Regular chats with lazy loading
/// - Pull to refresh
/// - Swipe actions for quick operations
struct ChatListView: View {
    // MARK: - Properties

    @State private var viewModel: ChatListViewModel

    /// Binding for navigation selection.
    @Binding var selectedChat: Chat?

    // MARK: - Environment

    @Environment(\.colorScheme) private var colorScheme

    // MARK: - Initialization

    init(
        viewModel: ChatListViewModel = ChatListViewModel(),
        selectedChat: Binding<Chat?>
    ) {
        _viewModel = State(initialValue: viewModel)
        _selectedChat = selectedChat
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            chatListContent
                .refreshable {
                    await viewModel.refresh()
                }

            // Loading overlay
            if viewModel.isLoading && viewModel.chats.isEmpty {
                loadingView
            }

            // Empty state
            if viewModel.isEmpty {
                emptyStateView
            }

            // Floating action button
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    GlassFAB(icon: "square.and.pencil") {
                        // TODO: Navigate to new message
                    }
                    .padding(Spacing.lg)
                }
            }
        }
        .navigationTitle(navigationTitle)
        .searchable(
            text: $viewModel.searchQuery,
            placement: .navigationBarDrawer(displayMode: .always),
            prompt: Text("Search chats...")
        )
        .toolbar {
            toolbarContent
        }
        .task {
            await viewModel.loadChats()
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

    // MARK: - Navigation Title

    private var navigationTitle: String {
        if let folder = viewModel.selectedFolder {
            return folder.title
        }
        return String(localized: "Chats")
    }

    // MARK: - Chat List Content

    private var chatListContent: some View {
        ScrollView {
            LazyVStack(spacing: 0, pinnedViews: [.sectionHeaders]) {
                // Folder pills
                if !viewModel.folders.isEmpty {
                    folderPillsSection
                }

                // Pinned chats
                if !viewModel.pinnedChats.isEmpty {
                    pinnedChatsSection
                }

                // Regular chats
                regularChatsSection

                // Load more indicator
                if viewModel.hasMoreChats && !viewModel.isSearching {
                    loadMoreIndicator
                }
            }
        }
        .scrollDismissesKeyboard(.interactively)
    }

    // MARK: - Folder Pills

    private var folderPillsSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Spacing.xs) {
                // All chats pill
                FolderPill(
                    title: String(localized: "All"),
                    icon: "tray.fill",
                    isSelected: viewModel.selectedFolder == nil
                ) {
                    viewModel.selectFolder(nil)
                }

                // Folder pills
                ForEach(viewModel.folders) { folder in
                    FolderPill(
                        title: folder.title,
                        icon: folder.icon.systemImage,
                        isSelected: viewModel.selectedFolder?.id == folder.id
                    ) {
                        viewModel.selectFolder(folder)
                    }
                }
            }
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.sm)
        }
    }

    // MARK: - Pinned Chats Section

    private var pinnedChatsSection: some View {
        Section {
            ForEach(viewModel.pinnedChats) { chat in
                chatRow(for: chat)
            }
        } header: {
            sectionHeader(title: String(localized: "Pinned"))
        }
    }

    // MARK: - Regular Chats Section

    private var regularChatsSection: some View {
        Section {
            ForEach(viewModel.regularChats) { chat in
                chatRow(for: chat)
                    .onAppear {
                        // Load more when reaching end
                        if chat.id == viewModel.regularChats.last?.id {
                            Task {
                                await viewModel.loadMoreChats()
                            }
                        }
                    }
            }
        } header: {
            if !viewModel.pinnedChats.isEmpty {
                sectionHeader(title: String(localized: "All Chats"))
            }
        }
    }

    // MARK: - Chat Row

    private func chatRow(for chat: Chat) -> some View {
        ChatRowView(
            chat: chat,
            action: viewModel.chatActions[chat.id]
        ) {
            selectedChat = chat
        }
        .background(selectedChat?.id == chat.id ? Color.accentColor.opacity(0.1) : Color.clear)
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            trailingSwipeActions(for: chat)
        }
        .swipeActions(edge: .leading, allowsFullSwipe: true) {
            leadingSwipeActions(for: chat)
        }
        .contextMenu {
            contextMenuContent(for: chat)
        }
    }

    // MARK: - Swipe Actions

    @ViewBuilder
    private func trailingSwipeActions(for chat: Chat) -> some View {
        // Delete/Leave
        Button(role: .destructive) {
            Task {
                await viewModel.delete(chat: chat)
            }
        } label: {
            Label(chat.isGroup ? "Leave" : "Delete", systemImage: "trash.fill")
        }

        // Archive
        Button {
            Task {
                await viewModel.archive(chat: chat)
            }
        } label: {
            Label("Archive", systemImage: "archivebox.fill")
        }
        .tint(.orange)

        // Mute/Unmute
        Button {
            Task {
                await viewModel.toggleMute(for: chat)
            }
        } label: {
            Label(
                chat.isMuted ? "Unmute" : "Mute",
                systemImage: chat.isMuted ? "bell.fill" : "bell.slash.fill"
            )
        }
        .tint(.gray)
    }

    @ViewBuilder
    private func leadingSwipeActions(for chat: Chat) -> some View {
        // Pin/Unpin
        Button {
            Task {
                await viewModel.togglePin(for: chat)
            }
        } label: {
            Label(
                chat.isPinned ? "Unpin" : "Pin",
                systemImage: chat.isPinned ? "pin.slash.fill" : "pin.fill"
            )
        }
        .tint(.accentColor)

        // Mark as read/unread
        Button {
            Task {
                await viewModel.toggleRead(for: chat)
            }
        } label: {
            Label(
                chat.hasUnread ? "Read" : "Unread",
                systemImage: chat.hasUnread ? "envelope.open.fill" : "envelope.badge.fill"
            )
        }
        .tint(.blue)
    }

    // MARK: - Context Menu

    @ViewBuilder
    private func contextMenuContent(for chat: Chat) -> some View {
        // Pin/Unpin
        Button {
            Task {
                await viewModel.togglePin(for: chat)
            }
        } label: {
            Label(
                chat.isPinned ? "Unpin" : "Pin",
                systemImage: chat.isPinned ? "pin.slash" : "pin"
            )
        }

        // Mark read/unread
        Button {
            Task {
                await viewModel.toggleRead(for: chat)
            }
        } label: {
            Label(
                chat.hasUnread ? "Mark as Read" : "Mark as Unread",
                systemImage: chat.hasUnread ? "envelope.open" : "envelope.badge"
            )
        }

        // Mute/Unmute
        Button {
            Task {
                await viewModel.toggleMute(for: chat)
            }
        } label: {
            Label(
                chat.isMuted ? "Unmute" : "Mute",
                systemImage: chat.isMuted ? "bell" : "bell.slash"
            )
        }

        Divider()

        // Archive
        Button {
            Task {
                await viewModel.archive(chat: chat)
            }
        } label: {
            Label("Archive", systemImage: "archivebox")
        }

        Divider()

        // Delete
        Button(role: .destructive) {
            Task {
                await viewModel.delete(chat: chat)
            }
        } label: {
            Label(chat.isGroup ? "Leave Chat" : "Delete Chat", systemImage: "trash")
        }
    }

    // MARK: - Section Header

    private func sectionHeader(title: String) -> some View {
        HStack {
            Text(title)
                .font(Typography.caption)
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
            Spacer()
        }
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.xs)
        .background(.ultraThinMaterial)
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

    // MARK: - Loading View

    private var loadingView: some View {
        VStack(spacing: Spacing.md) {
            ProgressView()
                .scaleEffect(1.5)
            Text("Loading chats...")
                .font(Typography.bodySmall)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.ultraThinMaterial)
    }

    // MARK: - Empty State View

    private var emptyStateView: some View {
        VStack(spacing: Spacing.lg) {
            Image(systemName: viewModel.isSearching ? "magnifyingglass" : "bubble.left.and.bubble.right")
                .font(.system(size: 60))
                .foregroundStyle(.tertiary)

            Text(viewModel.isSearching ? "No results" : "No chats yet")
                .font(Typography.headingMedium)
                .foregroundStyle(.primary)

            Text(viewModel.isSearching
                 ? "Try a different search term"
                 : "Start a new conversation by tapping the button below")
                .font(Typography.bodySmall)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, Spacing.xl)
        }
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            Button {
                // TODO: Navigate to settings
            } label: {
                Image(systemName: "line.3.horizontal")
            }
        }

        ToolbarItem(placement: .topBarTrailing) {
            Menu {
                Button {
                    // TODO: Show archived chats
                } label: {
                    Label("Archived", systemImage: "archivebox")
                }

                Button {
                    // TODO: Edit folders
                } label: {
                    Label("Edit Folders", systemImage: "folder.badge.gearshape")
                }
            } label: {
                Image(systemName: "ellipsis.circle")
            }
        }
    }
}

// MARK: - Folder Pill

/// A pill-shaped button for folder selection.
struct FolderPill: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: Spacing.xxs) {
                Image(systemName: icon)
                    .font(.caption)
                Text(title)
                    .font(Typography.captionBold)
            }
            .padding(.horizontal, Spacing.sm)
            .padding(.vertical, Spacing.xs)
            .background(
                Capsule()
                    .fill(isSelected ? Color.accentColor : Color.clear)
            )
            .background(
                Capsule()
                    .fill(.ultraThinMaterial)
            )
            .foregroundStyle(isSelected ? .white : .primary)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#Preview("Chat List") {
    NavigationStack {
        ChatListView(selectedChat: .constant(nil))
    }
}

#Preview("Chat List - Dark") {
    NavigationStack {
        ChatListView(selectedChat: .constant(nil))
    }
    .preferredColorScheme(.dark)
}
