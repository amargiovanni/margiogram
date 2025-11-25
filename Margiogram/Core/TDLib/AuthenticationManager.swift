//
//  AuthenticationManager.swift
//  Margiogram
//
//  Created by Andrea Margiovanni on 2024.
//

import Foundation
import OSLog
import Combine

// MARK: - Authorization State

/// Represents the current authorization state.
enum AuthorizationState: Equatable {
    case loading
    case unauthorized
    case waitingForPhoneNumber
    case waitingForCode(codeInfo: AuthCodeInfo)
    case waitingForPassword(hint: String)
    case waitingForRegistration
    case authorized
}

/// Information about the authentication code.
struct AuthCodeInfo: Equatable {
    let phoneNumber: String
    let type: CodeType
    let nextType: CodeType?
    let timeout: Int32

    enum CodeType: Equatable {
        case sms
        case call
        case flashCall
        case missedCall(pattern: String)
        case fragment
    }
}

// MARK: - Authentication Manager

/// Manages user authentication with Telegram.
///
/// This class handles the complete authentication flow:
/// 1. Phone number input
/// 2. Code verification (SMS/Call)
/// 3. 2FA password (if enabled)
/// 4. Registration (for new users)
///
/// ## Usage
///
/// ```swift
/// let authManager = AuthenticationManager()
/// await authManager.initialize()
///
/// try await authManager.sendPhoneNumber("+1234567890")
/// try await authManager.verifyCode("12345")
/// ```
@MainActor
final class AuthenticationManager: ObservableObject {
    // MARK: - Published Properties

    @Published private(set) var state: AuthorizationState = .loading
    @Published private(set) var isProcessing = false
    @Published private(set) var error: AuthenticationError?

    // MARK: - Properties

    private let client: TDLibClient
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "Auth")
    private var updateTask: Task<Void, Never>?

    // MARK: - Initialization

    init(client: TDLibClient = .shared) {
        self.client = client
    }

    deinit {
        updateTask?.cancel()
    }

    // MARK: - Public Methods

    /// Initializes the authentication manager and starts listening for updates.
    func initialize() async {
        logger.info("Initializing authentication manager")

        await client.start()

        // Start listening for authorization state updates
        updateTask = Task {
            for await update in await client.updates {
                await handleUpdate(update)
            }
        }

        // For now, simulate unauthorized state
        // In real implementation, TDLib would send the current auth state
        try? await Task.sleep(for: .seconds(0.5))
        state = .waitingForPhoneNumber
    }

    /// Sends the phone number to start authentication.
    ///
    /// - Parameter phoneNumber: The phone number in international format (e.g., +1234567890).
    /// - Throws: `AuthenticationError` if the operation fails.
    func sendPhoneNumber(_ phoneNumber: String) async throws {
        guard !isProcessing else {
            throw AuthenticationError.alreadyProcessing
        }

        guard isValidPhoneNumber(phoneNumber) else {
            throw AuthenticationError.invalidPhoneNumber
        }

        isProcessing = true
        error = nil

        defer { isProcessing = false }

        logger.info("Sending phone number")

        do {
            _ = try await client.send(SetAuthenticationPhoneNumber(phoneNumber: phoneNumber))

            // Simulate successful code sent
            state = .waitingForCode(codeInfo: AuthCodeInfo(
                phoneNumber: phoneNumber,
                type: .sms,
                nextType: .call,
                timeout: 60
            ))
        } catch {
            self.error = .networkError(error)
            throw error
        }
    }

    /// Verifies the authentication code.
    ///
    /// - Parameter code: The verification code received via SMS/Call.
    /// - Throws: `AuthenticationError` if the code is invalid.
    func verifyCode(_ code: String) async throws {
        guard !isProcessing else {
            throw AuthenticationError.alreadyProcessing
        }

        guard isValidCode(code) else {
            throw AuthenticationError.invalidCode
        }

        isProcessing = true
        error = nil

        defer { isProcessing = false }

        logger.info("Verifying authentication code")

        do {
            _ = try await client.send(CheckAuthenticationCode(code: code))

            // Simulate successful verification
            state = .authorized
        } catch let tdError as TDLibError {
            switch tdError {
            case .api(let code, let message) where code == 400:
                self.error = .invalidCode
                throw AuthenticationError.invalidCode
            default:
                self.error = .networkError(tdError)
                throw tdError
            }
        } catch {
            self.error = .networkError(error)
            throw error
        }
    }

    /// Verifies the 2FA password.
    ///
    /// - Parameter password: The two-factor authentication password.
    /// - Throws: `AuthenticationError` if the password is incorrect.
    func verifyPassword(_ password: String) async throws {
        guard !isProcessing else {
            throw AuthenticationError.alreadyProcessing
        }

        guard !password.isEmpty else {
            throw AuthenticationError.invalidPassword
        }

        isProcessing = true
        error = nil

        defer { isProcessing = false }

        logger.info("Verifying 2FA password")

        do {
            _ = try await client.send(CheckAuthenticationPassword(password: password))
            state = .authorized
        } catch let tdError as TDLibError {
            switch tdError {
            case .api(let code, _) where code == 400:
                self.error = .invalidPassword
                throw AuthenticationError.invalidPassword
            default:
                self.error = .networkError(tdError)
                throw tdError
            }
        } catch {
            self.error = .networkError(error)
            throw error
        }
    }

    /// Requests a new authentication code.
    func resendCode() async throws {
        guard case .waitingForCode = state else {
            throw AuthenticationError.invalidState
        }

        isProcessing = true
        defer { isProcessing = false }

        logger.info("Requesting new authentication code")

        // In real implementation: await client.send(ResendAuthenticationCode())
    }

    /// Logs out the current user.
    func logout() async throws {
        logger.info("Logging out")

        // In real implementation: await client.send(LogOut())
        state = .waitingForPhoneNumber
    }

    /// Clears the current error.
    func clearError() {
        error = nil
    }

    // MARK: - Private Methods

    private func handleUpdate(_ update: TDUpdate) async {
        switch update {
        case .authorizationStateUpdate(let authState):
            handleAuthorizationStateUpdate(authState)
        default:
            break
        }
    }

    private func handleAuthorizationStateUpdate(_ authState: AuthorizationState) {
        logger.info("Authorization state updated: \(String(describing: authState))")
        state = authState
    }

    private func isValidPhoneNumber(_ phone: String) -> Bool {
        let cleaned = phone.filter { $0.isNumber || $0 == "+" }
        return cleaned.count >= 7 && cleaned.count <= 15 && cleaned.hasPrefix("+")
    }

    private func isValidCode(_ code: String) -> Bool {
        code.count >= 4 && code.count <= 8 && code.allSatisfy { $0.isNumber }
    }
}

// MARK: - Authentication Error

/// Errors that can occur during authentication.
enum AuthenticationError: LocalizedError {
    case invalidPhoneNumber
    case invalidCode
    case invalidPassword
    case invalidState
    case alreadyProcessing
    case rateLimited(seconds: Int)
    case networkError(Error)
    case banned
    case sessionExpired

    var errorDescription: String? {
        switch self {
        case .invalidPhoneNumber:
            return "Please enter a valid phone number"
        case .invalidCode:
            return "The code you entered is incorrect"
        case .invalidPassword:
            return "The password is incorrect"
        case .invalidState:
            return "Invalid authentication state"
        case .alreadyProcessing:
            return "Please wait for the current operation to complete"
        case .rateLimited(let seconds):
            return "Too many attempts. Please try again in \(seconds) seconds"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .banned:
            return "This phone number is banned"
        case .sessionExpired:
            return "Your session has expired. Please log in again"
        }
    }
}
