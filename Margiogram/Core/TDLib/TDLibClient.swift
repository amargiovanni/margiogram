//
//  TDLibClient.swift
//  Margiogram
//
//  Created by Andrea Margiovanni on 2024.
//

import Foundation
import OSLog
@preconcurrency import TDLibKit

// MARK: - TDLib Client Wrapper

/// Main TDLib client wrapper for communicating with Telegram servers.
///
/// This class wraps TDLibKit to provide a clean interface for the app.
/// It handles initialization, authentication, and update handling.
@MainActor
final class TelegramClient: ObservableObject {
    // MARK: - Singleton

    static let shared = TelegramClient()

    // MARK: - Properties

    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "Margiogram", category: "TDLib")

    /// TDLibKit manager - only one instance allowed
    private var manager: TDLibClientManager?

    /// TDLibKit client instance
    /// Note: Using nonisolated(unsafe) due to TDLibKit not being Sendable
    nonisolated(unsafe) private var tdClient: TDLibKit.TDLibClient?

    /// Current connection state
    @Published private(set) var connectionState: MargiogramConnectionState = .waitingForNetwork

    /// Current authorization state
    @Published private(set) var authorizationState: TDAuthorizationState = .waitingForTdlibParameters

    /// Whether the client is running
    private var isRunning = false

    /// Stream of updates from TDLib
    private var updatesContinuation: AsyncStream<TDUpdate>.Continuation?

    /// AsyncStream of TDLib updates
    lazy var updates: AsyncStream<TDUpdate> = {
        AsyncStream { continuation in
            self.updatesContinuation = continuation
        }
    }()

    // MARK: - Mock Configuration

    /// Automatically uses mock data on simulator, real TDLib on physical device
    /// TDLibFramework crashes on iOS Simulator due to architecture issues
    #if targetEnvironment(simulator)
    static var useMockData = true
    #else
    static var useMockData = false
    #endif

    /// Simulated delay for mock API calls
    private let simulatedDelay: Duration = .milliseconds(500)

    // MARK: - Initialization

    private init() {
        logger.info("TelegramClient initialized (Mock Mode: \(Self.useMockData))")
    }

    // Note: deinit removed due to Swift 6 Sendable constraints
    // Cleanup is handled by stop() method

    // MARK: - Public Methods

    /// Starts the TDLib client and begins receiving updates.
    func start() {
        guard !isRunning else {
            logger.warning("TDLib client already started")
            return
        }

        isRunning = true
        logger.info("Starting TDLib client...")

        if Self.useMockData {
            Task {
                await simulateStartup()
            }
        } else {
            initializeTDLib()
        }
    }

    /// Stops the TDLib client.
    func stop() {
        logger.info("Stopping TDLib client...")
        manager?.closeClients()
        tdClient = nil
        manager = nil
        isRunning = false
        logger.info("TDLib client stopped")
    }

    // MARK: - TDLib Initialization

    private func initializeTDLib() {
        logger.info("Initializing TDLib...")

        // Create manager (only one allowed)
        manager = TDLibClientManager()

        // Create client with update handler
        // The handler is called from TDLibKit's internal queue
        tdClient = manager?.createClient { [weak self] data, _ in
            // Decode on the callback queue, then dispatch to main
            do {
                let decoder = JSONDecoder()
                decoder.keyDecodingStrategy = .convertFromSnakeCase
                let update = try decoder.decode(TDLibKit.Update.self, from: data)

                Task { @MainActor in
                    self?.processUpdate(update)
                }
            } catch {
                Task { @MainActor in
                    self?.logger.error("Failed to decode TDLib update: \(error.localizedDescription)")
                }
            }
        }

        logger.info("TDLib client created")
    }

    private func processUpdate(_ update: TDLibKit.Update) {
        switch update {
        case .updateAuthorizationState(let state):
            handleAuthorizationStateUpdate(state.authorizationState)

        case .updateConnectionState(let state):
            handleConnectionStateUpdate(state.state)

        case .updateNewMessage(let newMessage):
            logger.debug("New message received in chat \(newMessage.message.chatId)")
            // Emit update for listeners
            if let message = convertTDMessage(newMessage.message) {
                updatesContinuation?.yield(.newMessage(message))
            }

        case .updateMessageContent(let content):
            logger.debug("Message content updated: \(content.messageId)")

        case .updateDeleteMessages(let deleted):
            if deleted.isPermanent {
                updatesContinuation?.yield(.messagesDeleted(
                    chatId: deleted.chatId,
                    messageIds: deleted.messageIds
                ))
            }

        case .updateUser(let userUpdate):
            logger.debug("User updated: \(userUpdate.user.id)")

        case .updateUserStatus(let status):
            logger.debug("User status updated: \(status.userId)")

        case .updateFile(let fileUpdate):
            logger.debug("File updated: \(fileUpdate.file.id)")

        default:
            logger.debug("Unhandled update type")
        }
    }

    private func handleAuthorizationStateUpdate(_ state: TDLibKit.AuthorizationState) {
        logger.info("Authorization state changed")

        switch state {
        case .authorizationStateWaitTdlibParameters:
            authorizationState = .waitingForTdlibParameters
            Task {
                await setTdlibParameters()
            }

        case .authorizationStateWaitPhoneNumber:
            authorizationState = .waitingForPhoneNumber

        case .authorizationStateWaitCode(let codeState):
            let codeInfo = convertCodeInfo(codeState.codeInfo)
            authorizationState = .waitingForCode(codeInfo: codeInfo)

        case .authorizationStateWaitPassword(let passwordState):
            authorizationState = .waitingForPassword(hint: passwordState.passwordHint)

        case .authorizationStateWaitRegistration:
            authorizationState = .waitingForRegistration

        case .authorizationStateReady:
            authorizationState = .ready
            logger.info("User authenticated successfully")

        case .authorizationStateLoggingOut:
            authorizationState = .loggingOut

        case .authorizationStateClosing:
            authorizationState = .closing

        case .authorizationStateClosed:
            authorizationState = .closed

        default:
            logger.warning("Unknown authorization state")
        }
    }

    private func handleConnectionStateUpdate(_ state: TDLibKit.ConnectionState) {
        logger.info("Connection state changed")

        switch state {
        case .connectionStateWaitingForNetwork:
            connectionState = .waitingForNetwork
        case .connectionStateConnectingToProxy:
            connectionState = .connectingToProxy
        case .connectionStateConnecting:
            connectionState = .connecting
        case .connectionStateUpdating:
            connectionState = .updating
        case .connectionStateReady:
            connectionState = .ready
        }
    }

    // MARK: - TDLib Parameters

    private func setTdlibParameters() async {
        guard let client = tdClient else {
            logger.error("Client not initialized")
            return
        }

        logger.info("Setting TDLib parameters...")

        do {
            _ = try await client.setTdlibParameters(
                apiHash: TelegramConfig.apiHash,
                apiId: Int(TelegramConfig.apiId),
                applicationVersion: TelegramConfig.appVersion,
                databaseDirectory: TelegramConfig.databaseDirectory,
                databaseEncryptionKey: Data(),
                deviceModel: TelegramConfig.deviceModel,
                filesDirectory: TelegramConfig.filesDirectory,
                systemLanguageCode: TelegramConfig.languageCode,
                systemVersion: TelegramConfig.systemVersion,
                useChatInfoDatabase: TelegramConfig.useChatInfoDatabase,
                useFileDatabase: TelegramConfig.useFileDatabase,
                useMessageDatabase: TelegramConfig.useMessageDatabase,
                useSecretChats: TelegramConfig.useSecretChats,
                useTestDc: TelegramConfig.useTestDC
            )
            logger.info("TDLib parameters set successfully")
        } catch {
            logger.error("Failed to set TDLib parameters: \(error.localizedDescription)")
        }
    }

    // MARK: - Authentication Methods

    /// Sets the phone number for authentication.
    func setAuthenticationPhoneNumber(_ phoneNumber: String) async throws {
        logger.info("Setting authentication phone number")

        if Self.useMockData {
            try await Task.sleep(for: simulatedDelay)
            authorizationState = .waitingForCode(codeInfo: CodeInfo(
                phoneNumber: phoneNumber,
                type: .sms(length: 5),
                nextType: .call(length: 5),
                timeout: 60
            ))
            return
        }

        guard let client = tdClient else {
            throw TDLibError.clientNotInitialized
        }

        do {
            _ = try await client.setAuthenticationPhoneNumber(
                phoneNumber: phoneNumber,
                settings: PhoneNumberAuthenticationSettings(
                    allowFlashCall: false,
                    allowMissedCall: false,
                    allowSmsRetrieverApi: false,
                    authenticationTokens: [],
                    firebaseAuthenticationSettings: nil,
                    hasUnknownPhoneNumber: false,
                    isCurrentPhoneNumber: false
                )
            )
            logger.info("Phone number sent successfully")
        } catch {
            logger.error("Failed to set phone number: \(error.localizedDescription)")
            throw convertTDError(error)
        }
    }

    /// Checks the authentication code.
    func checkAuthenticationCode(_ code: String) async throws {
        logger.info("Checking authentication code")

        if Self.useMockData {
            try await Task.sleep(for: simulatedDelay)
            if code == "12345" || code.count >= 4 {
                authorizationState = .ready
            } else {
                throw TDLibError.api(code: 400, message: "Invalid code")
            }
            return
        }

        guard let client = tdClient else {
            throw TDLibError.clientNotInitialized
        }

        do {
            _ = try await client.checkAuthenticationCode(code: code)
            logger.info("Authentication code verified")
        } catch {
            logger.error("Failed to check code: \(error.localizedDescription)")
            throw convertTDError(error)
        }
    }

    /// Checks the 2FA password.
    func checkAuthenticationPassword(_ password: String) async throws {
        logger.info("Checking authentication password")

        if Self.useMockData {
            try await Task.sleep(for: simulatedDelay)
            authorizationState = .ready
            return
        }

        guard let client = tdClient else {
            throw TDLibError.clientNotInitialized
        }

        do {
            _ = try await client.checkAuthenticationPassword(password: password)
            logger.info("Password verified")
        } catch {
            logger.error("Failed to check password: \(error.localizedDescription)")
            throw convertTDError(error)
        }
    }

    /// Registers a new user.
    func registerUser(firstName: String, lastName: String) async throws {
        logger.info("Registering new user: \(firstName)")

        if Self.useMockData {
            try await Task.sleep(for: simulatedDelay)
            authorizationState = .ready
            return
        }

        guard let client = tdClient else {
            throw TDLibError.clientNotInitialized
        }

        do {
            _ = try await client.registerUser(
                disableNotification: false,
                firstName: firstName,
                lastName: lastName
            )
            logger.info("User registered successfully")
        } catch {
            logger.error("Failed to register user: \(error.localizedDescription)")
            throw convertTDError(error)
        }
    }

    /// Resends the authentication code.
    func resendAuthenticationCode() async throws {
        logger.info("Resending authentication code")

        if Self.useMockData {
            try await Task.sleep(for: simulatedDelay)
            return
        }

        guard let client = tdClient else {
            throw TDLibError.clientNotInitialized
        }

        do {
            _ = try await client.resendAuthenticationCode(
                reason: .resendCodeReasonUserRequest
            )
            logger.info("Code resent successfully")
        } catch {
            logger.error("Failed to resend code: \(error.localizedDescription)")
            throw convertTDError(error)
        }
    }

    /// Logs out the current user.
    func logOut() async throws {
        logger.info("Logging out...")

        if Self.useMockData {
            try await Task.sleep(for: simulatedDelay)
            authorizationState = .waitingForPhoneNumber
            return
        }

        guard let client = tdClient else {
            throw TDLibError.clientNotInitialized
        }

        do {
            _ = try await client.logOut()
            logger.info("Logged out successfully")
        } catch {
            logger.error("Failed to log out: \(error.localizedDescription)")
            throw convertTDError(error)
        }
    }

    // MARK: - Chat Methods

    /// Gets the list of chats.
    func getChats(limit: Int = 100) async throws -> [TDLibKit.Chat] {
        guard let client = tdClient else {
            throw TDLibError.clientNotInitialized
        }

        let chats = try await client.getChats(chatList: .chatListMain, limit: limit)
        var result: [TDLibKit.Chat] = []

        for chatId in chats.chatIds {
            let chat = try await client.getChat(chatId: chatId)
            result.append(chat)
        }

        return result
    }

    /// Gets chat history.
    func getChatHistory(chatId: Int64, fromMessageId: Int64 = 0, limit: Int = 50) async throws -> [TDLibKit.Message] {
        guard let client = tdClient else {
            throw TDLibError.clientNotInitialized
        }

        let messages = try await client.getChatHistory(
            chatId: chatId,
            fromMessageId: fromMessageId,
            limit: limit,
            offset: 0,
            onlyLocal: false
        )

        return messages.messages ?? []
    }

    /// Sends a text message.
    func sendMessage(chatId: Int64, text: String) async throws -> TDLibKit.Message {
        guard let client = tdClient else {
            throw TDLibError.clientNotInitialized
        }

        let formattedText = TDLibKit.FormattedText(entities: [], text: text)
        let inputText = InputMessageText(
            clearDraft: true,
            linkPreviewOptions: nil,
            text: formattedText
        )
        let content = TDLibKit.InputMessageContent.inputMessageText(inputText)

        let message = try await client.sendMessage(
            chatId: chatId,
            inputMessageContent: content,
            messageThreadId: 0,
            options: nil,
            replyMarkup: nil,
            replyTo: nil
        )

        return message
    }

    // MARK: - Helper Methods

    private func convertCodeInfo(_ info: TDLibKit.AuthenticationCodeInfo) -> CodeInfo {
        let type = convertCodeType(info.type)
        let nextType = info.nextType.flatMap { convertCodeType($0) }

        return CodeInfo(
            phoneNumber: info.phoneNumber,
            type: type,
            nextType: nextType,
            timeout: Int32(info.timeout)
        )
    }

    private func convertCodeType(_ type: TDLibKit.AuthenticationCodeType) -> CodeInfo.CodeType {
        switch type {
        case .authenticationCodeTypeTelegramMessage(let info):
            return .sms(length: Int32(info.length))
        case .authenticationCodeTypeSms(let info):
            return .sms(length: Int32(info.length))
        case .authenticationCodeTypeCall(let info):
            return .call(length: Int32(info.length))
        case .authenticationCodeTypeFlashCall(let info):
            return .flashCall(pattern: info.pattern)
        case .authenticationCodeTypeMissedCall(let info):
            return .missedCall(phoneNumberPrefix: info.phoneNumberPrefix, length: Int32(info.length))
        case .authenticationCodeTypeFragment(let info):
            return .fragment(url: info.url, length: Int32(info.length))
        case .authenticationCodeTypeFirebaseAndroid:
            return .firebaseAndroid
        case .authenticationCodeTypeFirebaseIos:
            return .firebaseIos
        case .authenticationCodeTypeSmsWord:
            return .sms(length: 5)
        case .authenticationCodeTypeSmsPhrase:
            return .sms(length: 5)
        }
    }

    private func convertTDMessage(_ tdMessage: TDLibKit.Message) -> Message? {
        // Convert TDLibKit message to app Message
        let content: MessageContent
        switch tdMessage.content {
        case .messageText(let text):
            content = .text(FormattedText(text: text.text.text))
        case .messagePhoto(let photo):
            content = .photo(Photo(
                id: String(photo.photo.sizes.first?.photo.id ?? 0),
                sizes: [],
                caption: FormattedText(text: photo.caption.text),
                hasSpoiler: photo.hasSpoiler
            ))
        case .messageVideo(let video):
            content = .video(Video(
                id: String(video.video.video.id),
                duration: Int32(video.video.duration),
                width: Int32(video.video.width),
                height: Int32(video.video.height),
                fileName: video.video.fileName,
                mimeType: video.video.mimeType,
                caption: FormattedText(text: video.caption.text),
                thumbnail: nil,
                file: File(
                    id: Int32(video.video.video.id),
                    size: Int64(video.video.video.size ?? 0),
                    expectedSize: Int64(video.video.video.expectedSize ?? 0),
                    localPath: video.video.video.local.path,
                    isDownloadingActive: video.video.video.local.isDownloadingActive,
                    isDownloadingCompleted: video.video.video.local.isDownloadingCompleted,
                    downloadedSize: Int64(video.video.video.local.downloadedSize)
                ),
                hasSpoiler: video.hasSpoiler,
                supportsStreaming: video.video.supportsStreaming
            ))
        default:
            content = .unsupported
        }

        let sender: MessageSender
        switch tdMessage.senderId {
        case .messageSenderUser(let user):
            sender = .user(userId: user.userId)
        case .messageSenderChat(let chat):
            sender = .chat(chatId: chat.chatId)
        }

        return Message(
            id: tdMessage.id,
            chatId: tdMessage.chatId,
            sender: sender,
            content: content,
            date: Date(timeIntervalSince1970: TimeInterval(tdMessage.date)),
            editDate: tdMessage.editDate > 0 ? Date(timeIntervalSince1970: TimeInterval(tdMessage.editDate)) : nil,
            isOutgoing: tdMessage.isOutgoing,
            canBeEdited: tdMessage.isOutgoing, // Assume editable if outgoing
            canBeForwarded: tdMessage.canBeSaved,
            canBeDeletedForAllUsers: tdMessage.isOutgoing,
            replyTo: nil,
            forwardInfo: nil,
            reactions: [],
            isRead: true,
            interactionInfo: nil
        )
    }

    private func convertTDError(_ error: Swift.Error) -> TDLibError {
        if let tdError = error as? TDLibKit.Error {
            return .api(code: Int(tdError.code), message: tdError.message)
        }
        return .api(code: 0, message: error.localizedDescription)
    }

    // MARK: - Mock Startup

    private func simulateStartup() async {
        try? await Task.sleep(for: .milliseconds(300))
        connectionState = .connecting

        try? await Task.sleep(for: .milliseconds(500))
        connectionState = .ready

        try? await Task.sleep(for: .milliseconds(200))
        authorizationState = .waitingForPhoneNumber
    }
}

// MARK: - Backwards Compatibility Typealias

/// Typealias for backwards compatibility with existing code
typealias TDLibClient = TelegramClient

// MARK: - Connection State

/// Represents the TDLib connection state.
enum MargiogramConnectionState: Equatable {
    case waitingForNetwork
    case connectingToProxy
    case connecting
    case updating
    case ready
}

// Typealias for backwards compatibility
typealias ConnectionState = MargiogramConnectionState

// MARK: - Authorization State

/// Represents the TDLib authorization state.
enum TDAuthorizationState: Equatable {
    case waitingForTdlibParameters
    case waitingForPhoneNumber
    case waitingForCode(codeInfo: CodeInfo)
    case waitingForPassword(hint: String)
    case waitingForRegistration
    case ready
    case loggingOut
    case closing
    case closed

    static func == (lhs: TDAuthorizationState, rhs: TDAuthorizationState) -> Bool {
        switch (lhs, rhs) {
        case (.waitingForTdlibParameters, .waitingForTdlibParameters),
             (.waitingForPhoneNumber, .waitingForPhoneNumber),
             (.waitingForRegistration, .waitingForRegistration),
             (.ready, .ready),
             (.loggingOut, .loggingOut),
             (.closing, .closing),
             (.closed, .closed):
            return true
        case (.waitingForCode(let lhsInfo), .waitingForCode(let rhsInfo)):
            return lhsInfo.phoneNumber == rhsInfo.phoneNumber
        case (.waitingForPassword(let lhsHint), .waitingForPassword(let rhsHint)):
            return lhsHint == rhsHint
        default:
            return false
        }
    }
}

/// Code information for authentication.
struct CodeInfo: Equatable {
    let phoneNumber: String
    let type: CodeType
    let nextType: CodeType?
    let timeout: Int32

    enum CodeType: Equatable {
        case sms(length: Int32)
        case call(length: Int32)
        case flashCall(pattern: String)
        case missedCall(phoneNumberPrefix: String, length: Int32)
        case fragment(url: String, length: Int32)
        case firebaseAndroid
        case firebaseIos

        var displayName: String {
            switch self {
            case .sms:
                return "SMS"
            case .call:
                return "Phone call"
            case .flashCall:
                return "Flash call"
            case .missedCall:
                return "Missed call"
            case .fragment:
                return "Fragment"
            case .firebaseAndroid, .firebaseIos:
                return "Firebase"
            }
        }

        var codeLength: Int32 {
            switch self {
            case .sms(let length), .call(let length), .missedCall(_, let length), .fragment(_, let length):
                return length
            case .flashCall:
                return 5
            case .firebaseAndroid, .firebaseIos:
                return 6
            }
        }
    }
}

// MARK: - TDLib Error

/// Errors that can occur when communicating with TDLib.
enum TDLibError: LocalizedError, Sendable {
    case clientNotInitialized
    case encodingFailed
    case decodingFailed
    case api(code: Int, message: String)
    case timeout
    case notImplemented

    var errorDescription: String? {
        switch self {
        case .clientNotInitialized:
            return "TDLib client is not initialized"
        case .encodingFailed:
            return "Failed to encode request"
        case .decodingFailed:
            return "Failed to decode response"
        case .api(let code, let message):
            return "TDLib error \(code): \(message)"
        case .timeout:
            return "Request timed out"
        case .notImplemented:
            return "Feature not yet implemented"
        }
    }
}
