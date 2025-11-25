//
//  NotificationService.swift
//  Margiogram
//
//  Created by Andrea Margiovanni on 2024.
//

import Foundation
@preconcurrency import UserNotifications

// MARK: - Notification Service

/// Service for handling push notifications.
actor NotificationService {
    // MARK: - Shared Instance

    static let shared = NotificationService()

    // MARK: - Properties

    nonisolated(unsafe) private let center = UNUserNotificationCenter.current()
    private var deviceToken: Data?

    // MARK: - Initialization

    private init() {}

    // MARK: - Authorization

    /// Requests notification authorization.
    func requestAuthorization() async throws -> Bool {
        let options: UNAuthorizationOptions = [.alert, .badge, .sound, .providesAppNotificationSettings]

        do {
            let granted = try await center.requestAuthorization(options: options)
            return granted
        } catch {
            throw NotificationError.authorizationFailed(error)
        }
    }

    /// Gets the current authorization status.
    func getAuthorizationStatus() async -> UNAuthorizationStatus {
        let settings = await center.notificationSettings()
        return settings.authorizationStatus
    }

    /// Checks if notifications are authorized.
    var isAuthorized: Bool {
        get async {
            let status = await getAuthorizationStatus()
            return status == .authorized || status == .provisional
        }
    }

    // MARK: - Device Token

    /// Sets the device token for remote notifications.
    func setDeviceToken(_ token: Data) {
        deviceToken = token
    }

    /// Gets the device token as a hex string.
    var deviceTokenString: String? {
        deviceToken?.map { String(format: "%02.2hhx", $0) }.joined()
    }

    // MARK: - Local Notifications

    /// Schedules a local notification.
    func scheduleNotification(
        identifier: String,
        title: String,
        body: String,
        badge: Int? = nil,
        sound: UNNotificationSound? = .default,
        userInfo: [AnyHashable: Any] = [:],
        trigger: UNNotificationTrigger? = nil
    ) async throws {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = sound

        if let badge {
            content.badge = NSNumber(value: badge)
        }

        content.userInfo = userInfo

        let request = UNNotificationRequest(
            identifier: identifier,
            content: content,
            trigger: trigger
        )

        try await center.add(request)
    }

    /// Cancels pending notifications.
    func cancelPendingNotifications(identifiers: [String]) {
        center.removePendingNotificationRequests(withIdentifiers: identifiers)
    }

    /// Cancels all pending notifications.
    func cancelAllPendingNotifications() {
        center.removeAllPendingNotificationRequests()
    }

    /// Removes delivered notifications.
    func removeDeliveredNotifications(identifiers: [String]) {
        center.removeDeliveredNotifications(withIdentifiers: identifiers)
    }

    /// Removes all delivered notifications.
    func removeAllDeliveredNotifications() {
        center.removeAllDeliveredNotifications()
    }

    // MARK: - Badge

    /// Updates the app badge count.
    @MainActor
    func setBadgeCount(_ count: Int) async throws {
        try await center.setBadgeCount(count)
    }

    /// Clears the app badge.
    @MainActor
    func clearBadge() async throws {
        try await center.setBadgeCount(0)
    }

    // MARK: - Categories

    /// Registers notification categories for interactive notifications.
    func registerCategories() {
        // Reply action
        let replyAction = UNTextInputNotificationAction(
            identifier: NotificationAction.reply.rawValue,
            title: "Reply",
            options: [],
            textInputButtonTitle: "Send",
            textInputPlaceholder: "Type a message..."
        )

        // Mark as read action
        let markReadAction = UNNotificationAction(
            identifier: NotificationAction.markAsRead.rawValue,
            title: "Mark as Read",
            options: []
        )

        // Mute action
        let muteAction = UNNotificationAction(
            identifier: NotificationAction.mute.rawValue,
            title: "Mute",
            options: .destructive
        )

        // Message category
        let messageCategory = UNNotificationCategory(
            identifier: NotificationCategory.message.rawValue,
            actions: [replyAction, markReadAction, muteAction],
            intentIdentifiers: [],
            options: [.customDismissAction]
        )

        // Call category
        let answerAction = UNNotificationAction(
            identifier: NotificationAction.answer.rawValue,
            title: "Answer",
            options: .foreground
        )

        let declineAction = UNNotificationAction(
            identifier: NotificationAction.decline.rawValue,
            title: "Decline",
            options: .destructive
        )

        let callCategory = UNNotificationCategory(
            identifier: NotificationCategory.call.rawValue,
            actions: [answerAction, declineAction],
            intentIdentifiers: [],
            options: []
        )

        center.setNotificationCategories([messageCategory, callCategory])
    }
}

// MARK: - Notification Category

enum NotificationCategory: String {
    case message = "MESSAGE"
    case call = "CALL"
}

// MARK: - Notification Action

enum NotificationAction: String {
    case reply = "REPLY"
    case markAsRead = "MARK_AS_READ"
    case mute = "MUTE"
    case answer = "ANSWER"
    case decline = "DECLINE"
}

// MARK: - Notification Error

enum NotificationError: LocalizedError {
    case authorizationFailed(Error)
    case schedulingFailed(Error)

    var errorDescription: String? {
        switch self {
        case .authorizationFailed(let error):
            return "Failed to request authorization: \(error.localizedDescription)"
        case .schedulingFailed(let error):
            return "Failed to schedule notification: \(error.localizedDescription)"
        }
    }
}
