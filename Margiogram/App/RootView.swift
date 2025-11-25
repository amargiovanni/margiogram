//
//  RootView.swift
//  Margiogram
//
//  Created by Andrea Margiovanni on 2024.
//

import SwiftUI

/// Root view that handles navigation between authentication and main content.
struct RootView: View {
    // MARK: - Environment

    @EnvironmentObject private var authManager: AuthenticationManager

    // MARK: - State

    @State private var showSplash = true

    // MARK: - Body

    var body: some View {
        ZStack {
            // Background
            backgroundView

            // Content
            Group {
                if showSplash {
                    SplashView()
                        .transition(.opacity)
                } else {
                    switch authManager.state {
                    case .unauthorized, .waitingForPhoneNumber, .waitingForCode, .waitingForPassword, .waitingForRegistration:
                        AuthenticationView()
                            .transition(.asymmetric(
                                insertion: .move(edge: .trailing).combined(with: .opacity),
                                removal: .move(edge: .leading).combined(with: .opacity)
                            ))

                    case .authorized:
                        MainView()
                            .transition(.asymmetric(
                                insertion: .move(edge: .trailing).combined(with: .opacity),
                                removal: .move(edge: .leading).combined(with: .opacity)
                            ))

                    case .loading:
                        LoadingView(message: "Connecting...")
                    }
                }
            }
            .animation(.spring(response: 0.5, dampingFraction: 0.8), value: authManager.state)
        }
        .task {
            // Hide splash after brief delay
            try? await Task.sleep(for: .seconds(1.5))
            withAnimation(.easeOut(duration: 0.5)) {
                showSplash = false
            }
        }
    }

    // MARK: - Background

    private var backgroundView: some View {
        ZStack {
            // Gradient background
            LinearGradient(
                colors: [
                    Color(.systemBackground),
                    Color(.systemBackground).opacity(0.95)
                ],
                startPoint: .top,
                endPoint: .bottom
            )

            // Subtle pattern overlay
            GeometryReader { geometry in
                Canvas { context, size in
                    // Draw subtle circles for depth
                    let circleCount = 5
                    for i in 0..<circleCount {
                        let radius = CGFloat(100 + i * 50)
                        let x = CGFloat.random(in: 0...size.width)
                        let y = CGFloat.random(in: 0...size.height)

                        let circle = Path(ellipseIn: CGRect(
                            x: x - radius,
                            y: y - radius,
                            width: radius * 2,
                            height: radius * 2
                        ))

                        context.fill(
                            circle,
                            with: .color(.accentColor.opacity(0.03))
                        )
                    }
                }
            }
        }
        .ignoresSafeArea()
    }
}

// MARK: - Splash View

struct SplashView: View {
    @State private var logoScale: CGFloat = 0.5
    @State private var logoOpacity: Double = 0

    var body: some View {
        VStack(spacing: 24) {
            // Logo
            Image(systemName: "paperplane.fill")
                .font(.system(size: 80))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.accentColor, .accentColor.opacity(0.7)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .scaleEffect(logoScale)
                .opacity(logoOpacity)

            // App name
            Text("Margiogram")
                .font(.system(size: 36, weight: .bold, design: .rounded))
                .foregroundStyle(.primary)
                .opacity(logoOpacity)
        }
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.6)) {
                logoScale = 1.0
                logoOpacity = 1.0
            }
        }
    }
}

// MARK: - Loading View

struct LoadingView: View {
    let message: String

    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)

            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - Main View

/// Main content view after authentication.
struct MainView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.horizontalSizeClass) private var sizeClass

    // MARK: - State

    @State private var selectedTab: Tab = .chats
    @State private var selectedChat: Chat?
    @State private var navigationPath = NavigationPath()

    // MARK: - Tab Enum

    enum Tab: String, CaseIterable {
        case contacts = "Contacts"
        case chats = "Chats"
        case settings = "Settings"

        var icon: String {
            switch self {
            case .contacts: return "person.crop.circle"
            case .chats: return "bubble.left.and.bubble.right"
            case .settings: return "gearshape"
            }
        }

        var selectedIcon: String {
            switch self {
            case .contacts: return "person.crop.circle.fill"
            case .chats: return "bubble.left.and.bubble.right.fill"
            case .settings: return "gearshape.fill"
            }
        }
    }

    var body: some View {
        Group {
            #if os(iOS)
            if sizeClass == .compact {
                iPhoneLayout
            } else {
                iPadLayout
            }
            #elseif os(macOS)
            macOSLayout
            #endif
        }
    }

    // MARK: - iPhone Layout

    private var iPhoneLayout: some View {
        TabView(selection: $selectedTab) {
            // Contacts Tab
            NavigationStack(path: $navigationPath) {
                ContactsView(selectedChat: $selectedChat)
                    .navigationDestination(for: Chat.self) { chat in
                        ConversationView(chat: chat)
                    }
            }
            .tabItem {
                Label(Tab.contacts.rawValue, systemImage: selectedTab == .contacts ? Tab.contacts.selectedIcon : Tab.contacts.icon)
            }
            .tag(Tab.contacts)

            // Chats Tab
            NavigationStack(path: $navigationPath) {
                ChatListView(selectedChat: $selectedChat)
                    .navigationDestination(for: Chat.self) { chat in
                        ConversationView(chat: chat)
                    }
            }
            .tabItem {
                Label(Tab.chats.rawValue, systemImage: selectedTab == .chats ? Tab.chats.selectedIcon : Tab.chats.icon)
            }
            .tag(Tab.chats)

            // Settings Tab
            NavigationStack {
                SettingsView()
            }
            .tabItem {
                Label(Tab.settings.rawValue, systemImage: selectedTab == .settings ? Tab.settings.selectedIcon : Tab.settings.icon)
            }
            .tag(Tab.settings)
        }
        .onChange(of: selectedChat) { _, newChat in
            if let chat = newChat {
                navigationPath.append(chat)
                selectedChat = nil
            }
        }
    }

    // MARK: - iPad Layout

    private var iPadLayout: some View {
        NavigationSplitView {
            // Sidebar
            List(selection: $selectedTab) {
                ForEach(Tab.allCases, id: \.self) { tab in
                    Label(tab.rawValue, systemImage: tab.icon)
                        .tag(tab)
                }
            }
            .listStyle(.sidebar)
            .navigationTitle("Margiogram")
        } content: {
            // Content based on selected tab
            switch selectedTab {
            case .contacts:
                ContactsView(selectedChat: $selectedChat)
            case .chats:
                ChatListView(selectedChat: $selectedChat)
            case .settings:
                SettingsView()
            }
        } detail: {
            // Detail view
            if let chat = selectedChat {
                ConversationView(chat: chat)
            } else if selectedTab == .settings {
                Text("Select a setting")
                    .foregroundStyle(.secondary)
            } else {
                ContentUnavailableView(
                    "Select a Chat",
                    systemImage: "bubble.left.and.bubble.right",
                    description: Text("Choose a conversation from the list")
                )
            }
        }
    }

    // MARK: - macOS Layout

    #if os(macOS)
    private var macOSLayout: some View {
        NavigationSplitView(columnVisibility: .constant(.all)) {
            // Sidebar with tabs
            List(selection: $selectedTab) {
                Section("Navigation") {
                    ForEach(Tab.allCases, id: \.self) { tab in
                        Label(tab.rawValue, systemImage: tab.icon)
                            .tag(tab)
                    }
                }

                Section("Folders") {
                    ForEach(SidebarFolder.allCases) { folder in
                        Label(folder.rawValue, systemImage: folder.icon)
                    }
                }
            }
            .listStyle(.sidebar)
            .navigationSplitViewColumnWidth(min: 180, ideal: 200, max: 250)
        } content: {
            // Content based on selected tab
            switch selectedTab {
            case .contacts:
                ContactsView(selectedChat: $selectedChat)
            case .chats:
                ChatListView(selectedChat: $selectedChat)
            case .settings:
                SettingsView()
            }
        } detail: {
            // Conversation or detail
            if let chat = selectedChat {
                ConversationView(chat: chat)
            } else {
                ContentUnavailableView(
                    "Select a Chat",
                    systemImage: "bubble.left.and.bubble.right",
                    description: Text("Choose a conversation from the list")
                )
            }
        }
        .frame(minWidth: 900, minHeight: 600)
    }
    #endif
}

// MARK: - Sidebar Folder (macOS)

#if os(macOS)
enum SidebarFolder: String, CaseIterable, Identifiable {
    case all = "All Chats"
    case personal = "Personal"
    case groups = "Groups"
    case channels = "Channels"
    case bots = "Bots"
    case archived = "Archived"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .all: return "tray.fill"
        case .personal: return "person.fill"
        case .groups: return "person.3.fill"
        case .channels: return "megaphone.fill"
        case .bots: return "cpu.fill"
        case .archived: return "archivebox.fill"
        }
    }
}
#endif


// MARK: - Menu Bar View (macOS)

#if os(macOS)
struct MenuBarView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        VStack(spacing: 8) {
            if appState.unreadCount > 0 {
                Text("\(appState.unreadCount) unread messages")
                    .font(.headline)
            } else {
                Text("No new messages")
                    .foregroundStyle(.secondary)
            }

            Divider()

            Button("Open Margiogram") {
                NSApplication.shared.activate(ignoringOtherApps: true)
            }

            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }
        }
        .padding()
        .frame(width: 200)
    }
}
#endif

// MARK: - Preview

#Preview {
    RootView()
        .environmentObject(AppState())
        .environmentObject(AuthenticationManager())
}
