//
//  TDLibClient.swift
//  Margiogram
//
//  Created by Andrea Margiovanni on 2024.
//

import Foundation
import OSLog

// MARK: - TDLib Client

/// Main TDLib client wrapper for communicating with Telegram servers.
///
/// This is a mock implementation for development/testing. In production,
/// this would integrate with the real TDLib library.
@MainActor
final class TDLibClient: ObservableObject {
    // MARK: - Singleton

    static let shared = TDLibClient()

    // MARK: - Properties

    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "Margiogram", category: "TDLib")

    /// Current connection state
    @Published private(set) var connectionState: ConnectionState = .waitingForNetwork

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

    /// Set to true to enable mock mode (skips real auth, shows mock data)
    static var useMockData = true

    /// Simulated delay for API calls
    private let simulatedDelay: Duration = .milliseconds(500)

    // MARK: - Initialization

    private init() {
        logger.info("TDLibClient initialized (Mock Mode: \(Self.useMockData))")
    }

    // MARK: - Public Methods

    /// Starts the TDLib client and begins receiving updates.
    func start() {
        guard !isRunning else {
            logger.warning("TDLib client already started")
            return
        }

        isRunning = true
        logger.info("TDLib client started")

        // Simulate startup
        Task {
            await simulateStartup()
        }
    }

    /// Stops the TDLib client.
    func stop() {
        logger.info("Stopping TDLib client...")
        isRunning = false
        logger.info("TDLib client stopped")
    }

    // MARK: - Authentication Methods

    /// Sets the phone number for authentication.
    func setAuthenticationPhoneNumber(_ phoneNumber: String) async throws {
        logger.info("Setting authentication phone number: \(phoneNumber)")

        try await Task.sleep(for: simulatedDelay)

        if Self.useMockData {
            // Simulate successful phone number submission
            authorizationState = .waitingForCode(codeInfo: CodeInfo(
                phoneNumber: phoneNumber,
                type: .sms(length: 5),
                nextType: .call(length: 5),
                timeout: 60
            ))
            logger.info("Mock: Phone number accepted, waiting for code")
        } else {
            throw TDLibError.notImplemented
        }
    }

    /// Checks the authentication code.
    func checkAuthenticationCode(_ code: String) async throws {
        logger.info("Checking authentication code")

        try await Task.sleep(for: simulatedDelay)

        if Self.useMockData {
            // Simulate successful code verification
            if code == "12345" || code.count >= 4 {
                authorizationState = .ready
                logger.info("Mock: Code verified, user authenticated")
            } else {
                throw TDLibError.api(code: 400, message: "Invalid code")
            }
        } else {
            throw TDLibError.notImplemented
        }
    }

    /// Checks the 2FA password.
    func checkAuthenticationPassword(_ password: String) async throws {
        logger.info("Checking authentication password")

        try await Task.sleep(for: simulatedDelay)

        if Self.useMockData {
            // Simulate successful password verification
            authorizationState = .ready
            logger.info("Mock: Password verified, user authenticated")
        } else {
            throw TDLibError.notImplemented
        }
    }

    /// Registers a new user.
    func registerUser(firstName: String, lastName: String) async throws {
        logger.info("Registering new user: \(firstName) \(lastName)")

        try await Task.sleep(for: simulatedDelay)

        if Self.useMockData {
            authorizationState = .ready
            logger.info("Mock: User registered")
        } else {
            throw TDLibError.notImplemented
        }
    }

    /// Resends the authentication code.
    func resendAuthenticationCode() async throws {
        logger.info("Resending authentication code")

        try await Task.sleep(for: simulatedDelay)

        if Self.useMockData {
            logger.info("Mock: New code sent")
            // In mock mode, keep the same state, just pretend a new code was sent
        } else {
            throw TDLibError.notImplemented
        }
    }

    /// Logs out the current user.
    func logOut() async throws {
        logger.info("Logging out...")

        try await Task.sleep(for: simulatedDelay)

        authorizationState = .waitingForPhoneNumber
        logger.info("Logged out successfully")
    }

    // MARK: - Private Methods

    private func simulateStartup() async {
        // Simulate TDLib initialization
        try? await Task.sleep(for: .milliseconds(300))
        connectionState = .connecting

        try? await Task.sleep(for: .milliseconds(500))
        connectionState = .ready

        try? await Task.sleep(for: .milliseconds(200))

        if Self.useMockData {
            // In mock mode, go directly to phone number input
            authorizationState = .waitingForPhoneNumber
        } else {
            authorizationState = .waitingForPhoneNumber
        }
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
