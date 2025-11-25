//
//  MargiogramApp.swift
//  Margiogram
//
//  Created by Andrea Margiovanni on 2024.
//

import SwiftUI

/// Main entry point for the Margiogram application.
///
/// Margiogram is a native Telegram client for iOS and macOS featuring
/// a Liquid Glass design system.
@main
struct MargiogramApp: App {
    // MARK: - State

    @StateObject private var appState = AppState()
    @StateObject private var authManager = AuthenticationManager()

    // MARK: - Environment

    @Environment(\.scenePhase) private var scenePhase

    // MARK: - Body

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(appState)
                .environmentObject(authManager)
                .onAppear {
                    setupApp()
                }
                .onChange(of: scenePhase) { _, newPhase in
                    handleScenePhaseChange(newPhase)
                }
        }
        #if os(macOS)
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
        .defaultSize(width: 1200, height: 800)
        #endif

        #if os(macOS)
        Settings {
            SettingsView()
                .environmentObject(appState)
        }

        MenuBarExtra("Margiogram", systemImage: "paperplane.fill") {
            MenuBarView()
                .environmentObject(appState)
        }
        .menuBarExtraStyle(.window)
        #endif
    }

    // MARK: - Setup

    private func setupApp() {
        // Configure appearance
        configureAppearance()

        // Initialize TDLib
        Task {
            await authManager.initialize()
        }
    }

    private func configureAppearance() {
        #if os(iOS)
        // Configure iOS appearance
        let appearance = UINavigationBarAppearance()
        appearance.configureWithTransparentBackground()
        appearance.backgroundEffect = UIBlurEffect(style: .systemUltraThinMaterial)
        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
        #endif
    }

    private func handleScenePhaseChange(_ phase: ScenePhase) {
        switch phase {
        case .active:
            // App became active
            Task {
                await appState.syncOnForeground()
            }
        case .inactive:
            // App became inactive
            break
        case .background:
            // App entered background
            appState.saveState()
        @unknown default:
            break
        }
    }
}

// MARK: - App State

/// Global application state manager.
@MainActor
final class AppState: ObservableObject {
    // MARK: - Published Properties

    @Published var selectedChatId: Int64?
    @Published var isOnline = true
    @Published var unreadCount: Int = 0

    // MARK: - Methods

    func syncOnForeground() async {
        // Trigger sync when app comes to foreground
    }

    func saveState() {
        // Save state before going to background
    }

    func selectChat(_ chatId: Int64?) {
        selectedChatId = chatId
    }
}
