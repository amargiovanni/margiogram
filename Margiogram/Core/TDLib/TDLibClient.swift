//
//  TDLibClient.swift
//  Margiogram
//
//  Created by Andrea Margiovanni on 2024.
//

import Foundation
import OSLog

// MARK: - TDLib Client Protocol

/// Protocol defining the TDLib client interface.
protocol TDLibClientProtocol: Actor {
    /// Sends a request to TDLib and returns the response.
    func send<T: TDFunction>(_ function: T) async throws -> T.Result

    /// Stream of updates from TDLib.
    var updates: AsyncStream<TDUpdate> { get }

    /// Current connection state.
    var connectionState: ConnectionState { get }
}

// MARK: - TDLib Client

/// Main TDLib client wrapper for communicating with Telegram servers.
///
/// This actor manages all interactions with TDLib, including:
/// - Sending requests and receiving responses
/// - Handling real-time updates
/// - Managing connection state
///
/// ## Usage
///
/// ```swift
/// let client = TDLibClient.shared
/// let chats = try await client.send(GetChats(limit: 100))
/// ```
actor TDLibClient: TDLibClientProtocol {
    // MARK: - Singleton

    static let shared = TDLibClient()

    // MARK: - Properties

    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "TDLib")

    /// TDLib client pointer (will be actual td_json_client when TDLib is integrated)
    private var clientId: Int32 = 0

    /// Pending requests waiting for responses
    private var pendingRequests: [String: CheckedContinuation<Any, Error>] = [:]

    /// Request ID counter
    private var requestId: Int64 = 0

    /// Whether the client is running
    private var isRunning = false

    /// Current connection state
    private(set) var connectionState: ConnectionState = .waitingForNetwork

    /// Update stream continuation
    private var updateContinuation: AsyncStream<TDUpdate>.Continuation?

    // MARK: - Updates Stream

    var updates: AsyncStream<TDUpdate> {
        AsyncStream { continuation in
            self.updateContinuation = continuation
        }
    }

    // MARK: - Initialization

    private init() {
        logger.info("TDLibClient initialized")
    }

    // MARK: - Public Methods

    /// Starts the TDLib client and begins receiving updates.
    func start() async {
        guard !isRunning else { return }

        isRunning = true
        logger.info("TDLib client started")

        // In real implementation, this would:
        // 1. Call td_json_client_create()
        // 2. Start a loop to receive updates via td_json_client_receive()
        // 3. Parse updates and yield them to the stream

        // Simulate startup
        await setConnectionState(.connecting)
    }

    /// Stops the TDLib client.
    func stop() {
        guard isRunning else { return }

        isRunning = false
        updateContinuation?.finish()
        logger.info("TDLib client stopped")

        // In real implementation: td_json_client_destroy(client)
    }

    /// Sends a function to TDLib and awaits the response.
    ///
    /// - Parameter function: The TDLib function to execute.
    /// - Returns: The result of the function.
    /// - Throws: `TDLibError` if the request fails.
    func send<T: TDFunction>(_ function: T) async throws -> T.Result {
        requestId += 1
        let currentRequestId = "\(requestId)"

        logger.debug("Sending request \(currentRequestId): \(String(describing: T.self))")

        // Encode the function to JSON
        var request = try function.encode()
        request["@extra"] = currentRequestId

        // In real implementation:
        // let jsonString = try JSONSerialization.string(from: request)
        // td_json_client_send(client, jsonString)

        // Wait for response
        return try await withCheckedThrowingContinuation { continuation in
            pendingRequests[currentRequestId] = continuation as! CheckedContinuation<Any, Error>

            // Simulate async response (remove in real implementation)
            Task {
                try? await Task.sleep(for: .milliseconds(100))
                await self.simulateResponse(for: function, requestId: currentRequestId)
            }
        }
    }

    // MARK: - Private Methods

    private func setConnectionState(_ state: ConnectionState) async {
        connectionState = state
        updateContinuation?.yield(.connectionStateUpdate(state))
    }

    /// Handles incoming TDLib response/update.
    private func handleResponse(_ json: [String: Any]) {
        // Check if it's a response to a request
        if let extra = json["@extra"] as? String,
           let continuation = pendingRequests.removeValue(forKey: extra) {
            // It's a response
            if let errorCode = json["code"] as? Int,
               let errorMessage = json["message"] as? String {
                continuation.resume(throwing: TDLibError.api(code: errorCode, message: errorMessage))
            } else {
                continuation.resume(returning: json)
            }
            return
        }

        // It's an update - parse and emit
        if let update = parseUpdate(json) {
            updateContinuation?.yield(update)
        }
    }

    private func parseUpdate(_ json: [String: Any]) -> TDUpdate? {
        guard let type = json["@type"] as? String else { return nil }

        switch type {
        case "updateAuthorizationState":
            // Parse authorization state update
            return nil

        case "updateNewMessage":
            // Parse new message update
            return nil

        case "updateConnectionState":
            // Parse connection state
            return nil

        default:
            logger.debug("Unhandled update type: \(type)")
            return nil
        }
    }

    // MARK: - Simulation (Remove when TDLib is integrated)

    private func simulateResponse<T: TDFunction>(for function: T, requestId: String) async {
        guard let continuation = pendingRequests.removeValue(forKey: requestId) else { return }

        // Simulate responses for development
        do {
            let result = try await simulateResult(for: function)
            continuation.resume(returning: result)
        } catch {
            continuation.resume(throwing: error)
        }
    }

    private func simulateResult<T: TDFunction>(for function: T) async throws -> T.Result {
        // This is temporary simulation code
        throw TDLibError.notImplemented
    }
}

// MARK: - Connection State

/// Represents the TDLib connection state.
enum ConnectionState: Equatable {
    case waitingForNetwork
    case connectingToProxy
    case connecting
    case updating
    case ready
}

// MARK: - TDLib Error

/// Errors that can occur when communicating with TDLib.
enum TDLibError: LocalizedError {
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

// MARK: - TDLib Update

/// Represents an update from TDLib.
enum TDUpdate {
    case connectionStateUpdate(ConnectionState)
    case authorizationStateUpdate(AuthorizationState)
    case newMessage(Message)
    case messageEdited(chatId: Int64, messageId: Int64, content: MessageContent)
    case messagesDeleted(chatId: Int64, messageIds: [Int64])
    case chatUpdated(Chat)
    case userUpdated(User)
    case userStatusUpdated(userId: Int64, status: UserStatus)
    case fileUpdated(File)
}

// MARK: - TDLib Function Protocol

/// Protocol for TDLib functions.
protocol TDFunction {
    associatedtype Result

    /// Encodes the function to a JSON dictionary.
    func encode() throws -> [String: Any]
}

// MARK: - Example TDLib Functions

/// Gets the list of chats.
struct GetChats: TDFunction {
    typealias Result = Chats

    let chatList: ChatList
    let limit: Int32

    init(chatList: ChatList = .main, limit: Int32 = 100) {
        self.chatList = chatList
        self.limit = limit
    }

    func encode() throws -> [String: Any] {
        [
            "@type": "getChats",
            "chat_list": chatList.encode(),
            "limit": limit
        ]
    }
}

/// Gets information about a chat.
struct GetChat: TDFunction {
    typealias Result = Chat

    let chatId: Int64

    func encode() throws -> [String: Any] {
        [
            "@type": "getChat",
            "chat_id": chatId
        ]
    }
}

/// Sends a message.
struct SendMessage: TDFunction {
    typealias Result = Message

    let chatId: Int64
    let replyToMessageId: Int64?
    let content: InputMessageContent

    init(chatId: Int64, replyToMessageId: Int64? = nil, content: InputMessageContent) {
        self.chatId = chatId
        self.replyToMessageId = replyToMessageId
        self.content = content
    }

    func encode() throws -> [String: Any] {
        var dict: [String: Any] = [
            "@type": "sendMessage",
            "chat_id": chatId,
            "input_message_content": content.encode()
        ]

        if let replyTo = replyToMessageId {
            dict["reply_to_message_id"] = replyTo
        }

        return dict
    }
}

/// Sets the phone number for authentication.
struct SetAuthenticationPhoneNumber: TDFunction {
    typealias Result = Ok

    let phoneNumber: String

    func encode() throws -> [String: Any] {
        [
            "@type": "setAuthenticationPhoneNumber",
            "phone_number": phoneNumber
        ]
    }
}

/// Checks the authentication code.
struct CheckAuthenticationCode: TDFunction {
    typealias Result = Ok

    let code: String

    func encode() throws -> [String: Any] {
        [
            "@type": "checkAuthenticationCode",
            "code": code
        ]
    }
}

/// Checks the 2FA password.
struct CheckAuthenticationPassword: TDFunction {
    typealias Result = Ok

    let password: String

    func encode() throws -> [String: Any] {
        [
            "@type": "checkAuthenticationPassword",
            "password": password
        ]
    }
}

// MARK: - Response Types

/// Represents a successful operation.
struct Ok {
    // Empty response
}

/// Represents a list of chats.
struct Chats {
    let totalCount: Int32
    let chatIds: [Int64]
}

// MARK: - Chat List

/// Represents a chat list type.
enum ChatList {
    case main
    case archive
    case folder(id: Int32)

    func encode() -> [String: Any] {
        switch self {
        case .main:
            return ["@type": "chatListMain"]
        case .archive:
            return ["@type": "chatListArchive"]
        case .folder(let id):
            return ["@type": "chatListFolder", "chat_folder_id": id]
        }
    }
}

// MARK: - Input Message Content

/// Represents input message content.
enum InputMessageContent {
    case text(String, entities: [TextEntity]? = nil)
    case photo(path: String, caption: String? = nil)
    case video(path: String, caption: String? = nil)
    case document(path: String, caption: String? = nil)
    case voice(path: String)
    case location(latitude: Double, longitude: Double)
    case contact(phoneNumber: String, firstName: String, lastName: String?)

    func encode() -> [String: Any] {
        switch self {
        case .text(let text, let entities):
            var dict: [String: Any] = [
                "@type": "inputMessageText",
                "text": [
                    "@type": "formattedText",
                    "text": text
                ]
            ]
            if let entities = entities {
                // Add entities encoding
            }
            return dict

        case .photo(let path, let caption):
            var dict: [String: Any] = [
                "@type": "inputMessagePhoto",
                "photo": ["@type": "inputFileLocal", "path": path]
            ]
            if let caption = caption {
                dict["caption"] = ["@type": "formattedText", "text": caption]
            }
            return dict

        case .video(let path, let caption):
            var dict: [String: Any] = [
                "@type": "inputMessageVideo",
                "video": ["@type": "inputFileLocal", "path": path]
            ]
            if let caption = caption {
                dict["caption"] = ["@type": "formattedText", "text": caption]
            }
            return dict

        case .document(let path, let caption):
            var dict: [String: Any] = [
                "@type": "inputMessageDocument",
                "document": ["@type": "inputFileLocal", "path": path]
            ]
            if let caption = caption {
                dict["caption"] = ["@type": "formattedText", "text": caption]
            }
            return dict

        case .voice(let path):
            return [
                "@type": "inputMessageVoiceNote",
                "voice_note": ["@type": "inputFileLocal", "path": path]
            ]

        case .location(let latitude, let longitude):
            return [
                "@type": "inputMessageLocation",
                "location": [
                    "@type": "location",
                    "latitude": latitude,
                    "longitude": longitude
                ]
            ]

        case .contact(let phone, let firstName, let lastName):
            var dict: [String: Any] = [
                "@type": "inputMessageContact",
                "contact": [
                    "@type": "contact",
                    "phone_number": phone,
                    "first_name": firstName
                ]
            ]
            if let lastName = lastName {
                (dict["contact"] as? [String: Any])?["last_name"] = lastName
            }
            return dict
        }
    }
}

// MARK: - Text Entity

/// Represents a text entity (formatting).
struct TextEntity {
    let offset: Int32
    let length: Int32
    let type: TextEntityType

    enum TextEntityType {
        case bold
        case italic
        case underline
        case strikethrough
        case code
        case pre
        case url(String)
        case mention
        case hashtag
        case spoiler
    }
}
