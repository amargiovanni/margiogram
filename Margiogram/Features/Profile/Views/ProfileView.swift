//
//  ProfileView.swift
//  Margiogram
//
//  Created by Andrea Margiovanni on 2024.
//

import SwiftUI
import PhotosUI

// MARK: - Profile View

/// User profile view.
///
/// Features:
/// - Profile header with avatar and info
/// - Action buttons (message, call, etc.)
/// - Info sections (phone, username, bio)
/// - Shared media gallery
struct ProfileView: View {
    // MARK: - Properties

    @State private var viewModel: ProfileViewModel

    // MARK: - State

    @State private var showPhotoOptions = false
    @State private var showPhotoPicker = false
    @State private var showBlockConfirmation = false
    @State private var selectedPhotoItem: PhotosPickerItem?

    // MARK: - Environment

    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    // MARK: - Initialization

    init(user: User? = nil, isCurrentUser: Bool = true) {
        let targetUser = user ?? User.mock(firstName: "Andrea", lastName: "Margiovanni")
        _viewModel = State(initialValue: ProfileViewModel(user: targetUser, isCurrentUser: isCurrentUser))
    }

    init(viewModel: ProfileViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    // MARK: - Body

    var body: some View {
        bodyWithModifiers
    }

    @ViewBuilder
    private var bodyWithModifiers: some View {
        let base = mainContent
            .background(Color(.systemGroupedBackground))
            .navigationTitle(viewModel.isEditing ? String(localized: "Edit Profile") : "")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                toolbarContent
            }
            .task {
                await viewModel.loadProfile()
            }

        let withDialogs = base
            .confirmationDialog("Profile Photo", isPresented: $showPhotoOptions) {
                photoOptionsButtons
            }
            .photosPicker(
                isPresented: $showPhotoPicker,
                selection: $selectedPhotoItem,
                matching: .images
            )

        let withBlockAlert = withDialogs
            .alert("Block User", isPresented: $showBlockConfirmation) {
                Button("Cancel", role: .cancel) {}
                Button("Block", role: .destructive) {
                    Task {
                        await viewModel.toggleBlock()
                    }
                }
            } message: {
                Text("Are you sure you want to block \(viewModel.user.fullName)?")
            }

        withBlockAlert
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

    private var mainContent: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Header
                profileHeader

                // Action buttons
                if !viewModel.isEditing {
                    actionButtons
                }

                // Info sections
                infoSections

                // Shared media (only for other users)
                if !viewModel.isCurrentUser {
                    sharedMediaSection
                }
            }
        }
    }

    // MARK: - Profile Header

    private var profileHeader: some View {
        VStack(spacing: Spacing.md) {
            // Avatar
            ZStack(alignment: .bottomTrailing) {
                AvatarView(
                    user: viewModel.user,
                    size: AvatarSize.header,
                    showOnlineIndicator: !viewModel.isCurrentUser
                )

                if viewModel.isCurrentUser && viewModel.isEditing {
                    Button {
                        showPhotoOptions = true
                    } label: {
                        Image(systemName: "camera.fill")
                            .font(.system(size: 14))
                            .foregroundStyle(.white)
                            .frame(width: 32, height: 32)
                            .background(Color.accentColor)
                            .clipShape(Circle())
                            .overlay(
                                Circle()
                                    .stroke(Color(.systemBackground), lineWidth: 2)
                            )
                    }
                }
            }
            .padding(.top, Spacing.lg)

            // Name
            if viewModel.isEditing {
                editableNameFields
            } else {
                VStack(spacing: Spacing.xxs) {
                    HStack(spacing: Spacing.xs) {
                        Text(viewModel.user.fullName)
                            .font(Typography.displaySmall)

                        if viewModel.user.isVerified {
                            Image(systemName: "checkmark.seal.fill")
                                .foregroundStyle(.blue)
                        }

                        if viewModel.user.isPremium {
                            Image(systemName: "star.fill")
                                .foregroundStyle(.purple)
                        }
                    }

                    Text(viewModel.user.statusText ?? "")
                        .font(Typography.bodySmall)
                        .foregroundStyle(viewModel.user.isOnline ? Color.accentColor : Color.secondary)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.bottom, Spacing.lg)
        .background(Color(.systemBackground))
    }

    // MARK: - Editable Name Fields

    private var editableNameFields: some View {
        VStack(spacing: Spacing.sm) {
            TextField("First Name", text: $viewModel.editedFirstName)
                .font(Typography.bodyLarge)
                .textFieldStyle(.roundedBorder)
                .frame(maxWidth: 250)

            TextField("Last Name", text: $viewModel.editedLastName)
                .font(Typography.bodyLarge)
                .textFieldStyle(.roundedBorder)
                .frame(maxWidth: 250)
        }
    }

    // MARK: - Action Buttons

    private var actionButtons: some View {
        HStack(spacing: Spacing.lg) {
            ForEach(viewModel.availableActions, id: \.self) { action in
                actionButton(action)
            }
        }
        .padding(.vertical, Spacing.md)
        .padding(.horizontal, Spacing.lg)
        .background(Color(.systemBackground))
    }

    private func actionButton(_ action: ProfileAction) -> some View {
        Button {
            handleAction(action)
        } label: {
            VStack(spacing: Spacing.xxs) {
                Image(systemName: action.icon)
                    .font(.system(size: 22))
                    .frame(width: 50, height: 50)
                    .background(
                        Circle()
                            .fill(action.isDestructive ? Color.red.opacity(0.1) : Color.accentColor.opacity(0.1))
                    )

                Text(action.title)
                    .font(Typography.caption)
            }
            .foregroundStyle(action.isDestructive ? Color.red : Color.accentColor)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Info Sections

    private var infoSections: some View {
        VStack(spacing: Spacing.sm) {
            ForEach(viewModel.sections) { section in
                infoSection(section)
            }

            // Bio editing
            if viewModel.isEditing {
                bioEditSection
            }
        }
        .padding(.top, Spacing.sm)
    }

    private func infoSection(_ section: ProfileSection) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            if let title = section.title {
                Text(title)
                    .font(Typography.caption)
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)
                    .padding(.horizontal, Spacing.md)
                    .padding(.bottom, Spacing.xs)
            }

            VStack(spacing: 0) {
                ForEach(section.items) { item in
                    infoRow(item)

                    if item.id != section.items.last?.id {
                        Divider()
                            .padding(.leading, Spacing.md + 30 + Spacing.sm)
                    }
                }
            }
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.medium))
            .padding(.horizontal, Spacing.md)
        }
    }

    private func infoRow(_ item: ProfileInfoItem) -> some View {
        Button {
            handleItemAction(item)
        } label: {
            HStack(spacing: Spacing.sm) {
                Image(systemName: item.icon)
                    .font(.system(size: 18))
                    .foregroundStyle(Color.accentColor)
                    .frame(width: 30)

                VStack(alignment: .leading, spacing: Spacing.xxxs) {
                    Text(item.title)
                        .font(Typography.caption)
                        .foregroundStyle(.secondary)

                    Text(item.value)
                        .font(Typography.bodyMedium)
                        .foregroundStyle(.primary)
                        .multilineTextAlignment(.leading)
                }

                Spacer()

                if item.action != nil {
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.sm)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(item.action == nil)
    }

    // MARK: - Bio Edit Section

    private var bioEditSection: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text("Bio")
                .font(Typography.caption)
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
                .padding(.horizontal, Spacing.md)

            TextEditor(text: $viewModel.editedBio)
                .font(Typography.bodyMedium)
                .frame(height: 100)
                .padding(Spacing.sm)
                .background(Color(.systemBackground))
                .clipShape(RoundedRectangle(cornerRadius: CornerRadius.medium))
                .padding(.horizontal, Spacing.md)

            Text("\(viewModel.editedBio.count)/70")
                .font(Typography.caption)
                .foregroundStyle(.secondary)
                .padding(.horizontal, Spacing.md)
        }
    }

    // MARK: - Shared Media Section

    private var sharedMediaSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            // Header
            HStack {
                Text("Shared Media")
                    .font(Typography.headingSmall)

                Spacer()

                NavigationLink {
                    SharedMediaView(viewModel: viewModel)
                } label: {
                    Text("See All")
                        .font(Typography.bodySmall)
                        .foregroundStyle(Color.accentColor)
                }
            }
            .padding(.horizontal, Spacing.md)
            .padding(.top, Spacing.lg)

            // Filter pills
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Spacing.xs) {
                    ForEach(SharedMediaFilter.allCases, id: \.self) { filter in
                        mediaFilterPill(filter)
                    }
                }
                .padding(.horizontal, Spacing.md)
            }

            // Media grid preview
            if viewModel.isLoadingMedia {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Spacing.xl)
            } else if viewModel.sharedMedia.isEmpty {
                Text("No shared media")
                    .font(Typography.bodySmall)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Spacing.xl)
            } else {
                mediaGridPreview
            }
        }
        .task {
            await viewModel.loadSharedMedia()
        }
        .onChange(of: viewModel.mediaFilter) { _, _ in
            Task {
                await viewModel.loadSharedMedia()
            }
        }
    }

    private func mediaFilterPill(_ filter: SharedMediaFilter) -> some View {
        Button {
            viewModel.mediaFilter = filter
        } label: {
            HStack(spacing: Spacing.xxs) {
                Image(systemName: filter.icon)
                    .font(.caption)
                Text(filter.title)
                    .font(Typography.captionBold)
            }
            .padding(.horizontal, Spacing.sm)
            .padding(.vertical, Spacing.xs)
            .background(
                Capsule()
                    .fill(viewModel.mediaFilter == filter ? Color.accentColor : Color.clear)
            )
            .background(
                Capsule()
                    .fill(.ultraThinMaterial)
            )
            .foregroundStyle(viewModel.mediaFilter == filter ? .white : .primary)
        }
        .buttonStyle(.plain)
    }

    private var mediaGridPreview: some View {
        LazyVGrid(
            columns: Array(repeating: GridItem(.flexible(), spacing: 2), count: 3),
            spacing: 2
        ) {
            ForEach(viewModel.sharedMedia.prefix(6)) { item in
                mediaCell(item)
            }
        }
        .padding(.horizontal, Spacing.md)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.medium))
    }

    private func mediaCell(_ item: SharedMediaItem) -> some View {
        Rectangle()
            .fill(Color.gray.opacity(0.2))
            .aspectRatio(1, contentMode: .fill)
            .overlay {
                if let thumbnail = item.thumbnail {
                    AsyncImage(url: thumbnail) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        ProgressView()
                    }
                } else {
                    Image(systemName: viewModel.mediaFilter.icon)
                        .font(.system(size: 24))
                        .foregroundStyle(.secondary)
                }
            }
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        if viewModel.isCurrentUser {
            if viewModel.isEditing {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        viewModel.cancelEditing()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        Task {
                            await viewModel.saveChanges()
                        }
                    }
                }
            } else {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Edit") {
                        viewModel.isEditing = true
                    }
                }
            }
        } else {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button {
                        // Share contact
                    } label: {
                        Label("Share Contact", systemImage: "square.and.arrow.up")
                    }

                    Button {
                        // Add to contacts
                    } label: {
                        Label("Add to Contacts", systemImage: "person.crop.circle.badge.plus")
                    }

                    Divider()

                    Button(role: .destructive) {
                        showBlockConfirmation = true
                    } label: {
                        Label("Block User", systemImage: "hand.raised.fill")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
    }

    // MARK: - Photo Options

    @ViewBuilder
    private var photoOptionsButtons: some View {
        Button("Take Photo") {
            // Camera
        }

        Button("Choose from Library") {
            showPhotoPicker = true
        }

        if viewModel.user.profilePhoto != nil {
            Button("Delete Photo", role: .destructive) {
                Task {
                    await viewModel.deletePhoto()
                }
            }
        }

        Button("Cancel", role: .cancel) {}
    }

    // MARK: - Actions

    private func handleAction(_ action: ProfileAction) {
        switch action {
        case .editProfile:
            viewModel.isEditing = true
        case .shareProfile:
            // Share profile
            break
        case .sendMessage:
            // Navigate to chat
            break
        case .call:
            // Start call
            break
        case .videoCall:
            // Start video call
            break
        case .shareContact:
            // Share contact
            break
        case .block:
            showBlockConfirmation = true
        }
    }

    private func handleItemAction(_ item: ProfileInfoItem) {
        guard let action = item.action else { return }

        switch action {
        case .call:
            if let phone = viewModel.user.phoneNumber,
               let url = URL(string: "tel://\(phone)") {
                UIApplication.shared.open(url)
            }
        case .copy:
            UIPasteboard.general.string = item.value
        case .toggleNotifications:
            Task {
                await viewModel.toggleNotifications()
            }
        }
    }
}

// MARK: - Shared Media View

/// Full shared media gallery view.
struct SharedMediaView: View {
    let viewModel: ProfileViewModel

    var body: some View {
        ScrollView {
            LazyVGrid(
                columns: Array(repeating: GridItem(.flexible(), spacing: 2), count: 3),
                spacing: 2
            ) {
                ForEach(viewModel.sharedMedia) { item in
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .aspectRatio(1, contentMode: .fill)
                        .overlay {
                            Image(systemName: viewModel.mediaFilter.icon)
                                .font(.system(size: 24))
                                .foregroundStyle(.secondary)
                        }
                }
            }
            .padding(2)
        }
        .navigationTitle(viewModel.mediaFilter.title)
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Preview

#Preview("Profile - Current User") {
    NavigationStack {
        ProfileView(isCurrentUser: true)
    }
}

#Preview("Profile - Other User") {
    NavigationStack {
        ProfileView(
            user: .mock(firstName: "John", lastName: "Doe"),
            isCurrentUser: false
        )
    }
}
