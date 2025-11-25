---
model: claude-opus-4-5-20251101
description: Security audit and best practices implementation (use Opus for thorough analysis)
updated: 2025-11
---

# Security Command

Esegui audit di sicurezza e implementa best practices.

## Utilizzo

```
/security [audit|fix|encrypt] [target]
```

## Security Audit Checklist

### 1. Authentication & Authorization

```markdown
- [ ] Token salvati in Keychain (non UserDefaults)
- [ ] Session timeout implementato
- [ ] Biometric auth disponibile (Face ID/Touch ID)
- [ ] 2FA supportato
- [ ] Logout pulisce tutti i dati sensibili
- [ ] Rate limiting per tentativi login
```

### 2. Data Storage

```markdown
- [ ] Dati sensibili criptati at rest
- [ ] Nessun dato sensibile in logs
- [ ] Nessun dato sensibile in crash reports
- [ ] Backup iCloud appropriatamente configurato
- [ ] Core Data/SwiftData con encryption se necessario
- [ ] File temporanei puliti correttamente
```

### 3. Network Security

```markdown
- [ ] Solo HTTPS (ATS configurato correttamente)
- [ ] Certificate pinning per API critiche
- [ ] Nessun dato sensibile in URL (query params)
- [ ] Headers sensibili non loggati
- [ ] Timeout appropriati
- [ ] Gestione errori non rivela info di sistema
```

### 4. Input Validation

```markdown
- [ ] Tutti gli input utente validati
- [ ] Sanitizzazione per injection attacks
- [ ] Limiti su lunghezza input
- [ ] Validazione formato (email, phone, etc.)
- [ ] File upload validation (tipo, dimensione)
```

### 5. Code Security

```markdown
- [ ] Nessun secret hardcoded
- [ ] Nessun debug code in produzione
- [ ] Obfuscation per release build
- [ ] Jailbreak/root detection (se necessario)
- [ ] Anti-tampering measures
- [ ] Nessuna API key esposta
```

## Implementation Guide

### Keychain Storage

```swift
import Security

/// Secure storage service using Keychain
final class KeychainService {
    enum Key: String, CaseIterable {
        case authToken
        case refreshToken
        case encryptionKey
        case userId
        case biometricEnabled
    }

    enum KeychainError: Error {
        case itemNotFound
        case duplicateItem
        case unexpectedStatus(OSStatus)
        case encodingFailed
        case decodingFailed
    }

    static let shared = KeychainService()
    private init() {}

    // MARK: - Save

    func save(_ value: String, for key: Key) throws {
        guard let data = value.data(using: .utf8) else {
            throw KeychainError.encodingFailed
        }
        try save(data, for: key)
    }

    func save(_ data: Data, for key: Key) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key.rawValue,
            kSecAttrService as String: Bundle.main.bundleIdentifier!,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]

        // Delete existing item
        SecItemDelete(query as CFDictionary)

        // Add new item
        let status = SecItemAdd(query as CFDictionary, nil)

        guard status == errSecSuccess else {
            throw KeychainError.unexpectedStatus(status)
        }
    }

    // MARK: - Retrieve

    func getString(for key: Key) throws -> String {
        let data = try getData(for: key)
        guard let string = String(data: data, encoding: .utf8) else {
            throw KeychainError.decodingFailed
        }
        return string
    }

    func getData(for key: Key) throws -> Data {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key.rawValue,
            kSecAttrService as String: Bundle.main.bundleIdentifier!,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess else {
            if status == errSecItemNotFound {
                throw KeychainError.itemNotFound
            }
            throw KeychainError.unexpectedStatus(status)
        }

        guard let data = result as? Data else {
            throw KeychainError.decodingFailed
        }

        return data
    }

    // MARK: - Delete

    func delete(key: Key) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key.rawValue,
            kSecAttrService as String: Bundle.main.bundleIdentifier!
        ]

        let status = SecItemDelete(query as CFDictionary)

        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.unexpectedStatus(status)
        }
    }

    func deleteAll() {
        for key in Key.allCases {
            try? delete(key: key)
        }
    }
}
```

### Biometric Authentication

```swift
import LocalAuthentication

final class BiometricAuthService {
    enum BiometricType {
        case none
        case touchID
        case faceID
    }

    enum BiometricError: Error {
        case notAvailable
        case notEnrolled
        case failed
        case cancelled
        case lockedOut
    }

    static let shared = BiometricAuthService()
    private init() {}

    var biometricType: BiometricType {
        let context = LAContext()
        var error: NSError?

        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            return .none
        }

        switch context.biometryType {
        case .touchID:
            return .touchID
        case .faceID:
            return .faceID
        default:
            return .none
        }
    }

    var isBiometricAvailable: Bool {
        biometricType != .none
    }

    func authenticate(reason: String) async throws -> Bool {
        let context = LAContext()
        var error: NSError?

        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            if let error = error {
                throw mapError(error)
            }
            throw BiometricError.notAvailable
        }

        do {
            return try await context.evaluatePolicy(
                .deviceOwnerAuthenticationWithBiometrics,
                localizedReason: reason
            )
        } catch let error as LAError {
            throw mapLAError(error)
        }
    }

    private func mapError(_ error: NSError) -> BiometricError {
        switch error.code {
        case LAError.biometryNotAvailable.rawValue:
            return .notAvailable
        case LAError.biometryNotEnrolled.rawValue:
            return .notEnrolled
        case LAError.biometryLockout.rawValue:
            return .lockedOut
        default:
            return .failed
        }
    }

    private func mapLAError(_ error: LAError) -> BiometricError {
        switch error.code {
        case .userCancel, .systemCancel, .appCancel:
            return .cancelled
        case .biometryLockout:
            return .lockedOut
        default:
            return .failed
        }
    }
}
```

### Data Encryption

```swift
import CryptoKit

final class EncryptionService {
    static let shared = EncryptionService()

    private var key: SymmetricKey {
        get throws {
            // Try to get existing key
            if let keyData = try? KeychainService.shared.getData(for: .encryptionKey) {
                return SymmetricKey(data: keyData)
            }

            // Generate new key
            let newKey = SymmetricKey(size: .bits256)
            let keyData = newKey.withUnsafeBytes { Data($0) }
            try KeychainService.shared.save(keyData, for: .encryptionKey)
            return newKey
        }
    }

    func encrypt(_ data: Data) throws -> Data {
        let sealedBox = try AES.GCM.seal(data, using: key)
        guard let combined = sealedBox.combined else {
            throw EncryptionError.encryptionFailed
        }
        return combined
    }

    func decrypt(_ data: Data) throws -> Data {
        let sealedBox = try AES.GCM.SealedBox(combined: data)
        return try AES.GCM.open(sealedBox, using: key)
    }

    func encrypt(_ string: String) throws -> Data {
        guard let data = string.data(using: .utf8) else {
            throw EncryptionError.invalidInput
        }
        return try encrypt(data)
    }

    func decryptToString(_ data: Data) throws -> String {
        let decrypted = try decrypt(data)
        guard let string = String(data: decrypted, encoding: .utf8) else {
            throw EncryptionError.decryptionFailed
        }
        return string
    }

    enum EncryptionError: Error {
        case invalidInput
        case encryptionFailed
        case decryptionFailed
    }
}
```

### Input Validation

```swift
import Foundation

enum ValidationResult {
    case valid
    case invalid(reason: String)
}

struct InputValidator {
    // MARK: - Text Validation

    static func validateText(
        _ text: String,
        minLength: Int = 1,
        maxLength: Int = 4096,
        allowedCharacters: CharacterSet? = nil
    ) -> ValidationResult {
        guard !text.isEmpty else {
            return .invalid(reason: "Text cannot be empty")
        }

        guard text.count >= minLength else {
            return .invalid(reason: "Text must be at least \(minLength) characters")
        }

        guard text.count <= maxLength else {
            return .invalid(reason: "Text must not exceed \(maxLength) characters")
        }

        if let allowed = allowedCharacters {
            let invalidChars = text.unicodeScalars.filter { !allowed.contains($0) }
            if !invalidChars.isEmpty {
                return .invalid(reason: "Text contains invalid characters")
            }
        }

        return .valid
    }

    // MARK: - Phone Validation

    static func validatePhoneNumber(_ phone: String) -> ValidationResult {
        let cleaned = phone.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()

        guard cleaned.count >= 7 && cleaned.count <= 15 else {
            return .invalid(reason: "Invalid phone number format")
        }

        return .valid
    }

    // MARK: - Email Validation

    static func validateEmail(_ email: String) -> ValidationResult {
        let emailRegex = #"^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$"#
        let predicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)

        guard predicate.evaluate(with: email) else {
            return .invalid(reason: "Invalid email format")
        }

        return .valid
    }

    // MARK: - Password Validation

    static func validatePassword(_ password: String) -> ValidationResult {
        guard password.count >= 8 else {
            return .invalid(reason: "Password must be at least 8 characters")
        }

        guard password.count <= 128 else {
            return .invalid(reason: "Password is too long")
        }

        // Check for at least one uppercase, one lowercase, one digit
        let hasUppercase = password.contains { $0.isUppercase }
        let hasLowercase = password.contains { $0.isLowercase }
        let hasDigit = password.contains { $0.isNumber }

        guard hasUppercase && hasLowercase && hasDigit else {
            return .invalid(reason: "Password must contain uppercase, lowercase, and digit")
        }

        return .valid
    }

    // MARK: - URL Validation

    static func validateURL(_ urlString: String) -> ValidationResult {
        guard let url = URL(string: urlString) else {
            return .invalid(reason: "Invalid URL format")
        }

        // Only allow HTTPS
        guard url.scheme == "https" else {
            return .invalid(reason: "Only HTTPS URLs are allowed")
        }

        return .valid
    }

    // MARK: - File Validation

    static func validateFile(
        at url: URL,
        maxSize: Int64 = 50 * 1024 * 1024,  // 50 MB
        allowedTypes: [String] = []
    ) -> ValidationResult {
        let fileManager = FileManager.default

        guard fileManager.fileExists(atPath: url.path) else {
            return .invalid(reason: "File does not exist")
        }

        do {
            let attributes = try fileManager.attributesOfItem(atPath: url.path)
            let fileSize = attributes[.size] as? Int64 ?? 0

            guard fileSize <= maxSize else {
                return .invalid(reason: "File exceeds maximum size")
            }

            if !allowedTypes.isEmpty {
                let fileExtension = url.pathExtension.lowercased()
                guard allowedTypes.contains(fileExtension) else {
                    return .invalid(reason: "File type not allowed")
                }
            }

            return .valid
        } catch {
            return .invalid(reason: "Cannot read file attributes")
        }
    }
}
```

### Secure Logging

```swift
import OSLog

/// Logger that ensures no sensitive data is logged
enum SecureLogger {
    private static let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier!,
        category: "App"
    )

    static func debug(_ message: String) {
        #if DEBUG
        logger.debug("\(sanitize(message))")
        #endif
    }

    static func info(_ message: String) {
        logger.info("\(sanitize(message))")
    }

    static func error(_ message: String) {
        logger.error("\(sanitize(message))")
    }

    static func error(_ error: Error) {
        // Never log full error details in production
        #if DEBUG
        logger.error("Error: \(error.localizedDescription)")
        #else
        logger.error("An error occurred")
        #endif
    }

    // MARK: - Sanitization

    private static func sanitize(_ message: String) -> String {
        var sanitized = message

        // Remove potential tokens
        sanitized = sanitized.replacingOccurrences(
            of: #"[A-Za-z0-9-_]{20,}"#,
            with: "[REDACTED]",
            options: .regularExpression
        )

        // Remove potential emails
        sanitized = sanitized.replacingOccurrences(
            of: #"[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}"#,
            with: "[EMAIL]",
            options: .regularExpression
        )

        // Remove potential phone numbers
        sanitized = sanitized.replacingOccurrences(
            of: #"\+?[\d\s-]{10,}"#,
            with: "[PHONE]",
            options: .regularExpression
        )

        return sanitized
    }
}
```

### Network Security

```swift
import Foundation

/// Secure URL session configuration
final class SecureNetworkService {
    static let shared = SecureNetworkService()

    private lazy var session: URLSession = {
        let config = URLSessionConfiguration.default

        // Timeout settings
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 60

        // Cache policy
        config.requestCachePolicy = .reloadIgnoringLocalCacheData

        // Only HTTPS
        config.tlsMinimumSupportedProtocolVersion = .TLSv12

        return URLSession(configuration: config, delegate: self, delegateQueue: nil)
    }()

    private let pinnedCertificates: [String: [Data]] = [
        // Add your pinned certificates here
        // "api.telegram.org": [certificateData]
    ]
}

extension SecureNetworkService: URLSessionDelegate {
    func urlSession(
        _ session: URLSession,
        didReceive challenge: URLAuthenticationChallenge,
        completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void
    ) {
        guard challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust,
              let serverTrust = challenge.protectionSpace.serverTrust,
              let hostname = challenge.protectionSpace.host as String?,
              let pinnedCerts = pinnedCertificates[hostname] else {
            completionHandler(.performDefaultHandling, nil)
            return
        }

        // Certificate pinning validation
        let serverCertificates = extractCertificates(from: serverTrust)

        let isPinned = serverCertificates.contains { serverCert in
            pinnedCerts.contains(serverCert)
        }

        if isPinned {
            let credential = URLCredential(trust: serverTrust)
            completionHandler(.useCredential, credential)
        } else {
            completionHandler(.cancelAuthenticationChallenge, nil)
        }
    }

    private func extractCertificates(from trust: SecTrust) -> [Data] {
        var certificates: [Data] = []

        if #available(iOS 15.0, macOS 12.0, *) {
            if let chain = SecTrustCopyCertificateChain(trust) as? [SecCertificate] {
                certificates = chain.map { SecCertificateCopyData($0) as Data }
            }
        } else {
            for i in 0..<SecTrustGetCertificateCount(trust) {
                if let cert = SecTrustGetCertificateAtIndex(trust, i) {
                    certificates.append(SecCertificateCopyData(cert) as Data)
                }
            }
        }

        return certificates
    }
}
```

## Security Audit Report Template

```markdown
# Security Audit Report

**Date**: [Date]
**Version**: [App Version]
**Auditor**: [Name/AI]

## Summary

| Category | Status | Issues |
|----------|--------|--------|
| Authentication | ✅/⚠️/❌ | X |
| Data Storage | ✅/⚠️/❌ | X |
| Network | ✅/⚠️/❌ | X |
| Input Validation | ✅/⚠️/❌ | X |
| Code Security | ✅/⚠️/❌ | X |

## Critical Issues
1. [Issue description]
   - **Location**: file:line
   - **Risk**: High/Medium/Low
   - **Fix**: [Recommended fix]

## Recommendations
1. [Recommendation]

## Passed Checks
- [x] Check 1
- [x] Check 2

## Next Steps
1. [Action item]
```
