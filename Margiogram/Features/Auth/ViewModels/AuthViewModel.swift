//
//  AuthViewModel.swift
//  Margiogram
//
//  Created by Andrea Margiovanni on 2024.
//

import Foundation
import SwiftUI
import OSLog

// MARK: - Auth View Model

/// ViewModel for the authentication flow.
///
/// This ViewModel coordinates between the UI and the `AuthenticationManager`,
/// handling input validation, state management, and user interactions.
@MainActor
@Observable
final class AuthViewModel {
    // MARK: - Properties

    /// The authentication manager.
    private let authManager: AuthenticationManager

    /// Logger for debugging.
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "AuthViewModel")

    // MARK: - Phone Input State

    /// The phone number entered by the user.
    var phoneNumber: String = ""

    /// The selected country for the phone number.
    var selectedCountry: Country = .italy

    /// Whether the country picker is shown.
    var showCountryPicker: Bool = false

    // MARK: - Code Verification State

    /// The verification code entered by the user.
    var verificationCode: String = ""

    /// Time remaining before code can be resent.
    var resendTimeRemaining: Int = 0

    /// Timer for resend countdown.
    private var resendTimer: Timer?

    // MARK: - Password State

    /// The 2FA password entered by the user.
    var password: String = ""

    /// Whether to show the password in plain text.
    var showPassword: Bool = false

    // MARK: - Registration State

    /// First name for registration.
    var firstName: String = ""

    /// Last name for registration.
    var lastName: String = ""

    // MARK: - UI State

    /// Whether a shake animation should play.
    var shouldShake: Bool = false

    // MARK: - Computed Properties

    /// The current authorization state.
    var authState: AuthorizationState {
        authManager.state
    }

    /// Whether the app is processing a request.
    var isProcessing: Bool {
        authManager.isProcessing
    }

    /// The current error, if any.
    var error: AuthenticationError? {
        authManager.error
    }

    /// Whether the phone number is valid.
    var isPhoneNumberValid: Bool {
        let digits = phoneNumber.filter { $0.isNumber }
        return digits.count >= 7
    }

    /// The full phone number with country code.
    var fullPhoneNumber: String {
        selectedCountry.dialCode + phoneNumber.filter { $0.isNumber }
    }

    /// Whether the verification code is valid.
    var isCodeValid: Bool {
        verificationCode.count >= 5
    }

    /// Whether the password is valid.
    var isPasswordValid: Bool {
        !password.isEmpty
    }

    /// Whether the registration data is valid.
    var isRegistrationValid: Bool {
        !firstName.trimmingCharacters(in: .whitespaces).isEmpty
    }

    /// Whether the resend button should be enabled.
    var canResendCode: Bool {
        resendTimeRemaining <= 0
    }

    /// The code info for the current verification step.
    var codeInfo: AuthCodeInfo? {
        if case .waitingForCode(let info) = authState {
            return info
        }
        return nil
    }

    /// The password hint for the current 2FA step.
    var passwordHint: String? {
        if case .waitingForPassword(let hint) = authState {
            return hint.isEmpty ? nil : hint
        }
        return nil
    }

    // MARK: - Initialization

    init(authManager: AuthenticationManager = AuthenticationManager()) {
        self.authManager = authManager
    }

    // MARK: - Public Methods

    /// Initializes the authentication flow.
    func initialize() async {
        logger.info("Initializing auth view model")
        await authManager.initialize()
    }

    /// Submits the phone number.
    func submitPhoneNumber() async {
        logger.info("Submitting phone number")

        do {
            try await authManager.sendPhoneNumber(fullPhoneNumber)
            resetPhoneState()
        } catch {
            triggerShake()
            logger.error("Failed to submit phone number: \(error.localizedDescription)")
        }
    }

    /// Submits the verification code.
    func submitCode() async {
        logger.info("Submitting verification code")

        do {
            try await authManager.verifyCode(verificationCode)
            resetCodeState()
        } catch {
            triggerShake()
            verificationCode = ""
            logger.error("Failed to verify code: \(error.localizedDescription)")
        }
    }

    /// Requests a new verification code.
    func resendCode() async {
        logger.info("Requesting new code")

        do {
            try await authManager.resendCode()
            startResendTimer()
        } catch {
            logger.error("Failed to resend code: \(error.localizedDescription)")
        }
    }

    /// Submits the 2FA password.
    func submitPassword() async {
        logger.info("Submitting 2FA password")

        do {
            try await authManager.verifyPassword(password)
            resetPasswordState()
        } catch {
            triggerShake()
            logger.error("Failed to verify password: \(error.localizedDescription)")
        }
    }

    /// Submits the registration data.
    func submitRegistration() async {
        logger.info("Submitting registration")

        // In real implementation, this would call authManager.register()
        // For now, we just log
        logger.info("Registration: \(firstName) \(lastName)")
    }

    /// Clears the current error.
    func clearError() {
        authManager.clearError()
    }

    /// Starts the resend countdown timer.
    func startResendTimer() {
        guard let codeInfo else { return }

        resendTimeRemaining = Int(codeInfo.timeout)
        resendTimer?.invalidate()

        resendTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] timer in
            Task { @MainActor in
                guard let self else {
                    timer.invalidate()
                    return
                }

                if self.resendTimeRemaining > 0 {
                    self.resendTimeRemaining -= 1
                } else {
                    timer.invalidate()
                }
            }
        }
    }

    /// Logs out the current user.
    func logout() async {
        logger.info("Logging out")

        do {
            try await authManager.logout()
            resetAllState()
        } catch {
            logger.error("Failed to logout: \(error.localizedDescription)")
        }
    }

    // MARK: - Private Methods

    private func triggerShake() {
        withAnimation(.default) {
            shouldShake.toggle()
        }
    }

    private func resetPhoneState() {
        phoneNumber = ""
    }

    private func resetCodeState() {
        verificationCode = ""
        resendTimeRemaining = 0
        resendTimer?.invalidate()
        resendTimer = nil
    }

    private func resetPasswordState() {
        password = ""
        showPassword = false
    }

    private func resetAllState() {
        resetPhoneState()
        resetCodeState()
        resetPasswordState()
        firstName = ""
        lastName = ""
    }
}

// MARK: - Preview Helpers

extension AuthViewModel {
    /// Creates a preview instance with a specific state.
    static func preview(state: AuthorizationState = .waitingForPhoneNumber) -> AuthViewModel {
        let viewModel = AuthViewModel()
        // In real implementation, we'd inject a mock auth manager
        return viewModel
    }
}
