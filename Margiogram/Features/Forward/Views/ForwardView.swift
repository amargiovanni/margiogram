//
//  ForwardView.swift
//  Margiogram
//
//  Created by Andrea Margiovanni on 2024.
//

import SwiftUI

// MARK: - Forward View

struct ForwardView: View {
    // MARK: - Properties

    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: ForwardViewModel

    var onForwardComplete: (() -> Void)?

    // MARK: - Initialization

    init(messages: [Message], from chat: Chat, onComplete: (() -> Void)? = nil) {
        let vm = ForwardViewModel()
        vm.configure(messages: messages, from: chat)
        self._viewModel = State(initialValue: vm)
        self.onForwardComplete = onComplete
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Selection Info Bar
                if viewModel.hasSelection {
                    selectionBar
                }

                // Content
                List {
                    // Recent Section
                    if !viewModel.recentChats.isEmpty && viewModel.searchText.isEmpty {
                        Section("Recent") {
                            ForEach(viewModel.recentChats) { chat in
                                ForwardChatRow(
                                    chat: chat,
                                    isSelected: viewModel.isSelected(chat.id)
                                ) {
                                    viewModel.toggleSelection(for: chat.id)
                                }
                            }
                        }
                    }

                    // Contacts Section
                    if !viewModel.filteredContacts.isEmpty {
                        Section("Contacts") {
                            ForEach(viewModel.filteredContacts) { contact in
                                ForwardContactRow(
                                    contact: contact,
                                    isSelected: viewModel.isSelected(contact.id)
                                ) {
                                    viewModel.toggleSelection(for: contact.id)
                                }
                            }
                        }
                    }

                    // Chats Section
                    if !viewModel.filteredChats.isEmpty {
                        Section("Chats") {
                            ForEach(viewModel.filteredChats) { chat in
                                ForwardChatRow(
                                    chat: chat,
                                    isSelected: viewModel.isSelected(chat.id)
                                ) {
                                    viewModel.toggleSelection(for: chat.id)
                                }
                            }
                        }
                    }
                }
                .listStyle(.insetGrouped)

                // Forward Options & Button
                if viewModel.hasSelection {
                    forwardSection
                }
            }
            .navigationTitle(viewModel.forwardTitle)
            .navigationBarTitleDisplayMode(.inline)
            .searchable(
                text: $viewModel.searchText,
                placement: .navigationBarDrawer(displayMode: .always),
                prompt: "Search chats..."
            )
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    if viewModel.hasSelection {
                        Button("Clear") {
                            viewModel.clearSelection()
                        }
                    }
                }
            }
            .overlay {
                if viewModel.isLoading && viewModel.allChats.isEmpty {
                    ProgressView()
                }
            }
        }
        .task {
            await viewModel.loadChats()
        }
        .alert("Forward Failed", isPresented: .init(
            get: { viewModel.error != nil },
            set: { if !$0 { viewModel.error = nil } }
        )) {
            Button("OK") { viewModel.error = nil }
        } message: {
            if let error = viewModel.error {
                Text(error.localizedDescription)
            }
        }
    }

    // MARK: - Selection Bar

    private var selectionBar: some View {
        HStack {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(Array(viewModel.selectedChats), id: \.self) { chatId in
                        if let chat = viewModel.allChats.first(where: { $0.id == chatId }) {
                            SelectedChatChip(chat: chat) {
                                viewModel.toggleSelection(for: chatId)
                            }
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
        .frame(height: 60)
        .background(Color(.secondarySystemGroupedBackground))
    }

    // MARK: - Forward Section

    private var forwardSection: some View {
        VStack(spacing: 12) {
            // Comment Field
            HStack {
                TextField("Add a comment...", text: $viewModel.comment)
                    .textFieldStyle(.plain)

                if !viewModel.comment.isEmpty {
                    Button {
                        viewModel.comment = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(12)
            .background(Color(.tertiarySystemGroupedBackground))
            .cornerRadius(10)

            // Options
            HStack(spacing: 16) {
                ForwardOptionToggle(
                    title: "Hide Caption",
                    isOn: $viewModel.hideCaption
                )

                ForwardOptionToggle(
                    title: "Hide Sender",
                    isOn: $viewModel.hideSender
                )
            }

            // Forward Button
            Button {
                Task {
                    if await viewModel.forward() {
                        onForwardComplete?()
                        dismiss()
                    }
                }
            } label: {
                HStack {
                    if viewModel.isForwarding {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Image(systemName: "arrowshape.turn.up.right.fill")
                    }

                    Text("Forward to \(viewModel.selectionCount) Chat\(viewModel.selectionCount == 1 ? "" : "s")")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Color.accentColor)
                .foregroundColor(.white)
                .cornerRadius(12)
            }
            .disabled(!viewModel.canForward || viewModel.isForwarding)
        }
        .padding()
        .background(Color(.systemGroupedBackground))
    }
}

// MARK: - Forward Chat Row

private struct ForwardChatRow: View {
    let chat: Chat
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Avatar
                Circle()
                    .fill(Color.accentColor.opacity(0.2))
                    .frame(width: 44, height: 44)
                    .overlay {
                        Text(chat.title.prefix(1).uppercased())
                            .font(.headline)
                            .foregroundColor(.accentColor)
                    }

                // Info
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 4) {
                        Text(chat.title)
                            .font(.body)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)

                    }

                    if let lastMessage = chat.lastMessage {
                        Text(lastMessage.content.previewText)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                }

                Spacer()

                // Selection Indicator
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundColor(isSelected ? .accentColor : .secondary)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Forward Contact Row

private struct ForwardContactRow: View {
    let contact: User
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Avatar
                Circle()
                    .fill(Color.green.opacity(0.2))
                    .frame(width: 44, height: 44)
                    .overlay {
                        Text(contact.fullName.prefix(1).uppercased())
                            .font(.headline)
                            .foregroundColor(.green)
                    }

                // Info
                VStack(alignment: .leading, spacing: 2) {
                    Text(contact.fullName)
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)

                    if let username = contact.username {
                        Text("@\(username)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()

                // Online status
                if contact.isOnline {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 8, height: 8)
                }

                // Selection Indicator
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundColor(isSelected ? .accentColor : .secondary)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Selected Chat Chip

private struct SelectedChatChip: View {
    let chat: Chat
    let onRemove: () -> Void

    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(Color.accentColor.opacity(0.2))
                .frame(width: 28, height: 28)
                .overlay {
                    Text(chat.title.prefix(1).uppercased())
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.accentColor)
                }

            Text(chat.title)
                .font(.subheadline)
                .fontWeight(.medium)
                .lineLimit(1)

            Button(action: onRemove) {
                Image(systemName: "xmark.circle.fill")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.leading, 4)
        .padding(.trailing, 8)
        .padding(.vertical, 6)
        .background(Color(.tertiarySystemGroupedBackground))
        .cornerRadius(20)
    }
}

// MARK: - Forward Option Toggle

private struct ForwardOptionToggle: View {
    let title: String
    @Binding var isOn: Bool

    var body: some View {
        Button {
            isOn.toggle()
        } label: {
            HStack(spacing: 6) {
                Image(systemName: isOn ? "checkmark.square.fill" : "square")
                    .foregroundColor(isOn ? .accentColor : .secondary)
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.primary)
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Share Sheet View

struct ShareSheetView: View {
    @Environment(\.dismiss) private var dismiss

    let content: ShareContent
    var onShare: ((ShareDestination) -> Void)?

    var body: some View {
        NavigationStack {
            List {
                Section {
                    // Preview
                    sharePreview
                }

                Section("Share to") {
                    ShareDestinationRow(icon: "square.and.arrow.up", title: "System Share") {
                        onShare?(.system)
                        dismiss()
                    }

                    ShareDestinationRow(icon: "doc.on.doc", title: "Copy Link") {
                        onShare?(.copyLink)
                        dismiss()
                    }

                    ShareDestinationRow(icon: "bookmark", title: "Saved Messages") {
                        onShare?(.savedMessages)
                        dismiss()
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Share")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var sharePreview: some View {
        VStack(alignment: .leading, spacing: 8) {
            switch content {
            case .text(let text):
                Text(text)
                    .font(.body)
                    .lineLimit(3)

            case .url(let url):
                HStack {
                    Image(systemName: "link")
                        .foregroundColor(.accentColor)
                    Text(url.absoluteString)
                        .font(.subheadline)
                        .lineLimit(1)
                }

            case .media(let description):
                HStack {
                    Image(systemName: "photo")
                        .foregroundColor(.accentColor)
                    Text(description)
                        .font(.subheadline)
                }
            }
        }
    }
}

// MARK: - Share Destination Row

private struct ShareDestinationRow: View {
    let icon: String
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(.accentColor)
                    .frame(width: 30)

                Text(title)
                    .font(.body)
                    .foregroundColor(.primary)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}

// MARK: - Share Content

enum ShareContent {
    case text(String)
    case url(URL)
    case media(String)
}

// MARK: - Share Destination

enum ShareDestination {
    case system
    case copyLink
    case savedMessages
    case chat(Int64)
}

// MARK: - Preview

#Preview {
    ForwardView(
        messages: [Message.mock()],
        from: Chat.mock()
    )
}

#Preview("Share Sheet") {
    ShareSheetView(content: .text("Check out this awesome content!"))
}
