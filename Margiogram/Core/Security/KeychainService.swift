//
//  KeychainService.swift
//  Margiogram
//
//  Created by Andrea Margiovanni on 2024.
//

import Foundation
import Security

// MARK: - Keychain Service

/// Service for securely storing sensitive data in the keychain.
actor KeychainService {
    // MARK: - Shared Instance

    static let shared = KeychainService()

    // MARK: - Constants

    private let serviceName = "com.margiovanni.margiogram"

    // MARK: - Initialization

    private init() {}

    // MARK: - Public Methods

    /// Saves data to the keychain.
    func save(_ data: Data, for key: String) throws {
        // Delete existing item first
        try? delete(key: key)

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        ]

        let status = SecItemAdd(query as CFDictionary, nil)

        guard status == errSecSuccess else {
            throw KeychainError.saveFailed(status)
        }
    }

    /// Saves a string to the keychain.
    func save(_ string: String, for key: String) throws {
        guard let data = string.data(using: .utf8) else {
            throw KeychainError.encodingFailed
        }
        try save(data, for: key)
    }

    /// Saves a codable object to the keychain.
    func save<T: Codable>(_ object: T, for key: String) throws {
        let data = try JSONEncoder().encode(object)
        try save(data, for: key)
    }

    /// Loads data from the keychain.
    func load(key: String) throws -> Data {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess else {
            throw KeychainError.itemNotFound
        }

        guard let data = result as? Data else {
            throw KeychainError.invalidData
        }

        return data
    }

    /// Loads a string from the keychain.
    func loadString(key: String) throws -> String {
        let data = try load(key: key)
        guard let string = String(data: data, encoding: .utf8) else {
            throw KeychainError.decodingFailed
        }
        return string
    }

    /// Loads a codable object from the keychain.
    func load<T: Codable>(key: String, as type: T.Type) throws -> T {
        let data = try load(key: key)
        return try JSONDecoder().decode(type, from: data)
    }

    /// Deletes data from the keychain.
    func delete(key: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: key
        ]

        let status = SecItemDelete(query as CFDictionary)

        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.deleteFailed(status)
        }
    }

    /// Checks if a key exists in the keychain.
    func exists(key: String) -> Bool {
        do {
            _ = try load(key: key)
            return true
        } catch {
            return false
        }
    }

    /// Deletes all items from the keychain for this service.
    func deleteAll() throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName
        ]

        let status = SecItemDelete(query as CFDictionary)

        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.deleteFailed(status)
        }
    }
}

// MARK: - Keychain Keys

extension KeychainService {
    enum Keys {
        static let authToken = "auth_token"
        static let userId = "user_id"
        static let encryptionKey = "encryption_key"
        static let passcode = "passcode"
        static let passcodeHash = "passcode_hash"
        static let biometricEnabled = "biometric_enabled"
    }
}

// MARK: - Keychain Error

enum KeychainError: LocalizedError {
    case saveFailed(OSStatus)
    case deleteFailed(OSStatus)
    case itemNotFound
    case invalidData
    case encodingFailed
    case decodingFailed

    var errorDescription: String? {
        switch self {
        case .saveFailed(let status):
            return "Failed to save to keychain: \(status)"
        case .deleteFailed(let status):
            return "Failed to delete from keychain: \(status)"
        case .itemNotFound:
            return "Item not found in keychain"
        case .invalidData:
            return "Invalid data in keychain"
        case .encodingFailed:
            return "Failed to encode data"
        case .decodingFailed:
            return "Failed to decode data"
        }
    }
}
