//
//  ContactsView.swift
//  Margiogram
//
//  Created by Andrea Margiovanni on 2024.
//

import SwiftUI

// MARK: - Contacts View

/// Main view displaying the user's contacts.
///
/// Features:
/// - Alphabetical grouping with section index
/// - Search functionality
/// - Add new contact
/// - Contact actions (message, call, share)
struct ContactsView: View {
    // MARK: - Properties

    @State private var viewModel = ContactsViewModel()

    /// Navigation to selected chat.
    @Binding var selectedChat: Chat?

    /// Whether to show add contact sheet.
    @State private var showAddContact = false

    // MARK: - Initialization

    init(selectedChat: Binding<Chat?>) {
        _selectedChat = selectedChat
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            contactsList

            // Loading overlay
            if viewModel.isLoading && viewModel.contacts.isEmpty {
                loadingView
            }

            // Empty state
            if viewModel.isEmpty {
                emptyStateView
            }
        }
        .navigationTitle(String(localized: "Contacts"))
        .searchable(
            text: $viewModel.searchQuery,
            placement: .navigationBarDrawer(displayMode: .always),
            prompt: Text("Search contacts...")
        )
        .toolbar {
            toolbarContent
        }
        .task {
            await viewModel.loadContacts()
        }
        .refreshable {
            await viewModel.refresh()
        }
        .sheet(isPresented: $showAddContact) {
            AddContactView { phoneNumber, firstName, lastName in
                Task {
                    if let _ = await viewModel.addContact(
                        phoneNumber: phoneNumber,
                        firstName: firstName,
                        lastName: lastName
                    ) {
                        showAddContact = false
                    }
                }
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

    // MARK: - Contacts List

    private var contactsList: some View {
        ScrollViewReader { proxy in
            List {
                // Online contacts section
                if !viewModel.onlineContacts.isEmpty && !viewModel.isSearching {
                    onlineSection
                }

                // Grouped contacts
                ForEach(viewModel.groupedContacts, id: \.letter) { group in
                    Section {
                        ForEach(group.contacts) { contact in
                            ContactRowView(user: contact) {
                                Task {
                                    if let chat = await viewModel.openChat(with: contact) {
                                        selectedChat = chat
                                    }
                                }
                            }
                            .swipeActions(edge: .trailing) {
                                Button(role: .destructive) {
                                    Task {
                                        await viewModel.deleteContact(contact)
                                    }
                                } label: {
                                    Label("Delete", systemImage: "trash.fill")
                                }

                                Button {
                                    viewModel.shareContact(contact)
                                } label: {
                                    Label("Share", systemImage: "square.and.arrow.up")
                                }
                                .tint(.blue)
                            }
                        }
                    } header: {
                        Text(group.letter)
                            .font(Typography.captionBold)
                            .id(group.letter)
                    }
                }
            }
            .listStyle(.plain)
            .overlay(alignment: .trailing) {
                // Section index
                if !viewModel.isSearching {
                    sectionIndexView(proxy: proxy)
                }
            }
        }
    }

    // MARK: - Online Section

    private var onlineSection: some View {
        Section {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Spacing.md) {
                    ForEach(viewModel.onlineContacts) { contact in
                        OnlineContactCell(user: contact) {
                            Task {
                                if let chat = await viewModel.openChat(with: contact) {
                                    selectedChat = chat
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, Spacing.md)
                .padding(.vertical, Spacing.xs)
            }
        } header: {
            Text("Online Now")
                .font(Typography.captionBold)
        }
    }

    // MARK: - Section Index

    private func sectionIndexView(proxy: ScrollViewProxy) -> some View {
        VStack(spacing: 2) {
            ForEach(viewModel.sectionIndexTitles, id: \.self) { letter in
                Button {
                    withAnimation {
                        proxy.scrollTo(letter, anchor: .top)
                    }
                } label: {
                    Text(letter)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(Color.accentColor)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, Spacing.xs)
        .padding(.horizontal, Spacing.xxs)
        .background(
            Capsule()
                .fill(.ultraThinMaterial)
        )
        .padding(.trailing, Spacing.xxs)
    }

    // MARK: - Loading View

    private var loadingView: some View {
        VStack(spacing: Spacing.md) {
            ProgressView()
                .scaleEffect(1.5)
            Text("Loading contacts...")
                .font(Typography.bodySmall)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.ultraThinMaterial)
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        VStack(spacing: Spacing.lg) {
            Image(systemName: viewModel.isSearching ? "magnifyingglass" : "person.crop.circle.badge.plus")
                .font(.system(size: 60))
                .foregroundStyle(.tertiary)

            Text(viewModel.isSearching ? "No results" : "No contacts yet")
                .font(Typography.headingMedium)
                .foregroundStyle(.primary)

            Text(viewModel.isSearching
                 ? "Try a different search term"
                 : "Add contacts to start messaging")
                .font(Typography.bodySmall)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, Spacing.xl)

            if !viewModel.isSearching {
                GlassButton("Add Contact", icon: "plus") {
                    showAddContact = true
                }
            }
        }
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Button {
                showAddContact = true
            } label: {
                Image(systemName: "plus")
            }
        }
    }
}

// MARK: - Contact Row View

/// A row displaying a single contact.
struct ContactRowView: View {
    let user: User
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: Spacing.sm) {
                AvatarView(
                    user: user,
                    size: AvatarSize.medium,
                    showOnlineIndicator: true
                )

                VStack(alignment: .leading, spacing: Spacing.xxxs) {
                    Text(user.fullName)
                        .font(Typography.bodyMedium)
                        .foregroundStyle(.primary)

                    if let status = user.statusText {
                        Text(status)
                            .font(Typography.caption)
                            .foregroundStyle(user.isOnline ? Color.accentColor : Color.secondary)
                    }
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Online Contact Cell

/// A circular cell for online contacts.
struct OnlineContactCell: View {
    let user: User
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: Spacing.xxs) {
                AvatarView(
                    user: user,
                    size: AvatarSize.large,
                    showOnlineIndicator: true
                )

                Text(user.firstName)
                    .font(Typography.caption)
                    .foregroundStyle(.primary)
                    .lineLimit(1)
            }
            .frame(width: 70)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Add Contact View

/// Sheet for adding a new contact.
struct AddContactView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var phoneNumber = ""
    @State private var firstName = ""
    @State private var lastName = ""

    let onAdd: (String, String, String) -> Void

    var isValid: Bool {
        !phoneNumber.isEmpty && !firstName.isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Phone Number", text: $phoneNumber)
                        .keyboardType(.phonePad)
                        .textContentType(.telephoneNumber)
                }

                Section {
                    TextField("First Name", text: $firstName)
                        .textContentType(.givenName)

                    TextField("Last Name (optional)", text: $lastName)
                        .textContentType(.familyName)
                }
            }
            .navigationTitle("New Contact")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        onAdd(phoneNumber, firstName, lastName)
                    }
                    .disabled(!isValid)
                }
            }
        }
    }
}

// MARK: - User Extensions

extension User {
    /// Status text for display.
    var statusText: String? {
        if isOnline {
            return String(localized: "online")
        } else if let lastSeen = lastSeenDate {
            return formatLastSeen(lastSeen)
        }
        return nil
    }

    private func formatLastSeen(_ date: Date) -> String {
        let calendar = Calendar.current
        let now = Date()

        if calendar.isDateInToday(date) {
            return String(localized: "last seen today at \(date.formatted(date: .omitted, time: .shortened))")
        } else if calendar.isDateInYesterday(date) {
            return String(localized: "last seen yesterday at \(date.formatted(date: .omitted, time: .shortened))")
        } else if calendar.isDate(date, equalTo: now, toGranularity: .weekOfYear) {
            return String(localized: "last seen \(date.formatted(.dateTime.weekday(.wide)))")
        } else {
            return String(localized: "last seen \(date.formatted(date: .abbreviated, time: .omitted))")
        }
    }
}

// MARK: - Preview

#Preview("Contacts") {
    NavigationStack {
        ContactsView(selectedChat: .constant(nil))
    }
}
