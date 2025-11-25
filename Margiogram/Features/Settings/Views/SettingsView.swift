//
//  SettingsView.swift
//  Margiogram
//
//  Created by Andrea Margiovanni on 2024.
//

import SwiftUI

// MARK: - Settings View

/// Main settings view with all app configuration options.
struct SettingsView: View {
    // MARK: - State

    @State private var showLogoutAlert = false

    // MARK: - Environment

    @Environment(\.colorScheme) private var colorScheme

    // MARK: - Body

    var body: some View {
        List {
            // Profile section
            profileSection

            // Account section
            accountSection

            // Appearance section
            appearanceSection

            // Notifications section
            notificationsSection

            // Privacy section
            privacySection

            // Data & Storage section
            dataSection

            // Help section
            helpSection

            // Logout
            logoutSection
        }
        .navigationTitle(String(localized: "Settings"))
        .alert("Log Out", isPresented: $showLogoutAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Log Out", role: .destructive) {
                // TODO: Perform logout
            }
        } message: {
            Text("Are you sure you want to log out?")
        }
    }

    // MARK: - Profile Section

    private var profileSection: some View {
        Section {
            NavigationLink {
                ProfileView()
            } label: {
                HStack(spacing: Spacing.md) {
                    AvatarView(
                        name: "Andrea Margiovanni",
                        size: AvatarSize.xlarge
                    )

                    VStack(alignment: .leading, spacing: Spacing.xxxs) {
                        Text("Andrea Margiovanni")
                            .font(Typography.headingMedium)

                        Text("+39 123 456 7890")
                            .font(Typography.bodySmall)
                            .foregroundStyle(.secondary)

                        Text("@andream")
                            .font(Typography.caption)
                            .foregroundStyle(.accentColor)
                    }
                }
                .padding(.vertical, Spacing.xs)
            }
        }
    }

    // MARK: - Account Section

    private var accountSection: some View {
        Section("Account") {
            NavigationLink {
                Text("My Account")
            } label: {
                SettingsRow(
                    icon: "person.circle.fill",
                    color: .blue,
                    title: "My Account"
                )
            }

            NavigationLink {
                Text("Telegram Premium")
            } label: {
                SettingsRow(
                    icon: "star.fill",
                    color: .purple,
                    title: "Telegram Premium",
                    badge: "NEW"
                )
            }

            NavigationLink {
                Text("Username")
            } label: {
                SettingsRow(
                    icon: "at",
                    color: .cyan,
                    title: "Username"
                )
            }

            NavigationLink {
                Text("Phone Number")
            } label: {
                SettingsRow(
                    icon: "phone.fill",
                    color: .green,
                    title: "Phone Number"
                )
            }
        }
    }

    // MARK: - Appearance Section

    private var appearanceSection: some View {
        Section("Appearance") {
            NavigationLink {
                AppearanceSettingsView()
            } label: {
                SettingsRow(
                    icon: "paintbrush.fill",
                    color: .orange,
                    title: "Appearance"
                )
            }

            NavigationLink {
                Text("Chat Wallpaper")
            } label: {
                SettingsRow(
                    icon: "photo.fill",
                    color: .pink,
                    title: "Chat Wallpaper"
                )
            }

            NavigationLink {
                Text("Stickers & Emoji")
            } label: {
                SettingsRow(
                    icon: "face.smiling.fill",
                    color: .yellow,
                    title: "Stickers & Emoji"
                )
            }
        }
    }

    // MARK: - Notifications Section

    private var notificationsSection: some View {
        Section("Notifications") {
            NavigationLink {
                NotificationSettingsView()
            } label: {
                SettingsRow(
                    icon: "bell.fill",
                    color: .red,
                    title: "Notifications and Sounds"
                )
            }
        }
    }

    // MARK: - Privacy Section

    private var privacySection: some View {
        Section("Privacy") {
            NavigationLink {
                PrivacySettingsView()
            } label: {
                SettingsRow(
                    icon: "lock.fill",
                    color: .gray,
                    title: "Privacy and Security"
                )
            }

            NavigationLink {
                Text("Active Sessions")
            } label: {
                SettingsRow(
                    icon: "desktopcomputer",
                    color: .indigo,
                    title: "Active Sessions"
                )
            }

            NavigationLink {
                Text("Passcode & Face ID")
            } label: {
                SettingsRow(
                    icon: "faceid",
                    color: .mint,
                    title: "Passcode & Face ID"
                )
            }
        }
    }

    // MARK: - Data Section

    private var dataSection: some View {
        Section("Data") {
            NavigationLink {
                DataSettingsView()
            } label: {
                SettingsRow(
                    icon: "chart.bar.fill",
                    color: .teal,
                    title: "Data and Storage"
                )
            }

            NavigationLink {
                Text("Language")
            } label: {
                SettingsRow(
                    icon: "globe",
                    color: .blue,
                    title: "Language",
                    value: "English"
                )
            }
        }
    }

    // MARK: - Help Section

    private var helpSection: some View {
        Section("Help") {
            NavigationLink {
                Text("FAQ")
            } label: {
                SettingsRow(
                    icon: "questionmark.circle.fill",
                    color: .blue,
                    title: "Telegram FAQ"
                )
            }

            NavigationLink {
                Text("Ask a Question")
            } label: {
                SettingsRow(
                    icon: "ellipsis.bubble.fill",
                    color: .orange,
                    title: "Ask a Question"
                )
            }

            NavigationLink {
                AboutView()
            } label: {
                SettingsRow(
                    icon: "info.circle.fill",
                    color: .gray,
                    title: "About"
                )
            }
        }
    }

    // MARK: - Logout Section

    private var logoutSection: some View {
        Section {
            Button(role: .destructive) {
                showLogoutAlert = true
            } label: {
                HStack {
                    Spacer()
                    Text("Log Out")
                        .font(Typography.bodyMedium)
                    Spacer()
                }
            }
        }
    }
}

// MARK: - Settings Row

/// A reusable settings row with icon.
struct SettingsRow: View {
    let icon: String
    let color: Color
    let title: String
    var value: String? = nil
    var badge: String? = nil

    var body: some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundStyle(.white)
                .frame(width: 30, height: 30)
                .background(color)
                .clipShape(RoundedRectangle(cornerRadius: 6))

            Text(title)
                .font(Typography.bodyMedium)

            Spacer()

            if let badge {
                Text(badge)
                    .font(Typography.captionBold)
                    .foregroundStyle(.white)
                    .padding(.horizontal, Spacing.xs)
                    .padding(.vertical, Spacing.xxxs)
                    .background(Color.accentColor)
                    .clipShape(Capsule())
            }

            if let value {
                Text(value)
                    .font(Typography.bodySmall)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

// MARK: - Appearance Settings

struct AppearanceSettingsView: View {
    @AppStorage("appearance") private var appearance = 0 // 0: system, 1: light, 2: dark
    @AppStorage("accentColor") private var accentColorIndex = 0
    @AppStorage("textSize") private var textSize = 1.0

    let accentColors: [Color] = [.blue, .purple, .pink, .orange, .green, .teal]
    let colorNames = ["Blue", "Purple", "Pink", "Orange", "Green", "Teal"]

    var body: some View {
        List {
            Section("Theme") {
                Picker("Appearance", selection: $appearance) {
                    Text("System").tag(0)
                    Text("Light").tag(1)
                    Text("Dark").tag(2)
                }
                .pickerStyle(.segmented)
            }

            Section("Accent Color") {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: Spacing.md) {
                    ForEach(0..<accentColors.count, id: \.self) { index in
                        Button {
                            accentColorIndex = index
                        } label: {
                            Circle()
                                .fill(accentColors[index])
                                .frame(width: 44, height: 44)
                                .overlay {
                                    if accentColorIndex == index {
                                        Image(systemName: "checkmark")
                                            .font(.system(size: 16, weight: .bold))
                                            .foregroundStyle(.white)
                                    }
                                }
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.vertical, Spacing.xs)
            }

            Section("Text Size") {
                VStack {
                    Slider(value: $textSize, in: 0.8...1.4, step: 0.1)

                    HStack {
                        Text("A")
                            .font(.system(size: 14))
                        Spacer()
                        Text("A")
                            .font(.system(size: 22))
                    }
                    .foregroundStyle(.secondary)
                }
            }
        }
        .navigationTitle("Appearance")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Notification Settings

struct NotificationSettingsView: View {
    @AppStorage("notifyPrivate") private var notifyPrivate = true
    @AppStorage("notifyGroups") private var notifyGroups = true
    @AppStorage("notifyChannels") private var notifyChannels = true
    @AppStorage("soundEnabled") private var soundEnabled = true
    @AppStorage("vibrationEnabled") private var vibrationEnabled = true
    @AppStorage("showPreviews") private var showPreviews = true

    var body: some View {
        List {
            Section("Message Notifications") {
                Toggle("Private Chats", isOn: $notifyPrivate)
                Toggle("Groups", isOn: $notifyGroups)
                Toggle("Channels", isOn: $notifyChannels)
            }

            Section("Alert Style") {
                Toggle("Sound", isOn: $soundEnabled)
                Toggle("Vibration", isOn: $vibrationEnabled)
                Toggle("Show Previews", isOn: $showPreviews)
            }

            Section {
                NavigationLink("Exceptions") {
                    Text("Notification Exceptions")
                }
            }
        }
        .navigationTitle("Notifications")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Privacy Settings

struct PrivacySettingsView: View {
    @AppStorage("lastSeenPrivacy") private var lastSeenPrivacy = 0
    @AppStorage("profilePhotoPrivacy") private var profilePhotoPrivacy = 0
    @AppStorage("callsPrivacy") private var callsPrivacy = 0

    var body: some View {
        List {
            Section("Privacy") {
                NavigationLink {
                    PrivacyOptionView(title: "Last Seen", selection: $lastSeenPrivacy)
                } label: {
                    HStack {
                        Text("Last Seen")
                        Spacer()
                        Text(privacyText(lastSeenPrivacy))
                            .foregroundStyle(.secondary)
                    }
                }

                NavigationLink {
                    PrivacyOptionView(title: "Profile Photo", selection: $profilePhotoPrivacy)
                } label: {
                    HStack {
                        Text("Profile Photo")
                        Spacer()
                        Text(privacyText(profilePhotoPrivacy))
                            .foregroundStyle(.secondary)
                    }
                }

                NavigationLink {
                    PrivacyOptionView(title: "Calls", selection: $callsPrivacy)
                } label: {
                    HStack {
                        Text("Calls")
                        Spacer()
                        Text(privacyText(callsPrivacy))
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Section("Security") {
                NavigationLink("Blocked Users") {
                    Text("Blocked Users")
                }

                NavigationLink("Two-Step Verification") {
                    Text("Two-Step Verification")
                }
            }

            Section {
                Button(role: .destructive) {
                    // Delete account
                } label: {
                    Text("Delete My Account")
                }
            }
        }
        .navigationTitle("Privacy and Security")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func privacyText(_ value: Int) -> String {
        switch value {
        case 0: return "Everyone"
        case 1: return "My Contacts"
        case 2: return "Nobody"
        default: return "Everyone"
        }
    }
}

struct PrivacyOptionView: View {
    let title: String
    @Binding var selection: Int

    var body: some View {
        List {
            Section {
                ForEach(0..<3) { index in
                    Button {
                        selection = index
                    } label: {
                        HStack {
                            Text(optionText(index))
                            Spacer()
                            if selection == index {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(.accentColor)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
    }

    private func optionText(_ value: Int) -> String {
        switch value {
        case 0: return "Everyone"
        case 1: return "My Contacts"
        case 2: return "Nobody"
        default: return "Everyone"
        }
    }
}

// MARK: - Data Settings

struct DataSettingsView: View {
    @AppStorage("autoDownloadPhotos") private var autoDownloadPhotos = true
    @AppStorage("autoDownloadVideos") private var autoDownloadVideos = false
    @AppStorage("autoDownloadDocuments") private var autoDownloadDocuments = false

    var body: some View {
        List {
            Section("Storage") {
                NavigationLink {
                    Text("Storage Usage")
                } label: {
                    HStack {
                        Text("Storage Usage")
                        Spacer()
                        Text("1.2 GB")
                            .foregroundStyle(.secondary)
                    }
                }

                NavigationLink {
                    Text("Network Usage")
                } label: {
                    HStack {
                        Text("Network Usage")
                        Spacer()
                        Text("2.5 GB")
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Section("Auto-Download Media") {
                Toggle("Photos", isOn: $autoDownloadPhotos)
                Toggle("Videos", isOn: $autoDownloadVideos)
                Toggle("Documents", isOn: $autoDownloadDocuments)
            }

            Section {
                Button(role: .destructive) {
                    // Clear cache
                } label: {
                    Text("Clear Cache")
                }
            }
        }
        .navigationTitle("Data and Storage")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - About View

struct AboutView: View {
    var body: some View {
        List {
            Section {
                VStack(spacing: Spacing.md) {
                    Image(systemName: "paperplane.fill")
                        .font(.system(size: 60))
                        .foregroundStyle(.accentColor)

                    Text("Margiogram")
                        .font(Typography.displaySmall)

                    Text("Version 1.0.0")
                        .font(Typography.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, Spacing.lg)
            }

            Section {
                Link(destination: URL(string: "https://telegram.org")!) {
                    HStack {
                        Text("Telegram Website")
                        Spacer()
                        Image(systemName: "arrow.up.right")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                }

                Link(destination: URL(string: "https://telegram.org/privacy")!) {
                    HStack {
                        Text("Privacy Policy")
                        Spacer()
                        Image(systemName: "arrow.up.right")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                }

                Link(destination: URL(string: "https://telegram.org/tos")!) {
                    HStack {
                        Text("Terms of Service")
                        Spacer()
                        Image(systemName: "arrow.up.right")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                }
            }

            Section {
                Text("Made with ❤️ by Andrea Margiovanni")
                    .font(Typography.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
            }
        }
        .navigationTitle("About")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Preview

#Preview("Settings") {
    NavigationStack {
        SettingsView()
    }
}
