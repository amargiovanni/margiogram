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
        case sms(length: Int32)
        case call(length: Int32)
        case flashCall(pattern: String)
        case missedCall(pattern: String, length: Int32)
        case fragment(url: String, length: Int32)

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
            }
        }

        var codeLength: Int32 {
            switch self {
            case .sms(let length), .call(let length), .missedCall(_, let length), .fragment(_, let length):
                return length
            case .flashCall:
                return 5
            }
        }
    }

    init(from codeInfo: CodeInfo) {
        self.phoneNumber = codeInfo.phoneNumber
        self.timeout = codeInfo.timeout

        switch codeInfo.type {
        case .sms(let length):
            self.type = .sms(length: length)
        case .call(let length):
            self.type = .call(length: length)
        case .flashCall(let pattern):
            self.type = .flashCall(pattern: pattern)
        case .missedCall(let prefix, let length):
            self.type = .missedCall(pattern: prefix, length: length)
        case .fragment(let url, let length):
            self.type = .fragment(url: url, length: length)
        default:
            self.type = .sms(length: 5)
        }

        if let nextType = codeInfo.nextType {
            switch nextType {
            case .sms(let length):
                self.nextType = .sms(length: length)
            case .call(let length):
                self.nextType = .call(length: length)
            case .flashCall(let pattern):
                self.nextType = .flashCall(pattern: pattern)
            case .missedCall(let prefix, let length):
                self.nextType = .missedCall(pattern: prefix, length: length)
            case .fragment(let url, let length):
                self.nextType = .fragment(url: url, length: length)
            default:
                self.nextType = nil
            }
        } else {
            self.nextType = nil
        }
    }

    init(phoneNumber: String, type: CodeType, nextType: CodeType?, timeout: Int32) {
        self.phoneNumber = phoneNumber
        self.type = type
        self.nextType = nextType
        self.timeout = timeout
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
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "Margiogram", category: "Auth")
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialization

    init(client: TDLibClient = .shared) {
        self.client = client
        setupObservers()
    }

    // MARK: - Setup

    private func setupObservers() {
        // Observe TDLibClient's authorization state
        client.$authorizationState
            .receive(on: DispatchQueue.main)
            .sink { [weak self] tdAuthState in
                self?.handleTDAuthorizationState(tdAuthState)
            }
            .store(in: &cancellables)
    }

    // MARK: - Public Methods

    /// Initializes the authentication manager and starts the TDLib client.
    func initialize() {
        logger.info("Initializing authentication manager")
        client.start()
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
            try await client.setAuthenticationPhoneNumber(phoneNumber)
            logger.info("Phone number sent successfully")
        } catch {
            logger.error("Failed to send phone number: \(error.localizedDescription)")
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
            try await client.checkAuthenticationCode(code)
            logger.info("Authentication code verified successfully")
        } catch {
            logger.error("Failed to verify code: \(error.localizedDescription)")
            // Check if it's an invalid code error
            if let tdError = error as? TDLibError {
                switch tdError {
                case .api(let code, _) where code == 400:
                    self.error = .invalidCode
                    throw AuthenticationError.invalidCode
                default:
                    self.error = .networkError(error)
                    throw error
                }
            } else {
                self.error = .networkError(error)
                throw error
            }
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
            try await client.checkAuthenticationPassword(password)
            logger.info("Password verified successfully")
        } catch {
            logger.error("Failed to verify password: \(error.localizedDescription)")
            if let tdError = error as? TDLibError {
                switch tdError {
                case .api(let code, _) where code == 400:
                    self.error = .invalidPassword
                    throw AuthenticationError.invalidPassword
                default:
                    self.error = .networkError(error)
                    throw error
                }
            } else {
                self.error = .networkError(error)
                throw error
            }
        }
    }

    /// Registers a new user.
    ///
    /// - Parameters:
    ///   - firstName: The user's first name.
    ///   - lastName: The user's last name (optional).
    /// - Throws: `AuthenticationError` if registration fails.
    func registerUser(firstName: String, lastName: String = "") async throws {
        guard !isProcessing else {
            throw AuthenticationError.alreadyProcessing
        }

        guard !firstName.isEmpty else {
            throw AuthenticationError.invalidState
        }

        isProcessing = true
        error = nil

        defer { isProcessing = false }

        logger.info("Registering new user: \(firstName)")

        do {
            try await client.registerUser(firstName: firstName, lastName: lastName)
            logger.info("User registered successfully")
        } catch {
            logger.error("Failed to register user: \(error.localizedDescription)")
            self.error = .networkError(error)
            throw error
        }
    }

    /// Requests a new authentication code.
    ///
    /// - Throws: `AuthenticationError` if the operation fails.
    func resendCode() async throws {
        guard !isProcessing else {
            throw AuthenticationError.alreadyProcessing
        }

        isProcessing = true
        error = nil

        defer { isProcessing = false }

        logger.info("Requesting new authentication code")

        do {
            try await client.resendAuthenticationCode()
            logger.info("New code requested successfully")
        } catch {
            logger.error("Failed to resend code: \(error.localizedDescription)")
            self.error = .networkError(error)
            throw error
        }
    }

    /// Logs out the current user.
    func logout() async throws {
        logger.info("Logging out")

        do {
            try await client.logOut()
            logger.info("Logged out successfully")
        } catch {
            logger.error("Failed to log out: \(error.localizedDescription)")
            throw error
        }
    }

    /// Clears the current error.
    func clearError() {
        error = nil
    }

    // MARK: - Private Methods

    private func handleTDAuthorizationState(_ tdState: TDAuthorizationState) {
        logger.info("TDLib authorization state changed: \(String(describing: tdState))")

        switch tdState {
        case .waitingForTdlibParameters:
            state = .loading

        case .waitingForPhoneNumber:
            state = .waitingForPhoneNumber

        case .waitingForCode(let codeInfo):
            state = .waitingForCode(codeInfo: AuthCodeInfo(from: codeInfo))

        case .waitingForPassword(let hint):
            state = .waitingForPassword(hint: hint)

        case .waitingForRegistration:
            state = .waitingForRegistration

        case .ready:
            state = .authorized

        case .loggingOut, .closing:
            state = .loading

        case .closed:
            state = .waitingForPhoneNumber
        }
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
