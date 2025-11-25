//
//  TelegramConfig.swift
//  Margiogram
//
//  Created by Andrea Margiovanni on 2024.
//

import Foundation
#if canImport(UIKit)
import UIKit
#endif

// MARK: - Telegram API Configuration

/// Configuration for Telegram API credentials.
///
/// To obtain your own API credentials:
/// 1. Go to https://my.telegram.org
/// 2. Log in with your phone number
/// 3. Go to "API development tools"
/// 4. Create a new application
/// 5. Copy the api_id and api_hash
///
/// For development/testing, you can use test credentials.
/// For production, replace these with your own credentials.
enum TelegramConfig {
    // MARK: - API Credentials

    /// Telegram API ID - Get yours at https://my.telegram.org
    /// WARNING: Replace with your own API ID for production use
    static let apiId: Int32 = 94575 // Test API ID - replace with your own

    /// Telegram API Hash - Get yours at https://my.telegram.org
    /// WARNING: Replace with your own API Hash for production use
    static let apiHash: String = "a3406de8d171bb422bb6ddf3bbd800e2" // Test API Hash - replace with your own

    // MARK: - App Configuration

    /// Application version
    static var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    }

    /// Application build number
    static var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }

    /// Device model
    static var deviceModel: String {
        #if os(iOS)
        return UIDevice.current.model
        #elseif os(macOS)
        return "Mac"
        #else
        return "Unknown"
        #endif
    }

    /// System version
    static var systemVersion: String {
        #if os(iOS)
        return UIDevice.current.systemVersion
        #elseif os(macOS)
        let version = ProcessInfo.processInfo.operatingSystemVersion
        return "\(version.majorVersion).\(version.minorVersion).\(version.patchVersion)"
        #else
        return "Unknown"
        #endif
    }

    /// System language code
    static var languageCode: String {
        Locale.current.language.languageCode?.identifier ?? "en"
    }

    // MARK: - TDLib Configuration

    /// Use test Telegram Data Center (for testing only)
    static let useTestDC: Bool = false

    /// Enable message database for local caching
    static let useMessageDatabase: Bool = true

    /// Enable file database for local file caching
    static let useFileDatabase: Bool = true

    /// Enable chat info database for local chat caching
    static let useChatInfoDatabase: Bool = true

    /// Enable secret chats support
    static let useSecretChats: Bool = true

    /// Enable storage optimizer
    static let enableStorageOptimizer: Bool = true

    /// Ignore file names (use file IDs instead)
    static let ignoreFileNames: Bool = false

    // MARK: - Paths

    /// Database directory path
    static var databaseDirectory: String {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let documentsDirectory = paths[0]
        let tdlibDirectory = documentsDirectory.appendingPathComponent("tdlib")

        // Create directory if it doesn't exist
        try? FileManager.default.createDirectory(at: tdlibDirectory, withIntermediateDirectories: true)

        return tdlibDirectory.path
    }

    /// Files directory path
    static var filesDirectory: String {
        let tdlibDirectory = URL(fileURLWithPath: databaseDirectory)
        let filesDirectory = tdlibDirectory.appendingPathComponent("files")

        // Create directory if it doesn't exist
        try? FileManager.default.createDirectory(at: filesDirectory, withIntermediateDirectories: true)

        return filesDirectory.path
    }
}
