//
//  BiometricService.swift
//  Margiogram
//
//  Created by Andrea Margiovanni on 2024.
//

import Foundation
import LocalAuthentication

// MARK: - Biometric Service

/// Service for handling biometric authentication (Face ID / Touch ID).
actor BiometricService {
    // MARK: - Shared Instance

    static let shared = BiometricService()

    // MARK: - Properties

    private let keychain = KeychainService.shared

    // MARK: - Initialization

    private init() {}

    // MARK: - Biometric Type

    /// The type of biometric authentication available.
    var biometricType: BiometricType {
        let context = LAContext()
        var error: NSError?

        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            return .none
        }

        switch context.biometryType {
        case .faceID:
            return .faceID
        case .touchID:
            return .touchID
        case .opticID:
            return .opticID
        case .none:
            return .none
        @unknown default:
            return .none
        }
    }

    /// Whether biometric authentication is available.
    var isBiometricAvailable: Bool {
        biometricType != .none
    }

    /// Whether biometric authentication is enabled by the user.
    var isBiometricEnabled: Bool {
        get async {
            await keychain.exists(key: KeychainService.Keys.biometricEnabled)
        }
    }

    // MARK: - Public Methods

    /// Enables biometric authentication.
    func enableBiometric() async throws {
        guard isBiometricAvailable else {
            throw BiometricError.notAvailable
        }

        // First authenticate to confirm
        try await authenticate(reason: "Enable biometric authentication")

        // Save enabled state
        try await keychain.save("true", for: KeychainService.Keys.biometricEnabled)
    }

    /// Disables biometric authentication.
    func disableBiometric() async throws {
        try await keychain.delete(key: KeychainService.Keys.biometricEnabled)
    }

    /// Authenticates the user using biometrics.
    func authenticate(reason: String) async throws {
        let context = LAContext()
        var error: NSError?

        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            if let error {
                throw BiometricError.evaluationFailed(error)
            }
            throw BiometricError.notAvailable
        }

        do {
            let success = try await context.evaluatePolicy(
                .deviceOwnerAuthenticationWithBiometrics,
                localizedReason: reason
            )

            guard success else {
                throw BiometricError.authenticationFailed
            }
        } catch let error as LAError {
            throw mapLAError(error)
        }
    }

    /// Authenticates with biometrics or falls back to passcode.
    func authenticateWithFallback(reason: String) async throws {
        let context = LAContext()
        var error: NSError?

        guard context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) else {
            if let error {
                throw BiometricError.evaluationFailed(error)
            }
            throw BiometricError.notAvailable
        }

        do {
            let success = try await context.evaluatePolicy(
                .deviceOwnerAuthentication,
                localizedReason: reason
            )

            guard success else {
                throw BiometricError.authenticationFailed
            }
        } catch let error as LAError {
            throw mapLAError(error)
        }
    }

    // MARK: - Private Methods

    private func mapLAError(_ error: LAError) -> BiometricError {
        switch error.code {
        case .authenticationFailed:
            return .authenticationFailed
        case .userCancel:
            return .userCancelled
        case .userFallback:
            return .userFallback
        case .biometryNotAvailable:
            return .notAvailable
        case .biometryNotEnrolled:
            return .notEnrolled
        case .biometryLockout:
            return .lockout
        case .passcodeNotSet:
            return .passcodeNotSet
        default:
            return .unknown(error)
        }
    }
}

// MARK: - Biometric Type

/// Type of biometric authentication.
enum BiometricType {
    case none
    case touchID
    case faceID
    case opticID

    var name: String {
        switch self {
        case .none:
            return "None"
        case .touchID:
            return "Touch ID"
        case .faceID:
            return "Face ID"
        case .opticID:
            return "Optic ID"
        }
    }

    var icon: String {
        switch self {
        case .none:
            return ""
        case .touchID:
            return "touchid"
        case .faceID:
            return "faceid"
        case .opticID:
            return "opticid"
        }
    }
}

// MARK: - Biometric Error

enum BiometricError: LocalizedError {
    case notAvailable
    case notEnrolled
    case authenticationFailed
    case userCancelled
    case userFallback
    case lockout
    case passcodeNotSet
    case evaluationFailed(Error)
    case unknown(Error)

    var errorDescription: String? {
        switch self {
        case .notAvailable:
            return "Biometric authentication is not available"
        case .notEnrolled:
            return "No biometric data enrolled"
        case .authenticationFailed:
            return "Authentication failed"
        case .userCancelled:
            return "Authentication was cancelled"
        case .userFallback:
            return "User chose to use passcode"
        case .lockout:
            return "Biometric authentication is locked"
        case .passcodeNotSet:
            return "Device passcode is not set"
        case .evaluationFailed(let error):
            return "Evaluation failed: \(error.localizedDescription)"
        case .unknown(let error):
            return "Unknown error: \(error.localizedDescription)"
        }
    }
}
