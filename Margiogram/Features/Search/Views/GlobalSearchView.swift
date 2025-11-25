//
//  GlobalSearchView.swift
//  Margiogram
//
//  Created by Andrea Margiovanni on 2024.
//

import SwiftUI

// MARK: - Global Search View

struct GlobalSearchView: View {
    // MARK: - Properties

    @Environment(\.dismiss) private var dismiss
    @State private var viewModel = GlobalSearchViewModel()

    // MARK: - Body

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Scope Picker
                scopePicker

                // Content
                if viewModel.showRecentSearches {
                    recentSearchesView
                } else if viewModel.searchText.isEmpty {
                    emptySearchView
                } else if viewModel.isSearching {
                    loadingView
                } else if viewModel.hasResults {
                    searchResultsView
                } else {
                    noResultsView
                }
            }
            .navigationTitle("Search")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(
                text: $viewModel.searchText,
                placement: .navigationBarDrawer(displayMode: .always),
                prompt: "Search messages, chats, and more"
            )
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    filterButton
                }
            }
        }
        .onAppear {
            viewModel.loadRecentSearches()
        }
    }

    // MARK: - Scope Picker

    private var scopePicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(SearchScope.allCases, id: \.self) { scope in
                    ScopeChip(
                        title: scope.rawValue,
                        icon: scope.icon,
                        isSelected: viewModel.selectedScope == scope
                    ) {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            viewModel.selectedScope = scope
                        }
                        Task {
                            await viewModel.search()
                        }
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
        .background(Color(.systemGroupedBackground))
    }

    // MARK: - Recent Searches

    private var recentSearchesView: some View {
        List {
            Section {
                ForEach(viewModel.recentSearches, id: \.self) { search in
                    Button {
                        viewModel.selectRecentSearch(search)
                    } label: {
                        HStack {
                            Image(systemName: "clock.arrow.circlepath")
                                .foregroundColor(.secondary)

                            Text(search)
                                .foregroundColor(.primary)

                            Spacer()
                        }
                    }
                    .swipeActions(edge: .trailing) {
                        Button(role: .destructive) {
                            viewModel.removeRecentSearch(search)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }
            } header: {
                HStack {
                    Text("Recent Searches")
                    Spacer()
                    Button("Clear") {
                        viewModel.clearRecentSearches()
                    }
                    .font(.caption)
                }
            }
        }
        .listStyle(.insetGrouped)
    }

    // MARK: - Empty Search View

    private var emptySearchView: some View {
        ContentUnavailableView {
            Label("Search Margiogram", systemImage: "magnifyingglass")
        } description: {
            Text("Search for messages, chats, contacts, and more.")
        }
    }

    // MARK: - Loading View

    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
            Text("Searching...")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - No Results View

    private var noResultsView: some View {
        ContentUnavailableView.search(text: viewModel.searchText)
    }

    // MARK: - Search Results

    private var searchResultsView: some View {
        List {
            // Chats Section
            if !viewModel.chatResults.isEmpty {
                Section("Chats") {
                    ForEach(viewModel.chatResults) { chat in
                        ChatSearchResultRow(chat: chat)
                    }
                }
            }

            // Contacts Section
            if !viewModel.contactResults.isEmpty {
                Section("Contacts") {
                    ForEach(viewModel.contactResults) { user in
                        ContactSearchResultRow(user: user)
                    }
                }
            }

            // Messages Section
            if !viewModel.messageResults.isEmpty {
                Section("Messages") {
                    ForEach(viewModel.messageResults) { result in
                        MessageSearchResultRow(result: result, searchQuery: viewModel.searchText)
                    }
                }
            }

            // Global Results Section
            if !viewModel.globalResults.isEmpty {
                Section("Global Search") {
                    ForEach(viewModel.globalResults) { result in
                        GlobalSearchResultRow(result: result)
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
    }

    // MARK: - Filter Button

    private var filterButton: some View {
        Menu {
            Section("Date") {
                ForEach(DateFilter.allCases, id: \.self) { filter in
                    Button {
                        viewModel.applyDateFilter(filter)
                    } label: {
                        HStack {
                            Text(filter.rawValue)
                            if viewModel.dateFilter == filter {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            }

            if viewModel.chatFilter != nil {
                Button(role: .destructive) {
                    viewModel.applyChatFilter(nil)
                } label: {
                    Label("Clear Chat Filter", systemImage: "xmark.circle")
                }
            }
        } label: {
            Image(systemName: "line.3.horizontal.decrease.circle")
                .foregroundColor(viewModel.dateFilter != .anytime || viewModel.chatFilter != nil ? .accentColor : .primary)
        }
    }
}

// MARK: - Scope Chip

private struct ScopeChip: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.caption)
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(isSelected ? Color.accentColor : Color(.systemBackground))
            .foregroundColor(isSelected ? .white : .primary)
            .cornerRadius(20)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(isSelected ? Color.clear : Color.secondary.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Chat Search Result Row

private struct ChatSearchResultRow: View {
    let chat: Chat

    var body: some View {
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
                Text(chat.title)
                    .font(.body)
                    .fontWeight(.medium)
                    .lineLimit(1)

                if let lastMessage = chat.lastMessage {
                    Text(lastMessage.text ?? "Media")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }

            Spacer()

            // Type indicator
            Image(systemName: chat.type.icon)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .contentShape(Rectangle())
    }
}

// MARK: - Contact Search Result Row

private struct ContactSearchResultRow: View {
    let user: User

    var body: some View {
        HStack(spacing: 12) {
            // Avatar
            Circle()
                .fill(Color.green.opacity(0.2))
                .frame(width: 44, height: 44)
                .overlay {
                    Text(user.fullName.prefix(1).uppercased())
                        .font(.headline)
                        .foregroundColor(.green)
                }

            // Info
            VStack(alignment: .leading, spacing: 2) {
                Text(user.fullName)
                    .font(.body)
                    .fontWeight(.medium)
                    .lineLimit(1)

                if let username = user.username {
                    Text("@\(username)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            // Status
            if user.status == .online {
                Text("online")
                    .font(.caption)
                    .foregroundColor(.green)
            }
        }
        .contentShape(Rectangle())
    }
}

// MARK: - Message Search Result Row

private struct MessageSearchResultRow: View {
    let result: SearchMessageResult
    let searchQuery: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Chat info
            HStack {
                Text(result.chat.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.accentColor)

                Spacer()

                Text(result.message.date.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            // Message content with highlighted query
            if let text = result.message.text {
                highlightedText(text, query: searchQuery)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
    }

    private func highlightedText(_ text: String, query: String) -> Text {
        guard !query.isEmpty else {
            return Text(text)
        }

        let lowercasedText = text.lowercased()
        let lowercasedQuery = query.lowercased()

        guard let range = lowercasedText.range(of: lowercasedQuery) else {
            return Text(text)
        }

        let startIndex = text.index(text.startIndex, offsetBy: lowercasedText.distance(from: lowercasedText.startIndex, to: range.lowerBound))
        let endIndex = text.index(startIndex, offsetBy: query.count)

        let before = String(text[..<startIndex])
        let match = String(text[startIndex..<endIndex])
        let after = String(text[endIndex...])

        return Text(before) + Text(match).bold().foregroundColor(.accentColor) + Text(after)
    }
}

// MARK: - Global Search Result Row

private struct GlobalSearchResultRow: View {
    let result: SearchGlobalResult

    var body: some View {
        HStack(spacing: 12) {
            // Avatar
            Circle()
                .fill(Color.purple.opacity(0.2))
                .frame(width: 44, height: 44)
                .overlay {
                    Image(systemName: result.type.icon)
                        .font(.title3)
                        .foregroundColor(.purple)
                }

            // Info
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 4) {
                    Text(result.title)
                        .font(.body)
                        .fontWeight(.medium)
                        .lineLimit(1)

                    if result.isVerified {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                }

                HStack {
                    if let username = result.username {
                        Text("@\(username)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }

                    if let count = result.memberCount {
                        Text("•")
                            .foregroundColor(.secondary)
                        Text("\(count.formatted()) members")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }

            Spacer()
        }
        .contentShape(Rectangle())
    }
}

// MARK: - Preview

#Preview {
    GlobalSearchView()
}
